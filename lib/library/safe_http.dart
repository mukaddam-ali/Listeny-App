import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'media_url_resolver.dart';

/// Centralized limits for direct media imports.
class DirectMediaLimits {
  /// Hard cap on a download's body, enforced while streaming.
  final int maxBytes;
  final int maxRedirects;

  /// How many leading bytes a probe reads before deciding.
  final int probeBytes;

  /// Cap on the single HTML page a generic web resolver will read.
  final int maxHtmlBytes;

  /// Cap on media candidates probed for one page.
  final int maxCandidates;

  const DirectMediaLimits({
    this.maxBytes = 512 * 1024 * 1024,
    this.maxRedirects = 5,
    this.probeBytes = 8192,
    this.maxHtmlBytes = 2 * 1024 * 1024,
    this.maxCandidates = 10,
  });
}

/// Resolves a host name to addresses (injectable so tests stay offline).
typedef HostResolver = Future<List<InternetAddress>> Function(String host);

Future<List<InternetAddress>> _lookup(String host) =>
    InternetAddress.lookup(host).timeout(const Duration(seconds: 5));

// IANA special-purpose IPv4 blocks that are not globally routable, as
// (address, prefix length).
const _blockedV4 = <(String, int)>[
  ('0.0.0.0', 8), // "this network"
  ('10.0.0.0', 8), // private
  ('100.64.0.0', 10), // carrier-grade NAT
  ('127.0.0.0', 8), // loopback
  ('169.254.0.0', 16), // link-local
  ('172.16.0.0', 12), // private
  ('192.0.0.0', 24), // IETF protocol assignments
  ('192.0.2.0', 24), // documentation (TEST-NET-1)
  ('192.88.99.0', 24), // deprecated 6to4 relay anycast
  ('192.168.0.0', 16), // private
  ('198.18.0.0', 15), // benchmarking
  ('198.51.100.0', 24), // documentation (TEST-NET-2)
  ('203.0.113.0', 24), // documentation (TEST-NET-3)
  ('224.0.0.0', 4), // multicast
  ('240.0.0.0', 4), // reserved + broadcast
];

// IPv6 is accepted only inside global unicast 2000::/3, minus these
// special-purpose blocks.
const _blockedV6 = <(String, int)>[
  ('2001::', 23), // IETF protocol assignments (Teredo, ORCHID, ...)
  ('2001:db8::', 32), // documentation
  ('2002::', 16), // 6to4 (deprecated)
  ('3fff::', 20), // documentation
];

bool _inPrefix(List<int> addr, String prefix, int bits) {
  final base = InternetAddress(prefix).rawAddress;
  var remaining = bits;
  for (var i = 0; remaining > 0; i++, remaining -= 8) {
    final mask = remaining >= 8 ? 0xFF : (0xFF << (8 - remaining)) & 0xFF;
    if ((addr[i] & mask) != (base[i] & mask)) return false;
  }
  return true;
}

/// True only for globally routable unicast destinations. Loopback, private,
/// link-local, multicast, documentation/benchmarking and every other
/// IANA special-purpose or reserved range are rejected. IPv4-mapped IPv6
/// addresses are judged by their embedded IPv4 address.
bool isGloballyRoutable(InternetAddress a) {
  final b = a.rawAddress;
  if (a.type == InternetAddressType.IPv4) {
    return !_blockedV4.any((r) => _inPrefix(b, r.$1, r.$2));
  }
  // ::ffff:a.b.c.d
  if (b.sublist(0, 10).every((x) => x == 0) && b[10] == 0xFF && b[11] == 0xFF) {
    return isGloballyRoutable(
      InternetAddress.fromRawAddress(Uint8List.fromList(b.sublist(12))),
    );
  }
  if (!_inPrefix(b, '2000::', 3)) return false;
  return !_blockedV6.any((r) => _inPrefix(b, r.$1, r.$2));
}

bool isDisallowedAddress(InternetAddress a) => !isGloballyRoutable(a);

/// Throws [MediaResolutionException] (redirectRejected / malformedUrl) unless
/// [url] is an http(s) URL without credentials whose host is neither a
/// local name nor resolves to a disallowed address.
Future<void> validateRemoteTarget(
  Uri url, {
  HostResolver? resolveHost,
  CancelToken? cancelToken,
}) async {
  const reject = MediaResolutionException(
    MediaResolutionFailure.redirectRejected,
  );
  final scheme = url.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') throw reject;
  if (url.userInfo.isNotEmpty) throw reject;
  final host = url.host.toLowerCase();
  if (host.isEmpty) {
    throw const MediaResolutionException(MediaResolutionFailure.malformedUrl);
  }
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host.endsWith('.internal')) {
    throw reject;
  }
  final literal = InternetAddress.tryParse(host);
  if (literal != null) {
    if (isDisallowedAddress(literal)) throw reject;
    return;
  }
  try {
    final lookup = (resolveHost ?? _lookup)(host);
    final addresses = cancelToken == null
        ? await lookup
        : await Future.any([
            lookup,
            cancelToken.whenCancel.then<List<InternetAddress>>((e) => throw e),
          ]);
    if (addresses.any(isDisallowedAddress)) throw reject;
  } on SocketException {
    // Unresolvable: the request itself will fail with a proper error.
  } on TimeoutException {
    // Same: let the request report it.
  }
}

