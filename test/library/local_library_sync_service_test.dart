import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/core/models/track.dart';
import 'package:listeny/core/storage/database.dart';
import 'package:listeny/library/library_repository.dart';
import 'package:listeny/library/local_library_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSource implements DeviceMp3Source {
  FakeSource(this.files, {this.sdk = 30});
  List<DeviceMp3> files;
  int sdk;
  int queries = 0;

  @override
  Future<int> sdkInt() async => sdk;

  @override
  Future<List<DeviceMp3>> queryMp3Files({bool Function()? shouldStop}) async {
    queries++;
    return List.of(files);
  }
}

DeviceMp3 mp3(int id, {String? name, int size = 1000}) => DeviceMp3(
  id: id,
  name: name ?? 'song$id.mp3',
  path: '/storage/emulated/0/Music/song$id.mp3',
  sizeBytes: size,
  durationMs: 180000,
);

Track libTrack(
  String id, {
  required String title,
  String artist = 'Artist',
  Duration duration = const Duration(minutes: 3),
  String? filePath,
}) => Track(
  id: id,
  filePath: filePath ?? '/app/audio/$id.mp3',
  title: title,
  artist: artist,
  album: 'Album',
  albumArtist: artist,
  duration: duration,
  format: 'mp3',
  fileSizeBytes: 1000,
  dateAdded: DateTime.now(),
);

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late LibraryRepository library;
  late Directory docsDir; // the app's own storage (owned)
  late Directory userDir; // the user's own files (never owned)
  late Directory artworkDir;
  late FakeSource source;
  late int extractCalls;
  late Set<String> missingFiles;
  late Set<String> failingPaths;
  var permission = true;

  setUp(() {
    docsDir = Directory.systemTemp.createTempSync('listeny_sync_docs');
    userDir = Directory.systemTemp.createTempSync('listeny_sync_user');
    library = LibraryRepository(
      AppDatabase(NativeDatabase.memory()),
      appDocsDir: () async => docsDir,
    );
    artworkDir = Directory('${docsDir.path}/artwork')..createSync();
    source = FakeSource([]);
    extractCalls = 0;
    missingFiles = {};
    failingPaths = {};
    permission = true;
  });

  tearDown(() {
    if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
    if (userDir.existsSync()) userDir.deleteSync(recursive: true);
  });

  LocalLibrarySyncService service() => LocalLibrarySyncService(
    library,
    source: source,
    ensurePermission: () async => permission,
    artworkDir: () async => artworkDir,
    fileExists: (path) async => !missingFiles.contains(path),
    contentEquals: (a, b) async => true,
    extractor: (path) async {
      extractCalls++;
      if (failingPaths.contains(path)) throw const FormatException('corrupt');
      final n = RegExp(r'song(\d+)').firstMatch(path)!.group(1)!;
      return ExtractedMetadata(
        title: 'Title $n',
        artist: 'Artist $n',
        album: 'Album',
        duration: const Duration(minutes: 3),
        artworkBytes: _png,
      );
    },
  );

  test(
    'initial sync adds MP3s as in-place references (nothing copied)',
    () async {
      source.files = [mp3(1), mp3(2)];
      final summary = await service().sync();

      expect(summary.outcome, SyncOutcome.completed);
      expect(summary.added, 2);
      final tracks = await library.getAllTracksOnce();
      expect(tracks, hasLength(2));
      expect(
        tracks.map((t) => t.filePath),
        containsAll([mp3(1).path, mp3(2).path]),
        reason: 'the original path is referenced, not a copy',
      );
      for (final t in tracks) {
        expect(await library.isReferencedTrack(t.id), isTrue);
        expect(
          File(t.artworkPath!).existsSync(),
          isTrue,
          reason: 'artwork extracted',
        );
      }
      final sources = await library.getLibrarySources();
      expect(sources.keys, containsAll(['ms:primary:1', 'ms:primary:2']));
    },
  );

  test('repeated scans are idempotent: no duplicates, no re-reading', () async {
    source.files = [mp3(1), mp3(2)];
    await service().sync();
    final callsAfterFirst = extractCalls;
    final second = await service().sync();
    final third = await service().sync();

    expect(second.added, 0);
    expect(second.alreadyKnown, 2);
    expect(third.added, 0);
    expect(
      extractCalls,
      callsAfterFirst,
      reason: 'known items are never re-read',
    );
    expect(await library.getAllTracksOnce(), hasLength(2));
  });

  test('new files are picked up incrementally', () async {
    source.files = [mp3(1)];
    await service().sync();
    source.files = [mp3(1), mp3(2), mp3(3)];
    final summary = await service().sync();
    expect(summary.added, 2);
    expect(summary.alreadyKnown, 1);
    expect(await library.getAllTracksOnce(), hasLength(3));
  });

  test('denied permission: nothing scanned or added, no crash', () async {
    permission = false;
    source.files = [mp3(1)];
    final summary = await service().sync();
    expect(summary.outcome, SyncOutcome.permissionDenied);
    expect(
      source.queries,
      0,
      reason: 'MediaStore is not queried without permission',
    );
    expect(await library.getAllTracksOnce(), isEmpty);
    // Granting later works.
    permission = true;
    expect((await service().sync()).added, 1);
  });

  test('Android 10 is reported unsupported, never forced', () async {
    source.sdk = 29;
    source.files = [mp3(1)];
    final summary = await service().sync();
    expect(summary.outcome, SyncOutcome.unsupportedAndroidVersion);
    expect(await library.getAllTracksOnce(), isEmpty);
    expect(source.queries, 0);
  });

  test('unavailable/unreadable files are skipped without a record and retried later', () async {
    source.files = [mp3(1), mp3(2)];
    missingFiles = {mp3(1).path};
    failingPaths = {mp3(2).path};
    final first = await service().sync();
    expect(first.added, 0);
    expect(first.unreadable, 2);
    expect(await library.getLibrarySources(), isEmpty);
    expect(artworkDir.listSync(), isEmpty, reason: 'no orphan artwork');

    missingFiles = {};
    failingPaths = {};
    final retry = await service().sync();
    expect(retry.added, 2, reason: 'recovers on the next sync');
  });

  test(
    'items disappearing from MediaStore never delete library records',
    () async {
      source.files = [mp3(1), mp3(2)];
      await service().sync();
      source.files = []; // temporarily absent (unmounted card, index rebuild)
      final summary = await service().sync();
      expect(summary.outcome, SyncOutcome.completed);
      expect(await library.getAllTracksOnce(), hasLength(2));
      expect(
        await library.rescanForMissingFiles(),
        0,
        reason: 'referenced originals are not removed for being unreachable',
      );
      expect(await library.getAllTracksOnce(), hasLength(2));
    },
  );

  test('manually imported records are kept; duplicates are skipped once and remembered', () async {
    await library.insertTrack(
      libTrack('manual', title: 'Title 1', artist: 'Artist 1'),
    );
    source.files = [mp3(1), mp3(2)];
    final first = await service().sync();
    expect(first.duplicatesSkipped, 1);
    expect(first.added, 1);
    final tracks = await library.getAllTracksOnce();
    expect(tracks, hasLength(2));
    expect(tracks.where((t) => t.id == 'manual'), hasLength(1));
    expect(await library.isReferencedTrack('manual'), isFalse);
    expect(
      (await library.getLibrarySources())['ms:primary:1']!.state,
      'skipped',
    );

    final calls = extractCalls;
    final second = await service().sync();
    expect(second.alreadyKnown, 2);
    expect(extractCalls, calls, reason: 'skipped duplicates are not re-read');
  });

  test(
    'an existing track already pointing at that path is not duplicated',
    () async {
      await library.insertTrack(
        libTrack('x', title: 'Whatever', filePath: mp3(1).path),
      );
      source.files = [mp3(1)];
      final summary = await service().sync();
      expect(summary.added, 0);
      expect(await library.getAllTracksOnce(), hasLength(1));
    },
  );

  test('favorites, playlists, play history survive syncs', () async {
    await library.insertTrack(libTrack('fav', title: 'Mine'));
    await library.setFavorite('fav', true);
    await library.recordPlay('fav');
    final playlistId = await library.createPlaylist('Road trip');
    await library.addSongToPlaylist(playlistId, 'fav');

    source.files = [mp3(1), mp3(2)];
    await service().sync();
    await service().sync();

    final fav = (await library.getAllTracksOnce()).firstWhere(
      (t) => t.id == 'fav',
    );
    expect(fav.favorite, isTrue);
    expect(fav.playCount, 1);
    final inPlaylist = await library
        .watchPlaylistSongs(playlistId)
        .firstWhere((s) => s.any((t) => t.id == 'fav'));
    expect(inPlaylist.map((t) => t.id), contains('fav'));
  });

  test(
    'deleting a referenced track never deletes the original file; not re-added',
    () async {
      final original = File('${userDir.path}/original.mp3')
        ..writeAsBytesSync([9, 9, 9]);
      source.files = [
        DeviceMp3(
          id: 7,
          name: 'song7.mp3',
          path: original.path,
          sizeBytes: 3,
          durationMs: 1000,
        ),
      ];
      // Extractor derives n from "song<digits>" in the path; use a name that fits.
      final svc = LocalLibrarySyncService(
        library,
        source: source,
        ensurePermission: () async => true,
        artworkDir: () async => artworkDir,
        extractor: (_) async => const ExtractedMetadata(title: 'Seven'),
      );
      await svc.sync();
      final track = (await library.getAllTracksOnce()).single;
      expect(track.filePath, original.path);

      await library.deleteTrackFromDevice(track);
      expect(
        original.existsSync(),
        isTrue,
        reason: 'the user\'s file is untouched',
      );
      expect(await library.getAllTracksOnce(), isEmpty);

      final again = await svc.sync();
      expect(
        again.added,
        0,
        reason: 'a removed track is not silently re-added',
      );
      expect(
        (await library.getLibrarySources())['ms:primary:7']!.state,
        'removed',
      );
    },
  );

  test('cancel keeps what was added; the next sync continues', () async {
    source.files = [mp3(1), mp3(2), mp3(3)];
    final token = SyncCancelToken();
    final summary = await service().sync(
      cancel: token,
      onProgress: (p) {
        if (p.processed == 1) token.cancel();
      },
    );
    expect(summary.outcome, SyncOutcome.cancelled);
    expect(await library.getAllTracksOnce(), hasLength(1));

    final resumed = await service().sync();
    expect(resumed.outcome, SyncOutcome.completed);
    expect(resumed.added, 2);
    expect(await library.getAllTracksOnce(), hasLength(3));
  });

  test('a second sync started while one runs is refused', () async {
    source.files = [mp3(1)];
    final svc = service();
    final first = svc.sync();
    final second = await svc.sync();
    expect(second.outcome, SyncOutcome.alreadyRunning);
    expect((await first).outcome, SyncOutcome.completed);
  });

  test(
    'invalid embedded artwork is never written; the track is still added',
    () async {
      source.files = [mp3(1)];
      final text = Uint8List.fromList(
        List.generate(80, (i) => i.isEven ? 0x61 : 0),
      ); // UTF-16 text, as seen on the device
      final svc = LocalLibrarySyncService(
        library,
        source: source,
        ensurePermission: () async => true,
        artworkDir: () async => artworkDir,
        fileExists: (_) async => true,
        extractor: (_) async =>
            ExtractedMetadata(title: 'T', artworkBytes: text),
      );
      final summary = await svc.sync();
      expect(summary.added, 1);
      expect((await library.getAllTracksOnce()).single.artworkPath, isNull);
      expect(artworkDir.listSync(), isEmpty, reason: 'no junk file on disk');
      expect(
        (await svc.sync()).added,
        0,
        reason: 'repeat sync stays idempotent',
      );
    },
  );

  group('first-launch sync', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('runs once; definitive outcomes mark it done', () async {
      source.files = [mp3(1)];
      await runInitialLocalSyncIfNeeded(library, service: service());
      expect(await library.getAllTracksOnce(), hasLength(1));
      final queries = source.queries;
      await runInitialLocalSyncIfNeeded(library, service: service());
      expect(source.queries, queries, reason: 'not repeated on later launches');
    });

    test(
      'denied permission is final (no nagging) but manual sync still works',
      () async {
        permission = false;
        source.files = [mp3(1)];
        await runInitialLocalSyncIfNeeded(library, service: service());
        permission = true;
        await runInitialLocalSyncIfNeeded(library, service: service());
        expect(await library.getAllTracksOnce(), isEmpty);
        expect((await service().sync()).added, 1);
      },
    );

    test('a failed first attempt is retried on the next launch', () async {
      final failing = FakeSource([mp3(1)]);
      final broken = LocalLibrarySyncService(
        library,
        source: _ThrowingSource(),
        ensurePermission: () async => true,
        artworkDir: () async => artworkDir,
      );
      await runInitialLocalSyncIfNeeded(library, service: broken);
      source = failing;
      await runInitialLocalSyncIfNeeded(library, service: service());
      expect(await library.getAllTracksOnce(), hasLength(1));
    });
  });
}

class _ThrowingSource implements DeviceMp3Source {
  @override
  Future<int> sdkInt() async => 30;

  @override
  Future<List<DeviceMp3>> queryMp3Files({bool Function()? shouldStop}) async =>
      throw StateError('boom');
}
