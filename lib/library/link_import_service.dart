import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/audio_formats.dart';
import 'audio_conversion_service.dart';
import 'import_models.dart';
import 'import_service.dart';
import 'library_repository.dart';
import 'link_import_models.dart';
import 'media_download_service.dart';
import 'media_url_resolver.dart';
import 'public_music_saver.dart';
import 'thumbnail_fetcher.dart';

class _Cancelled implements Exception {
  const _Cancelled();
}

/// A rejected or incomplete candidate. Its scratch file is discarded before
/// another candidate starts; bytes are never resumed across different streams.
class _CandidateFailed implements Exception {
  final String reason;
  const _CandidateFailed(this.reason);
}

// kDebugMode-guarded so this never runs (and is tree-shaken) in release
// builds — per-attempt byte counts/errors have no business in a
// production user's logs.
void _log(String message) {
  if (kDebugMode) debugPrint('[LinkImportService] $message');
}

/// Per-run state. Every download owns its own cancel token, cancel signal,
/// byte subscription and converter, so several runs can be in flight at once
/// without one run's cancel (or FFmpeg session) touching another's.
class _Run {
  final CancelToken cancelToken = CancelToken();
  final Completer<void> cancelSignal = Completer<void>();
  final AudioConversionService conversion;
  bool cancelRequested = false;
  StreamSubscription<List<int>>? byteSubscription;

  _Run(this.conversion);

  void cancel() {
    cancelRequested = true;
    cancelToken.cancel();
    unawaited(byteSubscription?.cancel());
    if (!cancelSignal.isCompleted) cancelSignal.complete();
    unawaited(conversion.cancel());
  }

  void throwIfCancelled() {
    if (cancelRequested) throw const _Cancelled();
  }
}

/// Orchestrates one link-to-library import: resolve the URL, stream the
/// download to a scratch file, convert it if needed, then hand the result
/// to the *existing* [ImportService] — every step after "get a real local
/// audio file" is the same metadata/artwork/duplicate-detection/persistence
/// pipeline every other import goes through, not a second copy of it.
class LinkImportService {
  final MediaUrlResolverRegistry _resolvers;
  final MediaDownloadService _downloadService;
  final AudioConversionService Function() _conversionFactory;
  final ImportService _importService;
  final LibraryRepository _libraryRepository;
  final ThumbnailFetcher _thumbnailFetcher;
  final PublicMusicSaver? _publicSaver;
  final Duration _firstByteTimeout;
  final _uuid = const Uuid();

  final _runs = <_Run>{};

  // ImportService's duplicate detection reads then writes the library, so
  // concurrent runs hand their file over one at a time.
  Future<void> _importLock = Future.value();

  LinkImportService({
    required this._resolvers,
    required this._importService,
    required this._libraryRepository,
    MediaDownloadService? downloadService,
    AudioConversionService? conversionService,
    // Each run needs its own converter (it tracks one FFmpeg session). A
    // single injected [conversionService] is shared as-is — tests only.
    AudioConversionService Function()? conversionServiceFactory,
    ThumbnailFetcher? thumbnailFetcher,
    // Null (tests) always imports into app-private storage.
    PublicMusicSaver? publicMusicSaver,
    // Only ever overridden in tests, so a candidate timing out doesn't mean
    // waiting the real 15s — production always gets the real value.
    @visibleForTesting this._firstByteTimeout = const Duration(seconds: 15),
  }) : _downloadService = downloadService ?? MediaDownloadService(),
       _conversionFactory =
           conversionServiceFactory ??
           (conversionService != null
               ? () => conversionService
               : AudioConversionService.new),
       _thumbnailFetcher = thumbnailFetcher ?? ThumbnailFetcher(),
       _publicSaver = publicMusicSaver;

