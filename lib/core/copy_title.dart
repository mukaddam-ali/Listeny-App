/// Naming for copies of a track (a trimmed cut, say): "Name", "Name (2)",
/// "Name (3)"... The counter is a plain suffix, so copies stay recognisable
/// and sort next to the original.
final _copyCounter = RegExp(r'\s\(\d+\)$');

/// [title] without a trailing copy counter: "Name (2)" -> "Name".
String stripCopyCounter(String title) =>
    title.replaceFirst(_copyCounter, '').trim();

/// The first "Base (n)", n >= 2, that is not already in [existing], where
/// Base is [title] without any counter it already carries.
String nextCopyTitle(String title, Iterable<String> existing) {
  final base = stripCopyCounter(title);
  final taken = {for (final t in existing) t.trim().toLowerCase()};
  var n = 2;
  while (taken.contains('$base ($n)'.toLowerCase())) {
    n++;
  }
  return '$base ($n)';
}
