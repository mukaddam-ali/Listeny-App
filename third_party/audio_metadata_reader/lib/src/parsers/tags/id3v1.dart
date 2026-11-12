import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/src/metadata/base.dart';
import 'package:audio_metadata_reader/src/parsers/tags/tag_parser.dart';

/// Parser for ID3v1 metadata tags.
class ID3v1Parser extends TagParser<Mp3Metadata> {
  /// Parsed ID3v1 metadata.
  final Mp3Metadata metadata = Mp3Metadata();

  /// Create an ID3v1 parser.
  ID3v1Parser({super.fetchImage = false});

  ///  Extract the part text between the [start] and the [end]
  ///  until we reach a "\x00" character
  ///
  /// Local patch (see ../../../../CHANGES.md): always decodes as ISO-8859-1
  /// (Latin-1), which is what the ID3v1 spec actually mandates — it has no
  /// per-tag encoding byte at all, unlike ID3v2. The original implementation
  /// decoded as UTF-8 whenever a null terminator happened to be found before
  /// [end], and Latin-1 otherwise — an inconsistency with two real problems:
  /// it could silently misdecode genuine (spec-correct) Latin-1 high bytes
  /// as different Unicode characters when they happened to form a valid
  /// UTF-8 sequence, and dart:convert's default `utf8.decode` *throws* on a
  /// sequence that isn't valid UTF-8, which ordinary accented Latin-1 text
  /// (e.g. 'é' = 0xE9 alone) very often isn't — a crash risk for exactly the
  /// terminated-before-`end` case. Latin-1 never throws (every byte 0-255 is
  /// a valid code point) and is byte-identical to UTF-8 decoding for the
  /// common case of plain ASCII text, so this is a strict improvement, not
  /// just a behavior change.
  String _extract(Uint8List tagData, int start, int end) {
    final nullPos = tagData.indexOf(0, start);
    final valueEnd = (nullPos >= 0 && nullPos < end) ? nullPos : end;
    return latin1.decode(tagData.sublist(start, valueEnd));
  }

  @override
  Mp3Metadata parse(RandomAccessFile reader) {
    final tagData = reader.readSync(128);
    metadata.songName = _extract(tagData, 3, 33);
    metadata.leadPerformer = _extract(tagData, 33, 63);
    metadata.album = _extract(tagData, 63, 93);
    final yearAsString =
        latin1.decode(tagData.sublist(93, 97)).replaceAll('\x00', '').trim();
    metadata.year = int.tryParse(yearAsString);
    metadata.comments = [
      Comment("", _extract(tagData, 97, 127)),
    ];
    metadata.genres = [""];

    // metadata.genres =  [tagData[127]];

    return metadata;
  }
}
