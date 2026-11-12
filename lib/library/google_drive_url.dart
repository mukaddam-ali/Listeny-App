import 'media_url_resolver.dart';

/// A Google Drive file a link points at.
class DriveFileRef {
  final String fileId;

  /// The link's `resourcekey`, needed by the API for older shared links.
  final String? resourceKey;
  const DriveFileRef(this.fileId, {this.resourceKey});
}

final _fileIdPattern = RegExp(r'^[A-Za-z0-9_-]{10,128}$');
final _resourceKeyPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

/// Extracts the Drive file id from an official file-link form, without any
/// network access. Only exact Drive hosts are accepted (no lookalikes, no
/// other subdomains).
///
/// Supported: `drive.google.com/file/d/<id>/...` (also `/file/u/<n>/d/<id>`),
/// `drive.google.com/open?id=<id>`, `drive.google.com/uc?id=<id>`,
/// `drive.usercontent.google.com/download?id=<id>`.
///
/// Throws [MediaResolutionException]:
/// - `unsupportedLink` for real Drive links that aren't a single downloadable
///   file (folders, Docs/Sheets/Slides, unknown paths);
/// - `malformedUrl` for a file link whose id is missing, invalid or
///   ambiguous.
DriveFileRef parseDriveFileRef(Uri url) {
  const unsupported = UnsupportedLinkException();
  const malformed = MediaResolutionException(
    MediaResolutionFailure.malformedUrl,
  );
  final scheme = url.scheme.toLowerCase();
  if (scheme != 'https' && scheme != 'http') throw unsupported;
  final host = url.host.toLowerCase();
  final segments = url.pathSegments.where((s) => s.isNotEmpty).toList();

  String? pathId;
  var isDriveFilePath = false;
  var isQueryForm = false;

  if (host == 'drive.google.com') {
    if (segments.length >= 3 && segments[0] == 'file' && segments[1] == 'd') {
      isDriveFilePath = true;
      pathId = segments[2];
    } else if (segments.length >= 5 &&
        segments[0] == 'file' &&
        segments[1] == 'u' &&
        segments[3] == 'd') {
      isDriveFilePath = true;
      pathId = segments[4];
    } else if (segments.length == 1 &&
        (segments[0] == 'open' || segments[0] == 'uc')) {
      isQueryForm = true;
    } else {
      throw unsupported; // folders, drive/..., etc.
    }
  } else if (host == 'drive.usercontent.google.com') {
    if (segments.length == 1 && segments[0] == 'download') {
      isQueryForm = true;
    } else {
      throw unsupported;
    }
  } else {
    // docs.google.com (Docs export is out of scope), lookalikes, and other
    // subdomains.
    throw unsupported;
  }

  final ids = url.queryParametersAll['id'] ?? const <String>[];
  if (ids.length > 1) throw malformed;
  final queryId = ids.isEmpty ? null : ids.single;

  final String? id;
  if (isDriveFilePath) {
    if (queryId != null && queryId != pathId) throw malformed; // ambiguous
    id = pathId;
  } else {
    assert(isQueryForm);
    id = queryId;
  }
  if (id == null || !_fileIdPattern.hasMatch(id)) throw malformed;

  final keys = url.queryParametersAll['resourcekey'] ?? const <String>[];
  if (keys.length > 1) throw malformed;
  final key = keys.isEmpty ? null : keys.single;
  if (key != null && !_resourceKeyPattern.hasMatch(key)) throw malformed;
  return DriveFileRef(id, resourceKey: key);
}
