import '../core/diagnostics/perf_frames.dart';
import '../core/diagnostics/perf_log.dart';

/// Extras key stamped (debug/profile only) on every MediaItem a traced play
/// request loads, so playback events can be attributed to the request whose
/// sources are actually current — never to a previously loaded track.
const playTapRequestExtrasKey = 'playTapReq';

/// Debug/profile-only timing for ONE play request (a track tap / Play button).
/// Every mark carries the request id and ms since that request began, so
/// phases stay attributable to the same request even when a newer tap
/// supersedes it mid-flight. Never records paths or names.
class PlayTapTrace {
  PlayTapTrace() : id = ++_nextId;

  static int _nextId = 0;

  final int id;

  /// True once THIS request's own `setAudioSources()` has succeeded. Until
  /// then nothing observed can belong to this request (the player still
  /// holds the previous source), so no milestone may be recorded.
  bool armed = false;

  void arm() {
    if (armed) return;
    armed = true;
    mark('armed (own sources loaded)');
  }

  final Stopwatch _sw = Stopwatch()..start();

  /// Which one-shot milestones have already been logged.
  final Set<String> _seen = {};

  void mark(String what) {
    if (!PerfLog.enabled) return;
    PerfLog.note('play-tap#$id $what (+${_sw.elapsedMilliseconds}ms)');
  }

  /// Records milestone [key]; logs it the first time only. Returns true when
  /// it was the first time (state is tracked even when logging is off).
  bool markOnce(String key, String what) {
    if (!_seen.add(key)) return false;
    mark(what);
    return true;
  }

  bool hasSeen(String key) => _seen.contains(key);

  /// Runs [body] between "START" and "END" marks for [phase].
  T phase<T>(String phase, T Function() body) {
    mark('$phase START');
    try {
      return body();
    } finally {
      mark('$phase END');
    }
  }

  /// Async variant of [phase].
  Future<T> phaseAsync<T>(String phase, Future<T> Function() body) async {
    mark('$phase START');
    try {
      return await body();
    } finally {
      mark('$phase END');
    }
  }
}

/// Owns the single active [PlayTapTrace] and its lifecycle: milestones are
/// accepted only from events bound to that request's own sources, and the
/// trace (plus its PerfLog TimelineTask) is always closed — on position
/// advance, failure, cancellation, pause/stop, supersession, or terminal
/// playback without advancement.
class PlayTapTracker {
  PlayTapTrace? _active;
  String? lastCloseReason;

  PlayTapTrace? get active => _active;

  /// Starts a new request, closing any previous one as superseded.
  PlayTapTrace begin(String detail) {
    close('superseded');
    final trace = _active = PlayTapTrace();
    lastCloseReason = null;
    PerfLog.begin('play-tap', 'req#${trace.id} $detail');
    PerfFrames.begin('play-tap');
    return trace;
  }

  /// Called for every queue load. Any load supersedes the active trace (it
  /// closes, releasing its TimelineTask); only an auto-playing load starts a
  /// new one — a restore-style `autoPlay:false` load returns null.
  PlayTapTrace? beginForLoad({required bool autoPlay, required String detail}) {
    if (autoPlay) return begin(detail);
    close('superseded by non-autoplay load');
    return null;
  }

  /// Closes [trace] if its request ended without ever being armed (cancelled,
  /// superseded or its queue edited before its own sources were ready), so
  /// its TimelineTask is never left open. No-op for armed or stale traces.
  void closeIfUnarmed(PlayTapTrace trace) {
    if (trace.armed) return;
    close('request ended before its sources were ready', only: trace);
  }

  /// Closes the active trace. With [only], does nothing unless that exact
  /// trace is still the active one (a stale request must not close a newer).
  void close(String reason, {PlayTapTrace? only}) {
    final trace = _active;
    if (trace == null) return;
    if (only != null && !identical(only, trace)) return;
    _active = null;
    lastCloseReason = reason;
    trace.mark('closed: $reason');
    PerfLog.end('play-tap', 'req#${trace.id} $reason');
    PerfFrames.end('play-tap', after: const Duration(milliseconds: 300));
  }

  /// Evaluates the trace against the player's LIVE state. Cached stream
  /// events (which can still describe the previous source) are only used as
  /// triggers to call this — never as the data. Ignored until the trace is
  /// armed and the live current item carries this request's id.
  void onLive({
    required int? boundRequestId,
    required bool playing,
    required bool ready,
    required bool completed,
    required Duration position,
  }) {
    final trace = _active;
    if (trace == null || !trace.armed || boundRequestId != trace.id) return;
    if (completed) {
      close('terminal playback without position advance');
      return;
    }
    if (playing) {
      trace.markOnce('playing', 'first playing=true');
    } else if (trace.hasSeen('playing')) {
      close('paused/stopped before position advance');
      return;
    }
    if (ready) trace.markOnce('ready', 'first processingState=ready');
    if (position > Duration.zero && playing && ready) {
      trace.markOnce('advance', 'first position advance beyond zero');
      close('position advancing');
    }
  }
}
