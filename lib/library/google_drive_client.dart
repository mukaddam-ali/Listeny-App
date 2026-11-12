import 'dart:convert';

import 'package:dio/dio.dart';

import 'google_drive_url.dart';
import 'media_url_resolver.dart';
import 'safe_http.dart';

/// What the Drive API says about a file (only what the resolver needs).
class DriveFileMetadata {
  final String id;
  final String name;
  final String mimeType;

  /// Bytes, when the API reports a size (binary files only).
  final int? size;
  final bool trashed;

  /// `capabilities.canDownload`. Null when the API did not report it (it is
  /// only returned to authorized callers).
  final bool? canDownload;

  /// Owner-set restrictions: `copyRequiresWriterPermission`, or
  /// `downloadRestrictions.itemDownloadRestriction.restrictedForReaders`.
  final bool downloadRestricted;

  const DriveFileMetadata({
    required this.id,
    required this.name,
    required this.mimeType,
    this.size,
    this.trashed = false,
    this.canDownload,
    this.downloadRestricted = false,
  });

  factory DriveFileMetadata.fromJson(Map<String, dynamic> json) {
    final capabilities = json['capabilities'];
    final restrictions = json['downloadRestrictions'];
    final itemRestriction = restrictions is Map
        ? restrictions['itemDownloadRestriction']
        : null;
    final size = json['size'];
    return DriveFileMetadata(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      mimeType: '${json['mimeType'] ?? ''}',
      size: size == null ? null : int.tryParse('$size'),
      trashed: json['trashed'] == true,
      canDownload: capabilities is Map && capabilities['canDownload'] is bool
          ? capabilities['canDownload'] as bool
          : null,
      downloadRestricted:
          json['copyRequiresWriterPermission'] == true ||
          (itemRestriction is Map &&
              itemRestriction['restrictedForReaders'] == true),
    );
  }
}

/// How to fetch a file's bytes: an official API URL plus the headers it
/// needs (e.g. an authorization header). The existing bounded download
/// service performs the transfer.
class DriveDownloadRequest {
  final Uri url;
  final Map<String, String> headers;
  const DriveDownloadRequest(this.url, {this.headers = const {}});
}

enum DriveApiError { unauthenticated, accessDenied, notFound, other }

class DriveApiException implements Exception {
  final DriveApiError error;
  const DriveApiException(this.error);
}

/// The authorization/transport boundary to the official Drive API. The
/// resolver contains no sign-in logic; whatever supplies credentials lives
/// behind this interface.
abstract class GoogleDriveClient {
  /// Whether requests carry a signed-in user's credentials (only then does
  /// the API report `capabilities`).
  bool get isAuthenticated;

  /// Throws [DriveApiException] for API failures and honors [cancelToken]
  /// (a cancelled request throws a cancel [DioException]).
  Future<DriveFileMetadata> getFileMetadata(
    DriveFileRef file, {
    CancelToken? cancelToken,
  });

  /// The official download request for [file] (Drive API `files.get` with
  /// `alt=media`).
  Future<DriveDownloadRequest> prepareDownload(
    DriveFileRef file, {
    CancelToken? cancelToken,
  });
}

/// Used until sign-in exists: every request reports that authorization is
/// required, so Drive links fail cleanly (and never fall through to another
/// resolver) instead of being scraped.
class UnauthenticatedGoogleDriveClient implements GoogleDriveClient {
  const UnauthenticatedGoogleDriveClient();

  @override
  bool get isAuthenticated => false;

  @override
  Future<DriveFileMetadata> getFileMetadata(
    DriveFileRef file, {
    CancelToken? cancelToken,
  }) async => throw const DriveApiException(DriveApiError.unauthenticated);

  @override
  Future<DriveDownloadRequest> prepareDownload(
    DriveFileRef file, {
    CancelToken? cancelToken,
  }) async => throw const DriveApiException(DriveApiError.unauthenticated);
}

const _driveApiHost = 'www.googleapis.com';

