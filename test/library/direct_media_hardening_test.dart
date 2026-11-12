import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/library/audio_conversion_service.dart';
import 'package:listeny/library/direct_media_url_resolver.dart';
import 'package:listeny/library/file_name_sanitizer.dart';
import 'package:listeny/library/media_download_service.dart';
import 'package:listeny/library/media_probe.dart';
import 'package:listeny/library/media_signature.dart';
import 'package:listeny/library/media_url_resolver.dart';
import 'package:listeny/library/safe_http.dart';

/// Genuine tiny media files (0.4s sine, generated with FFmpeg) live in
/// test/fixtures/audio; negatives are built from them or from raw bytes.
List<int> fx(String name) =>
    File('test/fixtures/audio/$name').readAsBytesSync();

class _Res {
  final int status;
  final Map<String, String> headers;
  final List<int> body;
  final Stream<Uint8List>? stream;

  /// When true the request never completes until it is cancelled.
  final bool hang;
  _Res(
    this.status, {
    this.headers = const {},
    this.body = const [],
    this.stream,
    this.hang = false,
  });
}

/// Serves canned responses keyed by "METHOD url" and records every request,
/// so no test touches a real network.
class _Adapter implements HttpClientAdapter {
  final Map<String, _Res> routes;
  final requests = <RequestOptions>[];
  int cancelledRequests = 0;
  _Adapter(this.routes);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = '${options.method} ${options.uri}';
    final r = routes[key];
    if (r == null) throw StateError('unexpected request: $key');
    if (r.hang) {
      await cancelFuture;
      cancelledRequests++;
      throw DioException.requestCancelled(
        requestOptions: options,
        reason: 'cancelled',
      );
    }
    return ResponseBody(
      r.stream ?? Stream.value(Uint8List.fromList(r.body)),
      r.status,
      headers: r.headers.map((k, v) => MapEntry(k, [v])),
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<List<InternetAddress>> _publicHost(String host) async => [
  InternetAddress('93.184.216.34'),
];

List<int> _html() =>
    '<!DOCTYPE html><html><body>Not found</body></html>'.codeUnits;

/// ID3v2 header declaring an empty tag, and nothing else.
List<int> _id3Only() => [0x49, 0x44, 0x33, 4, 0, 0, 0, 0, 0, 0];

/// ID3v2 header (empty tag) followed by non-audio bytes.
List<int> _id3Garbage() => [..._id3Only(), ...List.filled(900, 0x41)];

/// Just the ftyp box of a real MP4 — no moov/mdat, so no media.
List<int> _ftypOnly() {
  final b = fx('video_with_audio.mp4');
  final size = (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
  return b.sublist(0, size);
}

/// A real MP4 cut off before its index (moov) — structurally corrupt.
List<int> _truncatedMp4() => fx('video_with_audio.mp4').sublist(0, 2500);

const _limits = DirectMediaLimits(maxBytes: 20000, maxRedirects: 3);
final _mp3Url = Uri.parse('https://cdn.example.com/song.mp3');

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('direct_hardening_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  MediaDownloadService svc(_Adapter a, {FreeSpaceProbe? free}) =>
      MediaDownloadService(
        dio: Dio()..httpClientAdapter = a,
        limits: _limits,
        hostResolver: _publicHost,
        freeSpaceProbe: free,
      );

  String dest() => '${tmp.path}/out.bin';

  Future<Object?> failure(Future<void> f) async {
    try {
      await f;
    } catch (e) {
      return e;
    }
    return null;
  }

  Future<void> run(_Adapter a, Uri url, {CancelToken? token}) => svc(a)
      .download(
        url: url,
        destinationPath: dest(),
        cancelToken: token ?? CancelToken(),
      );

  group('early signature check (fast rejection only)', () {
    MediaEvidence? sniff(List<int> b, {String? mime, bool complete = true}) =>
        classifyMediaResponse(head: b, mimeType: mime, complete: complete);

    test('recognizes every genuine fixture', () {
      for (final e in {
        'tone.mp3': 'mp3',
        'tone.aac': 'aac',
        'tone.m4a': 'm4a',
        'tone.wav': 'wav',
        'tone.flac': 'flac',
        'tone.ogg': 'ogg',
        'video_with_audio.mp4': 'mp4',
      }.entries) {
        final head = fx(e.key);
        final cut = head.length > 512 ? head.sublist(0, 512) : head;
        expect(
          sniff(cut, complete: head.length <= 512)?.extension,
          e.value,
          reason: e.key,
        );
      }
    });

    test('rejects HTML, empty, garbage, ID3-only and ftyp-only bodies', () {
      expect(sniff(_html()), isNull);
      expect(sniff(_html(), mime: 'audio/mpeg'), isNull);
      expect(sniff([]), isNull);
      expect(sniff(List.filled(900, 7), mime: 'audio/mpeg'), isNull);
      expect(sniff(_id3Only()), isNull);
      expect(sniff(_id3Garbage().sublist(0, 512), complete: false), isNull);
      expect(sniff(_ftypOnly()), isNull);
    });

    test('a MIME type alone is never evidence', () {
      expect(sniff([9, 9, 9, 9], mime: 'audio/mpeg'), isNull);
      expect(sniff(fx('tone.mp3'), mime: 'text/html'), isNull);
    });

    test(
      'an ID3 tag larger than the bytes seen defers to the decode check',
      () {
        // Tag body of 0x3FFF bytes, only the header available so far.
        final head = [0x49, 0x44, 0x33, 4, 0, 0, 0, 0, 0x7F, 0x7F];
        expect(sniff(head, complete: false)?.extension, 'mp3');
        expect(sniff(head, complete: true), isNull);
      },
    );
  });

  group('download: genuine media', () {
    Future<void> accepts(
      String file, {
      Map<String, String> h = const {},
    }) async {
      final bytes = fx(file);
      final a = _Adapter({
        'GET $_mp3Url': _Res(
          200,
          headers: {'content-length': '${bytes.length}', ...h},
          body: bytes,
        ),
      });
      await run(a, _mp3Url);
      expect(File(dest()).lengthSync(), bytes.length, reason: file);
    }

    test('every fixture format downloads intact', () async {
      for (final f in [
        'tone.mp3',
        'tone.aac',
        'tone.m4a',
        'tone.wav',
        'tone.flac',
        'tone.ogg',
        'video_with_audio.mp4',
      ]) {
        await accepts(f);
      }
    });

    test('progress is reported with the declared total', () async {
      final bytes = fx('tone.mp3');
      final a = _Adapter({
        'GET $_mp3Url': _Res(
          200,
          headers: {'content-length': '${bytes.length}'},
          body: bytes,
        ),
      });
      int? total;
      await svc(a).download(
        url: _mp3Url,
        destinationPath: dest(),
        cancelToken: CancelToken(),
        onProgress: (r, t) => total = t,
      );
      expect(total, bytes.length);
    });

    test('uppercase extension and query string', () async {
      final u = Uri.parse('https://cdn.example.com/SONG.MP3?token=1');
      final a = _Adapter({
        'GET $u': _Res(
          200,
          headers: {'content-type': 'audio/mpeg'},
          body: fx('tone.mp3'),
        ),
      });
      await run(a, u);
      expect(File(dest()).existsSync(), isTrue);
    });

    test('missing / octet-stream Content-Type with real bytes', () async {
      await accepts('tone.mp3');
      await accepts(
        'tone.mp3',
        h: {'content-type': 'application/octet-stream'},
      );
    });

    test('genuine MP4 served under a wrong extension', () async {
      final u = Uri.parse('https://cdn.example.com/video.mp3');
      final a = _Adapter({
        'GET $u': _Res(
          200,
          headers: {'content-type': 'video/mp4'},
          body: fx('video_with_audio.mp4'),
        ),
      });
      await run(a, u);
      expect(File(dest()).existsSync(), isTrue);
    });
  });

  group('download: bad responses', () {
    Future<void> expectRejected(_Res res, MediaResolutionFailure f) async {
      final e = await failure(run(_Adapter({'GET $_mp3Url': res}), _mp3Url));
      expect(e, isA<DownloadFailedException>());
      expect((e as DownloadFailedException).failure, f);
      expect(
        File(dest()).existsSync(),
        isFalse,
        reason: 'partial file cleaned',
      );
    }

    const invalid = MediaResolutionFailure.invalidMediaResponse;

    test('.mp3 URL returning HTML', () async {
      await expectRejected(
        _Res(200, headers: {'content-type': 'text/html'}, body: _html()),
        invalid,
      );
    });

    test('HTML error page with 200 and an audio Content-Type', () async {
      await expectRejected(
        _Res(200, headers: {'content-type': 'audio/mpeg'}, body: _html()),
        invalid,
      );
    });

    test('known audio MIME with arbitrary garbage', () async {
      await expectRejected(
        _Res(
          200,
          headers: {'content-type': 'audio/mpeg'},
          body: List.filled(900, 7),
        ),
        invalid,
      );
    });

    test('ID3-only MP3-like file with no MPEG audio', () async {
      await expectRejected(
        _Res(200, headers: {'content-type': 'audio/mpeg'}, body: _id3Only()),
        invalid,
      );
      await expectRejected(
        _Res(200, headers: {'content-type': 'audio/mpeg'}, body: _id3Garbage()),
        invalid,
      );
    });

    test('ftyp-only MP4-like file', () async {
      await expectRejected(
        _Res(200, headers: {'content-type': 'video/mp4'}, body: _ftypOnly()),
        invalid,
      );
    });

    test('unsupported content type', () async {
      await expectRejected(
        _Res(
          200,
          headers: {'content-type': 'application/pdf'},
          body: List.filled(900, 7),
        ),
        invalid,
      );
    });

    test('truncated response (fewer bytes than Content-Length)', () async {
      final b = fx('tone.mp3');
      await expectRejected(
        _Res(200, headers: {'content-length': '${b.length + 500}'}, body: b),
        MediaResolutionFailure.incompleteDownload,
      );
    });

    test('body longer than Content-Length', () async {
      final b = fx('tone.mp3');
      await expectRejected(
        _Res(200, headers: {'content-length': '${b.length - 10}'}, body: b),
        MediaResolutionFailure.incompleteDownload,
      );
    });

    test('oversized Content-Length is rejected before any body', () async {
      await expectRejected(
        _Res(200, headers: {'content-length': '999999'}, body: fx('tone.mp3')),
        MediaResolutionFailure.responseTooLarge,
      );
    });

    test('stream exceeding the limit without Content-Length', () async {
      final chunk = Uint8List.fromList([
        ...fx('tone.mp3'),
        ...List.filled(8000, 0),
      ]);
      await expectRejected(
        _Res(
          200,
          stream: Stream<Uint8List>.periodic(Duration.zero, (_) => chunk),
        ),
        MediaResolutionFailure.responseTooLarge,
      );
    });

    test('HTTP 404 keeps the friendly message', () async {
      final e = await failure(
        run(_Adapter({'GET $_mp3Url': _Res(404)}), _mp3Url),
      );
      expect((e as DownloadFailedException).message, contains('404'));
    });

    test('insufficient free space is reported before writing', () async {
      final b = fx('tone.mp3');
      final a = _Adapter({
        'GET $_mp3Url': _Res(
          200,
          headers: {'content-length': '${b.length}'},
          body: b,
        ),
      });
      final e = await failure(
        svc(a, free: (_) async => 100).download(
          url: _mp3Url,
          destinationPath: dest(),
          cancelToken: CancelToken(),
        ),
      );
      expect((e as DownloadFailedException).message, contains('storage'));
      expect(File(dest()).existsSync(), isFalse);
    });
  });

  group('download: cancellation', () {
    test(
      'cancelling mid-stream throws cancelled and removes the file',
      () async {
        final ctrl = StreamController<Uint8List>();
        final a = _Adapter({'GET $_mp3Url': _Res(200, stream: ctrl.stream)});
        final token = CancelToken();
        final f = failure(run(a, _mp3Url, token: token));
        ctrl.add(Uint8List.fromList(fx('tone.mp3')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        token.cancel();
        expect(await f, isA<DownloadCancelledException>());
        expect(File(dest()).existsSync(), isFalse);
        unawaited(ctrl.close());
      },
    );
  });

  group('redirects', () {
    _Res redirect(String to) => _Res(302, headers: {'location': to});
    final ok = _Res(200, body: fx('tone.mp3'));

    test('valid redirect is followed and revalidated', () async {
      final a = _Adapter({
        'GET $_mp3Url': redirect('https://files.example.org/real.mp3'),
        'GET https://files.example.org/real.mp3': ok,
      });
      await run(a, _mp3Url);
      expect(a.requests.length, 2);
      expect(File(dest()).lengthSync(), fx('tone.mp3').length);
    });

    test('relative redirect', () async {
      final a = _Adapter({
        'GET $_mp3Url': redirect('/other/real.mp3'),
        'GET https://cdn.example.com/other/real.mp3': ok,
      });
      await run(a, _mp3Url);
      expect(File(dest()).existsSync(), isTrue);
    });

    test('too many redirects', () async {
      final routes = <String, _Res>{
        for (var i = 0; i < 10; i++)
          'GET https://cdn.example.com/r$i': redirect(
            'https://cdn.example.com/r${i + 1}',
          ),
      };
      final e = await failure(
        run(_Adapter(routes), Uri.parse('https://cdn.example.com/r0')),
      );
      expect(
        (e as DownloadFailedException).failure,
        MediaResolutionFailure.redirectRejected,
      );
    });

    test('redirect loop', () async {
      final a = _Adapter({
        'GET https://cdn.example.com/a': redirect('https://cdn.example.com/b'),
        'GET https://cdn.example.com/b': redirect('https://cdn.example.com/a'),
      });
      final e = await failure(run(a, Uri.parse('https://cdn.example.com/a')));
      expect(
        (e as DownloadFailedException).failure,
        MediaResolutionFailure.redirectRejected,
      );
      expect(a.requests.length, 2);
    });

    for (final target in [
      'http://127.0.0.1/x.mp3',
      'http://192.168.1.10/x.mp3',
      'http://10.0.0.5/x.mp3',
      'http://169.254.169.254/latest',
      'http://198.18.0.1/x.mp3',
      'http://[::1]/x.mp3',
      'http://[2001:db8::1]/x.mp3',
      'http://localhost/x.mp3',
      'ftp://cdn.example.com/x.mp3',
      'https://user:pw@cdn.example.com/x.mp3',
    ]) {
      test('redirect to $target is rejected', () async {
        final a = _Adapter({'GET $_mp3Url': redirect(target)});
        final e = await failure(run(a, _mp3Url));
        expect(
          (e as DownloadFailedException).failure,
          MediaResolutionFailure.redirectRejected,
        );
        expect(a.requests.length, 1, reason: 'target never contacted');
      });
    }

    test('hostname resolving to a special-use address is rejected', () async {
      for (final ip in [
        '10.1.2.3',
        '198.18.5.5',
        '192.0.2.7',
        '::1',
        '2001:db8::5',
      ]) {
        final a = _Adapter({
          'GET $_mp3Url': redirect('https://internal.example.com/x.mp3'),
        });
        final s = MediaDownloadService(
          dio: Dio()..httpClientAdapter = a,
          hostResolver: (h) async => [
            InternetAddress(h == 'internal.example.com' ? ip : '93.184.216.34'),
          ],
        );
        final e = await failure(
          s.download(
            url: _mp3Url,
            destinationPath: dest(),
            cancelToken: CancelToken(),
          ),
        );
        expect(
          (e as DownloadFailedException).failure,
          MediaResolutionFailure.redirectRejected,
          reason: ip,
        );
      }
    });

    test(
      'sensitive headers are dropped on cross-origin redirects only',
      () async {
        final a = _Adapter({
          'GET https://cdn.example.com/a': redirect(
            'https://cdn.example.com/b',
          ),
          'GET https://cdn.example.com/b': redirect(
            'https://other.example.org/c',
          ),
          'GET https://other.example.org/c': ok,
        });
        await getWithSafeRedirects(
          Dio()..httpClientAdapter = a,
          Uri.parse('https://cdn.example.com/a'),
          limits: _limits,
          resolveHost: _publicHost,
          headers: {'Authorization': 'secret', 'Cookie': 'c=1', 'X-Keep': '1'},
        );
        String? h(int i, String n) => a.requests[i].headers[n]?.toString();
        expect(h(0, 'Authorization'), 'secret');
        expect(h(1, 'Authorization'), 'secret', reason: 'same origin keeps it');
        expect(h(2, 'Authorization'), isNull);
        expect(h(2, 'Cookie'), isNull);
        expect(h(2, 'X-Keep'), '1');
      },
    );

    test('a private initial URL is rejected without a request', () async {
      final a = _Adapter({});
      final e = await failure(run(a, Uri.parse('http://192.168.0.2/x.mp3')));
      expect(e, isA<DownloadFailedException>());
      expect(a.requests, isEmpty);
    });
  });

  group('download: destination policy', () {
    void blockProviders(Uri u) {
      if (u.host.endsWith('blocked.example.com') || u.host.endsWith('instagram.com')) {
        throw const MediaResolutionException(
          MediaResolutionFailure.downloadNotPermitted,
        );
      }
    }

    Future<Object?> runWithPolicy(_Adapter a, Uri url, {CancelToken? token}) =>
        failure(
          svc(a).download(
            url: url,
            destinationPath: dest(),
            cancelToken: token ?? CancelToken(),
            destinationPolicy: blockProviders,
          ),
        );

    test(
      'a redirect into a blocked destination is rejected before contact',
      () async {
        final a = _Adapter({
          'GET $_mp3Url': _Res(
            302,
            headers: {
              'location': 'https://www.blocked.example.com/page',
            },
          ),
        });
        final e = await runWithPolicy(a, _mp3Url);
        expect(
          (e as DownloadFailedException).failure,
          MediaResolutionFailure.downloadNotPermitted,
        );
        expect(a.requests.length, 1);
        expect(File(dest()).existsSync(), isFalse);
      },
    );

    test('the initial URL is checked too', () async {
      final a = _Adapter({});
      final e = await runWithPolicy(
        a,
        Uri.parse('https://www.instagram.com/reel/abc/'),
      );
      expect(e, isA<DownloadFailedException>());
      expect(a.requests, isEmpty);
    });

    test('an allowed redirect still downloads under the policy', () async {
      final a = _Adapter({
        'GET $_mp3Url': _Res(
          302,
          headers: {'location': 'https://files.example.org/x.mp3'},
        ),
        'GET https://files.example.org/x.mp3': _Res(200, body: fx('tone.mp3')),
      });
      expect(await runWithPolicy(a, _mp3Url), isNull);
      expect(File(dest()).lengthSync(), fx('tone.mp3').length);
    });

    test('cancellation still works with a policy', () async {
      final ctrl = StreamController<Uint8List>();
      final a = _Adapter({'GET $_mp3Url': _Res(200, stream: ctrl.stream)});
      final token = CancelToken();
      final f = runWithPolicy(a, _mp3Url, token: token);
      ctrl.add(Uint8List.fromList(fx('tone.mp3')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      token.cancel();
      expect(await f, isA<DownloadCancelledException>());
      expect(File(dest()).existsSync(), isFalse);
      unawaited(ctrl.close());
    });

    test(
      'without a policy (user-pasted direct links) nothing changes',
      () async {
        final a = _Adapter({
          'GET $_mp3Url': _Res(
            302,
            headers: {'location': 'https://files.example.org/x.mp3'},
          ),
          'GET https://files.example.org/x.mp3': _Res(
            200,
            body: fx('tone.mp3'),
          ),
        });
        await run(a, _mp3Url);
        expect(File(dest()).existsSync(), isTrue);
      },
    );
  });

  group('address policy (globally routable only)', () {
    bool routable(String ip) => isGloballyRoutable(InternetAddress(ip));

    test('special-use IPv4 ranges are rejected', () {
      for (final ip in [
        '0.0.0.0',
        '0.1.2.3',
        '10.0.0.1',
        '10.255.255.255',
        '100.64.0.1',
        '100.127.255.255',
        '127.0.0.1',
        '127.255.255.254',
        '169.254.0.1',
        '169.254.169.254',
        '172.16.0.1',
        '172.31.255.255',
        '192.0.0.1',
        '192.0.0.170',
        '192.0.2.1',
        '192.88.99.1',
        '192.168.0.1',
        '198.18.0.0',
        '198.18.0.1',
        '198.19.255.255',
        '198.51.100.1',
        '203.0.113.1',
        '224.0.0.1',
        '239.255.255.255',
        '240.0.0.1',
        '255.255.255.255',
      ]) {
        expect(routable(ip), isFalse, reason: ip);
      }
    });

    test('ordinary public IPv4 addresses are accepted', () {
      for (final ip in [
        '8.8.8.8',
        '1.1.1.1',
        '93.184.216.34',
        '100.63.255.255',
        '100.128.0.1',
        '172.15.255.255',
        '172.32.0.1',
        '192.169.0.1',
        '198.17.255.255',
        '198.20.0.1',
        '169.253.1.1',
        '223.255.255.255',
      ]) {
        expect(routable(ip), isTrue, reason: ip);
      }
    });

    test('special-use IPv6 ranges are rejected', () {
      for (final ip in [
        '::',
        '::1',
        'fe80::1',
        'fc00::1',
        'fd12:3456::1',
        'ff02::1',
        'fec0::1',
        '2001::1',
        '2001:1::1',
        '2001:db8::1',
        '2002::1',
        '3fff::1',
        '64:ff9b::808:808',
        '100::1',
        '::ffff:127.0.0.1',
        '::ffff:192.168.0.1',
        '::ffff:198.18.0.1',
      ]) {
        expect(routable(ip), isFalse, reason: ip);
      }
    });

    test('global unicast IPv6 (and mapped public IPv4) is accepted', () {
      for (final ip in [
        '2606:4700:4700::1111',
        '2a00:1450:4001::1',
        '2001:4860:4860::8888',
        '2001:200::1',
        '::ffff:8.8.8.8',
      ]) {
        expect(routable(ip), isTrue, reason: ip);
      }
    });
  });

  group('MediaProbe', () {
    MediaProbe probe(_Adapter a) => MediaProbe(
      dio: Dio()..httpClientAdapter = a,
      limits: _limits,
      resolveHost: _publicHost,
    );
    final u = Uri.parse('https://cdn.example.com/stream/1');

    test('identifies media from bytes and sends a Range request', () async {
      final b = fx('tone.mp3');
      final a = _Adapter({
        'GET $u': _Res(
          200,
          headers: {
            'content-type': 'application/octet-stream',
            'content-length': '${b.length}',
          },
          body: b,
        ),
      });
      final r = await probe(a).probe(u);
      expect(r.evidence.extension, 'mp3');
      expect(r.contentLength, b.length);
      expect(a.requests.single.headers['Range'], startsWith('bytes=0-'));
    });

    test(
      'HTML, garbage with an audio MIME, and ID3-only are rejected',
      () async {
        for (final res in [
          _Res(200, headers: {'content-type': 'text/html'}, body: _html()),
          _Res(
            200,
            headers: {'content-type': 'audio/mpeg'},
            body: List.filled(900, 7),
          ),
          _Res(200, headers: {'content-type': 'audio/mpeg'}, body: _id3Only()),
        ]) {
          await expectLater(
            probe(_Adapter({'GET $u': res})).probe(u),
            throwsA(
              isA<MediaResolutionException>().having(
                (e) => e.failure,
                'f',
                MediaResolutionFailure.invalidMediaResponse,
              ),
            ),
          );
        }
      },
    );

    test('total size from Content-Range over the limit is rejected', () async {
      final a = _Adapter({
        'GET $u': _Res(
          206,
          headers: {'content-range': 'bytes 0-99/999999'},
          body: fx('tone.mp3'),
        ),
      });
      await expectLater(
        probe(a).probe(u),
        throwsA(
          isA<MediaResolutionException>().having(
            (e) => e.failure,
            'f',
            MediaResolutionFailure.responseTooLarge,
          ),
        ),
      );
    });
  });

  group('DirectMediaUrlResolver extensionless probing', () {
    final u = Uri.parse('https://cdn.example.com/stream/1');
    DirectMediaUrlResolver resolver(_Adapter a) => DirectMediaUrlResolver(
      dio: Dio()..httpClientAdapter = a,
      limits: _limits,
      hostResolver: _publicHost,
    );

    test('generic HEAD then real bytes resolves via the probe', () async {
      final a = _Adapter({
        'HEAD $u': _Res(
          200,
          headers: {'content-type': 'application/octet-stream'},
        ),
        'GET $u': _Res(200, body: fx('tone.mp3')),
      });
      final r = await resolver(a).resolve(u);
      expect(r.kind, MediaSourceKind.audio);
      expect(r.suggestedFileName, 'download.mp3');
      expect(r.originalUrl, u);
    });

    test('HEAD redirect is left to the safe probe', () async {
      final a = _Adapter({
        'HEAD $u': _Res(
          302,
          headers: {'location': 'https://files.example.org/x'},
        ),
        'GET $u': _Res(
          302,
          headers: {'location': 'https://files.example.org/x'},
        ),
        'GET https://files.example.org/x': _Res(
          200,
          body: fx('video_with_audio.mp4'),
        ),
      });
      final r = await resolver(a).resolve(u);
      expect(r.kind, MediaSourceKind.video);
      expect(r.suggestedFileName, 'download.mp4');
    });

    test('a misleading extension is corrected from the bytes', () async {
      final page = Uri.parse('https://cdn.example.com/page.html');
      final a = _Adapter({
        'HEAD $page': _Res(200),
        'GET $page': _Res(200, body: fx('tone.mp3')),
      });
      expect((await resolver(a).resolve(page)).suggestedFileName, 'page.mp3');
    });

    test('a redirect to a private host is a typed failure', () async {
      final a = _Adapter({
        'HEAD $u': _Res(200),
        'GET $u': _Res(302, headers: {'location': 'http://192.168.1.1/x'}),
      });
      await expectLater(
        resolver(a).resolve(u),
        throwsA(
          isA<MediaResolutionException>().having(
            (e) => e.failure,
            'f',
            MediaResolutionFailure.redirectRejected,
          ),
        ),
      );
    });

    test(
      'HTML, garbage or ID3-only at an extensionless URL stays unsupported',
      () async {
        for (final body in [_html(), List.filled(900, 7), _id3Only()]) {
          final a = _Adapter({
            'HEAD $u': _Res(200),
            'GET $u': _Res(
              200,
              headers: {'content-type': 'audio/mpeg'},
              body: body,
            ),
          });
          await expectLater(
            resolver(a).resolve(u),
            throwsA(isA<UnsupportedLinkException>()),
          );
        }
      },
    );

    test('supports() is pure: no requests', () {
      final a = _Adapter({});
      resolver(a).supports(u);
      expect(a.requests, isEmpty);
    });
  });

  group('resolution cancellation', () {
    final u = Uri.parse('https://cdn.example.com/stream/1');
    DirectMediaUrlResolver resolver(_Adapter a) => DirectMediaUrlResolver(
      dio: Dio()..httpClientAdapter = a,
      limits: _limits,
      hostResolver: _publicHost,
    );

    Future<void> cancelSoon(CancelToken t) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      t.cancel();
    }

    test(
      'cancel during HEAD aborts the request and maps to cancelled',
      () async {
        final a = _Adapter({'HEAD $u': _Res(200, hang: true)});
        final token = CancelToken();
        unawaited(cancelSoon(token));
        await expectLater(
          resolver(a).resolve(u, cancelToken: token),
          throwsA(isA<DownloadCancelledException>()),
        );
        expect(a.cancelledRequests, 1, reason: 'the HTTP request was aborted');
        expect(a.requests.length, 1, reason: 'no probe after cancel');
      },
    );

    test('cancel during the probe request aborts it', () async {
      final a = _Adapter({
        'HEAD $u': _Res(200),
        'GET $u': _Res(200, hang: true),
      });
      final token = CancelToken();
      unawaited(cancelSoon(token));
      await expectLater(
        resolver(a).resolve(u, cancelToken: token),
        throwsA(isA<DownloadCancelledException>()),
      );
      expect(a.cancelledRequests, 1);
    });

    test('cancel while the probe body stalls', () async {
      final ctrl = StreamController<Uint8List>();
      final a = _Adapter({
        'HEAD $u': _Res(200),
        'GET $u': _Res(200, stream: ctrl.stream),
      });
      final token = CancelToken();
      unawaited(cancelSoon(token));
      await expectLater(
        resolver(a).resolve(u, cancelToken: token),
        throwsA(isA<DownloadCancelledException>()),
      );
      unawaited(ctrl.close());
    });

    test('cancel during host resolution does not wait for DNS', () async {
      final never = Completer<List<InternetAddress>>();
      final r = DirectMediaUrlResolver(
        dio: Dio()..httpClientAdapter = _Adapter({}),
        hostResolver: (_) => never.future,
      );
      final token = CancelToken();
      unawaited(cancelSoon(token));
      await expectLater(
        r.resolve(u, cancelToken: token),
        throwsA(isA<DownloadCancelledException>()),
      );
    });

    test('an already-cancelled token never touches the network', () async {
      final a = _Adapter({'HEAD $u': _Res(200)});
      final token = CancelToken()..cancel();
      await expectLater(
        resolver(a).resolve(u, cancelToken: token),
        throwsA(isA<DownloadCancelledException>()),
      );
    });
  });

  group(
    'real FFmpeg decode validation (skipped when ffmpeg is not installed)',
    () {
      late bool hasFfmpeg;
      setUpAll(() async {
        try {
          hasFfmpeg = (await Process.run('ffmpeg', ['-version'])).exitCode == 0;
        } catch (_) {
          hasFfmpeg = false;
        }
      });

      Future<bool> decodes(List<int> bytes) async {
        if (!hasFfmpeg) return true;
        final f = File('${tmp.path}/probe.bin')..writeAsBytesSync(bytes);
        final r = await Process.run('ffmpeg', [
          '-hide_banner',
          ...AudioConversionService.decodeValidationArgs(f.path),
        ]);
        return r.exitCode == 0;
      }

      test('genuine fixtures decode', () async {
        for (final f in [
          'tone.mp3',
          'tone.aac',
          'tone.m4a',
          'tone.wav',
          'tone.flac',
          'tone.ogg',
          'video_with_audio.mp4',
        ]) {
          expect(await decodes(fx(f)), isTrue, reason: f);
        }
      });

      test('invalid media is rejected by the final check', () async {
        if (!hasFfmpeg) return;
        for (final c in {
          'ID3-only': _id3Only(),
          'ID3 + garbage': _id3Garbage(),
          'garbage': List.filled(900, 7),
          'ftyp-only': _ftypOnly(),
          'truncated mp4': _truncatedMp4(),
          'video without audio': fx('video_no_audio.mp4'),
          'garbage aac': List.filled(300, 0xF1),
        }.entries) {
          expect(await decodes(c.value), isFalse, reason: c.key);
        }
      });

      test('raw AAC is wrapped into an importable M4A; raw AAC itself is not importable', () async {
        if (!hasFfmpeg) return;
        final src = File('${tmp.path}/in.aac')
          ..writeAsBytesSync(fx('tone.aac'));
        final out = '${tmp.path}/out.m4a';
        final r = await Process.run('ffmpeg', [
          '-y',
          '-i',
          src.path,
          '-vn',
          '-acodec',
          'copy',
          '-bsf:a',
          'aac_adtstoasc',
          out,
        ]);
        expect(r.exitCode, 0);
        expect(() => readMetadata(File(out), getImage: false), returnsNormally);
        expect(await decodes(File(out).readAsBytesSync()), isTrue);
        expect(() => readMetadata(src, getImage: false), throwsA(anything));
      });
    },
  );

  group('sanitizeFileName', () {
    test('strips traversal and separators', () {
      expect(sanitizeFileName('../../etc/passwd.mp3'), 'passwd.mp3');
      expect(sanitizeFileName(r'..\..\evil.mp3'), 'evil.mp3');
      expect(sanitizeFileName('..'), 'download');
      expect(sanitizeFileName(''), 'download');
    });

    test('removes control characters and reserved characters', () {
      expect(
        sanitizeFileName(
          'a${String.fromCharCode(0)}b${String.fromCharCode(7)}c.mp3',
        ),
        'abc.mp3',
      );
      expect(sanitizeFileName('a:b*c?.mp3'), 'a_b_c_.mp3');
    });

    test('preserves Unicode', () {
      expect(sanitizeFileName('أغنية 歌曲 é.mp3'), 'أغنية 歌曲 é.mp3');
    });

    test('caps length but keeps the extension', () {
      final r = sanitizeFileName('${'a' * 500}.mp3');
      expect(r.length, 120);
      expect(r.endsWith('.mp3'), isTrue);
    });
  });
}
