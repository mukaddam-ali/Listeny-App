import 'package:dio/dio.dart';
import 'package:listeny/library/google_drive_client.dart';
import 'package:listeny/library/google_drive_url.dart';

/// A scripted Drive API: no network, no Google account.
class FakeDriveClient implements GoogleDriveClient {
  final bool authenticated;
  DriveFileMetadata? metadata;
  DriveApiException? metadataError;
  DriveDownloadRequest? request;

  /// When true, the metadata call never finishes on its own; it ends only
  /// when the cancel token fires (like a stalled request).
  bool hangMetadata;

  int metadataCalls = 0;
  int downloadCalls = 0;
  DriveFileRef? lastRef;

  FakeDriveClient({
    this.authenticated = true,
    this.metadata,
    this.metadataError,
    this.request,
    this.hangMetadata = false,
  });

  @override
  bool get isAuthenticated => authenticated;

  @override
  Future<DriveFileMetadata> getFileMetadata(
    DriveFileRef file, {
    CancelToken? cancelToken,
  }) async {
    metadataCalls++;
    lastRef = file;
    if (hangMetadata) {
      final token = cancelToken!;
      await token.whenCancel.then<void>((e) => throw e);
    }
    final error = metadataError;
    if (error != null) throw error;
    return metadata!;
  }

  @override
  Future<DriveDownloadRequest> prepareDownload(
    DriveFileRef file, {
    CancelToken? cancelToken,
  }) async {
    downloadCalls++;
    return request ??
        DriveDownloadRequest(
          Uri.parse(
            'https://www.googleapis.com/drive/v3/files/${file.fileId}?alt=media',
          ),
          headers: const {'Authorization': 'Bearer test-token'},
        );
  }
}

const driveTestId = 'AbCdEfGhIjKlMnOpQrStUv';

DriveFileMetadata driveFile({
  String name = 'Song.mp3',
  String mimeType = 'audio/mpeg',
  int? size = 2000,
  bool trashed = false,
  bool? canDownload = true,
  bool restricted = false,
}) => DriveFileMetadata(
  id: driveTestId,
  name: name,
  mimeType: mimeType,
  size: size,
  trashed: trashed,
  canDownload: canDownload,
  downloadRestricted: restricted,
);
