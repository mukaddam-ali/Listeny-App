import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/library/direct_media_url_resolver.dart';
import 'package:listeny/library/media_url_resolver.dart';

class _R implements MediaUrlResolver {
  final bool handles;
  final Object? failure;
  int resolveCalls = 0;
  int supportsCalls = 0;
  _R(this.handles, {this.failure});

  @override
  bool supports(Uri url) {
    supportsCalls++;
    return handles;
  }

  @override
  Future<ResolvedMedia> resolve(Uri url, {CancelToken? cancelToken}) async {
    resolveCalls++;
    if (failure != null) throw failure!;
    return ResolvedMedia(
      downloadUrl: url,
      suggestedFileName: 'a.mp3',
      kind: MediaSourceKind.audio,
      origin: MediaSourceOrigin.direct,
    );
  }
}

/// Fails the test if any HTTP request is made.
class _NoNetworkAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    throw StateError('network used');
  }

  @override
  void close({bool force = false}) {}
}

final _url = Uri.parse('https://example.com/a.mp3');

void main() {
  group('MediaUrlResolverRegistry', () {
    test(
      'supports() drives routing; non-supporting resolvers skipped',
      () async {
        final skipped = _R(false);
        final chosen = _R(true);
        final registry = MediaUrlResolverRegistry([skipped, chosen]);
        await registry.resolve(_url);
        expect(skipped.supportsCalls, 1);
        expect(skipped.resolveCalls, 0);
        expect(chosen.resolveCalls, 1);
      },
    );

    test('first supporting resolver wins (precedence)', () async {
      final first = _R(true);
      final second = _R(true);
      await MediaUrlResolverRegistry([first, second]).resolve(_url);
      expect(first.resolveCalls, 1);
      expect(second.resolveCalls, 0);
      expect(second.supportsCalls, 0);
    });

    test('selected resolver failure propagates; no fall-through', () async {
      final failing = _R(
        true,
        failure: const MediaResolutionException(
          MediaResolutionFailure.privateContent,
        ),
      );
      final next = _R(true);
      await expectLater(
        MediaUrlResolverRegistry([failing, next]).resolve(_url),
        throwsA(
          isA<MediaResolutionException>().having(
            (e) => e.failure,
            'failure',
            MediaResolutionFailure.privateContent,
          ),
        ),
      );
      expect(next.resolveCalls, 0);
    });

    test(
      'even UnsupportedLinkException from a claimed URL does not fall through',
      () async {
        final failing = _R(true, failure: const UnsupportedLinkException());
        final next = _R(true);
        await expectLater(
          MediaUrlResolverRegistry([failing, next]).resolve(_url),
          throwsA(isA<UnsupportedLinkException>()),
        );
        expect(next.resolveCalls, 0);
      },
    );

    test('no supporting resolver throws unsupportedLink', () async {
      await expectLater(
        MediaUrlResolverRegistry([_R(false)]).resolve(_url),
        throwsA(
          isA<UnsupportedLinkException>().having(
            (e) => e.failure,
            'failure',
            MediaResolutionFailure.unsupportedLink,
          ),
        ),
      );
      await expectLater(
        const MediaUrlResolverRegistry([]).resolve(_url),
        throwsA(isA<UnsupportedLinkException>()),
      );
    });

    test('direct is the catch-all', () {
      final direct = DirectMediaUrlResolver(dio: Dio());
      final registry = MediaUrlResolverRegistry([direct]);
      expect(registry.select(_url), same(direct));
      // Extensionless / opaque URLs still reach Direct (probed in resolve()).
      expect(
        registry.select(Uri.parse('https://cdn.example.com/stream/123')),
        same(direct),
      );
    });

    test('supports() of real resolvers makes no network calls', () {
      final adapter = _NoNetworkAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final direct = DirectMediaUrlResolver(dio: dio);
      for (final u in [
        'https://cdn.example.com/stream/123',
        'https://example.com/a.mp3',
      ]) {
        direct.supports(Uri.parse(u));
      }
      expect(adapter.requests, 0);
    });
  });

  group('ResolvedMedia', () {
    test('current construction stays valid with sensible defaults', () {
      final m = ResolvedMedia(
        downloadUrl: _url,
        suggestedFileName: 'a.mp3',
        kind: MediaSourceKind.audio,
        origin: MediaSourceOrigin.direct,
      );
      expect(m.originalUrl, isNull);
      expect(m.accessBasis, MediaAccessBasis.publicDirectLink);
      expect(m.mimeType, isNull);
      expect(m.expectedBytes, isNull);
      expect(m.title, isNull);
      expect(m.duration, isNull);
      expect(m.expiresAt, isNull);
    });

    test('optional fields round-trip', () {
      final m = ResolvedMedia(
        downloadUrl: _url,
        suggestedFileName: 'a.mp3',
        kind: MediaSourceKind.audio,
        origin: MediaSourceOrigin.googleDrive,
        originalUrl: _url,
        accessBasis: MediaAccessBasis.providerStream,
        mimeType: 'audio/mpeg',
        expectedBytes: 10,
        title: 't',
        artist: 'ar',
        album: 'al',
        duration: const Duration(seconds: 3),
      );
      expect(m.accessBasis, MediaAccessBasis.providerStream);
      expect(m.expectedBytes, 10);
      expect(m.duration, const Duration(seconds: 3));
    });
  });
}
