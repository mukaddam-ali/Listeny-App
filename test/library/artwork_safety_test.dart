import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/core/models/track.dart';
import 'package:listeny/core/storage/database.dart';
import 'package:listeny/library/artwork_validator.dart';
import 'package:listeny/library/library_repository.dart';
import 'package:listeny/library/local_library_sync_service.dart';
import 'package:listeny/shared/widgets/artwork_view.dart';

final Uint8List validPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);
final Uint8List validWebp = base64Decode(
  'UklGRhoAAABXRUJQVlA4TA0AAAAvAAAAEAcQERGIiP4HAA==',
);

/// A real 8x8 baseline JPEG.
final Uint8List _jpegBytes = base64Decode(
  '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAAIAAgDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDgKKKK+eP2E//Z',
);
Uint8List buildJpeg() => _jpegBytes;

Uint8List withLeak(Uint8List image) => Uint8List.fromList([
  ...'attached picture'.codeUnits.expand((c) => [c, 0]),
  0,
  ...image,
]);

Uint8List utf16Text() => Uint8List.fromList(
  List.generate(
    80,
    (i) => i.isEven ? 'attached picture'.codeUnitAt(i ~/ 2 % 16) : 0,
  ),
);

Track track(String id, String? artwork, {String? audioPath}) => Track(
  id: id,
  filePath: audioPath ?? '/music/$id.mp3',
  title: id,
  artist: 'A',
  album: 'B',
  albumArtist: 'A',
  duration: const Duration(minutes: 3),
  format: 'mp3',
  fileSizeBytes: 100,
  dateAdded: DateTime.now(),
  artworkPath: artwork,
);

class _FakeSource implements DeviceMp3Source {
  _FakeSource(this.files);
  final List<DeviceMp3> files;
  @override
  Future<int> sdkInt() async => 30;
  @override
  Future<List<DeviceMp3>> queryMp3Files({bool Function()? shouldStop}) async =>
      files;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  group('new artwork is verified (validation + real decoding kept)', () {
    test('valid PNG, JPEG and WebP are accepted', () async {
      expect((await decodeVerifiedArtwork(validPng))?.extension, 'png');
      expect((await decodeVerifiedArtwork(buildJpeg()))?.extension, 'jpg');
      expect((await decodeVerifiedArtwork(validWebp))?.extension, 'webp');
    });

    test('invalid, truncated and corrupt data is rejected', () async {
      expect(await decodeVerifiedArtwork(utf16Text()), isNull);
      expect(
        await decodeVerifiedArtwork(Uint8List.sublistView(validPng, 0, 40)),
        isNull,
      );
      final flipped = Uint8List.fromList(validPng)..[41] ^= 0xFF;
      expect(await decodeVerifiedArtwork(flipped), isNull);
      expect(
        await decodeVerifiedArtwork(Uint8List(artworkMaxBytes + 1)),
        isNull,
      );
    });

    test('a sync never writes invalid artwork, and leaves OLD malformed files alone', () async {
      final docs = Directory.systemTemp.createTempSync('listeny_as_docs');
      addTearDown(() => docs.deleteSync(recursive: true));
      final artDir = Directory('${docs.path}/artwork')..createSync();
      final oldBad = File('${artDir.path}/old-bad.png')
        ..writeAsBytesSync(utf16Text());
      final library = LibraryRepository(
        AppDatabase(NativeDatabase.memory()),
        appDocsDir: () async => docs,
      );
      await library.insertTrack(track('old', oldBad.path));
      final before = oldBad.readAsBytesSync();

      final svc = LocalLibrarySyncService(
        library,
        source: _FakeSource([
          const DeviceMp3(
            id: 1,
            name: 'a.mp3',
            path: '/m/a.mp3',
            sizeBytes: 10,
            durationMs: 1000,
          ),
          const DeviceMp3(
            id: 2,
            name: 'b.mp3',
            path: '/m/b.mp3',
            sizeBytes: 20,
            durationMs: 1000,
          ),
        ]),
        ensurePermission: () async => true,
        artworkDir: () async => artDir,
        fileExists: (_) async => true,
        extractor: (path) async => ExtractedMetadata(
          title: path,
          artworkBytes: path.endsWith('a.mp3') ? utf16Text() : validPng,
        ),
      );
      final summary = await svc.sync();
      expect(summary.added, 2);

      final tracks = {
        for (final t in await library.getAllTracksOnce()) t.title: t,
      };
      expect(
        tracks['/m/a.mp3']!.artworkPath,
        isNull,
        reason: 'invalid rejected',
      );
      final good = tracks['/m/b.mp3']!.artworkPath!;
      expect(File(good).readAsBytesSync(), validPng);
      expect(good.endsWith('.png'), isTrue);
      // The historical malformed file and its record are untouched.
      expect(oldBad.readAsBytesSync(), before);
      expect(tracks['old']!.artworkPath, oldBad.path);
      expect(artDir.listSync(), hasLength(2));
    });
  });

