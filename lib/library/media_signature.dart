import 'media_url_resolver.dart';

/// Content-Type -> extension, for responses whose URL path has no usable
/// extension and for the "signature unknown" fallback below.
const directMediaMimeTypeExtensions = <String, String>{
  'audio/mpeg': 'mp3',
  'audio/mp4': 'm4a',
  'audio/x-m4a': 'm4a',
  'audio/aac': 'aac',
  'audio/wav': 'wav',
  'audio/x-wav': 'wav',
  'audio/wave': 'wav',
  'audio/flac': 'flac',
  'audio/x-flac': 'flac',
  'audio/ogg': 'ogg',
  'application/ogg': 'ogg',
  'video/mp4': 'mp4',
  'video/webm': 'webm',
};

/// Lower-cased media type without parameters ("audio/mpeg; charset=x" ->
/// "audio/mpeg"), or null when absent/blank.
String? normalizedMimeType(String? contentType) {
  if (contentType == null) return null;
  final mime = contentType.split(';').first.trim().toLowerCase();
  return mime.isEmpty ? null : mime;
}

bool isHtmlMimeType(String? mime) =>
    mime == 'text/html' || mime == 'application/xhtml+xml';

/// What a response's actual bytes say it is. This is only the fast, early
/// check: final acceptance requires a real decode (see
/// `AudioConversionService.validateDecodableAudio`).
class MediaEvidence {
  final String extension;
  final MediaSourceKind kind;
  const MediaEvidence(this.extension, this.kind);
}

/// True if [head] looks like the start of an HTML/XML document rather than
/// media (typical "200 OK" error/login pages).
bool looksLikeHtml(List<int> head) {
  var i = 0;
  // UTF-8 BOM, then whitespace.
  if (head.length >= 3 &&
      head[0] == 0xEF &&
      head[1] == 0xBB &&
      head[2] == 0xBF) {
    i = 3;
  }
  final end = head.length < 512 ? head.length : 512;
  final text = String.fromCharCodes(
    head.sublist(i, end).map((b) => b < 128 ? b : 0x3F),
  ).toLowerCase().trimLeft();
  return text.startsWith('<!doctype html') ||
      text.startsWith('<html') ||
      text.startsWith('<?xml') ||
      text.contains('<html') ||
      text.contains('<head') ||
      text.contains('<body');
}

bool _at(List<int> b, int offset, String ascii) {
  if (b.length < offset + ascii.length) return false;
  for (var i = 0; i < ascii.length; i++) {
    if (b[offset + i] != ascii.codeUnitAt(i)) return false;
  }
  return true;
}

// Size of an ID3v2 tag (header + body [+ footer]) at the start of [b], or
// null if [b] doesn't start with a well-formed ID3v2 header.
int? _id3v2Size(List<int> b) {
  if (b.length < 10 || !_at(b, 0, 'ID3')) return null;
  if (b[3] == 0xFF || b[4] == 0xFF) return null;
  if (b.sublist(6, 10).any((x) => x & 0x80 != 0)) return null;
  final body = (b[6] << 21) | (b[7] << 14) | (b[8] << 7) | b[9];
  final footer = (b[5] & 0x10) != 0 ? 10 : 0;
  return 10 + body + footer;
}

// Plausible MPEG audio frame header (sync, non-reserved version/layer,
// valid bitrate and sample-rate indices).
bool _mpegFrameAt(List<int> b, int i) {
  if (b.length < i + 4 || b[i] != 0xFF || (b[i + 1] & 0xE0) != 0xE0) {
    return false;
  }
  final version = (b[i + 1] >> 3) & 3;
  final layer = (b[i + 1] >> 1) & 3;
  final bitrate = (b[i + 2] >> 4) & 0xF;
  final rate = (b[i + 2] >> 2) & 3;
  return version != 1 && layer != 0 && bitrate != 0xF && rate != 3;
}

MediaEvidence? _bySignature(List<int> b, bool complete) {
  MediaEvidence sig(String ext, MediaSourceKind kind) =>
      MediaEvidence(ext, kind);
  if (_at(b, 0, 'ID3')) {
    final end = _id3v2Size(b);
    if (end == null) return null;
    // Audio must follow the tag. If the tag runs past the bytes we have, the
    // final decode check decides; if the bytes end at/inside it with nothing
    // after (a complete file), there is no audio at all.
    if (end < b.length) {
      return _mpegFrameAt(b, end) ? sig('mp3', MediaSourceKind.audio) : null;
    }
    return complete ? null : sig('mp3', MediaSourceKind.audio);
  }
  if (_at(b, 0, 'fLaC')) return sig('flac', MediaSourceKind.audio);
  if (_at(b, 0, 'OggS')) return sig('ogg', MediaSourceKind.audio);
  if (_at(b, 0, 'RIFF') && _at(b, 8, 'WAVE')) {
    return sig('wav', MediaSourceKind.audio);
  }
  if (b.length >= 4 &&
      b[0] == 0x1A &&
      b[1] == 0x45 &&
      b[2] == 0xDF &&
      b[3] == 0xA3) {
    return sig('webm', MediaSourceKind.video);
  }
  if (_at(b, 4, 'ftyp')) {
    // A complete file that is nothing but an ftyp box has no media.
    final size = (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
    if (complete && size >= 8 && size >= b.length) return null;
    final audioBrand =
        _at(b, 8, 'M4A ') || _at(b, 8, 'M4B ') || _at(b, 8, 'M4P ');
    return audioBrand
        ? sig('m4a', MediaSourceKind.audio)
        : sig('mp4', MediaSourceKind.video);
  }
  if (b.length >= 2 && b[0] == 0xFF) {
    // ADTS AAC: 12-bit sync, layer bits 00.
    if ((b[1] & 0xF6) == 0xF0 && b.length >= 7) {
      return sig('aac', MediaSourceKind.audio);
    }
    if (_mpegFrameAt(b, 0)) return sig('mp3', MediaSourceKind.audio);
  }
  return null;
}

/// Decides whether a response is plausibly media from its first bytes, so
/// obvious non-media (HTML, empty bodies, garbage, ID3-only or ftyp-only
/// files) fails fast. MIME type and file extension never count as evidence.
/// [complete] means [head] is the entire body. Returns null when rejected.
MediaEvidence? classifyMediaResponse({
  required List<int> head,
  String? mimeType,
  bool complete = false,
}) {
  if (head.isEmpty) return null;
  if (isHtmlMimeType(mimeType) || looksLikeHtml(head)) return null;
  return _bySignature(head, complete);
}