class SafeResponse {
  final Response<ResponseBody> response;
  final Uri finalUrl;
  const SafeResponse(this.response, this.finalUrl);
}

const _sensitiveHeaders = {'authorization', 'cookie', 'proxy-authorization'};

bool _sameOrigin(Uri a, Uri b) =>
    a.scheme.toLowerCase() == b.scheme.toLowerCase() &&
    a.host.toLowerCase() == b.host.toLowerCase() &&
    a.port == b.port;

/// Stops reading [body] without consuming it.
void discardBody(ResponseBody body) {
  unawaited(body.stream.listen((_) {}).cancel());
}

/// GETs [url] as a stream, following redirects manually so every hop is
/// revalidated: bounded count, loop detection, [validateRemoteTarget] on
/// each target, and sensitive headers dropped when the origin changes.
/// Non-2xx final responses throw a [DioException] (badResponse). TLS
/// validation is left at Dio's defaults (enabled).
Future<SafeResponse> getWithSafeRedirects(
  Dio dio,
  Uri url, {
  required DirectMediaLimits limits,
  HostResolver? resolveHost,
  Map<String, String> headers = const {},
  CancelToken? cancelToken,
  DestinationPolicy? destinationPolicy,
}) async {
  var current = url;
  var currentHeaders = Map<String, String>.of(headers);
  final seen = <String>{};
  for (var hops = 0; ; hops++) {
    destinationPolicy?.call(current);
    await validateRemoteTarget(
      current,
      resolveHost: resolveHost,
      cancelToken: cancelToken,
    );
    if (!seen.add(current.toString())) {
      throw const MediaResolutionException(
        MediaResolutionFailure.redirectRejected,
      );
    }
    final response = await dio.requestUri<ResponseBody>(
      current,
      cancelToken: cancelToken,
      options: Options(
        method: 'GET',
        responseType: ResponseType.stream,
        followRedirects: false,
        validateStatus: (_) => true,
        headers: currentHeaders,
      ),
    );
    final status = response.statusCode ?? 0;
    final body = response.data!;
    if (const {301, 302, 303, 307, 308}.contains(status)) {
      final location = response.headers.value('location');
      discardBody(body);
      final next = location == null ? null : Uri.tryParse(location);
      if (next == null) {
        throw const MediaResolutionException(
          MediaResolutionFailure.redirectRejected,
        );
      }
      if (hops >= limits.maxRedirects) {
        throw const MediaResolutionException(
          MediaResolutionFailure.redirectRejected,
        );
      }
      final target = current.resolveUri(next);
      if (!_sameOrigin(current, target)) {
        currentHeaders.removeWhere(
          (k, _) => _sensitiveHeaders.contains(k.toLowerCase()),
        );
      }
      current = target;
      continue;
    }
    if (status < 200 || status >= 300) {
      discardBody(body);
      throw DioException.badResponse(
        statusCode: status,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
    return SafeResponse(response, current);
  }
}

/// Reads at most [max] bytes of [stream], then stops consuming it. The
/// result's `truncated` flag says more data existed. Completes with the
/// cancel error (a [DioException]) as soon as [cancelToken] fires, so a
/// stalled body can't outlive a cancel.
Future<({List<int> bytes, bool truncated})> readAtMost(
  Stream<List<int>> stream,
  int max, {
  CancelToken? cancelToken,
}) {
  final out = <int>[];
  final done = Completer<({List<int> bytes, bool truncated})>();
  late final StreamSubscription<List<int>> sub;
  sub = stream.listen(
    (chunk) {
      out.addAll(chunk);
      if (out.length > max && !done.isCompleted) {
        done.complete((bytes: out.sublist(0, max), truncated: true));
        unawaited(sub.cancel());
      }
    },
    onError: (Object e, StackTrace st) {
      if (!done.isCompleted) done.completeError(e, st);
    },
    onDone: () {
      if (!done.isCompleted) done.complete((bytes: out, truncated: false));
    },
    cancelOnError: true,
  );
  unawaited(
    cancelToken?.whenCancel.then((e) {
      if (!done.isCompleted) done.completeError(e);
      unawaited(sub.cancel());
    }),
  );
  return done.future;
}