  /// Starts a new resolve -> download -> convert -> import run for [url],
  /// emitting progress until it reaches [DownloadStage.completed],
  /// [DownloadStage.failed] or [DownloadStage.cancelled]. Runs are fully
  /// independent, so several can be active at once; pass a [handle] to be
  /// able to cancel just this one.
  Stream<LinkImportProgress> run({
    required Uri url,
    LinkImportHandle? handle,
  }) {
    final controller = StreamController<LinkImportProgress>();
    final run = _Run(_conversionFactory());
    _runs.add(run);
    handle?.attach(run.cancel);
    unawaited(_runInternal(url: url, controller: controller, run: run));
    return controller.stream;
  }

  /// Cancels every active run: aborts the in-flight HTTP request (or
  /// byte-stream subscription), stops the
  /// FFmpeg session if one is running, and (via the `finally` blocks below)
  /// cleans up every temp file it created and never starts another
  /// fallback candidate — no partial file is ever handed to
  /// [ImportService], so there's no way to end up with an incomplete
  /// library entry from a cancelled download.
  void cancel() {
    for (final run in _runs.toList()) {
      run.cancel();
    }
  }

  Future<T> _serializedImport<T>(Future<T> Function() action) {
    final previous = _importLock;
    final done = Completer<void>();
    _importLock = done.future;
    return previous.then((_) => action()).whenComplete(done.complete);
  }

