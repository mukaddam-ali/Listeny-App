import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:ui' show FrameTiming, FramePhase;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'perf_log.dart';

/// One frame's phase timestamps (microseconds, the engine's monotonic clock,
/// exactly as reported by [FrameTiming.timestampInMicroseconds]). Pure data +
/// derived durations so the arithmetic is unit-testable.
@visibleForTesting
class FrameSample {
  const FrameSample({
    required this.vsyncStart,
    required this.buildStart,
    required this.buildFinish,
    required this.rasterStart,
    required this.rasterFinish,
  });

  factory FrameSample.fromTiming(FrameTiming t) => FrameSample(
    vsyncStart: t.timestampInMicroseconds(FramePhase.vsyncStart),
    buildStart: t.timestampInMicroseconds(FramePhase.buildStart),
    buildFinish: t.timestampInMicroseconds(FramePhase.buildFinish),
    rasterStart: t.timestampInMicroseconds(FramePhase.rasterStart),
    rasterFinish: t.timestampInMicroseconds(FramePhase.rasterFinish),
  );

  final int vsyncStart, buildStart, buildFinish, rasterStart, rasterFinish;

  int get buildMicros => buildFinish - buildStart;
  int get rasterMicros => rasterFinish - rasterStart;

  /// Build start to raster finish (== build + gap + raster).
  int get totalMicros => rasterFinish - buildStart;

  /// Build finish to raster start: time the frame sat between the UI and
  /// raster phases. It is NOT attributed to any cause here (raster thread
  /// busy, queueing, waiting on the platform...) and is not GPU time.
  int get gapMicros => rasterStart - buildFinish;
}

/// Aggregate of the frames overlapping one window.
@visibleForTesting
class FrameWindowStats {
  const FrameWindowStats({
    required this.frames,
    required this.slow,
    required this.jank,
    required this.severe,
    required this.maxBuild,
    required this.maxRaster,
    required this.maxTotal,
    required this.avgTotal,
    required this.maxGap,
    required this.avgGap,
    required this.maxInterval,
    required this.avgInterval,
    required this.intervalsOver33,
  });

  final int frames, slow, jank, severe;
  final int maxBuild, maxRaster, maxTotal, avgTotal;
  final int maxGap, avgGap;
  final int maxInterval, avgInterval, intervalsOver33;
}

/// Named-window bookkeeping with rename support: a window renamed from `a` to
/// `b` is still found (and closed) under either name until it is taken.
@visibleForTesting
class WindowRegistry<T> {
  final Map<String, T> _items = {};
  final Map<String, String> _aliases = {};

  void put(String name, T value) {
    _aliases.remove(name);
    _items[name] = value;
  }

  /// Renames [from] to [to]; returns false when [from] isn't open.
  bool retag(String from, String to) {
    final v = _items.remove(from);
    if (v == null) return false;
    _items[to] = v;
    _aliases[from] = to;
    return true;
  }

  String? resolve(String name) {
    if (_items.containsKey(name)) return name;
    final alias = _aliases[name];
    return alias != null && _items.containsKey(alias) ? alias : null;
  }

  bool has(String name) => resolve(name) != null;

  /// Removes and returns the window known as [name] (or its new name).
  T? take(String name) {
    final key = resolve(name);
    if (key == null) return null;
    _aliases.removeWhere((_, to) => to == key);
    return _items.remove(key);
  }
}

/// Debug/profile-only frame-timing diagnostics (search logs for
/// `[ListenyPerf` + `frames[`). Disabled in release and `flutter test`.
///
/// Frame timings come from [SchedulerBinding.addTimingsCallback], which the
/// engine delivers in batches OUTSIDE frame production; the callback only
/// copies a few numbers into a ring buffer. Nothing is printed while a window
/// is running — each named window prints ONE summary line after it closes
/// (plus a short wait for the last batch of timings to arrive).
///
/// Only generic window names, durations, counts and byte totals are logged.
class PerfFrames {
  PerfFrames._();

  static const slowMicros = 16700; // > one 60 Hz frame
  static const jankMicros = 33400; // > two frames
  static const severeMicros = 100000;
  static const _maxFrames = 900;
  // How long after a window closes to wait for the engine's last timing batch.
  static const _deliveryWait = Duration(milliseconds: 900);

