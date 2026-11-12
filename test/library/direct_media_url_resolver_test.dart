import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/library/direct_media_url_resolver.dart';
import 'package:listeny/library/media_url_resolver.dart';

/// Swaps dio's real transport for a canned response, so the HEAD-sniffing
/// fallback can be tested without a network call.
class _FakeAdapter implements HttpClientAdapter {
  final Map<String, String> headers;
  _FakeAdapter(this.headers);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(
      const [],
      200,
      headers: headers.map((k, v) => MapEntry(k, [v])),
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Keeps extensionless-URL tests off real DNS.
Future<List<InternetAddress>> _publicHost(String host) async => [
  InternetAddress('93.184.216.34'),
];

void main() {
  group('DirectMediaUrlResolver — extension in the URL path', () {
    final resolver = DirectMediaUrlResolver();

    final audioExtensions = ['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg'];
    final videoExtensions = ['mp4', 'webm'];

    for (final ext in audioExtensions) {
      test('.$ext resolves as audio without a network call', () async {
        final resolved = await resolver.resolve(
          Uri.parse('https://example.com/track.$ext'),
        );
        expect(resolved.kind, MediaSourceKind.audio);
        expect(resolved.suggestedFileName, 'track.$ext');
        expect(
          resolved.downloadUrl,
          Uri.parse('https://example.com/track.$ext'),
        );
      });
    }

    for (final ext in videoExtensions) {
      test('.$ext resolves as video without a network call', () async {
        final resolved = await resolver.resolve(
          Uri.parse('https://example.com/clip.$ext'),
        );
        expect(resolved.kind, MediaSourceKind.video);
      });
    }

    test('extension matching is case-insensitive', () async {
      final resolved = await resolver.resolve(
        Uri.parse('https://example.com/track.MP3'),
      );
      expect(resolved.kind, MediaSourceKind.audio);
    });

    test(
      'query strings after the extension do not confuse resolution',
      () async {
        final resolved = await resolver.resolve(
          Uri.parse('https://cdn.example.com/a/b/song.flac?token=abc123'),
        );
        expect(resolved.kind, MediaSourceKind.audio);
        expect(resolved.suggestedFileName, 'song.flac');
      },
    );

    test('a bare filename with no extension in the last segment falls back to download.<ext>', () async {
      final adapter = _FakeAdapter({'content-type': 'audio/mpeg'});
      final resolver = DirectMediaUrlResolver(
        dio: Dio()..httpClientAdapter = adapter,
        hostResolver: _publicHost,
      );
      final resolved = await resolver.resolve(
        Uri.parse('https://cdn.example.com/blob/9f8a7'),
      );
      expect(resolved.suggestedFileName, 'download.mp3');
    });
  });

  group('DirectMediaUrlResolver — HEAD Content-Type fallback', () {
    Future<DirectMediaUrlResolver> resolverWithHeader(
      String? contentType,
    ) async {
      final headers = contentType == null
          ? <String, String>{}
          : {'content-type': contentType};
      return DirectMediaUrlResolver(
        dio: Dio()..httpClientAdapter = _FakeAdapter(headers),
        hostResolver: _publicHost,
      );
    }

    test('an opaque path resolves via a recognized Content-Type', () async {
      final resolver = await resolverWithHeader('audio/mpeg');
      final resolved = await resolver.resolve(
        Uri.parse('https://cdn.example.com/media/abc123'),
      );
      expect(resolved.kind, MediaSourceKind.audio);
    });

    test('a charset suffix on Content-Type does not break matching', () async {
      final resolver = await resolverWithHeader('audio/mpeg; charset=binary');
      final resolved = await resolver.resolve(
        Uri.parse('https://cdn.example.com/media/abc123'),
      );
      expect(resolved.kind, MediaSourceKind.audio);
    });

    test(
      'an unrecognized Content-Type throws UnsupportedLinkException',
      () async {
        final resolver = await resolverWithHeader('text/html');
        await expectLater(
          resolver.resolve(Uri.parse('https://example.com/page')),
          throwsA(isA<UnsupportedLinkException>()),
        );
      },
    );

    test('no Content-Type at all throws UnsupportedLinkException', () async {
      final resolver = await resolverWithHeader(null);
      await expectLater(
        resolver.resolve(Uri.parse('https://example.com/page')),
        throwsA(isA<UnsupportedLinkException>()),
      );
    });
  });

  test('an unrecognized extension with an unreachable HEAD request throws UnsupportedLinkException', () async {
    final resolver = DirectMediaUrlResolver(
      dio: Dio()..httpClientAdapter = _ThrowingAdapter(),
      hostResolver: _publicHost,
    );
    await expectLater(
      resolver.resolve(Uri.parse('https://example.com/page.html')),
      throwsA(isA<UnsupportedLinkException>()),
    );
  });
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}
