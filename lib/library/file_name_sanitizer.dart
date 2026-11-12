/// Makes a remote-supplied file name safe to use as a local name: keeps only
/// the last path component, strips control/bidi-override characters and
/// characters invalid in file names, preserves other Unicode, and caps the
/// length (keeping a short extension intact).
String sanitizeFileName(
  String name, {
  int maxLength = 120,
  String fallback = 'download',
}) {
  final parts = name.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty);
  var base = parts.isEmpty ? '' : parts.last;
  base = base.runes
      .where((r) => !_isStrippedRune(r))
      .map(String.fromCharCode)
      .join()
      .replaceAll(RegExp(r'[<>:"|?*]'), '_')
      .trim();
  base = base.replaceAll(RegExp(r'^[.\s]+|[.\s]+$'), '');
  if (base.isEmpty) return fallback;

  final runes = base.runes.toList();
  if (runes.length <= maxLength) return base;
  final dot = base.lastIndexOf('.');
  final ext = dot > 0 && base.length - dot <= 11 ? base.substring(dot) : '';
  final stemRunes = base.substring(0, ext.isEmpty ? base.length : dot).runes;
  final keep = maxLength - ext.runes.length;
  return String.fromCharCodes(stemRunes.take(keep < 1 ? 1 : keep)) + ext;
}

/// Control characters and bidi-override/format marks.
bool _isStrippedRune(int r) =>
    r <= 0x1F ||
    (r >= 0x7F && r <= 0x9F) ||
    r == 0x200E ||
    r == 0x200F ||
    (r >= 0x202A && r <= 0x202E) ||
    (r >= 0x2066 && r <= 0x2069);

/// Cleans page-supplied metadata text (a title, say): drops control and
/// bidi characters, collapses whitespace, caps the length. Null when
/// nothing usable is left.
String? sanitizeMetadataText(String? text, {int maxLength = 200}) {
  if (text == null) return null;
  final cleaned = text.runes
      .where((r) => !_isStrippedRune(r))
      .map(String.fromCharCode)
      .join()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return null;
  final runes = cleaned.runes.toList();
  return runes.length <= maxLength
      ? cleaned
      : String.fromCharCodes(runes.take(maxLength)).trim();
}

/// Local file name for a media URL: its sanitized last path segment, with a
/// misleading extension corrected to [extension]; `download.<ext>` when the
/// segment has no extension at all.
String mediaFileNameFor(Uri url, String? extension) {
  final lastSegment = url.pathSegments.isNotEmpty
      ? sanitizeFileName(url.pathSegments.last, fallback: '')
      : '';
  if (lastSegment.isNotEmpty && lastSegment.contains('.')) {
    final dot = lastSegment.lastIndexOf('.');
    if (extension != null &&
        lastSegment.substring(dot + 1).toLowerCase() != extension) {
      return '${lastSegment.substring(0, dot)}.$extension';
    }
    return lastSegment;
  }
  return 'download.${extension ?? 'bin'}';
}
