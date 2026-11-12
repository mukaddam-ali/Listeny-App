import 'package:dio/dio.dart';

/// Best-effort fetch of a source's thumbnail/cover image to a local file, so
/// [ImportService] can use it as a fallback when the downloaded audio has no
/// embedded artwork. Deliberately never throws — a thumbnail is a nice-to-
/// have, never something that should fail a whole download — [fetch] just
/// returns null on any error (network, bad status, etc.) and callers fall
/// back to the usual generated-gradient placeholder.
class ThumbnailFetcher {
  final Dio _dio;

  ThumbnailFetcher({Dio? dio}) : _dio = dio ?? Dio();

  /// [cancelToken], when given, aborts the in-flight request the moment it's
  /// cancelled — same token the caller uses for the rest of the download, so
  /// cancelling mid-thumbnail-fetch stops real network work immediately
  /// rather than just being ignored once the response eventually arrives.
  Future<String?> fetch(
    Uri url,
    String destinationPath, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.download(
        url.toString(),
        destinationPath,
        cancelToken: cancelToken,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return destinationPath;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
