import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Hard resource bounds for any artwork Listeny writes to disk.
const artworkMaxBytes = 8 * 1024 * 1024;
const artworkMinBytes = 32;
const artworkMaxSide = 8000;
const artworkMaxPixels = 36 * 1000 * 1000;

/// How far into the data we look for the real image when a tag parser leaked
/// text (e.g. a UTF-16 picture description) in front of it.
const _maxLeakedPrefix = 256;

/// A picture whose content has been structurally verified as a real image.
class ValidatedArtwork {
  /// Exactly the verified image bytes (any leaked prefix already stripped).
  final Uint8List bytes;

  /// File extension matching the VERIFIED content: 'png', 'jpg' or 'webp'.
  final String extension;
  final int width;
  final int height;

  /// True when the image only validated after dropping leaked bytes in front
  /// of it (the known tag-parser quirk), i.e. the original data was damaged.
  final bool repaired;

  const ValidatedArtwork({
    required this.bytes,
    required this.extension,
    required this.width,
    required this.height,
    required this.repaired,
  });
}

/// Validates [data] as a PNG, JPEG or WebP by CONTENT (never by a file name or
/// a declared MIME type) and returns null for anything else: text, truncated
/// or malformed images, oversized or zero-sized pictures.
///
/// Some tag readers return the picture with the frame's UTF-16 description
/// still attached in front of the image bytes. If the data doesn't start with
/// an image but a complete, valid image begins within the first
/// [_maxLeakedPrefix] bytes, that image is returned (marked `repaired`) —
/// never the leaked prefix, and never anything that fails validation.
///
/// Cost is bounded: only headers/chunk or marker structure is walked, never
/// pixel data, so it is cheap enough to run on the UI isolate.
ValidatedArtwork? validateArtwork(Uint8List data) {
  if (data.length < artworkMinBytes || data.length > artworkMaxBytes) {
    return null;
  }
  final direct = _validateAt(data, 0);
  if (direct != null) return direct;

  final limit = math.min(_maxLeakedPrefix, data.length - artworkMinBytes);
  for (var i = 1; i <= limit; i++) {
    if (!_looksLikeImageStart(data, i)) continue;
    final v = _validateAt(data, i);
    if (v != null) {
      return ValidatedArtwork(
        bytes: v.bytes,
        extension: v.extension,
        width: v.width,
        height: v.height,
        repaired: true,
      );
    }
  }
  return null;
}

bool _looksLikeImageStart(Uint8List b, int o) {
  if (o + 4 > b.length) return false;
  if (b[o] == 0x89 && b[o + 1] == 0x50 && b[o + 2] == 0x4E) return true;
  if (b[o] == 0xFF && b[o + 1] == 0xD8 && b[o + 2] == 0xFF) return true;
  if (b[o] == 0x52 && b[o + 1] == 0x49 && b[o + 2] == 0x46) return true;
  return false;
}

ValidatedArtwork? _validateAt(Uint8List all, int offset) {
  final b = offset == 0 ? all : Uint8List.sublistView(all, offset);
  if (b.length < artworkMinBytes) return null;
  ({int w, int h})? dims;
  String ext;
  if (b[0] == 0x89) {
    dims = _pngDims(b);
    ext = 'png';
  } else if (b[0] == 0xFF) {
    dims = _jpegDims(b);
    ext = 'jpg';
  } else if (b[0] == 0x52) {
    dims = _webpDims(b);
    ext = 'webp';
  } else {
    return null;
  }
  if (dims == null || !_dimsOk(dims.w, dims.h)) return null;
  return ValidatedArtwork(
    bytes: b,
    extension: ext,
    width: dims.w,
    height: dims.h,
    repaired: false,
  );
}

bool _dimsOk(int w, int h) =>
    w > 0 &&
    h > 0 &&
    w <= artworkMaxSide &&
    h <= artworkMaxSide &&
    w * h <= artworkMaxPixels;

