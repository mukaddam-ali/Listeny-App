import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:listeny/core/storage/database.dart';
import 'package:listeny/library/import_models.dart';
import 'package:listeny/library/import_service.dart';
import 'package:listeny/library/library_repository.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String tempPath;
  _FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
}

/// A minimal, genuinely valid 8-bit mono PCM WAV file — real enough for
/// `audio_metadata_reader` to parse successfully (unlike a byte soup, which
/// it correctly rejects as corrupt), with no embedded picture of its own.
void _writeMinimalWav(File file) {
  const sampleCount = 200;
  final data = Uint8List(sampleCount); // silence
  final builder = BytesBuilder();

  void writeAscii(String s) => builder.add(s.codeUnits);
  void writeUint32(int v) => builder.add(
    Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little),
  );
  void writeUint16(int v) => builder.add(
    Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little),
  );

  writeAscii('RIFF');
  writeUint32(36 + data.length);
  writeAscii('WAVE');
  writeAscii('fmt ');
  writeUint32(16);
  writeUint16(1); // PCM
  writeUint16(1); // mono
  writeUint32(8000); // sample rate
  writeUint32(8000); // byte rate
  writeUint16(1); // block align
  writeUint16(8); // bits per sample
  writeAscii('data');
  writeUint32(data.length);
  builder.add(data);

  file.writeAsBytesSync(builder.toBytes());
}

final Uint8List _validPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Future<String> _writeExternalArtwork(Directory dir, String name) async {
  final file = File(p.join(dir.path, name));
  await file.writeAsBytes(_validPng); // a real, verifiable image
  return file.path;
}

Uint8List _syncsafe(int value) => Uint8List.fromList([
  (value >> 21) & 0x7F,
  (value >> 14) & 0x7F,
  (value >> 7) & 0x7F,
  value & 0x7F,
]);

