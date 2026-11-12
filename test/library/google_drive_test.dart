import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/library/direct_media_url_resolver.dart';
import 'package:listeny/library/google_drive_client.dart';
import 'package:listeny/library/google_drive_resolver.dart';
import 'package:listeny/library/google_drive_url.dart';
import 'package:listeny/library/media_download_service.dart';
import 'package:listeny/library/media_url_resolver.dart';
import 'package:listeny/library/safe_http.dart';
import 'package:listeny/library/url_classifier.dart';

import 'fake_drive_client.dart';

Matcher failsWith(MediaResolutionFailure f) => throwsA(
  isA<MediaResolutionException>().having((e) => e.failure, 'failure', f),
);

Uri drive(String s) => Uri.parse(s);

/// scheme://host/path without the query string.
String _bare(Uri u) => '${u.scheme}://${u.host}${u.path}';

void main() {
  group('Drive URL parsing (pure)', () {
    test('supported file link forms', () {
      const id = driveTestId;
      for (final u in [
        'https://drive.google.com/file/d/$id/view',
        'https://drive.google.com/file/d/$id/view?usp=sharing',
        'https://drive.google.com/file/d/$id/edit',
        'https://drive.google.com/file/d/$id',
        'https://drive.google.com/file/u/0/d/$id/view',
        'https://drive.google.com/open?id=$id',
        'https://drive.google.com/uc?id=$id',
        'https://drive.google.com/uc?export=download&id=$id',
        'https://drive.usercontent.google.com/download?id=$id&export=download',
        'http://drive.google.com/open?id=$id',
      ]) {
        expect(parseDriveFileRef(drive(u)).fileId, id, reason: u);
      }
    });

    test('resourcekey is carried, validated and optional', () {
      final ref = parseDriveFileRef(
        drive(
          'https://drive.google.com/file/d/$driveTestId/view?resourcekey=0-abc_DEF',
        ),
      );
      expect(ref.resourceKey, '0-abc_DEF');
      expect(
        () => parseDriveFileRef(
          drive(
            'https://drive.google.com/file/d/$driveTestId/view?resourcekey=a%20b',
          ),
        ),
        failsWith(MediaResolutionFailure.malformedUrl),
      );
    });

    test('malformed or ambiguous ids are malformedUrl', () {
      for (final u in [
        'https://drive.google.com/file/d/short/view',
        'https://drive.google.com/file/d/bad%20id%20with%20spaces%20here/view',
        'https://drive.google.com/file/d/bad.id.with.dots.here.xxx/view',
        'https://drive.google.com/open',
        'https://drive.google.com/open?id=',
        'https://drive.google.com/uc?export=download',
        'https://drive.google.com/open?id=$driveTestId&id=ZzYyXxWwVvUuTtSsRrQq',
        'https://drive.google.com/file/d/$driveTestId/view?id=ZzYyXxWwVvUuTtSsRrQq',
        'https://drive.usercontent.google.com/download?id=..%2F..%2Fetc',
      ]) {
        expect(
          () => parseDriveFileRef(drive(u)),
          failsWith(MediaResolutionFailure.malformedUrl),
          reason: u,
        );
      }
    });

    test('a path id equal to the query id is not ambiguous', () {
      expect(
        parseDriveFileRef(
          drive(
            'https://drive.google.com/file/d/$driveTestId/view?id=$driveTestId',
          ),
        ).fileId,
        driveTestId,
      );
    });

    test('folders, Docs, other paths and lookalike hosts are unsupported', () {
      for (final u in [
        'https://drive.google.com/drive/folders/$driveTestId',
        'https://drive.google.com/drive/u/0/my-drive',
        'https://drive.google.com/',
        'https://docs.google.com/document/d/$driveTestId/edit',
        'https://docs.google.com/spreadsheets/d/$driveTestId/edit',
        'https://evil.drive.google.com/file/d/$driveTestId/view',
        'https://www.drive.google.com/file/d/$driveTestId/view',
        'https://drive.google.com.evil.com/file/d/$driveTestId/view',
        'https://notdrive.google.com/file/d/$driveTestId/view',
        'https://www.google.com/file/d/$driveTestId/view',
        'ftp://drive.google.com/file/d/$driveTestId/view',
      ]) {
        expect(
          () => parseDriveFileRef(drive(u)),
          failsWith(MediaResolutionFailure.unsupportedLink),
          reason: u,
        );
      }
    });
  });

  group('routing and ownership', () {
    final client = FakeDriveClient(metadata: driveFile());
    final driveResolver = GoogleDriveUrlResolver(client: client);

    test(
      'supports() is classifier-consistent and never touches the client',
      () {
        for (final u in [
          'https://drive.google.com/file/d/$driveTestId/view',
          'https://drive.google.com/drive/folders/$driveTestId',
          'https://docs.google.com/document/d/$driveTestId/edit',
          'https://drive.usercontent.google.com/download?id=$driveTestId',
        ]) {
          expect(driveResolver.supports(drive(u)), isTrue, reason: u);
          expect(const UrlClassifier().classify(u), UrlClass.googleDrive);
        }
        for (final u in [
          'https://www.google.com/search?q=x',
          'https://example.com/a.mp3',
          'https://example.com/page',
          'https://notdrive.google.com.evil.com/x',
        ]) {
          expect(driveResolver.supports(drive(u)), isFalse, reason: u);
        }
        expect(client.metadataCalls, 0);
      },
    );

    test('Drive is selected before Direct; others unchanged', () {
      final direct = DirectMediaUrlResolver();
      final registry = MediaUrlResolverRegistry([driveResolver, direct]);
      expect(
        registry.select(
          drive('https://drive.google.com/file/d/$driveTestId/view'),
        ),
        same(driveResolver),
      );
      expect(registry.select(drive('https://example.com/a.mp3')), same(direct));
    });

    test('a Drive failure never falls through to Direct', () async {
      final direct = _Spy();
      final failing = GoogleDriveUrlResolver(
        client: FakeDriveClient(metadata: driveFile(canDownload: false)),
      );
      await expectLater(
        MediaUrlResolverRegistry([
          failing,
          direct,
        ]).resolve(drive('https://drive.google.com/file/d/$driveTestId/view')),
        failsWith(MediaResolutionFailure.downloadNotPermitted),
      );
      expect(direct.calls, 0);
    });
  });

  group('metadata -> ResolvedMedia', () {
    Future<ResolvedMedia> resolve(
      DriveFileMetadata meta, {
      GoogleDriveClient? client,
      DirectMediaLimits limits = const DirectMediaLimits(),
    }) => GoogleDriveUrlResolver(
      client: client ?? FakeDriveClient(metadata: meta),
      limits: limits,
    ).resolve(drive('https://drive.google.com/file/d/$driveTestId/view'));

    test('downloadable MP3 maps every field', () async {
      final r = await resolve(driveFile(name: 'My Song.mp3', size: 1234));
      expect(r.kind, MediaSourceKind.audio);
      expect(r.origin, MediaSourceOrigin.googleDrive);
      expect(
        r.originalUrl,
        drive('https://drive.google.com/file/d/$driveTestId/view'),
      );
      expect(r.suggestedFileName, 'My Song.mp3');
      expect(r.title, 'My Song');
      expect(r.mimeType, 'audio/mpeg');
      expect(r.expectedBytes, 1234);
      expect(r.accessBasis, MediaAccessBasis.authorizedProviderApi);
      expect(r.downloadUrl.host, 'www.googleapis.com');
      expect(r.downloadUrl.queryParameters['alt'], 'media');
      expect(r.downloadHeaders, {'Authorization': 'Bearer test-token'});
      expect(r.destinationPolicy, isNotNull);
    });

    test('downloadable MP4 is video', () async {
      final r = await resolve(
        driveFile(name: 'clip.mp4', mimeType: 'video/mp4'),
      );
      expect(r.kind, MediaSourceKind.video);
      expect(r.suggestedFileName, 'clip.mp4');
    });

    test('generic octet-stream uploads use the file-name extension', () async {
      final r = await resolve(
        driveFile(name: 'track.FLAC', mimeType: 'application/octet-stream'),
      );
      expect(r.kind, MediaSourceKind.audio);
      expect(r.suggestedFileName, 'track.flac');
    });

    test(
      'a misleading name extension is corrected from the MIME type',
      () async {
        final r = await resolve(
          driveFile(name: 'weird.txt', mimeType: 'audio/mpeg'),
        );
        expect(r.suggestedFileName, 'weird.mp3');
      },
    );

    test(
      'path-like and control characters in the name are sanitized',
      () async {
        final r = await resolve(
          driveFile(name: '../../evil${String.fromCharCode(7)}.mp3'),
        );
        expect(r.suggestedFileName, 'evil.mp3');
      },
    );

    test('unsupported / non-media files', () async {
      await expectLater(
        resolve(driveFile(name: 'doc.pdf', mimeType: 'application/pdf')),
        failsWith(MediaResolutionFailure.noMediaFound),
      );
      for (final mime in [
        'application/vnd.google-apps.folder',
        'application/vnd.google-apps.document',
        'application/vnd.google-apps.shortcut',
      ]) {
        await expectLater(
          resolve(driveFile(name: 'x', mimeType: mime, size: null)),
          throwsA(isA<UnsupportedLinkException>()),
          reason: mime,
        );
      }
    });

    test('trashed files are unavailable', () async {
      await expectLater(
        resolve(driveFile(trashed: true)),
        failsWith(MediaResolutionFailure.mediaUnavailable),
      );
    });

    test('a file larger than the limit is rejected before download', () async {
      final client = FakeDriveClient(metadata: driveFile(size: 5000));
      await expectLater(
        resolve(
          driveFile(size: 5000),
          client: client,
          limits: const DirectMediaLimits(maxBytes: 1000),
        ),
        failsWith(MediaResolutionFailure.responseTooLarge),
      );
      expect(client.downloadCalls, 0, reason: 'no download prepared');
    });

    test(
      'an unknown size is allowed (the stream limit still applies)',
      () async {
        final r = await resolve(driveFile(size: null));
        expect(r.expectedBytes, isNull);
      },
    );
  });

  group('permissions', () {
    Future<ResolvedMedia> resolveWith(FakeDriveClient c) =>
        GoogleDriveUrlResolver(client: c)
            .resolve(drive('https://drive.google.com/uc?id=$driveTestId'));

    test('canDownload true proceeds', () async {
      await resolveWith(
        FakeDriveClient(metadata: driveFile(canDownload: true)),
      );
    });

    test(
      'canDownload false is downloadNotPermitted, no download prepared',
      () async {
        final c = FakeDriveClient(metadata: driveFile(canDownload: false));
        await expectLater(
          resolveWith(c),
          failsWith(MediaResolutionFailure.downloadNotPermitted),
        );
        expect(c.downloadCalls, 0);
      },
    );

    test('owner download restrictions are honored', () async {
      await expectLater(
        resolveWith(FakeDriveClient(metadata: driveFile(restricted: true))),
        failsWith(MediaResolutionFailure.downloadNotPermitted),
      );
    });

    test(
      'an authorized caller with no capability info cannot be assumed allowed',
      () async {
        await expectLater(
          resolveWith(FakeDriveClient(metadata: driveFile(canDownload: null))),
          failsWith(MediaResolutionFailure.downloadNotPermitted),
        );
      },
    );

    test(
      'an anonymous caller (API key) leaves an absent flag to the API',
      () async {
        await resolveWith(
          FakeDriveClient(
            authenticated: false,
            metadata: driveFile(canDownload: null),
          ),
        );
      },
    );

    test('authentication required', () async {
      await expectLater(
        resolveWith(
          FakeDriveClient(
            metadataError: const DriveApiException(
              DriveApiError.unauthenticated,
            ),
          ),
        ),
        failsWith(MediaResolutionFailure.authenticationRequired),
      );
      await expectLater(
        GoogleDriveUrlResolver(client: const UnauthenticatedGoogleDriveClient())
            .resolve(drive('https://drive.google.com/uc?id=$driveTestId')),
        failsWith(MediaResolutionFailure.authenticationRequired),
      );
    });

    test('access denied: sign-in needed when anonymous, unavailable when signed in', () async {
      await expectLater(
        resolveWith(
          FakeDriveClient(
            authenticated: false,
            metadataError: const DriveApiException(DriveApiError.accessDenied),
          ),
        ),
        failsWith(MediaResolutionFailure.authenticationRequired),
      );
      await expectLater(
        resolveWith(
          FakeDriveClient(
            authenticated: true,
            metadataError: const DriveApiException(DriveApiError.accessDenied),
          ),
        ),
        failsWith(MediaResolutionFailure.mediaUnavailable),
      );
    });

    test('missing/deleted and other API failures are unavailable', () async {
      for (final e in [DriveApiError.notFound, DriveApiError.other]) {
        await expectLater(
          resolveWith(FakeDriveClient(metadataError: DriveApiException(e))),
          failsWith(MediaResolutionFailure.mediaUnavailable),
        );
      }
    });

    test('malformed Drive links fail before any API call', () async {
      final c = FakeDriveClient(metadata: driveFile());
      await expectLater(
        GoogleDriveUrlResolver(client: c)
            .resolve(drive('https://drive.google.com/file/d/x/view')),
        failsWith(MediaResolutionFailure.malformedUrl),
      );
      await expectLater(
        GoogleDriveUrlResolver(
          client: c,
        ).resolve(drive('https://drive.google.com/drive/folders/$driveTestId')),
        throwsA(isA<UnsupportedLinkException>()),
      );
      expect(c.metadataCalls, 0);
    });

    test('the resource key reaches the client', () async {
      final c = FakeDriveClient(metadata: driveFile());
      await GoogleDriveUrlResolver(client: c).resolve(
        drive(
          'https://drive.google.com/file/d/$driveTestId/view?resourcekey=0-key',
        ),
      );
      expect(c.lastRef?.resourceKey, '0-key');
    });
  });

  group('cancellation during resolution', () {
    test(
      'cancel during the metadata request maps to the cancelled path',
      () async {
        final c = FakeDriveClient(hangMetadata: true);
        final token = CancelToken();
        final f = GoogleDriveUrlResolver(client: c).resolve(
          drive('https://drive.google.com/file/d/$driveTestId/view'),
          cancelToken: token,
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        token.cancel();
        await expectLater(f, throwsA(isA<DownloadCancelledException>()));
        expect(c.downloadCalls, 0);
      },
    );
  });

  group('destination policy', () {
    bool allowed(String u) {
      try {
        enforceGoogleDriveDestination(Uri.parse(u));
        return true;
      } on MediaResolutionException {
        return false;
      }
    }

    test('only the official API / user-content destinations are allowed', () {
      for (final u in [
        'https://www.googleapis.com/drive/v3/files/x?alt=media',
        'https://drive.usercontent.google.com/download?id=x',
        'https://lh3.googleusercontent.com/abc',
        'https://doc-0k-0k-docs.googleusercontent.com/docs/securesc/x',
      ]) {
        expect(allowed(u), isTrue, reason: u);
      }
    });

    test('everything else is refused', () {
      for (final u in [
        'http://www.googleapis.com/drive/v3/files/x',
        'https://www.example.com/watch?v=1',
        'https://www.instagram.com/reel/abc/',
        'https://www.facebook.com/reel/1',
        'https://www.google.com/',
        'https://drive.google.com/uc?id=x',
        'https://accounts.google.com/signin',
        'https://evilgoogleusercontent.com/x',
        'https://googleusercontent.com/x',
        'https://googleapis.com/x',
        'https://storage.googleapis.com/bucket/x',
        'https://www.googleapis.com.evil.com/x',
        'https://www.googleapis.com:8443/x',
        'https://user:pw@www.googleapis.com/x',
        'https://example.com/a.mp3',
        'ftp://www.googleapis.com/x',
      ]) {
        expect(allowed(u), isFalse, reason: u);
      }
    });

    test('a client-supplied download URL outside the allow-list is refused at resolve', () async {
      final c = FakeDriveClient(
        metadata: driveFile(),
        request: DriveDownloadRequest(
          Uri.parse('https://evil.example.com/x.mp3'),
        ),
      );
      await expectLater(
        GoogleDriveUrlResolver(
          client: c,
        ).resolve(drive('https://drive.google.com/file/d/$driveTestId/view')),
        failsWith(MediaResolutionFailure.redirectRejected),
      );
    });

    test('the SSRF checks still apply on top of the policy', () async {
      final a = _RedirectAdapter({
        'https://www.googleapis.com/x': 'https://lh3.googleusercontent.com/y',
        'https://lh3.googleusercontent.com/y': 'http://192.168.1.5/z',
      });
      await expectLater(
        getWithSafeRedirects(
          Dio()..httpClientAdapter = a,
          Uri.parse('https://www.googleapis.com/x'),
          limits: const DirectMediaLimits(),
          resolveHost: (_) async => [InternetAddress('142.250.80.1')],
          destinationPolicy: enforceGoogleDriveDestination,
        ),
        failsWith(MediaResolutionFailure.redirectRejected),
      );
      expect(a.urls, isNot(contains('http://192.168.1.5/z')));
    });
  });

  group('ApiKeyGoogleDriveClient (official API over the safe path)', () {
    test('requests only the official API host and maps the JSON', () async {
      final a = _JsonAdapter({
        'https://www.googleapis.com/drive/v3/files/$driveTestId': (
          200,
          jsonEncode({
            'id': driveTestId,
            'name': 'x.mp3',
            'mimeType': 'audio/mpeg',
            'size': '1234',
            'capabilities': {'canDownload': true},
          }),
        ),
      });
      final client = ApiKeyGoogleDriveClient(
        apiKey: 'KEY',
        dio: Dio()..httpClientAdapter = a,
        hostResolver: (_) async => [InternetAddress('142.250.80.1')],
      );
      final meta = await client.getFileMetadata(
        const DriveFileRef(driveTestId, resourceKey: 'rk'),
      );
      expect(meta.size, 1234);
      expect(meta.canDownload, isTrue);
      final req = a.requests.single;
      expect(req.uri.host, 'www.googleapis.com');
      expect(req.uri.queryParameters['key'], 'KEY');
      expect(req.headers['X-Goog-Drive-Resource-Keys'], '$driveTestId/rk');
      final dl = await client.prepareDownload(const DriveFileRef(driveTestId));
      expect(dl.url.queryParameters['alt'], 'media');
    });

    test('HTTP errors map to typed API errors', () async {
      for (final e in {
        401: DriveApiError.unauthenticated,
        403: DriveApiError.accessDenied,
        404: DriveApiError.notFound,
        500: DriveApiError.other,
      }.entries) {
        final a = _JsonAdapter({
          'https://www.googleapis.com/drive/v3/files/$driveTestId': (
            e.key,
            '{}',
          ),
        });
        final client = ApiKeyGoogleDriveClient(
          apiKey: 'KEY',
          dio: Dio()..httpClientAdapter = a,
          hostResolver: (_) async => [InternetAddress('142.250.80.1')],
        );
        await expectLater(
          client.getFileMetadata(const DriveFileRef(driveTestId)),
          throwsA(
            isA<DriveApiException>().having((x) => x.error, 'error', e.value),
          ),
          reason: '${e.key}',
        );
      }
    });

    test(
      'a metadata redirect to another provider is refused before contact',
      () async {
        final a = _RedirectAdapter({
          'https://www.googleapis.com/drive/v3/files/$driveTestId':
              'https://www.instagram.com/reel/abc/',
        });
        final client = ApiKeyGoogleDriveClient(
          apiKey: 'KEY',
          dio: Dio()..httpClientAdapter = a,
          hostResolver: (_) async => [InternetAddress('142.250.80.1')],
        );
        await expectLater(
          client.getFileMetadata(const DriveFileRef(driveTestId)),
          failsWith(MediaResolutionFailure.redirectRejected),
        );
        expect(a.urls.where((u) => u.contains('instagram')), isEmpty);
      },
    );
  });
}

class _Spy implements MediaUrlResolver {
  int calls = 0;
  @override
  bool supports(Uri url) => true;
  @override
  Future<ResolvedMedia> resolve(Uri url, {CancelToken? cancelToken}) async {
    calls++;
    throw StateError('should not be reached');
  }
}

class _RedirectAdapter implements HttpClientAdapter {
  final Map<String, String> redirects;
  final urls = <String>[];
  _RedirectAdapter(this.redirects);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    urls.add(url);
    final target = redirects[url] ?? redirects[_bare(options.uri)];
    if (target == null) return ResponseBody.fromBytes(const [], 200);
    return ResponseBody.fromBytes(
      const [],
      302,
      headers: {
        'location': [target],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _JsonAdapter implements HttpClientAdapter {
  final Map<String, (int, String)> routes;
  final requests = <RequestOptions>[];
  _JsonAdapter(this.routes);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = _bare(options.uri);
    final r = routes[key];
    if (r == null) return ResponseBody.fromBytes(const [], 404);
    return ResponseBody.fromBytes(
      utf8.encode(r.$2),
      r.$1,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