  static bool _installed = false;
  static final Queue<FrameSample> _ring = Queue<FrameSample>();
  static final WindowRegistry<_Window> _windows = WindowRegistry<_Window>();
  static int? _lastPointerUpMicros;

  static void install() {
    if (!PerfLog.enabled || _installed) return;
    _installed = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  static void _onPointer(PointerEvent e) {
    if (e is PointerUpEvent) _lastPointerUpMicros = developer.Timeline.now;
  }

  /// ms since the last finger-up, or null when there was none recently.
  static int? msSinceLastTap() {
    final up = _lastPointerUpMicros;
    if (up == null) return null;
    final ms = (developer.Timeline.now - up) ~/ 1000;
    return ms > 3000 ? null : ms;
  }

  static void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _ring.addLast(FrameSample.fromTiming(t));
    }
    while (_ring.length > _maxFrames) {
      _ring.removeFirst();
    }
  }

  /// Opens (or restarts) window [name], snapshotting the image cache so the
  /// summary can report how many images/bytes were decoded into it.
  static void begin(String name) {
    if (!PerfLog.enabled) return;
    install();
    final cache = PaintingBinding.instance.imageCache;
    _windows.put(
      name,
      _Window(
        name: name,
        startMicros: developer.Timeline.now,
        cacheImages: cache.currentSize,
        cacheBytes: cache.currentSizeBytes,
      ),
    );
    PerfLog.note('frames[$name] window START');
  }

  /// Renames an open window (e.g. the generic nav 'push' to 'push:album' once
  /// the destination screen identifies itself). The old name stays resolvable
  /// by [end] and [isOpen] until the window closes.
  static void retag(String from, String to) {
    if (!PerfLog.enabled) return;
    _windows._items[from]?.name = to;
    _windows.retag(from, to);
  }

  static bool isOpen(String name) => _windows.has(name);

  /// Closes [name] (or the name it was renamed to) [after] from now (frames
  /// up to then are counted) and logs one summary once the last timing batch
  /// has had time to arrive.
  static void end(String name, {Duration after = Duration.zero}) {
    if (!PerfLog.enabled) return;
    final w = _windows.take(name);
    if (w == null) return;
    final endMicros = developer.Timeline.now + after.inMicroseconds;
    Timer(after + _deliveryWait, () => _summarize(w, endMicros));
  }

  /// Aggregates [frames] overlapping [startMicros]..[endMicros]. Frame-start
  /// intervals are between consecutive selected frames' build starts.
  @visibleForTesting
  static FrameWindowStats computeStats(
    Iterable<FrameSample> frames,
    int startMicros,
    int endMicros,
  ) {
    var n = 0, slow = 0, jank = 0, severe = 0;
    var maxBuild = 0, maxRaster = 0, maxTotal = 0, sumTotal = 0;
    var maxGap = 0, sumGap = 0;
    var intervals = 0, maxInterval = 0, sumInterval = 0, over33 = 0;
    int? prevStart;
    for (final f in frames) {
      if (f.rasterFinish < startMicros || f.buildStart > endMicros) continue;
      n++;
      sumTotal += f.totalMicros;
      sumGap += f.gapMicros;
      if (f.totalMicros > slowMicros) slow++;
      if (f.totalMicros > jankMicros) jank++;
      if (f.totalMicros > severeMicros) severe++;
      if (f.buildMicros > maxBuild) maxBuild = f.buildMicros;
      if (f.rasterMicros > maxRaster) maxRaster = f.rasterMicros;
      if (f.totalMicros > maxTotal) maxTotal = f.totalMicros;
      if (f.gapMicros > maxGap) maxGap = f.gapMicros;
      if (prevStart != null) {
        final iv = f.buildStart - prevStart;
        intervals++;
        sumInterval += iv;
        if (iv > maxInterval) maxInterval = iv;
        if (iv > jankMicros) over33++;
      }
      prevStart = f.buildStart;
    }
    return FrameWindowStats(
      frames: n,
      slow: slow,
      jank: jank,
      severe: severe,
      maxBuild: maxBuild,
      maxRaster: maxRaster,
      maxTotal: maxTotal,
      avgTotal: n == 0 ? 0 : sumTotal ~/ n,
      maxGap: maxGap,
      avgGap: n == 0 ? 0 : sumGap ~/ n,
      maxInterval: maxInterval,
      avgInterval: intervals == 0 ? 0 : sumInterval ~/ intervals,
      intervalsOver33: over33,
    );
  }

  static void _summarize(_Window w, int endMicros) {
    final s = computeStats(_ring, w.startMicros, endMicros);
    final cache = PaintingBinding.instance.imageCache;
    String ms(int micros) => (micros / 1000).toStringAsFixed(1);
    final dImages = cache.currentSize - w.cacheImages;
    final dMb = (cache.currentSizeBytes - w.cacheBytes) / (1024 * 1024);
    PerfLog.note(
      'frames[${w.name}] window=${(endMicros - w.startMicros) ~/ 1000}ms '
      'frames=${s.frames} slow(>16.7ms)=${s.slow} jank(>33ms)=${s.jank} '
      'severe(>100ms)=${s.severe} '
      'maxBuild=${ms(s.maxBuild)}ms maxRaster=${ms(s.maxRaster)}ms '
      'maxTotal=${ms(s.maxTotal)}ms avgTotal=${ms(s.avgTotal)}ms '
      '| build->raster gap (unattributed wait, NOT confirmed GPU time) '
      'max=${ms(s.maxGap)}ms avg=${ms(s.avgGap)}ms '
      '| frame-start interval max=${ms(s.maxInterval)}ms '
      'avg=${ms(s.avgInterval)}ms over33ms=${s.intervalsOver33} '
      '| imageCache images=${dImages >= 0 ? '+' : ''}$dImages '
      'bytes=${dMb >= 0 ? '+' : ''}${dMb.toStringAsFixed(1)}MB '
      '(now ${cache.currentSize} images, '
      '${(cache.currentSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB, '
      'live=${cache.liveImageCount} pending=${cache.pendingImageCount})',
    );
  }
}

