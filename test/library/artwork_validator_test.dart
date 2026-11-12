import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/core/models/track.dart';
import 'package:listeny/library/artwork_validator.dart';

/// A real 1x1 PNG.
final Uint8List validPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// A structurally valid baseline JPEG (APP0, SOF0, SOS, data, EOI).
Uint8List buildJpeg({int w = 4, int h = 4, bool eoi = true}) =>
    Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      0xE0,
      0x00,
      0x10,
      0x4A,
      0x46,
      0x49,
      0x46,
      0x00,
      1,
      1,
      0,
      0,
      1,
      0,
      1,
      0,
      0,
      0xFF,
      0xC0,
      0x00,
      0x11,
      8,
      h >> 8,
      h & 255,
      w >> 8,
      w & 255,
      3,
      1,
      0x11,
      0,
      2,
      0x11,
      1,
      3,
      0x11,
      1,
      0xFF,
      0xDA,
      0x00,
      0x0C,
      3,
      1,
      0,
      2,
      0x11,
      3,
      0x11,
      0,
      0x3F,
      0,
      ...List.filled(40, 0x55),
      if (eoi) ...[0xFF, 0xD9],
    ]);

/// UTF-16LE "attached picture" + a single stray byte, exactly the leak seen
/// on the device, followed by [image].
Uint8List withLeakedDescription(Uint8List image) => Uint8List.fromList([
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

Track track(String id, String? artwork) => Track(
  id: id,
  filePath: '/music/$id.mp3',
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  group('validateArtwork', () {
    test('valid PNG and JPEG are accepted with the verified extension', () {
      final png = validateArtwork(validPng)!;
      expect(
        (png.extension, png.width, png.height, png.repaired),
        ('png', 1, 1, false),
      );
      final jpg = validateArtwork(buildJpeg(w: 300, h: 200))!;
      expect((jpg.extension, jpg.width, jpg.height), ('jpg', 300, 200));
    });

    test('extension follows content, not a declared type', () {
      // PNG bytes are "png" no matter what a tag claimed.
      expect(validateArtwork(validPng)!.extension, 'png');
      expect(validateArtwork(buildJpeg())!.extension, 'jpg');
    });

    test('UTF-16 text pretending to be an image is rejected', () {
      expect(validateArtwork(utf16Text()), isNull);
    });

    test('the leaked-description damage is recovered, prefix stripped', () {
      final damaged = withLeakedDescription(validPng);
      final v = validateArtwork(damaged)!;
      expect(v.repaired, isTrue);
      expect(v.extension, 'png');
      expect(v.bytes, validPng, reason: 'exactly the image, none of the text');
      final j = validateArtwork(withLeakedDescription(buildJpeg()))!;
      expect((j.repaired, j.extension), (true, 'jpg'));
    });

    test('truncated or malformed images are rejected', () {
      expect(validateArtwork(Uint8List.sublistView(validPng, 0, 50)), isNull);
      expect(validateArtwork(buildJpeg(eoi: false)), isNull);
      final broken = Uint8List.fromList(validPng)
        ..[12] = 0x58; // IHDR -> garbage
      expect(validateArtwork(broken), isNull);
      expect(validateArtwork(Uint8List(0)), isNull);
      expect(validateArtwork(Uint8List.fromList([1, 2, 3])), isNull);
    });

    test('resource bounds: zero or absurd dimensions and oversize data', () {
      expect(validateArtwork(buildJpeg(w: 0, h: 10)), isNull);
      expect(validateArtwork(buildJpeg(w: 9000, h: 10)), isNull);
      expect(validateArtwork(Uint8List(artworkMaxBytes + 1)), isNull);
    });

    test('a leaked prefix longer than the bound is not searched', () {
      final far = Uint8List.fromList([...List.filled(400, 0x41), ...validPng]);
      expect(validateArtwork(far), isNull);
    });
  });
}
