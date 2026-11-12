import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'perf_frames.dart';

/// Debug/profile-only interaction-latency diagnostics. Search logs for
/// `[ListenyPerf`. Every entry point returns immediately in release builds
/// and `flutter test`.
///
/// Only generic action/screen names, durations and counts are ever logged —
/// never track metadata, file paths, URLs, search text or account data.
/// Timestamps are ms on one monotonic [Stopwatch].
///
/// Each interaction ([begin] .. [end]) is also emitted as a
/// [developer.TimelineTask] (visible in DevTools' timeline next to frame
/// bars) and collects the DB/stream events that happened while it was open.
class PerfLog {
  PerfLog._();

  static final bool enabled =
      !kReleaseMode && !Platform.environment.containsKey('FLUTTER_TEST');

  static final Stopwatch _clock = Stopwatch()..start();
  static final Map<String, _Interaction> _open = {};
  static final Map<String, int> _totals = {};
  static final Map<String, int> _builds = {};

  static String get _stamp =>
      '[ListenyPerf +${_clock.elapsedMilliseconds.toString().padLeft(6, '0')}ms]';

  /// Plain log line.
  static void note(String message) {
    if (!enabled) return;
    debugPrint('$_stamp $message');
  }

  /// Starts interaction [name] (logs START, opens a timeline task).
  static void begin(String name, [String detail = '']) {
    if (!enabled) return;
    final task = developer.TimelineTask(filterKey: 'ListenyPerf')..start(name);
    _open[name] = _Interaction(task);
    note('$name START${detail.isEmpty ? '' : ' ($detail)'}');
  }

  /// Logs a step of an open interaction with elapsed ms since [begin].
  static void step(String name, String what) {
    if (!enabled) return;
    final i = _open[name];
    if (i == null) return;
    note('$name: $what (+${i.sw.elapsedMilliseconds}ms)');
  }

  /// Ends [name]: logs total latency and the DB events seen meanwhile.
  static void end(String name, [String what = 'END']) {
    if (!enabled) return;
    final i = _open.remove(name);
    if (i == null) return;
    final db = i.db.isEmpty
        ? 'none'
        : i.db.entries.map((e) => '${e.key}x${e.value}').join(', ');
    note('$name: $what total=${i.sw.elapsedMilliseconds}ms db-events=[$db]');
    i.task.finish();
  }

  /// True while [name] is open.
  static bool isOpen(String name) => _open.containsKey(name);

  /// Ends [name] after the next frame has been built and painted.
  static void endAfterFrame(String name, [String what = 'first frame']) {
    if (!enabled || !_open.containsKey(name)) return;
    step(name, 'frame requested');
    SchedulerBinding.instance.addPostFrameCallback((_) => end(name, what));
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// Records a database/stream event (stream created/subscribed, storage
  /// scan, ...). Attributed to every currently open interaction and counted
  /// app-wide. Also logged when nothing is open, so background/unrelated
  /// reloads are visible too.
  static void db(String event) {
    if (!enabled) return;
    _totals[event] = (_totals[event] ?? 0) + 1;
    for (final i in _open.values) {
      i.db[event] = (i.db[event] ?? 0) + 1;
    }
    note(
      'db $event #${_totals[event]}'
      '${_open.isEmpty ? ' (no interaction open)' : ' during ${_open.keys.join('+')}'}',
    );
  }

  /// Records [event] and returns [value] unchanged (for expression bodies).
  static T traced<T>(String event, T value) {
    db(event);
    return value;
  }
}

class _Interaction {
  final Stopwatch sw = Stopwatch()..start();
  final developer.TimelineTask task;
  final Map<String, int> db = {};
  _Interaction(this.task);
}

/// Wraps a screen's root to measure its open: START at mount, then the
/// first and second builds reported through [PerfOpenScope.onBuild] (streams
/// are seeded with an empty list, so build #1 is seed data and build #2 is
/// the first real emission). Transparent in release/test builds.
class PerfOpenScope extends StatefulWidget {
  final String name;
  final Widget child;
  const PerfOpenScope({super.key, required this.name, required this.child});

  /// Call from the screen's data builder.
  static void onBuild(String name) {
    if (!PerfLog.enabled) return;
    final key = 'open $name';
    if (!PerfLog.isOpen(key)) return;
    final n = (PerfLog._builds[key] ?? 0) + 1;
    PerfLog._builds[key] = n;
    if (n == 1) {
      PerfLog.step(key, 'first build (seed data)');
    } else if (n == 2) {
      PerfLog.step(key, 'second build (real data)');
      PerfLog.endAfterFrame(key, 'data frame painted');
    }
  }

  @override
  State<PerfOpenScope> createState() => _PerfOpenScopeState();
}

class _PerfOpenScopeState extends State<PerfOpenScope> {
  @override
  void initState() {
    super.initState();
    if (!PerfLog.enabled) return;
    final key = 'open ${widget.name}';
    PerfLog._builds.remove(key);
    PerfLog.begin(key);
    // Name the navigation frame window (opened by PerfNavObserver) after
    // this screen, e.g. 'push' -> 'push:album'.
    PerfFrames.retag('push', 'push:${widget.name}');
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => PerfLog.step(key, 'first frame painted'),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