  Future<void> _runInternal({
    required Uri url,
    required StreamController<LinkImportProgress> controller,
    required _Run run,
  }) async {
    final cancelToken = run.cancelToken;
    final conversion = run.conversion;
    String? downloadedPath;
    Directory? attemptDir;
    String? finalPath;
    String? thumbnailPath;
    String? embeddedArtworkPath;
    var unknownEmbeddedArtwork = false;
    ByteStreamSourceProvider? provider;
    // Download History bookkeeping: reasonable defaults in case resolving
    // itself fails (so even an unrecognized link leaves a useful row),
    // overwritten with the real values once resolve() succeeds. Left null
    // for a user-cancelled attempt — cancelling isn't a result worth
    // logging, just resolved/failed/succeeded ones.
    var attemptTitle = url.host.isNotEmpty ? url.host : url.toString();
    var sourceType = 'direct';
    String? historyStatus;
    String? historyOutputFormat;
    String? historyMessage;
    try {
      controller.add(const LinkImportProgress(stage: DownloadStage.resolving));
      final resolved = await _resolvers.resolve(url, cancelToken: cancelToken);
      attemptTitle = p.basenameWithoutExtension(resolved.suggestedFileName);
      sourceType = resolved.origin.name;
      run.throwIfCancelled();

      // One directory per attempt, removed wholesale in `finally`.
      final scratchDir = await _scratchDir();
      attemptDir = scratchDir;

      // fraction: null (not 0) — this is "about to start", not "0% done";
      // showing a literal 0% here is what made a stalled download look
      // stuck rather than indeterminate.
      controller.add(
        const LinkImportProgress(stage: DownloadStage.downloading),
      );

      provider = resolved.byteSourceProvider;
      if (provider != null) {
        final downloaded = await _downloadWithFallback(
          provider: provider,
          scratchDir: scratchDir,
          controller: controller,
          run: run,
        );
        downloadedPath = downloaded.path;
      } else {
        final sourceExt = extensionOf(resolved.suggestedFileName);
        downloadedPath = p.join(scratchDir.path, '${_uuid.v4()}.$sourceExt');
        await _downloadService.download(
          url: resolved.downloadUrl,
          destinationPath: downloadedPath,
          cancelToken: cancelToken,
          destinationPolicy: resolved.destinationPolicy,
          headers: resolved.downloadHeaders,
          onProgress: (received, total) {
            controller.add(
              LinkImportProgress(
                stage: DownloadStage.downloading,
                fraction: total == null ? null : received / total,
              ),
            );
          },
        );
      }
      run.throwIfCancelled();

      controller.add(const LinkImportProgress(stage: DownloadStage.converting));
      // Cover art is pulled from the SOURCE first (an audio-only MP3 encode
      // drops it); resolver tags are offered to the converter, which only
      // uses them for fields the source provably lacks.
      final artwork = await conversion.extractEmbeddedArtwork(
        downloadedPath,
        scratchDir.path,
      );
      embeddedArtworkPath = artwork.path;
      unknownEmbeddedArtwork = artwork.unknown;
      run.throwIfCancelled();
      final hasResolverTags =
          resolved.title != null ||
          resolved.artist != null ||
          resolved.album != null;
      finalPath = await conversion.process(
        inputPath: downloadedPath,
        outputDir: scratchDir.path,
        fallbackMetadata: hasResolverTags
            ? TrackMetadataFallback(
                title: resolved.title,
                artist: resolved.artist,
                album: resolved.album,
              )
            : null,
      );
      run.throwIfCancelled();

      // Best-effort only: a thumbnail is a nice-to-have, never something
      // that should fail a download that otherwise succeeded, and
      // ThumbnailFetcher itself never throws (returns null on any error).
      // cancelToken is the same token cancel() triggers, so a cancel mid-
      // fetch aborts the real HTTP request instead of being ignored.
      // Embedded source artwork wins; a resolver thumbnail is only fetched
      // when there is none.
      thumbnailPath = embeddedArtworkPath;
      // A remote thumbnail is only the fallback when the source is KNOWN to
      // have no artwork, never when that could not be determined.
      if (thumbnailPath == null &&
          !unknownEmbeddedArtwork &&
          resolved.thumbnailUrl != null) {
        thumbnailPath = await _thumbnailFetcher.fetch(
          resolved.thumbnailUrl!,
          p.join(scratchDir.path, '${_uuid.v4()}_thumb.jpg'),
          cancelToken: cancelToken,
        );
      }
      run.throwIfCancelled();

      controller.add(const LinkImportProgress(stage: DownloadStage.importing));
      final baseName = p.basenameWithoutExtension(resolved.suggestedFileName);
      final pickedName = '$baseName.${extensionOf(finalPath)}';
      final importPath = finalPath;
      final importArtwork = thumbnailPath;
      // Preferred (Android 11+): publish the MP3 into Music/Listeny and
      // reference that single file in place — a real local file, no second
      // copy, and no storage permission. Everywhere else (or on any failure)
      // this is null and the normal app-private import below is used.
      final saved = extensionOf(importPath) == 'mp3'
          ? await _publicSaver?.save(path: importPath, name: pickedName)
          : null;
      final summary = await _serializedImport(
        () => _importService.importAndSummarize([
          PickedFile(
            name: pickedName,
            path: saved?.path ?? importPath,
            externalArtworkPath: importArtwork,
            referencedSource: saved == null
                ? null
                : ReferencedSource(
                    sourceKey: saved.sourceKey,
                    volume: saved.volume,
                    sizeBytes: saved.sizeBytes,
                    modifiedSec: saved.modifiedSec,
                  ),
          ),
        ]),
      );
      // Nothing took ownership of the published file (duplicate / failed
      // import): remove it so no orphan is left in the Music folder.
      if (saved != null && summary.songsAdded == 0) {
        await _publicSaver?.discard(saved);
      }
      controller.add(
        LinkImportProgress(stage: DownloadStage.completed, summary: summary),
      );
      // A duplicate is a real, intended outcome (the track is already in
      // the library) — the existing UI shows it under the same "completed"
      // card as a fresh add, not as an error — so it counts as success
      // here too. Only corrupt/unsupported outcomes (no add, no duplicate)
      // are a history failure, reusing the same detail text the UI itself
      // shows for them.
      if (summary.songsAdded > 0 || summary.duplicates.isNotEmpty) {
        historyStatus = 'success';
        historyOutputFormat = extensionOf(finalPath);
      } else {
        historyStatus = 'failed';
        historyMessage = summary.corrupt.isNotEmpty
            ? summary.corrupt.first.detail
            : summary.unsupported.isNotEmpty
            ? summary.unsupported.first.detail
            : 'Import failed.';
      }
    } on MediaResolutionException catch (e) {
      final message = switch (e.failure) {
        MediaResolutionFailure.unsupportedLink =>
          'This link is not supported yet.',
        MediaResolutionFailure.authenticationRequired ||
        MediaResolutionFailure.privateContent =>
          'This video is private or needs a login, so it can\'t be downloaded.',
        MediaResolutionFailure.noMediaFound =>
          'No downloadable video was found at this link.',
        MediaResolutionFailure.mediaUnavailable =>
          'This video is unavailable or the site blocked the request.',
        MediaResolutionFailure.downloadNotPermitted =>
          'Downloading from this service is turned off.',
        _ => 'Couldn\'t download this link.',
      };
      controller.add(
        LinkImportProgress(stage: DownloadStage.failed, message: message),
      );
      historyStatus = 'failed';
      historyMessage = message;
    } on _Cancelled {
      controller.add(const LinkImportProgress(stage: DownloadStage.cancelled));
    } on DownloadCancelledException {
      controller.add(const LinkImportProgress(stage: DownloadStage.cancelled));
    } on ConversionCancelledException {
      controller.add(const LinkImportProgress(stage: DownloadStage.cancelled));
    } on DownloadFailedException catch (e) {
      controller.add(
        LinkImportProgress(stage: DownloadStage.failed, message: e.message),
      );
      historyStatus = 'failed';
      historyMessage = e.message;
    } on ConversionFailedException catch (e) {
      controller.add(
        LinkImportProgress(stage: DownloadStage.failed, message: e.message),
      );
      historyStatus = 'failed';
      historyMessage = e.message;
    } catch (_) {
      const message = 'Something went wrong with this link. Please try again.';
      controller.add(
        const LinkImportProgress(stage: DownloadStage.failed, message: message),
      );
      historyStatus = 'failed';
      historyMessage = message;
    } finally {
      // ImportService always copies its input into the app's own storage,
      // so every scratch file used to get there — the raw download, and
      // any separate converted file — is redundant afterward regardless of
      // whether the import succeeded, failed, or was cancelled.
      if (provider != null) await provider.dispose();
      if (downloadedPath != null) await _deleteQuietly(downloadedPath);
      if (finalPath != null && finalPath != downloadedPath) {
        await _deleteQuietly(finalPath);
      }
      if (thumbnailPath != null) await _deleteQuietly(thumbnailPath);
      if (attemptDir != null) await _deleteDirQuietly(attemptDir);
      // No row for a cancelled attempt — cancelling isn't a result worth
      // showing in history, only resolved successes/failures are.
      if (historyStatus != null) {
        await _libraryRepository.recordDownloadHistory(
          title: attemptTitle,
          sourceType: sourceType,
          status: historyStatus,
          outputFormat: historyOutputFormat,
          message: historyMessage,
        );
      }
      _runs.remove(run);
      await controller.close();
    }
  }

