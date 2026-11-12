import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_metadata_reader/src/constants/id3_genres.dart';
import 'package:audio_metadata_reader/src/metadata/base.dart';
import 'package:audio_metadata_reader/src/utils/bit_manipulator.dart';
import 'package:audio_metadata_reader/src/utils/buffer.dart';
import 'package:charset/charset.dart';
import 'tag_parser.dart';

const utf8Decoder = Utf8Decoder();
const utf16Decoder = Utf16Decoder();
const latin1Decoder = Latin1Decoder();

class ID3v3Frame {
  final String id;
  final int size;
  final Uint8List flags;

  ID3v3Frame(this.id, this.size, this.flags);
}

/// One decoded ID3v2 text value, plus the index of the first byte after its
/// terminator (or `bytes.length` if none was found) — so a caller reading
/// several values back-to-back out of the same frame (TXXX's
/// description+value, USLT's description+lyric) knows where the next one
/// starts.
class Id3TextValue {
  final String text;
  final int nextIndex;
  const Id3TextValue(this.text, this.nextIndex);
}

/// Decodes one ID3v2 text value starting at [start] in [bytes], per the
/// spec's encoding byte: 0 = ISO-8859-1 (Latin-1), 1 = UTF-16 with a leading
/// byte-order mark, 2 = UTF-16BE with no BOM (ID3v2.4), 3 = UTF-8.
///
/// This is the single, shared decode path for every ID3v2 text field
/// (TALB/TIT2/TPE1/... via [getTextFromFrame], [TXXXFrame],
/// [getUnsynchronisedLyric]) — a fix here fixes all of them at once,
/// instead of three independent, near-duplicate implementations that could
/// (and, upstream, did) drift out of sync and each carry their own bugs.
///
/// Local patch (see ../../../../CHANGES.md) — bugs this fixes relative to
/// the original audio_metadata_reader 1.7.1 implementation:
/// - encoding 1 (UTF-16 with BOM) was always decoded as little-endian,
///   ignoring whatever endianness the BOM actually declared. A file with a
///   big-endian BOM would come out byte-swapped — which is exactly what
///   turns ordinary Latin text into CJK-looking mojibake: e.g. 'A' is
///   U+0041, and its bytes swapped land at U+4100, inside the CJK Unified
///   Ideographs block.
/// - encoding 2 (UTF-16BE, no BOM) was *also* always decoded as
///   little-endian instead of big-endian — the exact defect named in the
///   task this patch was written for.
/// - the double-null (0x00 0x00) terminator scan for UTF-16 wasn't 2-byte
///   aligned relative to where the actual character data starts (i.e.
///   after any BOM), so a single 0x00 byte that happens to fall on an odd
///   offset — the low or high byte of a non-Latin BMP character below
///   U+0100 is a common way for that to happen — could be mistaken for
///   half of the terminator and truncate genuine text.
/// - a truncated/malformed UTF-16 value (odd number of trailing bytes)
///   could hand the decoder a half a character instead of being trimmed
///   safely.
Id3TextValue decodeId3TextValue(Uint8List bytes, int encoding, int start) {
  if (start >= bytes.length) return Id3TextValue("", bytes.length);
  switch (encoding) {
    case 0:
      final nullPos = bytes.indexOf(0, start);
      final end = (nullPos >= 0) ? nullPos : bytes.length;
      return Id3TextValue(
        latin1Decoder.convert(bytes, start, end),
        (nullPos >= 0) ? end + 1 : end,
      );
    case 3:
      final nullPos = bytes.indexOf(0, start);
      final end = (nullPos >= 0) ? nullPos : bytes.length;
      return Id3TextValue(
        utf8Decoder.convert(bytes, start, end),
        (nullPos >= 0) ? end + 1 : end,
      );
    case 1:
    case 2:
      return _decodeId3Utf16(bytes, start, forceBigEndianNoBom: encoding == 2);
    default:
      return Id3TextValue("", bytes.length);
  }
}

