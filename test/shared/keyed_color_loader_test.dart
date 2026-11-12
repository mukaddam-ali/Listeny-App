import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/shared/artwork_color.dart';

void main() {
  late List<(String?, String)> calls;
  late List<Color> notified;
  late Map<int, Completer<Color>> pending;

  KeyedColorLoader make({Color initial = const Color(0xFF111111)}) {
    calls = [];
    notified = [];
    pending = {};
    return KeyedColorLoader(
      initial: initial,
      onColor: notified.add,
      extractor: (path, seed) {
        calls.add((path, seed));
        return (pending[calls.length - 1] = Completer<Color>()).future;
      },
    );
  }

  test('repeated builds with the same key extract exactly once', () async {
    final l = make();
    for (var i = 0; i < 20; i++) {
      l.request('/a.jpg', 'Album|Artist');
    }
    expect(calls, hasLength(1));
    pending[0]!.complete(const Color(0xFF222222));
    await Future<void>.delayed(Duration.zero);
    // The result's own rebuild calls request() again: still no new extraction.
    l.request('/a.jpg', 'Album|Artist');
    l.request('/a.jpg', 'Album|Artist');
    expect(calls, hasLength(1));
    expect(notified, [const Color(0xFF222222)]);
  });

  test('a changed key (path, album or artist) triggers a new extraction', () {
    final l = make();
    l.request('/a.jpg', 'A|X');
    l.request('/b.jpg', 'A|X');
    l.request('/b.jpg', 'B|X');
    l.request('/b.jpg', 'B|Y');
    l.request(null, 'B|Y');
    expect(calls, hasLength(5));
  });

  test('stale result for an older key never updates a newer one', () async {
    final l = make();
    l.request('/a.jpg', 'A|X');
    l.request('/b.jpg', 'B|X');
    pending[1]!.complete(const Color(0xFF00FF00)); // newer finishes first
    await Future<void>.delayed(Duration.zero);
    pending[0]!.complete(const Color(0xFFFF0000)); // stale arrives late
    await Future<void>.delayed(Duration.zero);
    expect(notified, [const Color(0xFF00FF00)]);
    expect(l.color, const Color(0xFF00FF00));
  });

  test('result after dispose (unmounted widget) is ignored', () async {
    final l = make();
    l.request('/a.jpg', 'A|X');
    l.dispose();
    pending[0]!.complete(const Color(0xFF123456));
    await Future<void>.delayed(Duration.zero);
    expect(notified, isEmpty);
    l.request('/b.jpg', 'B|X');
    expect(calls, hasLength(1), reason: 'no new extraction after dispose');
  });

  test('no notification when the effective colour is unchanged', () async {
    final l = make(initial: const Color(0xFF111111));
    l.request('/a.jpg', 'A|X');
    pending[0]!.complete(const Color(0xFF111111));
    await Future<void>.delayed(Duration.zero);
    expect(notified, isEmpty);
  });

  test(
    'extractor failure keeps the current colour and does not throw',
    () async {
      final l = make();
      l.request('/a.jpg', 'A|X');
      pending[0]!.completeError(StateError('decode failed'));
      await Future<void>.delayed(Duration.zero);
      expect(notified, isEmpty);
      expect(l.color, const Color(0xFF111111));
    },
  );
}