  /// Tries a bounded provider's candidates, discarding failed or incomplete
  /// scratch files before starting another transfer from byte zero.
  Future<_DownloadedFile> _downloadWithFallback({
    required ByteStreamSourceProvider provider,
    required Directory scratchDir,
    required StreamController<LinkImportProgress> controller,
    required _Run run,
  }) async {
    var attemptNumber = 0;
    while (true) {
      run.throwIfCancelled();
      attemptNumber++;
      final source = await provider.next();
      run.throwIfCancelled();
      if (source == null) {
        _log(
          'downloadWithFallback: no more candidates after ${attemptNumber - 1} attempt(s)',
        );
        throw const DownloadFailedException(
          "Couldn't download audio for this link right now. Please try again.",
        );
      }

      final ext = source.fileExtension;
      final path = p.join(scratchDir.path, '${_uuid.v4()}.$ext');
      var succeeded = false;
      try {
        await _downloadSingleCandidate(
          source: source,
          destinationPath: path,
          controller: controller,
          run: run,
          attemptNumber: attemptNumber,
        );
        run.throwIfCancelled();
        succeeded = true;
        return _DownloadedFile(path, ext);
      } on _CandidateFailed catch (e) {
        _log(
          'downloadWithFallback: attempt $attemptNumber failed (${e.reason}) — trying the next candidate',
        );
        controller.add(
          const LinkImportProgress(
            stage: DownloadStage.downloading,
            message: 'Trying another media stream...',
          ),
        );
      } finally {
        if (!succeeded) await _deleteQuietly(path);
      }
    }
  }

