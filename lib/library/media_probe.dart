import 'dart:async';

import 'package:dio/dio.dart';

import 'media_signature.dart';
import 'media_url_resolver.dart';
import 'safe_http.dart';

/// What a probe learned about a remote media response.
class MediaProbeResult {
  final Uri finalUrl;
  final String? mimeType;

  /// Total size when the server declared one.
  final int? contentLength;
  final MediaEvidence evidence;
  const MediaProbeResult({
    required this.finalUrl,
    required this.mimeType,
    required this.contentLength,
    required this.evidence,
  });
}

/// Fetches only the first bytes of a URL (bounded ranged GET, safe
/// redirects) and decides from the bytes and headers together whether it
/// is supported media. Never downloads the whole body.
class MediaProbe {
  final Dio _dio;
  final DirectMediaLimits limits;
  final HostResolver? _resolveHost;
  final DestinationPolicy? _destinationPolicy;

  MediaProbe({
    required this._dio,
    this.limits = const DirectMediaLimits(),
    this._resolveHost,
    this._destinationPolicy,
  });

  /// Throws [MediaResolutionException] (redirectRejected, responseTooLarge,
  /// invalidMediaResponse, ...) or [DioException] for HTTP/network errors.
  Future<MediaProbeResult> probe(Uri url, {CancelToken? cancelToken}) async {
    final safe = await getWithSafeRedirects(
      _dio,
      url,
      limits: limits,
      resolveHost: _resolveHost,
      destinationPolicy: _destinationPolicy,
      cancelToken: cancelToken,
      headers: {
        'Range': 'bytes=0-${limits.probeBytes - 1}',
        'Accept-Encoding': 'identity',
      },
    );
    final response = safe.response;
    final body = response.data!;
    final mime = normalizedMimeType(response.headers.value('content-type'));
    final total = _totalLength(response);
    if (total != null && total > limits.maxBytes) {
      discardBody(body);
      throw const MediaResolutionException(
        MediaResolutionFailure.responseTooLarge,
      );
    }
    final head = (await readAtMost(
      body.stream,
      limits.probeBytes,
      cancelToken: cancelToken,
    )).bytes;
    final evidence = classifyMediaResponse(
      head: head,
      mimeType: mime,
      complete: head.length < limits.probeBytes,
    );
    if (evidence == null) {
      throw const MediaResolutionException(
        MediaResolutionFailure.invalidMediaResponse,
      );
    }
    return MediaProbeResult(
      finalUrl: safe.finalUrl,
      mimeType: mime,
      contentLength: total,
      evidence: evidence,
    );
  }

  int? _totalLength(Response<ResponseBody> r) {
    if (r.statusCode == 206) {
      final range = r.headers.value('content-range');
      return int.tryParse(range?.split('/').last.trim() ?? '');
    }
    return int.tryParse(r.headers.value('content-length') ?? '');
  }
}