Id3TextValue _decodeId3Utf16(
  Uint8List bytes,
  int start, {
  required bool forceBigEndianNoBom,
}) {
  final hasBeBom = !forceBigEndianNoBom && hasUtf16BeBom(bytes, start);
  final hasLeBom = !forceBigEndianNoBom && hasUtf16LeBom(bytes, start);
  final dataStart = (hasBeBom || hasLeBom) ? start + 2 : start;

  // 2-byte-aligned scan for the terminator, relative to the real start of
  // character data (dataStart, i.e. past any BOM) — see decodeId3TextValue's
  // doc comment for why alignment matters here.
  var i = dataStart;
  while (i + 1 < bytes.length && !(bytes[i] == 0 && bytes[i + 1] == 0)) {
    i += 2;
  }
  final foundTerminator = i + 1 < bytes.length;
  var end = foundTerminator ? i : bytes.length;
  // Truncated/malformed value: drop a stray trailing odd byte rather than
  // handing the decoder half a character.
  if ((end - start).isOdd) end -= 1;
  if (end < start) end = start;

  // Slice includes the BOM (if any); decodeUtf16Be/Le strip a matching BOM
  // by default, so there's no need to compute an offset past it separately.
  final slice = bytes.sublist(start, end);
  final isBigEndian = forceBigEndianNoBom || hasBeBom;
  final text = isBigEndian
      ? utf16Decoder.decodeUtf16Be(slice)
      : utf16Decoder.decodeUtf16Le(slice);
  return Id3TextValue(text, foundTerminator ? i + 2 : bytes.length);
}

///
/// Metadata frame defined in the ID3 tag
///
String getTextFromFrame(Uint8List information) {
  if (information.isEmpty) return "";
  final encoding = information.first;
  return decodeId3TextValue(information, encoding, 1).text;
}

/// Custom metadata frame
/// Can be used my MusicBrainz for instance
///
/// Local patch (see ../../../../CHANGES.md): rewritten on top of the shared
/// [decodeId3TextValue] instead of its own independent (and, for encoding 1,
/// buggy — see that function's doc comment) offset/terminator logic.
class TXXXFrame {
  late final int encoding;
  late final String description;
  late final String information;

  TXXXFrame(Uint8List information) {
    encoding = information.isEmpty ? 0 : information[0];
    final desc = decodeId3TextValue(information, encoding, 1);
    description = desc.text;
    this.information = decodeId3TextValue(
      information,
      encoding,
      desc.nextIndex,
    ).text;
  }
}

///
/// Parser for the ID3 tags
///
///
/// https://teslabs.com/openplayer/docs/docs/specs/id3v2.3.0%20-%20ID3.org.pdf
///
class ID3v2Parser extends TagParser<Mp3Metadata> {
  final Mp3Metadata metadata = Mp3Metadata();
  late final Buffer buffer;

  static final _discRegex = RegExp(r"(\d+)/(\d+)");
  static final _trackRegex = RegExp(r"(\d+)/(\d+)");

  ID3v2Parser({bool fetchImage = false}) : super(fetchImage: fetchImage);

  @override
  Mp3Metadata parse(RandomAccessFile reader) {
    buffer = Buffer(randomAccessFile: reader);

    final headerBytes = buffer.read(10);
    final majorVersion = headerBytes[3];

    if (majorVersion == 1) {
      return metadata;
    }

    var sizeBytes = headerBytes.sublist(6);

    // size of the ID3 tag minus id3 header size
    int size = (sizeBytes[3] & 0x7F) |
        ((sizeBytes[2] & 0x7F) << 7) |
        ((sizeBytes[1] & 0x7F) << 14) |
        ((sizeBytes[0] & 0x7F) << 21);

    int offset = 10;

    // extended header
    // useless
    //
    // > The extended header contains information
    // > that is not vital to the correct
    // > parsing of the tag information
    if (getBit(headerBytes[5], 6) == 1) {
      final extendedHeaderSize = getUint32(buffer.read(4));
      buffer.skip(extendedHeaderSize - 4);
    }

    while (offset < size) {
      final frame = getFrame(reader, isV4: majorVersion == 4);

      if (frame == null) {
        break;
      }

      // 10 -> frame header
      offset = offset + 10 + frame.size;
      processFrame(frame.id, frame.size);
    }

    return metadata;
  }

