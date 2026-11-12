import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../library/link_import_models.dart';
import '../../library/link_import_service.dart';

/// One link on the Download screen. Holds the single [LinkImportProgress]
/// that matters for it, so a card never juggles booleans that could
/// disagree with each other. [isQueued] is the only extra state: the job
/// exists but is waiting for one of the concurrent slots.
class DownloadJob {
  final int id;
  final Uri url;
  final LinkImportHandle handle = LinkImportHandle();

  LinkImportProgress progress = const LinkImportProgress(
    stage: DownloadStage.idle,
  );
  bool isQueued = true;

  DownloadJob(this.id, this.url);

  DownloadStage get stage => progress.stage;

  bool get isFinished => const {
    DownloadStage.completed,
    DownloadStage.failed,
    DownloadStage.cancelled,
  }.contains(stage);

  /// Cancelling during [DownloadStage.importing] wouldn't actually stop
  /// anything — the file copy/tag read it's doing is fast and has no
  /// cancellation point — so the button is only offered where it does
  /// something real (waiting jobs can always be dropped).
  bool get canCancel =>
      !isFinished && (isQueued || stage != DownloadStage.importing);
}

/// Drives the Download screen: any number of pasted links, of which at most
/// [maxConcurrent] download at the same time — the rest wait their turn.
/// URL imports always produce MP3, so there is no format to choose.
class DownloadController extends ChangeNotifier {
  static const maxConcurrent = 3;

  final LinkImportService _service;
  final _jobs = <DownloadJob>[];
  final _subscriptions = <int, StreamSubscription<LinkImportProgress>>{};
  var _nextId = 0;
  var _disposed = false;
  String? _validationError;

  DownloadController(this._service);

  List<DownloadJob> get jobs => List.unmodifiable(_jobs);
  String? get validationError => _validationError;

  /// Whether any job is still waiting or running.
  bool get hasActive => _jobs.any((j) => !j.isFinished);

  bool get hasFinished => _jobs.any((j) => j.isFinished);

  /// Adds [rawUrl] to the list and starts it as soon as a slot is free.
  /// Returns false (leaving the input untouched) for an invalid link or one
  /// that is already waiting/downloading.
  bool start(String rawUrl) {
    final url = _parseUrl(rawUrl);
    if (url == null) {
      _validationError = 'Paste a valid link to a media file.';
      notifyListeners();
      return false;
    }
    _validationError = null;
    if (_jobs.any((j) => !j.isFinished && j.url == url)) {
      notifyListeners();
      return false;
    }
    // Newest first, so the link just pasted is right under the field.
    _jobs.insert(0, DownloadJob(_nextId++, url));
    _pump();
    notifyListeners();
    return true;
  }

  void clearValidationError() {
    if (_validationError == null) return;
    _validationError = null;
    notifyListeners();
  }

  /// Stops [job]: a waiting one is simply dropped, a running one is aborted
  /// and shows as cancelled until the user removes its card.
  void cancel(DownloadJob job) {
    if (!job.canCancel) return;
    if (job.isQueued) {
      _jobs.remove(job);
    } else {
      job.handle.cancel();
    }
    notifyListeners();
  }

  /// Removes a finished card from the list.
  void dismiss(DownloadJob job) {
    if (!job.isFinished) return;
    _jobs.remove(job);
    notifyListeners();
  }

  void dismissFinished() {
    _jobs.removeWhere((j) => j.isFinished);
    notifyListeners();
  }

  void _pump() {
    var running = _jobs.where((j) => !j.isQueued && !j.isFinished).length;
    // Oldest waiting job first (the list is newest-first).
    for (final job in _jobs.reversed.toList()) {
      if (running >= maxConcurrent) break;
      if (!job.isQueued) continue;
      job.isQueued = false;
      job.progress = const LinkImportProgress(stage: DownloadStage.resolving);
      running++;
      _subscriptions[job.id] = _service
          .run(url: job.url, handle: job.handle)
          .listen(
            (update) {
              job.progress = update;
              if (!_disposed) notifyListeners();
            },
            onDone: () {
              _subscriptions.remove(job.id);
              _pump();
              if (!_disposed) notifyListeners();
            },
          );
    }
  }

  Uri? _parseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.isAbsolute) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  @override
  void dispose() {
    _disposed = true;
    _service.cancel();
    for (final sub in _subscriptions.values) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    super.dispose();
  }
}