  /// Streams a candidate to disk with progress, first-byte timeout and cancel.
  /// Rejects incomplete files before conversion/import; never combines sources.
  Future<void> _downloadSingleCandidate({
    required ByteStreamSource source,
    required String destinationPath,
    required StreamController<LinkImportProgress> controller,
    required _Run run,
    required int attemptNumber,
  }) async {
    final contentLength = source.contentLength;
    _log('attempt $attemptNumber: opening — contentLength=$contentLength');
    final sink = File(destinationPath).openWrite();
    var received = 0;
    var gotFirstByte = false;
    final completer = Completer<void>();

    final stopwatch = Stopwatch()..start();
    final firstByteTimer = Timer(_firstByteTimeout, () {
      if (!gotFirstByte && !completer.isCompleted) {
        _log(
          'attempt $attemptNumber: no data after ${_firstByteTimeout.inSeconds}s — timing out',
        );
        completer.completeError(const _CandidateFailed('first-byte timeout'));
      }
    });

    var acceptingBytes = true;
    late final StreamSubscription<List<int>> subscription;
    subscription = source.open().listen(
      (chunk) {
        if (!acceptingBytes || chunk.isEmpty || completer.isCompleted) return;
        if (!gotFirstByte) {
          gotFirstByte = true;
          firstByteTimer.cancel();
          _log(
            'attempt $attemptNumber: first chunk after ${stopwatch.elapsedMilliseconds}ms, ${chunk.length} bytes',
          );
        }
        sink.add(chunk);
        received += chunk.length;
        controller.add(
          LinkImportProgress(
            stage: DownloadStage.downloading,
            fraction: (contentLength == null || contentLength == 0)
                ? null
                : received / contentLength,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        if (completer.isCompleted) return;
        if (!gotFirstByte) {
          _log(
            'attempt $attemptNumber: network exception before any data: $error',
          );
          completer.completeError(
            _CandidateFailed('network exception: $error'),
          );
        } else {
          _log(
            'attempt $attemptNumber: stream error after $received bytes: $error',
          );
          completer.completeError(
            _CandidateFailed('stream interrupted: $error'),
          );
        }
      },
      onDone: () {
        _log(
          'attempt $attemptNumber: done after ${stopwatch.elapsedMilliseconds}ms, received=$received',
        );
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );
    run.byteSubscription = subscription;

    try {
      await Future.any([completer.future, run.cancelSignal.future]);
    } on _CandidateFailed {
      rethrow;
    } on Object catch (_) {
      throw const DownloadFailedException(
        "Couldn't stream this download. Please try again.",
      );
    } finally {
      firstByteTimer.cancel();
      acceptingBytes = false;
      if (source is CancellableByteStreamSource) source.cancel();
      // Not awaited: if the underlying stream is genuinely stuck (the exact
      // case the first-byte timeout above exists for), a stalled async*
      // generator does not honor cancellation until its current pending
      // await resolves — which, for a hung socket read, may be never.
      // Awaiting this would mean the timeout we just fired never actually
      // unblocks anything. Disposing the whole client afterward (in the
      // provider) is what actually tears down the connection.
      unawaited(subscription.cancel());
      run.byteSubscription = null;
      await sink.close();
    }
    run.throwIfCancelled();
    final length = await File(destinationPath).length();
    if (received == 0 ||
        length != received ||
        (contentLength != null && length != contentLength)) {
      throw _CandidateFailed(
        'incomplete media: received=$received file=$length expected=$contentLength',
      );
    }
  }

  Future<Directory> _scratchDir() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(p.join(tempDir.path, 'link_downloads', _uuid.v4()));
    await dir.create(recursive: true);
    return dir;
  }

  Future<void> _deleteDirQuietly(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }
}

class _DownloadedFile {
  final String path;
  final String extension;
  const _DownloadedFile(this.path, this.extension);
}
