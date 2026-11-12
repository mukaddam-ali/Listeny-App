import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'media_signature.dart';
import 'media_url_resolver.dart';
import 'safe_http.dart';

/// Thrown when a download is cancelled mid-flight via the same [CancelToken]
/// passed to [MediaDownloadService.download].
class DownloadCancelledException implements Exception {
  const DownloadCancelledException();
}

/// A download failure with an already-friendly message — callers can show
/// [message] directly instead of a raw exception dump. [failure] carries the
/// typed reason when the failure is a direct-media transport one.
class DownloadFailedException implements Exception {
  final String message;
  final MediaResolutionFailure? failure;
  const DownloadFailedException(this.message, {this.failure});

  @override
  String toString() => message;
}

/// Free bytes on the volume holding [directory], or null when unknown.
/// No reliable dependency-free implementation exists on every platform, so
/// none is wired by default; supplying one enables a pre-download check.
typedef FreeSpaceProbe = Future<int?> Function(String directory);

/// Streams a URL straight to disk in bounded, validated fashion: redirects
/// are followed manually and revalidated, the body is size-capped while
/// streaming, HTML/non-media bodies are rejected from their first bytes,
/// and truncated bodies are detected. The partial file is removed on any
/// failure.
class MediaDownloadService {
  final Dio _dio;
  final DirectMediaLimits _limits;
  final HostResolver? _resolveHost;
  final FreeSpaceProbe? _freeSpace;

  MediaDownloadService({
    Dio? dio,
    this._limits = const DirectMediaLimits(),
    HostResolver? hostResolver,
    FreeSpaceProbe? freeSpaceProbe,
  }) : _dio = dio ?? Dio(),
       _resolveHost = hostResolver,
       _freeSpace = freeSpaceProbe;

  /// Downloads [url] to [destinationPath]. [destinationPolicy], when the
  /// resolver supplied one, is applied before the first request and every
  /// redirect target. [onProgress] receives
  /// (bytesReceived, totalBytes) — totalBytes is null when the server
  /// doesn't send a Content-Length. Cancel the download by calling
  /// `cancelToken.cancel()`.
  Future<void> download({
    required Uri url,
    required String destinationPath,
    required CancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
    DestinationPolicy? destinationPolicy,
    Map<String, String>? headers,
  }) async {
    try {
      await _download(
        url,
        destinationPath,
        cancelToken,
        onProgress,
        destinationPolicy,
        headers,
      );
    } catch (e) {
      await _deleteQuietly(destinationPath);
      if (e is DownloadCancelledException || e is DownloadFailedException) {
        rethrow;
      }
      if (cancelToken.isCancelled) throw const DownloadCancelledException();
      if (e is MediaResolutionException) {
        throw DownloadFailedException(
          _resolutionMessage(e.failure),
          failure: e.failure,
        );
      }
      if (e is FileSystemException) throw _storageFailure();
      if (e is DioException) {
        if (e.type == DioExceptionType.cancel) {
          throw const DownloadCancelledException();
        }
        if (e.error is FileSystemException) throw _storageFailure();
        throw DownloadFailedException(friendlyDownloadMessage(e));
      }
      rethrow;
    }
  }