  /// Process a frame.
  ///
  /// If the frame ID is not defined in the id3vX specs, then its content is dropped.
  void processFrame(String frameId, int size) {
    // why do we duplicate the content in every block?
    // it's because the biggest thing to get in the cover
    // sometimes, we don't want to read so we have to read the content
    // at the very last time

    final handlers = switch (frameId) {
      "APIC" => () {
          if (fetchImage) {
            final content = buffer.read(size);
            final picture = getPicture(content);
            metadata.pictures.add(picture);
          } else {
            buffer.skip(size);
          }
        },
      "TALB" => () {
          final content = buffer.read(size);
          metadata.album = getTextFromFrame(content);
        },
      "TBPM" => () {
          final content = buffer.read(size);
          metadata.bpm = getTextFromFrame(content);
        },
      "TCOP" => () {
          final content = buffer.read(size);
          metadata.copyrightMessage = getTextFromFrame(content);
        },
      "TCON" => () {
          final content = buffer.read(size);
          metadata.contentType = getTextFromFrame(content);
          final regex = RegExp(r"(\d+).*");
          final containRegex = RegExp(r";|/|\||,");

          if (metadata.contentType!.contains(containRegex)) {
            metadata.genres.addAll(metadata.contentType!
                .split(containRegex)
                .map((e) => e.trim())
                .toList());
          } else if (regex.hasMatch(metadata.contentType!)) {
            metadata.genres.add(id3Genres[
                    regex.allMatches(metadata.contentType!).first.group(0)!] ??
                "");
          } else if (metadata.contentType!.isNotEmpty) {
            metadata.genres.add(metadata.contentType!);
          }
        },
      "TCOM" => () {
          final content = buffer.read(size);
          metadata.composer = getTextFromFrame(content);
        },
      "TDAT" => () {
          final content = buffer.read(size);
          metadata.date = getTextFromFrame(content);
        },
      "TDLY" => () {
          final content = buffer.read(size);
          metadata.playlistDelay = getTextFromFrame(content);
        },
      "TENC" => () {
          final content = buffer.read(size);
          metadata.encodedBy = getTextFromFrame(content);
        },
      "TFLT" => () {
          final content = buffer.read(size);
          metadata.fileType = getTextFromFrame(content);
        },
      "TIME" => () {
          final content = buffer.read(size);
          metadata.time = getTextFromFrame(content);
        },
      "TIT1" => () {
          final content = buffer.read(size);
          metadata.contentGroupDescription = getTextFromFrame(content);
        },
      "TIT2" => () {
          final content = buffer.read(size);
          metadata.songName = getTextFromFrame(content);
        },
      "TIT3" => () {
          final content = buffer.read(size);
          metadata.subtitle = getTextFromFrame(content);
        },
      "TKEY" => () {
          final content = buffer.read(size);
          metadata.initialKey = getTextFromFrame(content);
        },
      "TLAN" => () {
          final content = buffer.read(size);
          metadata.languages = getTextFromFrame(content);
        },
      "TLEN" => () {
          final content = buffer.read(size);
          final time = int.tryParse(getTextFromFrame(content));

          if (time != null) {
            if ((time / 1000) < 1) {
              metadata.duration = Duration(seconds: time);
            } else {
              metadata.duration = Duration(milliseconds: time);
            }
          }
        },
      "TMED" => () {
          final content = buffer.read(size);
          metadata.mediatype = getTextFromFrame(content);
        },
      "TOAL" => () {
          final content = buffer.read(size);
          metadata.originalAlbum = getTextFromFrame(content);
        },
      "TOFN" => () {
          final content = buffer.read(size);
          metadata.originalFilename = getTextFromFrame(content);
        },
      "TOLY" => () {
          final content = buffer.read(size);
          metadata.originalTextWriter = getTextFromFrame(content);
        },
      "TOPE" => () {
          final content = buffer.read(size);
          metadata.originalArtist = getTextFromFrame(content);
        },
      "TORY" => () {
          final content = buffer.read(size);
          metadata.originalReleaseYear = _parseYear(getTextFromFrame(content));
        },
      "TOWN" => () {
          final content = buffer.read(size);
          metadata.fileOwner = getTextFromFrame(content);
        },
      "TDRC" => () {
          final content = buffer.read(size);
          metadata.year = _parseYear(getTextFromFrame(content));
        },
      "TYER" => () {
          final content = buffer.read(size);
          metadata.year = _parseYear(getTextFromFrame(content));
        },
      "TRDA" => () {
          final content = buffer.read(size);
          metadata.year = _parseYear(getTextFromFrame(content));
        },
      "TPE1" => () {
          final content = buffer.read(size);
          metadata.leadPerformer = getTextFromFrame(content);
        },
      "TPE2" => () {
          final content = buffer.read(size);
          metadata.bandOrOrchestra = getTextFromFrame(content);
        },
      "TPE3" => () {
          final content = buffer.read(size);
          metadata.conductor = getTextFromFrame(content);
        },
      "TPE4" => () {
          final content = buffer.read(size);
          metadata.interpreted = getTextFromFrame(content);
        },
      "TEXT" => () {
          final content = buffer.read(size);
          metadata.textWriter = getTextFromFrame(content);
        },
      "TPOS" || "TPA" => () {
          final content = buffer.read(size);
          final value = getTextFromFrame(content);
          metadata.partOfSet = value;

          final match = _discRegex.firstMatch(value);

          if (match != null) {
            metadata.discNumber = int.parse(match.group(1)!);
            metadata.totalDics = int.parse(match.group(2)!);
          } else {
            metadata.discNumber = int.tryParse(value);
          }
        },
      "TPUB" => () {
          final content = buffer.read(size);
          metadata.publisher = getTextFromFrame(content);
        },
      "TRCK" => () {
          final content = buffer.read(size);
          final trackInfo = getTextFromFrame(content);

          if (trackInfo.isEmpty) {
            return;
          }

          final match = _trackRegex.firstMatch(trackInfo);

          if (match != null) {
            metadata.trackNumber = int.parse(match.group(1)!);
            metadata.trackTotal = int.parse(match.group(2)!);
          } else {
            metadata.trackNumber = int.parse(trackInfo);
          }
        },
      "TRSN" => () {
          final content = buffer.read(size);
          metadata.internetRadioStationName = getTextFromFrame(content);
        },
      "TRSO" => () {
          final content = buffer.read(size);
          metadata.internetRadioStationOwner = getTextFromFrame(content);
        },
      "TSIZ" => () {
          final content = buffer.read(size);
          metadata.size = getTextFromFrame(content);
        },
      "TSRC" => () {
          final content = buffer.read(size);
          metadata.isrc = getTextFromFrame(content);
        },
      "TXXX" => () {
          final content = buffer.read(size);
          final frame = TXXXFrame(content);
          metadata.customMetadata[frame.description] = frame.information;
        },
      "USLT" => () {
          final content = buffer.read(size);
          metadata.lyric = getUnsynchronisedLyric(content);
        },
      "TSSE" => () {
          final content = buffer.read(size);
          metadata.encoderSoftware = getTextFromFrame(content);
        },
      _ => () {
          buffer.skip(size);
        }
    };

    handlers.call();
  }

