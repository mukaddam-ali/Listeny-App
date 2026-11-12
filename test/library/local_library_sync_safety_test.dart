import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/core/models/track.dart';
import 'package:listeny/core/storage/database.dart';
import 'package:listeny/library/library_repository.dart';
import 'package:listeny/library/local_library_sync_service.dart';

class FakeSource implements DeviceMp3Source {
  FakeSource(this.files);
  List<DeviceMp3> files;
  Completer<void>? gate; // blocks queryMp3Files until completed

  @override
  Future<int> sdkInt() async => 30;

  @override
  Future<List<DeviceMp3>> queryMp3Files({bool Function()? shouldStop}) async {
    await gate?.future;
    return List.of(files);
  }
}

DeviceMp3 entry(
  int id, {
  String volume = 'primary',
  String? path,
  int size = 1000,
  int modified = 100,
}) => DeviceMp3(
  id: id,
  name: 'f$id.mp3',
  path: path ?? '/storage/$volume/Music/f$id.mp3',
  sizeBytes: size,
  durationMs: 180000,
  modifiedSec: modified,
  volume: volume,
);

Track libTrack(
  String id, {
  required String path,
  String title = 'Same Title',
  int size = 1000,
}) => Track(
  id: id,
  filePath: path,
  title: title,
  artist: 'Same Artist',
  album: 'Album',
  albumArtist: 'Same Artist',
  duration: const Duration(minutes: 3),
  format: 'mp3',
  fileSizeBytes: size,
  dateAdded: DateTime.now(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late Directory docsDir;
  late Directory userDir;
  late LibraryRepository library;
  late FakeSource source;
  late Set<String> missing;
  var sameContent = false;
  // Every file gets identical tags (the "distinct recordings, same metadata"
  // situation) unless a test overrides it.
  ExtractedMetadata sameMeta(String _) => const ExtractedMetadata(
    title: 'Same Title',
    artist: 'Same Artist',
    album: 'Album',
    duration: Duration(minutes: 3),
  );

  setUp(() {
    docsDir = Directory.systemTemp.createTempSync('listeny_safe_docs');
    userDir = Directory.systemTemp.createTempSync('listeny_safe_user');
    Directory('${docsDir.path}/artwork').createSync();
    library = LibraryRepository(
      AppDatabase(NativeDatabase.memory()),
      appDocsDir: () async => docsDir,
    );
    source = FakeSource([]);
    missing = {};
    sameContent = false;
  });

  tearDown(() {
    docsDir.deleteSync(recursive: true);
    userDir.deleteSync(recursive: true);
  });

  LocalLibrarySyncService service({LibraryRepository? repo}) =>
      LocalLibrarySyncService(
        repo ?? library,
        source: source,
        ensurePermission: () async => true,
        artworkDir: () async => Directory('${docsDir.path}/artwork'),
        fileExists: (path) async => !missing.contains(path),
        contentEquals: (a, b) async => sameContent,
        extractor: (p) async => sameMeta(p),
      );

  group('concurrency', () {
    test(
      'two service instances: only one sync runs, no duplicate tracks',
      () async {
        source
          ..files = [entry(1), entry(2, size: 2000), entry(3, size: 3000)]
          ..gate = Completer<void>();
        final first = service().sync();
        await Future<void>.delayed(Duration.zero);
        final second = await service()
            .sync(); // e.g. Settings during first launch
        expect(second.outcome, SyncOutcome.alreadyRunning);

        source.gate!.complete();
        final done = await first;
        expect(done.outcome, SyncOutcome.completed);
        expect(await library.getAllTracksOnce(), hasLength(3));

        // The lock is released afterwards, for any instance.
        expect((await service().sync()).outcome, SyncOutcome.completed);
        expect(await library.getAllTracksOnce(), hasLength(3));
      },
    );

    test('the lock is released after a failure or cancel', () async {
      final token = SyncCancelToken()..cancel();
      source.files = [entry(1)];
      expect(
        (await service().sync(cancel: token)).outcome,
        SyncOutcome.cancelled,
      );
      expect((await service().sync()).outcome, SyncOutcome.completed);
    });

    test(
      'atomic claim: concurrent claims of one source/path insert exactly once',
      () async {
        final a = libTrack('a', path: '/storage/primary/Music/x.mp3');
        final b = libTrack('b', path: '/storage/primary/Music/x.mp3');
        final results = await Future.wait([
          library.claimReferencedTrack(
            a,
            sourceKey: 'ms:primary:9',
            volume: 'primary',
            sizeBytes: 1,
            modifiedSec: 1,
          ),
          library.claimReferencedTrack(
            b,
            sourceKey: 'ms:primary:9',
            volume: 'primary',
            sizeBytes: 1,
            modifiedSec: 1,
          ),
        ]);
        expect(results.where((r) => r), hasLength(1));
        final tracks = await library.getAllTracksOnce();
        expect(tracks, hasLength(1));
        expect(
          await library.isReferencedTrack(tracks.single.id),
          isTrue,
          reason: 'no track without its owning source row',
        );
      },
    );

    test(
      'a different source cannot claim an already-referenced path',
      () async {
        final a = libTrack('a', path: '/p/x.mp3');
        await library.claimReferencedTrack(
          a,
          sourceKey: 'ms:primary:1',
          volume: 'primary',
          sizeBytes: 1,
          modifiedSec: 1,
        );
        final ok = await library.claimReferencedTrack(
          libTrack('b', path: '/p/x.mp3'),
          sourceKey: 'ms:primary:2',
          volume: 'primary',
          sizeBytes: 1,
          modifiedSec: 1,
        );
        expect(ok, isFalse);
        expect(await library.getAllTracksOnce(), hasLength(1));
      },
    );
  });

  group('original-file deletion is fail-closed', () {
    test('a referenced track never deletes the original', () async {
      final original = File('${userDir.path}/mine.mp3')..writeAsBytesSync([1]);
      await library.claimReferencedTrack(
        libTrack('r', path: original.path),
        sourceKey: 'ms:primary:1',
        volume: 'primary',
        sizeBytes: 1,
        modifiedSec: 1,
      );
      await library.deleteTrackFromDevice(
        (await library.getAllTracksOnce()).single,
      );
      expect(original.existsSync(), isTrue);
    });

    test('a track with NO ownership record but an outside path is not deleted', () async {
      // e.g. an orphan from a crash/race: ownership uncertain => keep the file.
      final original = File('${userDir.path}/orphan.mp3')
        ..writeAsBytesSync([1]);
      await library.insertTrack(libTrack('o', path: original.path));
      await library.deleteTrackFromDevice(
        (await library.getAllTracksOnce()).single,
      );
      expect(original.existsSync(), isTrue);
      expect(
        await library.getAllTracksOnce(),
        isEmpty,
        reason: 'row still removed',
      );
    });

    test('an app-owned imported copy is still physically deleted', () async {
      final owned = File('${docsDir.path}/audio/imp.mp3')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      await library.insertTrack(libTrack('i', path: owned.path));
      await library.deleteTrackFromDevice(
        (await library.getAllTracksOnce()).single,
      );
      expect(owned.existsSync(), isFalse);
    });

    test(
      'if the app directory cannot be determined, nothing is deleted',
      () async {
        final repo = LibraryRepository(
          AppDatabase(NativeDatabase.memory()),
          appDocsDir: () async => throw StateError('no docs dir'),
        );
        final f = File('${docsDir.path}/audio/x.mp3')
          ..createSync(recursive: true)
          ..writeAsBytesSync([1]);
        await repo.insertTrack(libTrack('x', path: f.path));
        await repo.deleteTrackFromDevice(
          (await repo.getAllTracksOnce()).single,
        );
        expect(f.existsSync(), isTrue);
      },
    );
  });

  group('source identity and fingerprint', () {
    test(
      'same MediaStore id on different volumes are different sources',
      () async {
        source.files = [
          entry(5, volume: 'external_primary', size: 100),
          entry(5, volume: '1234-ABCD', size: 200),
        ];
        final s = await service().sync();
        expect(s.added, 2);
        final keys = (await library.getLibrarySources()).keys;
        expect(keys, containsAll(['ms:external_primary:5', 'ms:1234-ABCD:5']));
        expect((await service().sync()).added, 0);
      },
    );

    test('reused id (different file) keeps the old track protected and adds the new', () async {
      source.files = [entry(5, path: '/m/old.mp3', size: 100)];
      await service().sync();
      final oldTrack = (await library.getAllTracksOnce()).single;

      source.files = [entry(5, path: '/m/new.mp3', size: 999)];
      final s = await service().sync();
      expect(s.added, 1);
      final tracks = await library.getAllTracksOnce();
      expect(tracks, hasLength(2));
      expect(
        tracks.map((t) => t.filePath),
        containsAll(['/m/old.mp3', '/m/new.mp3']),
      );
      expect(
        await library.isReferencedTrack(oldTrack.id),
        isTrue,
        reason: 'old original stays protected under an orphan key',
      );
    });

    test(
      'changed size/mtime on the same path refreshes without a new track',
      () async {
        source.files = [entry(1, size: 1000, modified: 100)];
        await service().sync();
        source.files = [entry(1, size: 1500, modified: 200)];
        final s = await service().sync();
        expect(s.added, 0);
        expect(await library.getAllTracksOnce(), hasLength(1));
        final row = (await library.getLibrarySources())['ms:primary:1']!;
        expect(row.sizeBytes, 1500);
        expect(row.modifiedSec, 200);
        expect((await library.getAllTracksOnce()).single.fileSizeBytes, 1500);
      },
    );

    test('a legitimate move (same id, size, mtime, name; old gone, new present) re-points the track', () async {
      source.files = [entry(1, path: '/m/a.mp3')];
      await service().sync();
      final id = (await library.getAllTracksOnce()).single.id;
      missing = {'/m/a.mp3'}; // the old location really is gone
      source.files = [entry(1, path: '/m/moved/a.mp3')];
      await service().sync();
      final tracks = await library.getAllTracksOnce();
      expect(tracks, hasLength(1));
      expect(tracks.single.id, id, reason: 'same track, user data kept');
      expect(tracks.single.filePath, '/m/moved/a.mp3');
    });

    test('reused id: different path but IDENTICAL size must not re-point the old track', () async {
      source.files = [entry(1, path: '/m/old/song.mp3', size: 777)];
      await service().sync();
      final old = (await library.getAllTracksOnce()).single;
      // Another file reuses id 1: same size, but different name and mtime.
      source.files = [
        entry(1, path: '/m/other/different.mp3', size: 777, modified: 555),
      ];
      final s = await service().sync();
      expect(s.added, 1);
      final tracks = await library.getAllTracksOnce();
      expect(tracks, hasLength(2));
      expect(
        tracks.firstWhere((t) => t.id == old.id).filePath,
        '/m/old/song.mp3',
        reason: 'old track keeps pointing at its own file',
      );
      expect(await library.isReferencedTrack(old.id), isTrue);
    });

    test('uncertain identity: same size/name/mtime but the old file still exists => not a move', () async {
      source.files = [entry(1, path: '/m/a/song.mp3')];
      await service().sync();
      final old = (await library.getAllTracksOnce()).single;
      // missing is empty: the old path still exists, so this is a second file.
      source.files = [entry(1, path: '/m/b/song.mp3')];
      final s = await service().sync();
      expect(s.added, 1);
      expect(
        (await library.getAllTracksOnce())
            .firstWhere((t) => t.id == old.id)
            .filePath,
        '/m/a/song.mp3',
      );
    });

    test('same size and path-name but a different mtime is uncertain => preserved + new', () async {
      source.files = [entry(1, path: '/m/a/song.mp3', modified: 100)];
      await service().sync();
      missing = {'/m/a/song.mp3'};
      source.files = [entry(1, path: '/m/b/song.mp3', modified: 999)];
      final s = await service().sync();
      expect(s.added, 1);
      expect(await library.getAllTracksOnce(), hasLength(2));
    });
  });

  group('duplicate accuracy (verified content only)', () {
    test('identical metadata AND identical byte size but different content = two recordings', () async {
      await library.insertTrack(
        libTrack('manual', path: '/app/audio/m.mp3', size: 1000),
      );
      sameContent = false; // bytes differ
      source.files = [entry(1, size: 1000), entry(2, size: 1000)];
      final s = await service().sync();
      expect(s.added, 2);
      expect(s.duplicatesSkipped, 0);
      expect(await library.getAllTracksOnce(), hasLength(3));
    });

    test(
      'identical metadata but different size is never a candidate',
      () async {
        await library.insertTrack(
          libTrack('manual', path: '/app/audio/m.mp3', size: 5000),
        );
        sameContent = true; // would match if (wrongly) compared
        source.files = [entry(1, size: 1000)];
        final s = await service().sync();
        expect(s.added, 1);
        expect(s.duplicatesSkipped, 0);
      },
    );

    test(
      'a manual import with exactly identical content IS a duplicate',
      () async {
        await library.insertTrack(
          libTrack('manual', path: '/app/audio/m.mp3', size: 1000),
        );
        sameContent = true;
        source.files = [entry(1, size: 1000)];
        final s = await service().sync();
        expect(s.duplicatesSkipped, 1);
        expect(await library.getAllTracksOnce(), hasLength(1));
      },
    );

    test('content that cannot be read is not verified, so the file is added', () async {
      await library.insertTrack(
        libTrack('manual', path: '/does/not/exist.mp3', size: 1000),
      );
      // Real comparer: the manual copy is unreadable => not verified identical.
      final svc = LocalLibrarySyncService(
        library,
        source: source,
        ensurePermission: () async => true,
        artworkDir: () async => Directory('${docsDir.path}/artwork'),
        fileExists: (_) async => true,
        extractor: (p) async => sameMeta(p),
      );
      source.files = [entry(1, size: 1000)];
      expect((await svc.sync()).added, 1);
    });

    test(
      'the real comparer: equal bytes true, one differing byte false',
      () async {
        final a = File('${userDir.path}/a.bin')
          ..writeAsBytesSync(List.filled(200000, 7));
        final b = File('${userDir.path}/b.bin')
          ..writeAsBytesSync(List.filled(200000, 7));
        final c = File('${userDir.path}/c.bin')
          ..writeAsBytesSync([...List.filled(199999, 7), 8]);
        expect(await filesHaveIdenticalContent(a.path, b.path), isTrue);
        expect(await filesHaveIdenticalContent(a.path, c.path), isFalse);
        expect(
          await filesHaveIdenticalContent(a.path, '${userDir.path}/none'),
          isFalse,
        );
      },
    );

    test(
      'a skipped duplicate is reconsidered when what it duplicated is gone',
      () async {
        await library.insertTrack(
          libTrack('manual', path: '/app/audio/m.mp3', size: 1000),
        );
        sameContent = true;
        source.files = [entry(1, size: 1000)];
        await service().sync();
        expect(await library.getAllTracksOnce(), hasLength(1));

        await library.removeTrackFromLibraryOnly(
          (await library.getAllTracksOnce()).single,
        );
        final s = await service().sync();
        expect(s.added, 1);
      },
    );

    test(
      'a skipped duplicate is reconsidered when its fingerprint changes',
      () async {
        await library.insertTrack(
          libTrack('manual', path: '/app/audio/m.mp3', size: 1000),
        );
        sameContent = true;
        source.files = [entry(1, size: 1000)];
        await service().sync();
        sameContent = false; // the file changed: no longer the same bytes
        source.files = [entry(1, size: 1234, modified: 999)];
        expect((await service().sync()).added, 1);
      },
    );

    test('repeated sync stays idempotent', () async {
      source.files = [entry(1), entry(2, size: 2000)];
      await service().sync();
      final again = await service().sync();
      expect(again.added, 0);
      expect(await library.getAllTracksOnce(), hasLength(2));
    });
  });

  group('large libraries', () {
    test('more than 2000 MP3s are all added, then idempotent', () async {
      source.files = [
        for (var i = 1; i <= 2050; i++)
          entry(i, size: 1000 + i, modified: 100 + i),
      ];
      final first = await service().sync();
      expect(first.outcome, SyncOutcome.completed);
      expect(first.added, 2050);
      expect(await library.getAllTracksOnce(), hasLength(2050));
      final second = await service().sync();
      expect(second.added, 0);
      expect(second.alreadyKnown, 2050);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  group('partial failures and cancellation', () {
    test(
      'a failure on one file does not block the rest; it retries later',
      () async {
        source.files = [entry(1), entry(2, size: 2000)];
        var fail = true;
        final svc = LocalLibrarySyncService(
          library,
          source: source,
          ensurePermission: () async => true,
          artworkDir: () async => Directory('${docsDir.path}/artwork'),
          fileExists: (_) async => true,
          extractor: (p) async {
            if (fail && p.endsWith('f1.mp3')) {
              throw const FormatException('bad');
            }
            return sameMeta(p);
          },
        );
        final first = await svc.sync();
        expect(first.added, 1);
        expect(first.unreadable, 1);
        fail = false;
        expect((await svc.sync()).added, 1);
        expect(await library.getAllTracksOnce(), hasLength(2));
      },
    );

    test(
      'cancel during the query ends as cancelled and adds nothing',
      () async {
        final token = SyncCancelToken();
        final svc = LocalLibrarySyncService(
          library,
          source: _CancelOnQuerySource(token),
          ensurePermission: () async => true,
          artworkDir: () async => Directory('${docsDir.path}/artwork'),
        );
        expect((await svc.sync(cancel: token)).outcome, SyncOutcome.cancelled);
        expect(await library.getAllTracksOnce(), isEmpty);
        // Lock released; a retry works.
        source.files = [entry(1)];
        expect((await service().sync()).added, 1);
      },
    );
  });

  group('Android boundary (MethodChannel pagination contract)', () {
    const channel = MethodChannel('listeny/media_store_test');

    void mock(Future<Object?> Function(MethodCall call) handler) =>
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, handler);

    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    Map<String, Object?> row(int id, String volume) => {
      'id': id,
      'name': 'f$id.mp3',
      'path': '/storage/$volume/Music/f$id.mp3',
      'sizeBytes': 10,
      'durationMs': 1000,
      'modifiedSec': 5,
    };

    /// A native-like fake: per-volume raw rows (null path = pathless raw row),
    /// keyset paging with explicit lastId/hasMore based on RAW progress.
    void mockVolumes(
      Map<String, List<Map<String, Object?>?>> raw, {
      List<Map<Object?, Object?>>? calls,
    }) {
      mock((call) async {
        if (call.method == 'mp3Volumes') return raw.keys.toList();
        if (call.method != 'queryMp3Files') return null;
        final args = Map<Object?, Object?>.from(call.arguments as Map);
        calls?.add(args);
        final volume = args['volume'] as String;
        final after = args['afterId'] as int;
        final limit = args['limit'] as int;
        // raw entry: row map, or {'rawId': n} for a pathless/filtered row.
        final all = raw[volume]!;
        final page = <Map<String, Object?>>[];
        for (final r in all) {
          final id = (r!['id'] ?? r['rawId']) as int;
          if (id > after) page.add(r);
          if (page.length == limit) break;
        }
        final lastId = page.isEmpty
            ? after
            : (page.last['id'] ?? page.last['rawId']) as int;
        return {
          'rows': [
            for (final r in page)
              if (r['id'] != null) r,
          ],
          'lastId': lastId,
          'hasMore': page.length >= limit,
        };
      });
    }

    test(
      'identical ids on different volumes are both fully returned',
      () async {
        mockVolumes({
          'external_primary': [for (var i = 1; i <= 6; i++) row(i, 'p')],
          '1234-ABCD': [for (var i = 1; i <= 6; i++) row(i, 's')],
        });
        final files = await MediaStoreMp3Source(
          channel: channel,
          pageSize: 3, // volume collision exactly at the page boundary
        ).queryMp3Files();
        expect(files, hasLength(12));
        expect(
          files.map((f) => f.sourceKey).toSet(),
          hasLength(12),
          reason: 'volume + id keeps the colliding ids distinct',
        );
        expect(
          files.where((f) => f.volume == '1234-ABCD' && f.id == 3),
          hasLength(1),
        );
      },
    );

    test('each volume is paged independently from afterId 0', () async {
      final calls = <Map<Object?, Object?>>[];
      mockVolumes({
        'a': [for (var i = 1; i <= 4; i++) row(i, 'a')],
        'b': [for (var i = 1; i <= 4; i++) row(i, 'b')],
      }, calls: calls);
      await MediaStoreMp3Source(channel: channel, pageSize: 3).queryMp3Files();
      final byVolume = <Object?, List<Object?>>{};
      for (final c in calls) {
        byVolume.putIfAbsent(c['volume'], () => []).add(c['afterId']);
      }
      expect(byVolume['a'], [0, 3]);
      expect(byVolume['b'], [0, 3]);
    });

    test('pathless/filtered raw rows inside a page do not end the scan early', () async {
      // Raw page 1 = ids 1..3 where 2 and 3 have no path => only 1 usable row.
      mockVolumes({
        'v': [
          row(1, 'v'),
          {'rawId': 2},
          {'rawId': 3},
          row(4, 'v'),
          row(5, 'v'),
          {'rawId': 6},
          row(7, 'v'),
        ],
      });
      final files = await MediaStoreMp3Source(
        channel: channel,
        pageSize: 3,
      ).queryMp3Files();
      expect(files.map((f) => f.id), [1, 4, 5, 7]);
    });

    test('more than 2000 rows are all returned across many pages', () async {
      mockVolumes({
        'v': [for (var i = 1; i <= 2600; i++) row(i, 'v')],
      });
      final files = await MediaStoreMp3Source(
        channel: channel,
        pageSize: 500,
      ).queryMp3Files();
      expect(files, hasLength(2600));
      expect(files.last.id, 2600);
    });

    test('no forward progress cannot loop forever', () async {
      var calls = 0;
      mock((call) async {
        if (call.method == 'mp3Volumes') return ['v'];
        calls++;
        return {'rows': <Object?>[], 'lastId': 0, 'hasMore': true};
      });
      final files = await MediaStoreMp3Source(channel: channel).queryMp3Files();
      expect(files, isEmpty);
      expect(calls, 1);
    });

    test('shouldStop between pages cancels the query', () async {
      mockVolumes({
        'v': [for (var i = 1; i <= 9; i++) row(i, 'v')],
      });
      var pages = 0;
      await expectLater(
        MediaStoreMp3Source(
          channel: channel,
          pageSize: 3,
        ).queryMp3Files(shouldStop: () => pages++ >= 1),
        throwsA(isA<MediaStoreQueryCancelled>()),
      );
    });

    test('PERMISSION_DENIED surfaces as a typed exception', () async {
      mock((call) async => throw PlatformException(code: 'PERMISSION_DENIED'));
      await expectLater(
        MediaStoreMp3Source(channel: channel).queryMp3Files(),
        throwsA(isA<MediaStorePermissionException>()),
      );
    });

    test(
      'a revoked permission during the query maps to permissionDenied',
      () async {
        final svc = LocalLibrarySyncService(
          library,
          source: _DeniedSource(),
          ensurePermission: () async => true,
          artworkDir: () async => Directory('${docsDir.path}/artwork'),
        );
        expect((await svc.sync()).outcome, SyncOutcome.permissionDenied);
        expect(await library.getAllTracksOnce(), isEmpty);
      },
    );
  });
}

class _DeniedSource implements DeviceMp3Source {
  @override
  Future<int> sdkInt() async => 30;

  @override
  Future<List<DeviceMp3>> queryMp3Files({bool Function()? shouldStop}) async =>
      throw const MediaStorePermissionException();
}

class _CancelOnQuerySource implements DeviceMp3Source {
  _CancelOnQuerySource(this.token);
  final SyncCancelToken token;

  @override
  Future<int> sdkInt() async => 30;

  @override
  Future<List<DeviceMp3>> queryMp3Files({bool Function()? shouldStop}) async {
    token.cancel();
    if (shouldStop?.call() ?? false) throw const MediaStoreQueryCancelled();
    return [];
  }
}