  Future<void> _download(
    Uri url,
    String destinationPath,
    CancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
    DestinationPolicy? destinationPolicy,
    Map<String, String>? headers,
  ) async {
    final safe = await getWithSafeRedirects(
      _dio,
      url,
      limits: _limits,
      resolveHost: _resolveHost,
      cancelToken: cancelToken,
      destinationPolicy: destinationPolicy,
      headers: {...?headers, 'Accept-Encoding': 'identity'},
    );
    final response = safe.response;
    final body = response.data!;
    final mime = normalizedMimeType(response.headers.value('content-type'));
    final encoded =
        (response.headers.value('content-encoding') ?? 'identity')
            .toLowerCase() !=
        'identity';
    final declared = int.tryParse(
      response.headers.value('content-length') ?? '',
    );
    // A compressed transfer's Content-Length doesn't match the decoded
    // bytes, so it can't be used for size validation.
    final expected = (declared != null && declared >= 0 && !encoded)
        ? declared
        : null;

    if (expected != null && expected > _limits.maxBytes) {
      discardBody(body);
      throw const MediaResolutionException(
        MediaResolutionFailure.responseTooLarge,
      );
    }
    if (isHtmlMimeType(mime)) {
      discardBody(body);
      throw const MediaResolutionException(
        MediaResolutionFailure.invalidMediaResponse,
      );
    }
    final free = await _freeSpace?.call(p.dirname(destinationPath));
    // Room for the download plus a possible converted copy.
    if (free != null && expected != null && free < expected * 2) {
      discardBody(body);
      throw _storageFailure();
    }

    final sink = File(destinationPath).openWrite();
    final done = Completer<void>();
    final head = <int>[];
    var validated = false;
    var received = 0;

    void validateHead({bool complete = false}) {
      if (validated) return;
      validated = true;
      if (classifyMediaResponse(
            head: head,
            mimeType: mime,
            complete: complete,
          ) ==
          null) {
        throw const MediaResolutionException(
          MediaResolutionFailure.invalidMediaResponse,
        );
      }
    }

    late final StreamSubscription<List<int>> sub;
    void fail(Object error, [StackTrace? st]) {
      if (!done.isCompleted) done.completeError(error, st);
      unawaited(sub.cancel());
    }

    sub = body.stream.listen(
      (chunk) {
        if (done.isCompleted) return;
        try {
          received += chunk.length;
          if (received > _limits.maxBytes) {
            throw const MediaResolutionException(
              MediaResolutionFailure.responseTooLarge,
            );
          }
          if (expected != null && received > expected) {
            throw const MediaResolutionException(
              MediaResolutionFailure.incompleteDownload,
            );
          }
          if (!validated) {
            final room = 512 - head.length;
            head.addAll(chunk.length > room ? chunk.sublist(0, room) : chunk);
            if (head.length >= 512) validateHead();
          }
          sink.add(chunk);
          onProgress?.call(received, expected);
        } catch (e, st) {
          fail(e, st);
        }
      },
      onError: (Object e, StackTrace st) => fail(e, st),
      onDone: () {
        if (done.isCompleted) return;
        try {
          validateHead(complete: true);
          done.complete();
        } catch (e, st) {
          done.completeError(e, st);
        }
      },
      cancelOnError: true,
    );
    unawaited(
      cancelToken.whenCancel.then(
        (_) => fail(const DownloadCancelledException()),
      ),
    );
    unawaited(
      sink.done.then((_) {}, onError: (Object e, StackTrace st) => fail(e, st)),
    );

    try {
      await done.future;
    } catch (_) {
      unawaited(sub.cancel());
      try {
        await sink.close();
      } catch (_) {}
      rethrow;
    }
    await sink.close();

    if (expected != null && received != expected) {
      throw const MediaResolutionException(
        MediaResolutionFailure.incompleteDownload,
      );
    }
  }

  DownloadFailedException _storageFailure() => const DownloadFailedException(
    "There isn't enough free storage to download this file.",
  );

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  String _resolutionMessage(MediaResolutionFailure failure) {
    switch (failure) {
      case MediaResolutionFailure.responseTooLarge:
        return 'This file is too large to download.';
      case MediaResolutionFailure.invalidMediaResponse:
        return "This link didn't return a playable audio or video file.";
      case MediaResolutionFailure.redirectRejected:
      case MediaResolutionFailure.malformedUrl:
        return "This link redirects somewhere Listeny can't safely download from.";
      case MediaResolutionFailure.incompleteDownload:
        return 'The download was cut off before it finished. Please try again.';
      case MediaResolutionFailure.downloadNotPermitted:
      case MediaResolutionFailure.unsupportedLink:
        return "This link leads to a service Listeny can't download from here.";
      default:
        return "Couldn't download this link.";
    }
  }
}

/// Friendly, user-facing text for a failed HTTP transfer.
String friendlyDownloadMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return "Couldn't reach that link in time. Check your connection and try again.";
    case DioExceptionType.connectionError:
      return "Couldn't connect. Check your internet connection.";
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      if (status == 404) {
        return "That link doesn't point to a file (404 Not Found).";
      }
      if (status != null && status >= 400 && status < 500) {
        return "The server refused this link (error $status).";
      }
      return "The server had a problem serving this link (error $status).";
    case DioExceptionType.cancel:
      return 'Cancelled.';
    case DioExceptionType.badCertificate:
      return "This link's server has an invalid security certificate.";
    case DioExceptionType.unknown:
      return "Couldn't download this link.";
  }
}
