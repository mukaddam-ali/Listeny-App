import 'package:dio/dio.dart';

import 'file_name_sanitizer.dart';
import 'google_drive_client.dart';
import 'google_drive_url.dart';
import 'media_download_service.dart' show DownloadCancelledException;
import 'media_signature.dart';
import 'media_url_resolver.dart';
import 'safe_http.dart';
import 'url_classifier.dart';

/// Resolves Google Drive file links through the OFFICIAL Drive API only:
/// file id from the URL → authorized metadata request → existence, download
/// permission and media checks → an official `alt=media` download request.
/// It never fetches or parses Drive web pages, follows confirmation-token
/// tricks, or works around owner download restrictions. Once it claims a
/// Drive URL, every failure is its own — nothing falls through to another
/// resolver.
class GoogleDriveUrlResolver implements MediaUrlResolver {
  final GoogleDriveClient _client;
  final DirectMediaLimits _limits;
  final UrlClassifier _classifier;

  GoogleDriveUrlResolver({
    required this._client,
    this._limits = const DirectMediaLimits(),
  }) : _classifier = const UrlClassifier();

  /// Pure: every URL the classifier assigns to Drive belongs here (even ones
  /// that turn out not to be a single file — those fail typed in resolve()).
  @override
  bool supports(Uri url) =>
      _classifier.classifyUri(url) == UrlClass.googleDrive;

  @override
  Future<ResolvedMedia> resolve(Uri url, {CancelToken? cancelToken}) async {
    try {
      return await _resolve(url, cancelToken);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const DownloadCancelledException();
      }
      throw const MediaResolutionException(
        MediaResolutionFailure.mediaUnavailable,
      );
    }
  }

  Future<ResolvedMedia> _resolve(Uri url, CancelToken? cancelToken) async {
    final ref = parseDriveFileRef(url);

    final DriveFileMetadata meta;
    try {
      meta = await _client.getFileMetadata(ref, cancelToken: cancelToken);
    } on DriveApiException catch (e) {
      throw MediaResolutionException(_failureFor(e.error));
    }

    if (meta.trashed) {
      throw const MediaResolutionException(
        MediaResolutionFailure.mediaUnavailable,
      );
    }
    // Folders, shortcuts and Google Docs/Sheets/Slides are not binary files
    // (export is out of scope).
    if (meta.mimeType.startsWith('application/vnd.google-apps.')) {
      throw const UnsupportedLinkException();
    }
    // Owner restrictions and the API's own capability flag decide download
    // rights. Being able to view a file is not enough. `capabilities` is only
    // reported to authorized callers, so for an anonymous client an absent
    // flag is left to the API to enforce at download time.
    final refused = meta.downloadRestricted || meta.canDownload == false;
    final cannotVerify = meta.canDownload == null && _client.isAuthenticated;
    if (refused || cannotVerify) {
      throw const MediaResolutionException(
        MediaResolutionFailure.downloadNotPermitted,
      );
    }

    final media = _mediaTypeOf(meta);
    if (media == null) {
      throw const MediaResolutionException(MediaResolutionFailure.noMediaFound);
    }
    final size = meta.size;
    if (size != null && size > _limits.maxBytes) {
      throw const MediaResolutionException(
        MediaResolutionFailure.responseTooLarge,
      );
    }

    final DriveDownloadRequest request;
    try {
      request = await _client.prepareDownload(ref, cancelToken: cancelToken);
    } on DriveApiException catch (e) {
      throw MediaResolutionException(_failureFor(e.error));
    }
    // The client's URL must itself be an allowed Drive destination.
    enforceGoogleDriveDestination(request.url);

    final baseName = sanitizeFileName(meta.name, fallback: 'drive_audio');
    final dot = baseName.lastIndexOf('.');
    final stem = dot > 0 ? baseName.substring(0, dot) : baseName;
    return ResolvedMedia(
      downloadUrl: request.url,
      suggestedFileName: '$stem.${media.extension}',
      kind: media.kind,
      origin: MediaSourceOrigin.googleDrive,
      originalUrl: url,
      // Transport provenance only — says nothing about rights to the file.
      accessBasis: MediaAccessBasis.authorizedProviderApi,
      mimeType: meta.mimeType,
      expectedBytes: size,
      title: sanitizeMetadataText(stem),
      downloadHeaders: request.headers,
      destinationPolicy: enforceGoogleDriveDestination,
    );
  }

  MediaResolutionFailure _failureFor(DriveApiError error) {
    switch (error) {
      case DriveApiError.unauthenticated:
        return MediaResolutionFailure.authenticationRequired;
      case DriveApiError.accessDenied:
        // Anonymous callers can't tell "private" from "needs sign-in".
        return _client.isAuthenticated
            ? MediaResolutionFailure.mediaUnavailable
            : MediaResolutionFailure.authenticationRequired;
      case DriveApiError.notFound:
      case DriveApiError.other:
        return MediaResolutionFailure.mediaUnavailable;
    }
  }

  /// Extension and kind for a media file, from its Drive MIME type or (for
  /// generic `application/octet-stream` uploads) its file-name extension.
  ({String extension, MediaSourceKind kind})? _mediaTypeOf(
    DriveFileMetadata meta,
  ) {
    final mime = normalizedMimeType(meta.mimeType);
    final nameExt = () {
      final dot = meta.name.lastIndexOf('.');
      return dot < 0 ? null : meta.name.substring(dot + 1).toLowerCase();
    }();
    final mimeExt = directMediaMimeTypeExtensions[mime];
    final ext =
        mimeExt ??
        (directMediaExtensionKinds.containsKey(nameExt) ? nameExt : null);
    if (ext != null) {
      return (extension: ext, kind: directMediaExtensionKinds[ext]!);
    }
    if (mime != null &&
        (mime.startsWith('audio/') || mime.startsWith('video/'))) {
      return (
        extension: 'bin',
        kind: mime.startsWith('video/')
            ? MediaSourceKind.video
            : MediaSourceKind.audio,
      );
    }
    return null;
  }
}
