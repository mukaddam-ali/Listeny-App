import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import 'perf_log.dart';

/// Debug/profile-only startup timing diagnostics. Every entry point returns
/// immediately (and the logging bodies are dead code) in release builds, in
/// `flutter test`, and never writes to a file, the network or analytics —
/// just `debugPrint`. Search logs for `[ListenyStartup`.
///
/// All timestamps are milliseconds on one monotonic [Stopwatch] started by
/// [init], so every line is comparable regardless of wall-clock changes.
/// Only stage names, durations and counts are ever logged — never track
/// metadata, file paths or URLs.
class StartupLog {
  StartupLog._();

  static final bool enabled =
      !kReleaseMode && !Platform.environment.containsKey('FLUTTER_TEST');

  static final Stopwatch _clock = Stopwatch();
  static String _lastStage = '(none)';
  static final Set<String> _inFlight = <String>{};
  static final Set<String> _once = <String>{};
  static final Map<String, int> _ticks = <String, int>{};
  static final List<Timer> _watchdogs = <Timer>[];
  static bool _bootstrapDone = false;

  /// True only while playback restore is running, so the shared audio
  /// handler's `setAudioSources` timing is attributed to restore and not to
  /// every later user-initiated queue load.
  static bool inRestore = false;

  /// Starts the shared clock. Call first thing in `main()`.
  static void init() {
    if (!enabled) return;
    if (!_clock.isRunning) _clock.start();
    mark('Dart main entered');
  }

  static String get _stamp {
    final ms = _clock.elapsedMilliseconds.toString().padLeft(4, '0');
    return '[ListenyStartup +${ms}ms]';
  }

  /// Logs [message] and records it as the last known startup stage.
  static void mark(String message) {
    if (!enabled) return;
    _lastStage = message;
    debugPrint('$_stamp $message');
  }

  /// Logs a line that is NOT a stage boundary (does not update the last
  /// known stage used by the watchdog).
  static void note(String message) {
    if (!enabled) return;
    debugPrint('$_stamp $message');
  }

  /// [mark]s [message] only the first time [key] is seen.
  static void markOnce(String key, String message) {
    if (!enabled) return;
    if (_once.add(key)) mark(message);
  }

  /// Counts calls to [name] and logs the first few, then powers of two, so
  /// repeated calls (e.g. a stream created on every rebuild) are visible
  /// without flooding the log.
  static void tick(String name) {
    if (!enabled) return;
    final n = (_ticks[name] ?? 0) + 1;
    _ticks[name] = n;
    if (n <= 5 || (n & (n - 1)) == 0) note('$name call #$n');
  }

  /// Runs [body] logging START / END / duration, and on failure the stage
  /// name, exception and stack trace — then rethrows unchanged.
  static Future<T> stage<T>(String name, Future<T> Function() body) {
    if (!enabled) return body();
    return _stage(name, body);
  }

  static Future<T> _stage<T>(String name, Future<T> Function() body) async {
    final sw = Stopwatch()..start();
    _inFlight.add(name);
    mark('$name START');
    try {
      final result = await body();
      _inFlight.remove(name);
      mark('$name END (${sw.elapsedMilliseconds}ms)');
      return result;
    } catch (e, st) {
      _inFlight.remove(name);
      mark('$name FAILED after ${sw.elapsedMilliseconds}ms: $e\n$st');
      rethrow;
    }
  }

  /// Synchronous variant of [stage].
  static T stageSync<T>(String name, T Function() body) {
    if (!enabled) return body();
    final sw = Stopwatch()..start();
    mark('$name START');
    try {
      final result = body();
      mark('$name END (${sw.elapsedMilliseconds}ms)');
      return result;
    } catch (e, st) {
      mark('$name FAILED after ${sw.elapsedMilliseconds}ms: $e\n$st');
      rethrow;
    }
  }