class _Window {
  String name;
  final int startMicros;
  final int cacheImages;
  final int cacheBytes;
  _Window({
    required this.name,
    required this.startMicros,
    required this.cacheImages,
    required this.cacheBytes,
  });
}

/// Navigator observer (debug/profile only) timing route pushes and pops:
/// tap-to-push gap, transition completion, first frame after the action, and
/// a [PerfFrames] window around each. Attach to every Navigator that hosts
/// user navigation (the app's root and each tab's nested Navigator).
class PerfNavObserver extends NavigatorObserver {
  PerfNavObserver(this.scope);

  /// Generic scope label ('root', 'library', ...), never user data.
  final String scope;

  String _routeName(Route<dynamic> r) =>
      r.settings.name ?? r.runtimeType.toString();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!PerfLog.enabled || previousRoute == null) return;
    _track('push', route, forward: true);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!PerfLog.enabled) return;
    _track('pop', route, forward: false);
  }

  void _track(String kind, Route<dynamic> route, {required bool forward}) {
    final sw = Stopwatch()..start();
    PerfFrames.begin(kind);
    final gap = forward ? PerfFrames.msSinceLastTap() : null;
    PerfLog.note(
      'nav $kind START scope=$scope route=${_routeName(route)}'
      '${gap == null ? '' : ' tap-to-push=${gap}ms'}',
    );
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => PerfLog.note(
        'nav $kind: first frame after action (+${sw.elapsedMilliseconds}ms)',
      ),
    );
    final animation = (route is TransitionRoute) ? route.animation : null;
    void finish() {
      PerfLog.note(
        'nav $kind: transition complete (+${sw.elapsedMilliseconds}ms)',
      );
      // Keep counting for a moment: data/second-build frames land just after.
      PerfFrames.end(kind, after: const Duration(milliseconds: 500));
    }

    bool settled(AnimationStatus status) => forward
        ? status == AnimationStatus.completed
        : status == AnimationStatus.dismissed;
    if (animation == null || settled(animation.status)) {
      finish();
      return;
    }
    late final AnimationStatusListener listener;
    listener = (status) {
      if (!settled(status)) return;
      animation.removeStatusListener(listener);
      finish();
    };
    animation.addStatusListener(listener);
  }
}
