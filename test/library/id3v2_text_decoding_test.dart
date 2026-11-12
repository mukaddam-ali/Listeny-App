// Tests for the locally patched ID3v2/ID3v1 text decoding in
// third_party/audio_metadata_reader (see its CHANGES.md). These exercise
// the exported `ID3v2Parser`/`ID3v1Parser` directly against hand-built raw
// tag bytes — the smallest real fixture that reaches the actual parser code
// path, without needing a full playable audio file (ID3v2Parser.parse stops
// reading once the tag ends; it never touches the audio frames after it).
//
// Regression coverage: before this patch, ID3v2 encoding 1 (UTF-16 with
// BOM) was always decoded as little-endian regardless of the BOM actually
// present, and encoding 2 (UTF-16BE, no BOM) was also always decoded as
// little-endian — together, the root cause of plain Latin metadata coming
// out looking like Chinese/Japanese mojibake. See
// third_party/audio_metadata_reader/CHANGES.md for the full writeup.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Uint8List _syncsafe(int value) => Uint8List.fromList([
  (value >> 21) & 0x7F,
  (value >> 14) & 0x7F,
  (value >> 7) & 0x7F,
  value & 0x7F,
]);

Uint8List _utf16LeBytes(String s) {
  final builder = BytesBuilder();
  for (final unit in s.codeUnits) {
    builder.add([unit & 0xFF, (unit >> 8) & 0xFF]);
  }
  return builder.toBytes();
}

Uint8List _utf16BeBytes(String s) {
  final builder = BytesBuilder();
  for (final unit in s.codeUnits) {
    builder.add([(unit >> 8) & 0xFF, unit & 0xFF]);
  }
  return builder.toBytes();
}

/// Builds one ID3v2.3 text frame ([id], e.g. "TIT2") with the given
/// [encoding] byte and already-encoded [valueBytes] (not including the
/// encoding byte or terminator) — [valueBytes] should be created by one of
/// the `_utf16*Bytes`/latin1/utf8 helpers matching [encoding].
Uint8List _textFrame(String id, int encoding, Uint8List valueBytes) {
  final terminator = (encoding == 1 || encoding == 2)
      ? Uint8List.fromList([0, 0])
      : Uint8List.fromList([0]);
  final body = BytesBuilder()
    ..addByte(encoding)
    ..add(valueBytes)
    ..add(terminator);
  final bodyBytes = body.toBytes();
  return (BytesBuilder()
        ..add(id.codeUnits)
        ..add(
          Uint8List(4)
            ..buffer.asByteData().setUint32(0, bodyBytes.length, Endian.big),
        )
        ..add([0x00, 0x00]) // flags
        ..add(bodyBytes))
      .toBytes();
}

Uint8List _id3v23Tag(List<Uint8List> frames) {
  final frameBytes = (BytesBuilder()..add(frames.expand((f) => f).toList()))
      .toBytes();
  return (BytesBuilder()
        ..add('ID3'.codeUnits)
        ..add([0x03, 0x00]) // ID3v2.3.0
        ..addByte(0x00) // flags
        ..add(_syncsafe(frameBytes.length))
        ..add(frameBytes))
      .toBytes();
}