  ID3v3Frame? getFrame(
    RandomAccessFile reader, {
    required bool isV4,
  }) {
    final headerBytes = buffer.read(10);

    if (headerBytes.every((element) => element == 0)) return null;

    int size;

    // the id3 v4 ignore the first bit of every byte from the size
    if (isV4) {
      size = (headerBytes[7] & 0xFF) |
          ((headerBytes[6] & 0xFF) << 7) |
          ((headerBytes[5] & 0xFF) << 14) |
          ((headerBytes[4] & 0xFF) << 21);
    } else {
      size = headerBytes[7] +
          (headerBytes[6] << 8) +
          (headerBytes[5] << 16) +
          (headerBytes[4] << 24);
    }

    final flags = headerBytes.sublist(8);
    final id = String.fromCharCodes(headerBytes.sublist(0, 4));

    return ID3v3Frame(
      id,
      size,
      flags,
    );
  }

  Picture getPicture(Uint8List content) {
    int offset = 0;

    final reader = ByteData.sublistView(content);
    final encoding = reader.getUint8(offset++);

    final mimetype = [reader.getUint8(offset++)];

    while (mimetype.last != 0) {
      mimetype.add(reader.getUint8(offset));
      offset++;
    }
    mimetype.removeLast();

    final pictureType = reader.getUint8(offset);

    offset++;

    final description = [reader.getInt8(offset++)];

    while (description.last != 0) {
      description.add(reader.getInt8(offset++));
    }

    if (encoding == 1 || encoding == 2) {
      while (reader.getInt8(offset) == 0) {
        offset++;
      }
    }

    return Picture(
      reader.buffer.asUint8List(offset),
      String.fromCharCodes(mimetype),
      getPictureTypeEnum(pictureType),
    );
  }

  /// Local patch (see ../../../../CHANGES.md): rewritten on top of the
  /// shared [decodeId3TextValue] instead of its own independent (and, for
  /// encodings 1/2, buggy — always little-endian regardless of actual BOM/
  /// spec — see that function's doc comment) logic.
  String getUnsynchronisedLyric(Uint8List content) {
    if (content.isEmpty) return "";
    final encoding = content[0];
    const languageBytes = 3;
    final descStart = 1 + languageBytes;
    if (descStart > content.length) return "";
    final desc = decodeId3TextValue(content, encoding, descStart);
    return decodeId3TextValue(content, encoding, desc.nextIndex).text;
  }

  int? _parseYear(String year) {
    if (year.contains("-")) {
      return int.tryParse(year.split("-").first);
    } else if (year.contains("/")) {
      return int.tryParse(year.split("/").first);
    } else {
      return int.tryParse(year);
    }
  }
}