/// The only destinations a Drive download may touch: the Drive API host, the
/// Drive user-content host, and Google's user-content download CDN
/// (`*.googleusercontent.com`). HTTPS on the default port only, no
/// credentials. Anything else — including other Google properties and any
/// other provider — is refused before contact.
void enforceGoogleDriveDestination(Uri url) {
  const rejected = MediaResolutionException(
    MediaResolutionFailure.redirectRejected,
  );
  if (url.scheme.toLowerCase() != 'https') throw rejected;
  if (url.userInfo.isNotEmpty) throw rejected;
  if (url.hasPort && url.port != 443) throw rejected;
  final host = url.host.toLowerCase();
  final allowed =
      host == _driveApiHost ||
      host == 'drive.usercontent.google.com' ||
      (host.endsWith('.googleusercontent.com') &&
          host.length > '.googleusercontent.com'.length);
  if (!allowed) throw rejected;
}

/// Official Drive API v3 over the shared safe HTTP path, authorized with a
/// restricted API key. An API key can read only files shared publicly
/// ("anyone with the link"); it grants no access to private files.
class ApiKeyGoogleDriveClient implements GoogleDriveClient {
  final String _apiKey;
  final Dio _dio;
  final DirectMediaLimits _limits;
  final HostResolver? _resolveHost;

  ApiKeyGoogleDriveClient({
    required this._apiKey,
    Dio? dio,
    this._limits = const DirectMediaLimits(),
    HostResolver? hostResolver,
  }) : _dio = dio ?? Dio(),
       _resolveHost = hostResolver;

  @override
  bool get isAuthenticated => false;

  static const _fields =
      'id,name,mimeType,size,trashed,capabilities/canDownload,'
      'copyRequiresWriterPermission,downloadRestrictions';

  Map<String, String> _headers(DriveFileRef file) => {
    if (file.resourceKey != null)
      'X-Goog-Drive-Resource-Keys': '${file.fileId}/${file.resourceKey}',
  };

  @override
  Future<DriveFileMetadata> getFileMetadata(
    DriveFileRef file, {
    CancelToken? cancelToken,
  }) async {
    final url = Uri.https(_driveApiHost, '/drive/v3/files/${file.fileId}', {
      'fields': _fields,
      'supportsAllDrives': 'true',
      'key': _apiKey,
    });
    final SafeResponse safe;
    try {
      safe = await getWithSafeRedirects(
        _dio,
        url,
        limits: _limits,
        resolveHost: _resolveHost,
        cancelToken: cancelToken,
        destinationPolicy: enforceGoogleDriveDestination,
        headers: _headers(file),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      switch (e.response?.statusCode) {
        case 401:
          throw const DriveApiException(DriveApiError.unauthenticated);
        case 403:
          throw const DriveApiException(DriveApiError.accessDenied);
        case 404:
          throw const DriveApiException(DriveApiError.notFound);
        default:
          throw const DriveApiException(DriveApiError.other);
      }
    }
    final body = await readAtMost(
      safe.response.data!.stream,
      64 * 1024,
      cancelToken: cancelToken,
    );
    if (body.truncated) throw const DriveApiException(DriveApiError.other);
    try {
      final json = jsonDecode(utf8.decode(body.bytes, allowMalformed: true));
      if (json is! Map<String, dynamic>) {
        throw const DriveApiException(DriveApiError.other);
      }
      return DriveFileMetadata.fromJson(json);
    } on FormatException {
      throw const DriveApiException(DriveApiError.other);
    }
  }

  @override
  Future<DriveDownloadRequest> prepareDownload(
    DriveFileRef file, {
    CancelToken? cancelToken,
  }) async => DriveDownloadRequest(
    Uri.https(_driveApiHost, '/drive/v3/files/${file.fileId}', {
      'alt': 'media',
      'supportsAllDrives': 'true',
      'key': _apiKey,
    }),
    headers: _headers(file),
  );
}