void main() {
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('id3v2_decoding_test_');
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  Mp3Metadata parseTag(Uint8List tagBytes) {
    final file = File(
      p.join(tempDir.path, 'tag_${DateTime.now().microsecondsSinceEpoch}.id3'),
    );
    file.writeAsBytesSync(tagBytes);
    final raf = file.openSync();
    try {
      return ID3v2Parser().parse(raf);
    } finally {
      raf.closeSync();
    }
  }

  group('encoding 0 (Latin-1) and 3 (UTF-8)', () {
    test('plain English/ASCII round-trips (encoding 0)', () {
      final meta = parseTag(
        _id3v23Tag([_textFrame('TIT2', 0, latin1.encode('Bohemian Rhapsody'))]),
      );
      expect(meta.songName, 'Bohemian Rhapsody');
    });

    test('Latin-1 extended characters round-trip (encoding 0)', () {
      final meta = parseTag(
        _id3v23Tag([_textFrame('TALB', 0, latin1.encode('Café Del Mar'))]),
      );
      expect(meta.album, 'Café Del Mar');
    });

    test('UTF-8 round-trips, including non-ASCII (encoding 3)', () {
      final meta = parseTag(
        _id3v23Tag([
          _textFrame('TPE1', 3, Uint8List.fromList(utf8.encode('Beyoncé'))),
        ]),
      );
      expect(meta.leadPerformer, 'Beyoncé');
    });
  });

  group('encoding 1 (UTF-16 with BOM) — the primary regression', () {
    test('LE BOM + plain Latin text decodes correctly', () {
      final meta = parseTag(
        _id3v23Tag([
          _textFrame(
            'TIT2',
            1,
            Uint8List.fromList([
              0xFF, 0xFE, // LE BOM
              ..._utf16LeBytes('Hello World'),
            ]),
          ),
        ]),
      );
      expect(meta.songName, 'Hello World');
    });

    test('BE BOM + plain Latin text decodes correctly — this is the exact '
        'upstream bug: hardcoded LE decoding of a BE-BOM value byte-swaps '
        'every character, landing ordinary Latin letters inside the CJK '
        'Unified Ideographs Unicode block', () {
      final meta = parseTag(
        _id3v23Tag([
          _textFrame(
            'TPE1',
            1,
            Uint8List.fromList([
              0xFE, 0xFF, // BE BOM
              ..._utf16BeBytes('The Beatles'),
            ]),
          ),
        ]),
      );
      expect(meta.leadPerformer, 'The Beatles');
      // Guards against the specific historical failure mode: no CJK
      // codepoints (U+4E00-U+9FFF) should appear in plainly Latin text.
      expect(
        meta.leadPerformer!.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF),
        isFalse,
      );
    });

    test('genuine Simplified Chinese (LE BOM) round-trips unchanged', () {
      final meta = parseTag(
        _id3v23Tag([
          _textFrame(
            'TALB',
            1,
            Uint8List.fromList([0xFF, 0xFE, ..._utf16LeBytes('你好世界')]),
          ),
        ]),
      );
      expect(meta.album, '你好世界');
    });

    test('genuine Japanese (BE BOM) round-trips unchanged', () {
      final meta = parseTag(
        _id3v23Tag([
          _textFrame(
            'TIT2',
            1,
            Uint8List.fromList([0xFE, 0xFF, ..._utf16BeBytes('こんにちは')]),
          ),
        ]),
      );
      expect(meta.songName, 'こんにちは');
    });

    test('genuine Arabic (LE BOM) round-trips unchanged', () {
      final meta = parseTag(
        _id3v23Tag([
          _textFrame(
            'TPE1',
            1,
            Uint8List.fromList([0xFF, 0xFE, ..._utf16LeBytes('مرحبا بالعالم')]),
          ),
        ]),
      );
      expect(meta.leadPerformer, 'مرحبا بالعالم');
    });
  });

  group('encoding 2 (UTF-16BE, no BOM) — the exact reported defect', () {
    test('plain Latin text decodes as big-endian, not little-endian', () {
      final meta = parseTag(
        _id3v23Tag([_textFrame('TALB', 2, _utf16BeBytes('Greatest Hits'))]),
      );
      expect(meta.album, 'Greatest Hits');
    });

    test('genuine Japanese text (no BOM, per spec) round-trips unchanged', () {
      final meta = parseTag(
        _id3v23Tag([_textFrame('TIT2', 2, _utf16BeBytes('さようなら'))]),
      );
      expect(meta.songName, 'さようなら');
    });
  });

  group('malformed/truncated values', () {
    test('an odd trailing byte on a UTF-16 value is trimmed, not crashed', () {
      final good = _utf16LeBytes('Hi');
      final truncated = Uint8List.fromList([
        ...good,
        0x41, // one stray trailing byte, no partner
      ]);
      // No terminator either — exercises the "ran off the end" path too.
      final body = BytesBuilder()
        ..addByte(1)
        ..add([0xFF, 0xFE]) // LE BOM
        ..add(truncated);
      final bodyBytes = body.toBytes();
      final frame =
          (BytesBuilder()
                ..add('TIT2'.codeUnits)
                ..add(
                  Uint8List(4)
                    ..buffer.asByteData().setUint32(
                      0,
                      bodyBytes.length,
                      Endian.big,
                    ),
                )
                ..add([0x00, 0x00])
                ..add(bodyBytes))
              .toBytes();

      expect(() => parseTag(_id3v23Tag([frame])), returnsNormally);
    });

    test('an empty text frame decodes to an empty string, not a crash', () {
      final meta = parseTag(_id3v23Tag([_textFrame('TIT2', 3, Uint8List(0))]));
      expect(meta.songName, '');
    });
  });

  group('TXXX (custom frame) and USLT (lyrics) share the same decode path', () {
    test('TXXX description+value round-trip under UTF-16BE (encoding 2)', () {
      final descBytes = _utf16BeBytes('MusicBrainz Track Id');
      final valueBytes = _utf16BeBytes('abc-123');
      final body = BytesBuilder()
        ..addByte(2)
        ..add(descBytes)
        ..add([0, 0]) // description terminator
        ..add(valueBytes);
      final bodyBytes = body.toBytes();
      final frame =
          (BytesBuilder()
                ..add('TXXX'.codeUnits)
                ..add(
                  Uint8List(4)
                    ..buffer.asByteData().setUint32(
                      0,
                      bodyBytes.length,
                      Endian.big,
                    ),
                )
                ..add([0x00, 0x00])
                ..add(bodyBytes))
              .toBytes();

      final meta = parseTag(_id3v23Tag([frame]));
      expect(meta.customMetadata['MusicBrainz Track Id'], 'abc-123');
    });

    test('USLT lyric body decodes correctly under a BE-BOM UTF-16 value', () {
      final body = BytesBuilder()
        ..addByte(1) // encoding: UTF-16 with BOM
        ..add('eng'.codeUnits) // language
        ..add([0xFE, 0xFF]) // description BOM (empty description)
        ..add([0, 0]) // description terminator
        ..add([0xFE, 0xFF]) // lyric BOM
        ..add(_utf16BeBytes('La la la'));
      final bodyBytes = body.toBytes();
      final frame =
          (BytesBuilder()
                ..add('USLT'.codeUnits)
                ..add(
                  Uint8List(4)
                    ..buffer.asByteData().setUint32(
                      0,
                      bodyBytes.length,
                      Endian.big,
                    ),
                )
                ..add([0x00, 0x00])
                ..add(bodyBytes))
              .toBytes();

      final meta = parseTag(_id3v23Tag([frame]));
      expect(meta.lyric, 'La la la');
    });
  });

  group('ID3v1 (always Latin-1, no encoding byte)', () {
    Uint8List buildId3v1({required String title, required String artist}) {
      final tag = Uint8List(128);
      tag.setRange(0, 3, 'TAG'.codeUnits);
      void writeField(int start, int len, String value) {
        final bytes = latin1.encode(value);
        final n = bytes.length > len ? len : bytes.length;
        tag.setRange(start, start + n, bytes.sublist(0, n));
      }

      writeField(3, 30, title);
      writeField(33, 30, artist);
      return tag;
    }

    test('plain ASCII title/artist round-trip', () {
      final file = File(
        p.join(tempDir.path, 'v1_${DateTime.now().microsecondsSinceEpoch}.id3'),
      );
      file.writeAsBytesSync(
        buildId3v1(title: 'Yesterday', artist: 'The Beatles'),
      );
      final raf = file.openSync();
      final meta = ID3v1Parser().parse(raf);
      raf.closeSync();
      expect(meta.songName, 'Yesterday');
      expect(meta.leadPerformer, 'The Beatles');
    });

    test('a Latin-1 extended character (e.g. é) that terminates before the '
        "field's end no longer throws — this is the historical bug: the "
        'original code decoded as UTF-8 whenever a null terminator was found '
        "early, and a lone 0xE9 byte ('é' in Latin-1) is not valid UTF-8, so "
        'dart:convert\'s utf8.decode would throw', () {
      final file = File(
        p.join(
          tempDir.path,
          'v1_accented_${DateTime.now().microsecondsSinceEpoch}.id3',
        ),
      );
      file.writeAsBytesSync(buildId3v1(title: 'Café', artist: 'Björk'));
      final raf = file.openSync();
      Mp3Metadata? meta;
      expect(() => meta = ID3v1Parser().parse(raf), returnsNormally);
      raf.closeSync();
      expect(meta!.songName, 'Café');
      expect(meta!.leadPerformer, 'Björk');
    });
  });
}