  /// Logs a failure of [future] (stage name, exception, stack trace) while
  /// preserving it: the returned future still completes with the original
  /// error, so an unawaited caller sees exactly what it saw before.
  static Future<T> logFailure<T>(String name, Future<T> future) {
    if (!enabled) return future;
    return future.catchError((Object e, StackTrace st) {
      mark('$name FAILED: $e\n$st');
      Error.throwWithStackTrace(e, st);
    });
  }

  /// Logs a restore-scoped line, only while [inRestore] is set.
  static void restoreMark(String message) {
    if (!enabled || !inRestore) return;
    mark(message);
  }

  // --- Bootstrap tracking + watchdog ---

  /// Observes [bootstrap] without altering it: logs completion or error and
  /// stops the watchdog. Returns [bootstrap] itself.
  static Future<T> watchBootstrap<T>(Future<T> bootstrap) {
    if (!enabled) return bootstrap;
    _startWatchdog();
    bootstrap.then(
      (_) {
        _bootstrapDone = true;
        _cancelWatchdog();
        mark('bootstrap Future completed OK');
      },
      onError: (Object e, StackTrace st) {
        _bootstrapDone = true;
        _cancelWatchdog();
        mark('bootstrap Future completed WITH ERROR: $e\n$st');
      },
    );
    return bootstrap;
  }

  static void _startWatchdog() {
    for (final seconds in const [5, 15, 30]) {
      _watchdogs.add(
        Timer(Duration(seconds: seconds), () {
          if (_bootstrapDone) return;
          note(
            'WATCHDOG: bootstrap still not complete after ${seconds}s. '
            'last stage="$_lastStage" in-flight=${_inFlight.toList()}',
          );
        }),
      );
    }
  }

  static void _cancelWatchdog() {
    for (final t in _watchdogs) {
      t.cancel();
    }
    _watchdogs.clear();
  }

  // --- Frames ---

  /// Logs the first Flutter frame (whatever it shows) and when it is
  /// rasterized. Call right after `runApp`.
  static void trackFirstFrame() {
    if (!enabled) return;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) => mark('first Flutter frame rendered'));
    binding.waitUntilFirstFrameRasterized.then(
      (_) => note('first Flutter frame rasterized'),
    );
  }

  /// Logs once when a frame containing the real app (not the loading
  /// screen) has been painted. Call from the real app's first build.
  static void trackFirstRealFrame() {
    if (!enabled || !_once.add('first-real-frame')) return;
    mark('real ListenyApp first build (frame pending)');
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => mark('first real ListenyApp frame rendered'),
    );
  }

  // --- Error hooks (chain, never swallow) ---

  static void installErrorHooks() {
    if (!enabled) return;
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      note(
        'FlutterError: ${details.exceptionAsString()}\n'
        '${details.stack}',
      );
      // Preserve the original behavior (default: dump to console).
      if (previousFlutter != null) {
        previousFlutter(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      note('Uncaught async/platform error: $error\n$stack');
      // false = not handled here; the engine reports it exactly as before.
      return previousPlatform?.call(error, stack) ?? false;
    };
  }

  // --- Data stream tracing ---

  /// Logs the first emission of [source] (per call) with an item count and
  /// the time since it was first listened to. Passes events through
  /// untouched. [name] must not contain private data.
  static Stream<T> traceFirst<T>(
    Stream<T> source,
    String name,
    int Function(T) countOf,
  ) {
    if (!enabled) return source;
    tick('$name stream created');
    PerfLog.db('$name created');
    final sw = Stopwatch();
    var first = true;
    return source
        .doOnListen(() {
          PerfLog.db('$name subscribed');
          if (!sw.isRunning) sw.start();
        })
        .doOnData((data) {
          if (!first) return;
          first = false;
          final logKey = 'first-result:$name';
          // Cap per-name logging: streams are re-created on rebuilds.
          final n = (_ticks[logKey] ?? 0) + 1;
          _ticks[logKey] = n;
          if (n <= 3) {
            note(
              'first $name result: ${countOf(data)} rows '
              '(${sw.elapsedMilliseconds}ms after subscribe)',
            );
          }
        });
  }
}
