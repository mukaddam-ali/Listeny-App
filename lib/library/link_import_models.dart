import 'import_models.dart';

/// Where a single link-import attempt currently is. Deliberately a single
/// state instead of a pile of booleans — the Download screen renders
/// directly off this, one state at a time, never several flags that could
/// disagree with each other.
enum DownloadStage {
  idle,
  resolving,
  downloading,
  converting,
  importing,
  completed,
  failed,
  cancelled,
}

/// One update in the life of a link import — [LinkImportService.run] emits
/// a stream of these.
class LinkImportProgress {
  final DownloadStage stage;

  /// 0.0-1.0 while [stage] is [DownloadStage.downloading] and the server
  /// reported a Content-Length; null otherwise (including an
  /// indeterminate/unknown-size download).
  final double? fraction;

  /// A friendly, human-readable detail — populated on [DownloadStage.failed].
  final String? message;

  /// Set once [stage] is [DownloadStage.completed].
  final ImportSummary? summary;

  const LinkImportProgress({
    required this.stage,
    this.fraction,
    this.message,
    this.summary,
  });
}

/// Lets a caller cancel one specific [LinkImportService.run] without
/// touching any other run that is active at the same time.
class LinkImportHandle {
  void Function()? _onCancel;
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    _onCancel?.call();
  }

  /// Called by the service once the run exists; a cancel that arrived
  /// before then is applied immediately.
  void attach(void Function() onCancel) {
    _onCancel = onCancel;
    if (_cancelled) onCancel();
  }
}
