/// Parsing and formatting of the times typed into the trim screen.
///
/// Accepted: `13`, `13.5`, `1:05`, `1:05.25`, `1:02:03.5` (hours:minutes:
/// seconds, any unit may be left off from the front). `,` and the Arabic
/// decimal separator work as `.`, and Arabic-Indic / Persian digits are read
/// as ordinary digits.
Duration? parseTrimTime(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  s = _normalizeDigits(s).replaceAll(RegExp('[,٫]'), '.');
  final parts = s.split(':');
  if (parts.length > 3) return null;

  final last = parts.last;
  if (!RegExp(r'^(\d+(\.\d*)?|\.\d+)$').hasMatch(last)) return null;
  var seconds = double.parse(last.startsWith('.') ? '0$last' : last);
  final whole = <int>[];
  for (final part in parts.take(parts.length - 1)) {
    if (!RegExp(r'^\d+$').hasMatch(part)) return null;
    whole.add(int.parse(part));
  }
  // [h, m] or [m] in front of the seconds.
  if (whole.length == 2) {
    seconds += whole[0] * 3600 + whole[1] * 60;
  } else if (whole.length == 1) {
    seconds += whole[0] * 60;
  }
  if (seconds >= 100 * 3600) return null; // not a plausible track length
  return Duration(milliseconds: (seconds * 1000).round());
}

/// `m:ss`, `m:ss.5`, `h:mm:ss.25`: milliseconds shown only when non-zero,
/// without trailing zeros, so it round-trips through [parseTrimTime].
String formatTrimTime(Duration d) {
  final totalMs = d.inMilliseconds < 0 ? 0 : d.inMilliseconds;
  final h = totalMs ~/ 3600000;
  final m = (totalMs ~/ 60000) % 60;
  final s = (totalMs ~/ 1000) % 60;
  final ms = totalMs % 1000;
  final ss = s.toString().padLeft(2, '0');
  final head = h > 0 ? '$h:${m.toString().padLeft(2, '0')}' : '$m';
  var out = '$head:$ss';
  if (ms != 0) {
    out += '.${ms.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '')}';
  }
  return out;
}

String _normalizeDigits(String input) {
  final buf = StringBuffer();
  for (final unit in input.runes) {
    if (unit >= 0x0660 && unit <= 0x0669) {
      buf.writeCharCode(0x30 + unit - 0x0660); // Arabic-Indic
    } else if (unit >= 0x06F0 && unit <= 0x06F9) {
      buf.writeCharCode(0x30 + unit - 0x06F0); // Persian / Urdu
    } else {
      buf.writeCharCode(unit);
    }
  }
  return buf.toString();
}
