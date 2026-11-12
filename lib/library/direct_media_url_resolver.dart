import 'package:dio/dio.dart';

import 'file_name_sanitizer.dart';
import 'media_download_service.dart' show DownloadCancelledException;
import 'media_probe.dart';
import 'media_signature.dart';
import 'media_url_resolver.dart';
import 'safe_http.dart';
import 'url_classifier.dart';

/// Resolves URLs that already point directly at a media file, by extension
/// first; for links without a usable extension, a HEAD request's
/// Content-Type, then (when that is absent, generic or unavailable) a
/// bounded ranged GET whose actual bytes are checked by [MediaProbe].
/// Extension links resolve without any network call — the download step
/// validates the real bytes. Anything unrecognized throws
/// [UnsupportedLinkException].
class DirectMediaUrlResolver implements MediaUrlResolver {
  final Dio _dio;
  final HostResolver? _resolveHost;
  final MediaProbe _probe;

  DirectMediaUrlResolver({
    Dio? dio,
    DirectMediaLimits limits = const DirectMediaLimits(),
    HostResolver? hostResolver,
    MediaProbe? probe,
  }) : this._(dio ?? Dio(), limits, hostResolver, probe);

  DirectMediaUrlResolver._(
    this._dio,
    DirectMediaLimits limits,
    this._resolveHost,
    MediaProbe? probe,
  ) : _probe =
          probe ??
          MediaProbe(dio: _dio, limits: limits, resolveHost: _resolveHost);

  // Last-resort resolver: claims everything so behavior matches the old
  // "try each in order" chain (unrecognized links throw from resolve()).
  // Must stay pure and network-free.
  @override
  bool supports(Uri url) => true;

  @override
  Future<ResolvedMedia> resolve(Uri url, {CancelToken? cancelToken}) async {
    try {
      return await _resolve(url, cancelToken);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const DownloadCancelledException();
      }
      rethrow;
    }
  }

  Future<ResolvedMedia> _resolve(Uri url, CancelToken? cancelToken) async {
    final pathExtension = _extensionOf(url.path);
    var kind = directMediaExtensionKinds[pathExtension];
    var extension = pathExtension;
    String? mimeType;
    int? expectedBytes;

    if (kind == null) {
      // Extensionless/opaque link: the only path that touches the network.
      await validateRemoteTarget(
        url,
        resolveHost: _resolveHost,
        cancelToken: cancelToken,
      );
      final head = await _headContentType(url, cancelToken);
      extension = directMediaMimeTypeExtensions[head.mime];
      kind = directMediaExtensionKinds[extension];
      mimeType = head.mime;

      if (kind == null && head.inconclusive) {
        try {
          final probed = await _probe.probe(url, cancelToken: cancelToken);
          extension = probed.evidence.extension;
          kind = probed.evidence.kind;
          mimeType = probed.mimeType;
          expectedBytes = probed.contentLength;
        } on MediaResolutionException catch (e) {
          if (e.failure != MediaResolutionFailure.invalidMediaResponse) {
            rethrow;
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.cancel) rethrow;
          // Couldn't tell — unsupported, as before.
        }
      }
    }

    if (kind == null) throw const UnsupportedLinkException();

    return ResolvedMedia(
      downloadUrl: url,
      suggestedFileName: mediaFileNameFor(url, extension),
      kind: kind,
      origin: MediaSourceOrigin.direct,
      originalUrl: url,
      mimeType: mimeType,
      expectedBytes: expectedBytes,
    );
  }

  /// HEAD without following redirects (a redirected link is left to the
  /// probe, which revalidates every hop). "Inconclusive" means no
  /// Content-Type, a generic binary one, or the request failing.
  Future<({String? mime, bool inconclusive})> _headContentType(
    Uri url,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await _dio.head<void>(
        url.toString(),
        cancelToken: cancelToken,
        options: Options(followRedirects: false),
      );
      final mime = normalizedMimeType(response.headers.value('content-type'));
      final generic =
          mime == null ||
          mime == 'application/octet-stream' ||
          mime == 'binary/octet-stream';
      return (mime: mime, inconclusive: generic);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      return (mime: null, inconclusive: true);
    }
  }

  String? _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return null;
    return path.substring(dot + 1).toLowerCase();
  }
}