int _u32be(Uint8List b, int o) =>
    (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

int _u16be(Uint8List b, int o) => (b[o] << 8) | b[o + 1];

// --- PNG: signature, IHDR first, whole chunk chain fits, IDAT seen, IEND last.
({int w, int h})? _pngDims(Uint8List b) {
  const sig = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  for (var i = 0; i < 8; i++) {
    if (b[i] != sig[i]) return null;
  }
  var pos = 8;
  int? w, h;
  var sawIdat = false;
  var first = true;
  while (pos + 12 <= b.length) {
    final len = _u32be(b, pos);
    final type = String.fromCharCodes(b.sublist(pos + 4, pos + 8));
    if (len < 0 || pos + 12 + len > b.length) return null; // truncated chunk
    // Every chunk's CRC must match: catches corrupted/garbage chunk data that
    // the engine's lenient decoder would otherwise render as a partial image.
    if (_crc32(b, pos + 4, pos + 8 + len) != _u32be(b, pos + 8 + len)) {
      return null;
    }
    if (first) {
      if (type != 'IHDR' || len != 13) return null;
      w = _u32be(b, pos + 8);
      h = _u32be(b, pos + 12);
      first = false;
    } else if (type == 'IDAT') {
      sawIdat = true;
    } else if (type == 'IEND') {
      if (!sawIdat || len != 0) return null;
      // Nothing but (at most) a little padding may follow IEND.
      if (b.length - (pos + 12) > 16) return null;
      return (w: w!, h: h!);
    }
    pos += 12 + len;
  }
  return null; // ran out of data before IEND: truncated
}

// --- JPEG: SOI, a SOF with dimensions before SOS, and a closing EOI.
({int w, int h})? _jpegDims(Uint8List b) {
  if (b[0] != 0xFF || b[1] != 0xD8 || b[2] != 0xFF) return null;
  var end = b.length;
  while (end > 2 && b[end - 1] == 0) {
    end--;
  }
  if (end < 4 || b[end - 2] != 0xFF || b[end - 1] != 0xD9) return null;

  var i = 2;
  int? w, h;
  while (i + 4 <= end) {
    if (b[i] != 0xFF) return null;
    var marker = b[i + 1];
    while (marker == 0xFF && i + 2 < end) {
      i++;
      marker = b[i + 1];
    }
    if (marker == 0xD8 ||
        marker == 0x01 ||
        (marker >= 0xD0 && marker <= 0xD7)) {
      i += 2;
      continue;
    }
    if (marker == 0xD9) return null; // EOI before any scan data
    final len = _u16be(b, i + 2);
    if (len < 2 || i + 2 + len > end) return null;
    final isSof =
        marker == 0xC0 || marker == 0xC1 || marker == 0xC2 || marker == 0xC3;
    if (isSof) {
      if (len < 8) return null;
      h = _u16be(b, i + 5);
      w = _u16be(b, i + 7);
    }
    if (marker == 0xDA) {
      // Start of scan: entropy-coded data follows. Dimensions must be known.
      return (w != null && h != null) ? (w: w, h: h) : null;
    }
    i += 2 + len;
  }
  return null;
}

// --- WebP: RIFF container with a consistent size and a VP8/VP8L/VP8X header.
({int w, int h})? _webpDims(Uint8List b) {
  if (b.length < 30) return null;
  if (String.fromCharCodes(b.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(b.sublist(8, 12)) != 'WEBP') {
    return null;
  }
  final riffSize = b[4] | (b[5] << 8) | (b[6] << 16) | (b[7] << 24);
  // The declared size must fit the data we have (truncation check).
  if (riffSize + 8 > b.length + 1 || riffSize < 22) return null;
  final fourcc = String.fromCharCodes(b.sublist(12, 16));
  switch (fourcc) {
    case 'VP8X':
      final w = 1 + (b[24] | (b[25] << 8) | (b[26] << 16));
      final h = 1 + (b[27] | (b[28] << 8) | (b[29] << 16));
      return (w: w, h: h);
    case 'VP8L':
      if (b[20] != 0x2F) return null;
      final bits = b[21] | (b[22] << 8) | (b[23] << 16) | (b[24] << 24);
      return (w: 1 + (bits & 0x3FFF), h: 1 + ((bits >> 14) & 0x3FFF));
    case 'VP8 ':
      if (b[23] != 0x9D || b[24] != 0x01 || b[25] != 0x2A) return null;
      return (
        w: (b[26] | (b[27] << 8)) & 0x3FFF,
        h: (b[28] | (b[29] << 8)) & 0x3FFF,
      );
  }
  return null;
}

/// Longest side the verification decode is scaled down to, so checking a huge
/// (but within-bounds) picture never allocates its full pixel buffer.
const _verifyDecodeSide = 128;

/// [validateArtwork] PLUS a real, bounded codec decode (PNG, JPEG, WebP) of
/// the verified bytes. Structure alone can't prove an image is decodable, so
/// this decodes it through the engine's codecs — on the engine's own decode
/// threads, not the Dart UI isolate — scaled down to at most
/// [_verifyDecodeSide] px and under [timeout]. Anything malformed, truncated
/// or undecodable returns null and must never be saved as artwork.
Future<ValidatedArtwork?> decodeVerifiedArtwork(
  Uint8List data, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final v = validateArtwork(data);
  if (v == null) return null;
  ui.Codec? codec;
  try {
    final longest = math.max(v.width, v.height);
    int? tw, th;
    if (longest > _verifyDecodeSide) {
      final scale = _verifyDecodeSide / longest;
      tw = math.max(1, (v.width * scale).round());
      th = math.max(1, (v.height * scale).round());
    }
    codec = await ui
        .instantiateImageCodec(v.bytes, targetWidth: tw, targetHeight: th)
        .timeout(timeout);
    final frame = await codec.getNextFrame().timeout(timeout);
    frame.image.dispose();
    return v;
  } catch (_) {
    return null;
  } finally {
    codec?.dispose();
  }
}

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

/// CRC-32 (PNG/zlib polynomial) of `b[start, end)`.
int _crc32(Uint8List b, int start, int end) {
  var c = 0xFFFFFFFF;
  for (var i = start; i < end; i++) {
    c = _crcTable[(c ^ b[i]) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