  group('startup runs no repair or cleanup', () {
    test('no repair/cleanup code is referenced from the app', () {
      expect(File('lib/library/artwork_repair.dart').existsSync(), isFalse);
      final main = File('lib/main.dart').readAsStringSync();
      expect(main.contains('artwork_repair'), isFalse);
      expect(main.toLowerCase().contains('repairinvalidartwork'), isFalse);
      expect(main.toLowerCase().contains('artworkrepair'), isFalse);
      final lib = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.readAsStringSync())
          .join('\n');
      expect(lib.contains('artwork_cleanup_pending'), isFalse);
      expect(lib.contains('artwork_repair_v1_done'), isFalse);
    });
  });

  group('UI fallback', () {
    testWidgets('an undecodable artwork file is not retried on rebuild', (
      tester,
    ) async {
      final dir = Directory.systemTemp.createTempSync('listeny_ui_art');
      addTearDown(() => dir.deleteSync(recursive: true));
      final bad = File('${dir.path}/bad.png')..writeAsBytesSync(utf16Text());

      Widget host() => MaterialApp(
        home: Scaffold(
          body: ArtworkView(artworkPath: bad.path, seed: 's', size: 40),
        ),
      );

      await tester.pumpWidget(host());
      expect(find.byType(Image), findsOneWidget, reason: 'first attempt');
      // Let the real decode fail and the fallback appear.
      for (
        var i = 0;
        i < 40 && find.byType(GeneratedArtwork).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      expect(find.byType(GeneratedArtwork), findsOneWidget);
      // Rebuild with a brand-new widget instance: no second decode attempt.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host());
      expect(
        find.byType(Image),
        findsNothing,
        reason: 'straight to the fallback',
      );
      expect(find.byType(GeneratedArtwork), findsOneWidget);
    });
  });

  group('physical deletion boundary', () {
    late Directory docs, artDir, userDir;
    late LibraryRepository library;

    setUp(() {
      docs = Directory.systemTemp.createTempSync('listeny_del_docs');
      artDir = Directory('${docs.path}/artwork')..createSync();
      userDir = Directory.systemTemp.createTempSync('listeny_del_user');
      library = LibraryRepository(
        AppDatabase(NativeDatabase.memory()),
        appDocsDir: () async => docs,
      );
    });

    tearDown(() {
      docs.deleteSync(recursive: true);
      userDir.deleteSync(recursive: true);
    });

    File art(String name, List<int> bytes) =>
        File('${artDir.path}/$name')..writeAsBytesSync(bytes);

    test('an artwork path pointing at app-owned audio, the database or prefs is never deleted', () async {
      final mp3 = File('${docs.path}/audio/song.mp3')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);
      final db = File('${docs.path}/listeny.sqlite')..writeAsBytesSync([4, 5]);
      final journal = File('${docs.path}/listeny.sqlite-journal')
        ..writeAsBytesSync([6]);
      final prefs = File('${docs.path}/shared_prefs.xml')
        ..writeAsBytesSync([7]);
      // Even a "wrongly named" audio file inside the artwork folder.
      final sneaky = File('${artDir.path}/song.mp3')..writeAsBytesSync([8]);

      var i = 0;
      for (final f in [mp3, db, journal, prefs, sneaky]) {
        final t = track('t${i++}', f.path);
        await library.insertTrack(t);
        expect(await library.deleteArtworkIfUnreferenced(f.path), isFalse);
        await library.deleteTrackFromDevice(t);
        expect(f.existsSync(), isTrue, reason: '${f.path} must survive');
      }
    });

    test(
      'a real artwork file in the artwork folder is deleted once unreferenced',
      () async {
        final f = art('x.png', validPng);
        await library.insertTrack(track('a', f.path));
        await library.deleteTrackFromDevice(track('a', f.path));
        expect(f.existsSync(), isFalse);
      },
    );

    test('shared artwork stays protected (tracks and playlists)', () async {
      final shared = art('shared.png', validPng);
      await library.insertTrack(track('a', shared.path));
      await library.insertTrack(track('b', shared.path));
      await library.createPlaylist('Mix', artworkPath: shared.path);
      await library.deleteTrackFromDevice(track('a', shared.path));
      expect(shared.existsSync(), isTrue);
      await library.deleteTrackFromDevice(track('b', shared.path));
      expect(shared.existsSync(), isTrue, reason: 'the playlist still uses it');
    });

    test('external artwork is never physically deleted', () async {
      final ext = File('${userDir.path}/cover.png')..writeAsBytesSync(validPng);
      await library.insertTrack(track('a', ext.path));
      await library.deleteTrackFromDevice(track('a', ext.path));
      expect(ext.existsSync(), isTrue);
    });

    test(
      'playlist create, update and remove work and keep shared files',
      () async {
        final one = art('one.png', validPng);
        final two = art('two.png', validPng);
        final id = await library.createPlaylist('P', artworkPath: one.path);
        var pl = await library.watchPlaylists().firstWhere((l) => l.isNotEmpty);
        expect(pl.single.artworkPath, one.path);

        expect(await library.updatePlaylistArtwork(id, two.path), isTrue);
        await library.deleteArtworkIfUnreferenced(one.path);
        expect(one.existsSync(), isFalse, reason: 'old, unreferenced: removed');
        expect(two.existsSync(), isTrue);

        expect(await library.updatePlaylistArtwork(id, null), isTrue);
        await library.deleteArtworkIfUnreferenced(two.path);
        expect(two.existsSync(), isFalse);

        // A missing file is never stored as a reference.
        expect(
          await library.updatePlaylistArtwork(id, '${artDir.path}/gone.png'),
          isFalse,
        );
      },
    );

    test(
      'a playlist writer racing a delete never ends with a dangling reference',
      () async {
        final f = art('race.png', validPng);
        final id = await library.createPlaylist('P');
        final deleting = library.deleteArtworkIfUnreferenced(f.path);
        final storing = library.updatePlaylistArtwork(id, f.path);
        await deleting;
        final stored = await storing;
        final artwork = (await library.watchPlaylists().firstWhere(
          (l) => l.isNotEmpty,
        )).single.artworkPath;
        if (stored) {
          expect(File(artwork!).existsSync(), isTrue);
        } else {
          expect(artwork, isNull);
        }
      },
    );
  });
}
