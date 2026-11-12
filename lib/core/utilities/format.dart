import '../../l10n/generated/app_localizations.dart';

String formatDuration(Duration d) {
  final minutes = d.inMinutes
      .remainder(60)
      .toString()
      .padLeft(d.inHours > 0 ? 2 : 1, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours > 0) {
    return '${d.inHours}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

String formatDurationLong(AppLocalizations l10n, Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours > 0) return l10n.formatHoursMinutes(hours, minutes);
  return l10n.formatMinutesOnly(minutes);
}

/// A short "how long ago" label (e.g. "2m ago", "3h ago", "5d ago") for
/// compact rows like Download History — falls back to a plain date once
/// something is more than a week old, since "9d ago" stops being useful.
String formatRelativeTime(AppLocalizations l10n, DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return l10n.formatJustNow;
  if (diff.inMinutes < 60) return l10n.formatMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.formatHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.formatDaysAgo(diff.inDays);
  return '${time.day}/${time.month}/${time.year}';
}

String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '$bytes B';
}