/// A minimal, genuinely valid MP3 with a real ID3v2.3 APIC (embedded
/// picture) frame ahead of one silent MPEG audio frame — real enough for
/// `audio_metadata_reader` to parse the embedded picture back out.
void _writeMp3WithEmbeddedPicture(File file, Uint8List pictureBytes) {
  final apicBody = BytesBuilder()
    ..addByte(0x00) // text encoding
    ..add('image/jpeg'.codeUnits)
    ..addByte(0x00) // mime null terminator
    ..addByte(0x03) // picture type: cover (front)
    ..addByte(0x00) // description null terminator
    ..add(pictureBytes);
  final apicBodyBytes = apicBody.toBytes();

  final frame = BytesBuilder()
    ..add('APIC'.codeUnits)
    ..add(
      Uint8List(4)
        ..buffer.asByteData().setUint32(0, apicBodyBytes.length, Endian.big),
    )
    ..add([0x00, 0x00]) // flags
    ..add(apicBodyBytes);
  final frameBytes = frame.toBytes();

  final builder = BytesBuilder()
    ..add('ID3'.codeUnits)
    ..add([0x03, 0x00]) // ID3v2.3.0
    ..addByte(0x00) // flags
    ..add(_syncsafe(frameBytes.length))
    ..add(frameBytes);

  // One silent MPEG1 Layer3 frame (44.1kHz/128kbps sync header, zeroed
  // body) so the parser finds real audio data after the tag.
  final mpegFrame = Uint8List(417);
  mpegFrame[0] = 0xFF;
  mpegFrame[1] = 0xFB;
  mpegFrame[2] = 0x90;
  builder.add(mpegFrame);

  file.writeAsBytesSync(builder.toBytes());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('import_service_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  ImportService service() =>
      ImportService(LibraryRepository(AppDatabase(NativeDatabase.memory())));

  test(
    'no embedded artwork and no external artwork -> artworkPath stays null',
    () async {
      final source = File(
        p.join(
          tempDir.path,
          'plain_${DateTime.now().microsecondsSinceEpoch}.wav',
        ),
      );
      _writeMinimalWav(source);

      final summary = await service().importAndSummarize([
        PickedFile(name: p.basename(source.path), path: source.path),
      ]);

      expect(summary.songsAdded, 1);
      expect(summary.addedTracks.single.artworkPath, isNull);
    },
  );

  test(
    'external artwork is copied and used when there is no embedded picture',
    () async {
      final source = File(
        p.join(
          tempDir.path,
          'thumb_${DateTime.now().microsecondsSinceEpoch}.wav',
        ),
      );
      _writeMinimalWav(source);
      final externalArtworkPath = await _writeExternalArtwork(
        tempDir,
        'external_thumb.jpg',
      );

      final summary = await service().importAndSummarize([
        PickedFile(
          name: p.basename(source.path),
          path: source.path,
          externalArtworkPath: externalArtworkPath,
        ),
      ]);

      expect(summary.songsAdded, 1);
      final track = summary.addedTracks.single;
      expect(track.artworkPath, isNotNull);
      // Copied into Listeny's own storage, not left pointing at the original.
      expect(track.artworkPath, isNot(externalArtworkPath));
      expect(await File(track.artworkPath!).exists(), isTrue);
      expect(
        await File(track.artworkPath!).readAsBytes(),
        await File(externalArtworkPath).readAsBytes(),
      );
    },
  );

  test(
    'embedded artwork wins over external artwork when both are present',
    () async {
      final source = File(
        p.join(
          tempDir.path,
          'embedded_${DateTime.now().microsecondsSinceEpoch}.mp3',
        ),
      );
      final embeddedBytes = Uint8List.fromList(_validPng);
      _writeMp3WithEmbeddedPicture(source, embeddedBytes);

      final externalArtworkPath = await _writeExternalArtwork(
        tempDir,
        'should_be_ignored.jpg',
      );

      final summary = await service().importAndSummarize([
        PickedFile(
          name: p.basename(source.path),
          path: source.path,
          externalArtworkPath: externalArtworkPath,
        ),
      ]);

      expect(summary.songsAdded, 1);
      final track = summary.addedTracks.single;
      expect(track.artworkPath, isNotNull);
      expect(await File(track.artworkPath!).readAsBytes(), embeddedBytes);
    },
  );

  test('manual local import (no externalArtworkPath) is unaffected', () async {
    final source = File(
      p.join(
        tempDir.path,
        'manual_${DateTime.now().microsecondsSinceEpoch}.wav',
      ),
    );
    _writeMinimalWav(source);

    final summary = await service().importAndSummarize([
      PickedFile(name: p.basename(source.path), path: source.path),
    ]);

    expect(summary.songsAdded, 1);
    expect(summary.addedTracks.single.artworkPath, isNull);
  });

  group(
    'in-place referenced import (downloads published to Music/Listeny)',
    () {
      ReferencedSource ref(String key) => ReferencedSource(
        sourceKey: key,
        volume: 'external_primary',
        sizeBytes: 1,
        modifiedSec: 1,
      );

      test(
        'references the file in place: no copy, source row recorded',
        () async {
          final db = AppDatabase(NativeDatabase.memory());
          final repo = LibraryRepository(db);
          final source = File(
            p.join(
              tempDir.path,
              'inplace_${DateTime.now().microsecondsSinceEpoch}.wav',
            ),
          );
          _writeMinimalWav(source);

          final summary = await ImportService(repo).importAndSummarize([
            PickedFile(
              name: p.basename(source.path),
              path: source.path,
              referencedSource: ref('ms:external_primary:42'),
            ),
          ]);

          expect(summary.songsAdded, 1);
          final track = summary.addedTracks.single;
          expect(track.filePath, source.path);
          expect(await source.exists(), isTrue);
          final row = await repo.getLibrarySource('ms:external_primary:42');
          expect(row?.state, 'added');
          expect(row?.trackId, track.id);
          expect(await repo.isReferencedTrack(track.id), isTrue);
        },
      );

      test(
        'an already-owned source is reported as duplicate, file kept',
        () async {
          final db = AppDatabase(NativeDatabase.memory());
          final repo = LibraryRepository(db);
          final service = ImportService(repo);
          final a = File(
            p.join(
              tempDir.path,
              'own_a_${DateTime.now().microsecondsSinceEpoch}.wav',
            ),
          );
          _writeMinimalWav(a);

          await service.importAndSummarize([
            PickedFile(
              name: p.basename(a.path),
              path: a.path,
              referencedSource: ref('ms:external_primary:7'),
            ),
          ]);
          final again = await service.importAndSummarize([
            PickedFile(
              name: p.basename(a.path),
              path: a.path,
              referencedSource: ref('ms:external_primary:7'),
            ),
          ]);

          expect(again.songsAdded, 0);
          expect(again.duplicates, hasLength(1));
          expect(await a.exists(), isTrue); // never deleted by the importer
        },
      );
    },
  );
}
