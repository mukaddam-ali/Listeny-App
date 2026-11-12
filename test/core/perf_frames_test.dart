import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/core/diagnostics/perf_frames.dart';
import 'package:listeny/core/diagnostics/perf_log.dart';

FrameSample frame({
  required int buildStart,
  int build = 8000,
  int gap = 0,
  int raster = 10000,
  int vsyncLead = 1000,
}) => FrameSample(
  vsyncStart: buildStart - vsyncLead,
  buildStart: buildStart,
  buildFinish: buildStart + build,
  rasterStart: buildStart + build + gap,
  rasterFinish: buildStart + build + gap + raster,
);

void main() {
  test('frame instrumentation is disabled (no-op) under flutter test', () {
    expect(PerfLog.enabled, isFalse);
    PerfFrames.begin('push');
    PerfFrames.retag('push', 'push:album');
    expect(PerfFrames.isOpen('push'), isFalse);
    PerfFrames.end('push:album');
    expect(PerfFrames.msSinceLastTap(), isNull);
  });

  group('WindowRegistry (renamed windows)', () {
    test('window renamed push -> push:album closes under either name', () {
      final r = WindowRegistry<int>()..put('push', 1);
      expect(r.retag('push', 'push:album'), isTrue);
      expect(r.has('push'), isTrue, reason: 'old name still resolves');
      expect(r.has('push:album'), isTrue);
      expect(r.take('push'), 1, reason: 'end("push") finds the renamed window');
      expect(r.has('push'), isFalse);
      expect(r.has('push:album'), isFalse);
      expect(r.take('push'), isNull, reason: 'closed exactly once');
    });

    test('closing by the new name also clears the alias', () {
      final r = WindowRegistry<int>()..put('push', 7);
      r.retag('push', 'push:album');
      expect(r.take('push:album'), 7);
      expect(r.has('push'), isFalse);
    });

    test(
      'a new window reusing the old name is not shadowed by a stale alias',
      () {
        final r = WindowRegistry<int>()..put('push', 1);
        r.retag('push', 'push:album');
        r.put('push', 2); // next navigation begins before the old one closed
        expect(r.take('push'), 2);
        expect(r.take('push:album'), 1);
      },
    );

    test('retag of an unknown window is a no-op', () {
      final r = WindowRegistry<int>();
      expect(r.retag('push', 'push:album'), isFalse);
      expect(r.has('push:album'), isFalse);
    });
  });

  group('FrameSample / computeStats arithmetic', () {
    test('derived durations: total == build + gap + raster', () {
      final f = frame(
        buildStart: 1000000,
        build: 8000,
        gap: 170000,
        raster: 20000,
      );
      expect(f.buildMicros, 8000);
      expect(f.rasterMicros, 20000);
      expect(f.gapMicros, 170000);
      expect(f.totalMicros, 198000);
      expect(f.totalMicros, f.buildMicros + f.gapMicros + f.rasterMicros);
    });

    test('counts slow/jank/severe, maxima, averages and gap', () {
      final frames = [
        frame(buildStart: 0, gap: 0), // total 18ms -> slow only
        frame(buildStart: 200000, gap: 20000), // 38ms -> jank
        frame(
          buildStart: 400000,
          gap: 170000,
          raster: 20000,
        ), // 198ms -> severe
        frame(buildStart: 600000, build: 4000, raster: 5000), // 9ms -> fine
      ];
      final s = PerfFrames.computeStats(frames, 0, 1000000);
      expect(s.frames, 4);
      expect(s.slow, 3);
      expect(s.jank, 2);
      expect(s.severe, 1);
      expect(s.maxBuild, 8000);
      expect(s.maxRaster, 20000);
      expect(s.maxTotal, 198000);
      expect(s.avgTotal, (18000 + 38000 + 198000 + 9000) ~/ 4);
      expect(s.maxGap, 170000);
      expect(s.avgGap, (0 + 20000 + 170000 + 0) ~/ 4);
    });

    test('frame-start intervals use consecutive build starts', () {
      final frames = [
        frame(buildStart: 100000),
        frame(buildStart: 116000),
        frame(buildStart: 316000), // 200ms after the previous
        frame(buildStart: 332000),
      ];
      final s = PerfFrames.computeStats(frames, 0, 1000000);
      expect(s.maxInterval, 200000);
      expect(s.avgInterval, (16000 + 200000 + 16000) ~/ 3);
      expect(s.intervalsOver33, 1);
    });

    test('only frames overlapping the window are counted', () {
      final frames = [
        frame(buildStart: 0), // ends 18ms: before the window
        frame(buildStart: 500000),
        frame(buildStart: 2000000), // after the window
      ];
      final s = PerfFrames.computeStats(frames, 400000, 1000000);
      expect(s.frames, 1);
      expect(s.maxInterval, 0, reason: 'a single frame has no interval');
    });

    test('empty window yields zeros without dividing by zero', () {
      final s = PerfFrames.computeStats(const [], 0, 1000);
      expect(s.frames, 0);
      expect(s.avgTotal, 0);
      expect(s.avgGap, 0);
      expect(s.avgInterval, 0);
    });
  });

  testWidgets('PerfNavObserver does not interfere with navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [PerfNavObserver('test')],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const Text('next'))),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('next'), findsOneWidget);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.text('go'), findsOneWidget);
  });
}
