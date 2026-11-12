import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/diagnostics/perf_log.dart';
import '../core/diagnostics/startup_log.dart';
import 'play_tap_trace.dart';

/// Android-only setting: whether audio playing/buffering at the moment the
/// user swipes Listeny away from Recents should be allowed to keep playing
/// (via the existing foreground service) instead of being stopped. Default
/// OFF. Not shown in Settings on iOS, whose task-termination model doesn't
/// offer the same guarantee this relies on.
///
/// Read directly from SharedPreferences wherever it's needed (here and in
/// the Settings screen) rather than injected from one owner, so
/// [ListenyAudioHandler.onTaskRemoved] — which can fire without the Settings
/// screen ever having been opened this session — always sees the current
/// value independently of that screen's widget lifecycle.
const keepPlayingWhenClosedPrefKey = 'keep_playing_when_closed';

/// Reads the "Keep playing when app is closed" setting, defaulting to OFF
/// when nothing has been saved yet (first launch, or on iOS where the
/// Settings toggle is hidden and this is never explicitly set).
bool keepPlayingWhenClosedEnabled(SharedPreferences prefs) =>
    prefs.getBool(keepPlayingWhenClosedPrefKey) ?? false;

void _debugLog(String message) {
  if (kDebugMode) debugPrint('[ListenyAudioHandler] $message');
}

/// Tracks how many playback-changing commands (play/replay, seek, skip,
/// queue mutations, queue/source replacement) are currently in flight on a
/// [ListenyAudioHandler].
///
/// Why this exists: a natural queue completion is handled by checking
/// [AudioPlayer.processingState] live, right before stopping — but with
/// just_audio 0.10.6, a newer command can have real async work of its own
/// (a seek's platform round-trip, a queue reload's `setAudioSources` call)
/// *before* `processingState` itself moves away from `completed`. A delayed
/// old completion arriving during that window would see `processingState`
/// still reporting `completed` and wrongly stop the newer operation. This
/// tracker closes that gap: every such command marks itself "pending" here
/// synchronously, before it awaits anything, and a queued completion is
/// required to check it (and, if pending, wait and recheck — see
/// [ListenyAudioHandler.handleQueueCompleted]) before acting.
///
/// A counter, not a boolean flag, so overlapping commands are handled
/// correctly: if command A finishes while command B is still pending, A's
/// release only decrements its own count — it can't clear the guard out
/// from under B.
@visibleForTesting
class PendingPlaybackChangeTracker {
  int _count = 0;
  Completer<void>? _idleCompleter;

  /// Whether any tracked command is currently in flight.
  bool get hasPending => _count > 0;

  void _release() {
    if (_count > 0) _count--;
    if (_count == 0) {
      _idleCompleter?.complete();
      _idleCompleter = null;
    }
  }

  /// Runs [operation] with this command marked pending for its whole
  /// duration — incremented synchronously here (before [operation] is even
  /// invoked, so strictly before its first await), decremented once it
  /// settles, success or failure. Use for commands whose own Future is
  /// already a good bound on the transition being protected (seek, skip,
  /// queue mutations, queue/source replacement).
  Future<T> track<T>(Future<T> Function() operation) async {
    _count++;
    try {
      return await operation();
    } finally {
      _release();
    }
  }

  /// Like [track], but for a command whose own Future is *not* a reliable
  /// bound on the transition being protected — just_audio 0.10.6's
  /// `AudioPlayer.play()` is the motivating case: its Future can remain
  /// unresolved well past playback actually starting (see
  /// [ListenyAudioHandler.play]'s doc comment), so waiting for it here
  /// would hold this guard for far longer than the startup transition it's
  /// meant to protect, silently blocking every later completion for the
  /// rest of the session. Instead, pending is released at the *first* of:
  /// [operation] itself settling, or [firstSignOfChange] firing — whichever
  /// happens first — while still returning (and propagating errors from)
  /// the one real [operation] call to the caller, unaffected by the race.
  Future<T> trackTransition<T>(
    Future<T> Function() operation,
    Future<void> firstSignOfChange,
  ) {
    _count++;
    var released = false;
    void releaseOnce() {
      if (released) return;
      released = true;
      _release();
    }

    firstSignOfChange.then((_) => releaseOnce(), onError: (_) => releaseOnce());
    final result = operation();
    result.then((_) => releaseOnce(), onError: (_) => releaseOnce());
    return result;
  }

  /// Resolves the next time [hasPending] becomes false — immediately if
  /// nothing is pending right now. Lets a deferred completion wait for
  /// whatever's currently in flight to settle, then recheck fresh state,
  /// instead of permanently discarding itself the moment it sees anything
  /// pending.
  Future<void> whenIdle() {
    if (!hasPending) return Future.value();
    return (_idleCompleter ??= Completer<void>()).future;
  }
}

/// Whether a pending (still-loading) auto-play request may still start
/// playback. Each load takes a generation from [begin]; [cancel] (pause, stop,
/// interruption) or a newer [begin] invalidates every older one.
@visibleForTesting
class AutoPlayIntent {
  int _generation = 0;

  int begin() => ++_generation;
  void cancel() => _generation++;
  bool isCurrent(int generation) => generation == _generation;
}

/// A [ShuffleOrder] that can insert a new/moved item at an exact, caller-
/// chosen *displayed* position instead of just_audio's [DefaultShuffleOrder]
/// behavior of always picking a random one. Without this, "play next",
/// queue inserts and reorders would land wherever this order randomly put
/// them rather than where the user actually asked for — the root cause of
/// shuffle-mode queue edits appearing to happen at the wrong spot.
///
/// Falls back to the same random placement as [DefaultShuffleOrder] when no
/// position was requested (e.g. a plain queue append), and is otherwise
/// behavior-identical to it (same shuffle()/removeRange()/clear()).
class DisplayOrderShuffleOrder extends ShuffleOrder {
  final Random _random;
  @override
  final indices = <int>[];

  /// The displayed position the next [insert] call should place its new
  /// index at; consumed (reset to null) by that call.
  int? pendingDisplayPosition;

  DisplayOrderShuffleOrder({Random? random}) : _random = random ?? Random();

  @override
  void shuffle({int? initialIndex}) {
    assert(initialIndex == null || indices.contains(initialIndex));
    if (indices.length <= 1) return;
    indices.shuffle(_random);
    if (initialIndex == null) return;
    const initialPos = 0;
    final swapPos = indices.indexOf(initialIndex);
    final swapIndex = indices[initialPos];
    indices[initialPos] = initialIndex;
    indices[swapPos] = swapIndex;
  }

  @override
  void insert(int index, int count) {
    for (var i = 0; i < indices.length; i++) {
      if (indices[i] >= index) indices[i] += count;
    }
    final requested = pendingDisplayPosition;
    pendingDisplayPosition = null;
    final newIndices = List.generate(count, (i) => index + i);
    for (var i = 0; i < newIndices.length; i++) {
      final insertionIndex = requested == null
          ? _random.nextInt(indices.length + 1)
          : (requested + i).clamp(0, indices.length);
      indices.insert(insertionIndex, newIndices[i]);
    }
  }

  @override
  void removeRange(int start, int end) {
    final count = end - start;
    final oldIndices = List.generate(count, (i) => start + i).toSet();
    indices.removeWhere(oldIndices.contains);
    for (var i = 0; i < indices.length; i++) {
      if (indices[i] >= end) indices[i] -= count;
    }
  }

  @override
  void clear() => indices.clear();
}

/// The real background audio engine, wired to the operating system through
/// `audio_service` (foreground service + MediaSession on Android, Now
/// Playing/MPRemoteCommandCenter on iOS) and `just_audio` (actual local
/// decode/playback).
///
/// This class only speaks `audio_service`'s vocabulary (`MediaItem`,
/// `AudioServiceRepeatMode`, ...). It knows nothing about this app's domain
/// model — [AudioServicePlaybackService] (in audio_service_playback_service.dart)
/// is the adapter that translates to/from the app's [Track]-based
/// `PlaybackService` interface the UI actually depends on.
///
/// Each queued [MediaItem] carries the real local file path in
/// `extras['filePath']`.
class ListenyAudioHandler extends BaseAudioHandler with SeekHandler {
  late final DisplayOrderShuffleOrder _shuffleOrder;
  late final AudioPlayer _player;
  final Expando<MediaItem> _mediaItemForSource = Expando<MediaItem>();
  final _pendingPlaybackChanges = PendingPlaybackChangeTracker();

  ListenyAudioHandler() {
    StartupLog.mark('ListenyAudioHandler constructor entered');
    _shuffleOrder = DisplayOrderShuffleOrder();
    _player = AudioPlayer(shuffleOrder: _shuffleOrder);
    StartupLog.mark('AudioPlayer constructed');
    // Not awaited, exactly as before; logFailure only observes and rethrows.
    unawaited(StartupLog.logFailure('ListenyAudioHandler._init', _init()));
  }

  Future<void> _init() async {
    StartupLog.mark('ListenyAudioHandler._init started');
    final session = await AudioSession.instance;
    StartupLog.mark('AudioSession instance obtained');
    await session.configure(const AudioSessionConfiguration.music());
    StartupLog.mark('AudioSession configured');

    // Real headphone/Bluetooth-unplugged handling: the OS fires this when the
    // active output device disappears (wired or Bluetooth) — pause instead of
    // continuing to blast audio out of the speaker unannounced.
    session.becomingNoisyEventStream.listen((_) => pause());

    // Real interruption handling: phone calls, another app's audio, Siri, etc.
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        // Also cancels a load that hasn't started playing yet.
        _cancelPendingAutoPlay('interruption');
        if (_player.playing) pause();
      }
    });

    // Broadcast the effective (shuffle-aware) sequence as the audio_service
    // queue, and keep `mediaItem` pointing at whichever entry is current.
    _effectiveSequence
        .map(
          (sequence) => sequence.map((s) => _mediaItemForSource[s]!).toList(),
        )
        .pipe(queue);

    Rx.combineLatest4<int?, List<MediaItem>, bool, List<int>?, MediaItem?>(
      _player.currentIndexStream,
      queue,
      _player.shuffleModeEnabledStream,
      _player.shuffleIndicesStream,
      (index, currentQueue, shuffleEnabled, shuffleIndices) {
        final effectiveIndex = _effectiveIndex(
          index,
          shuffleEnabled,
          shuffleIndices,
        );
        if (effectiveIndex == null || effectiveIndex >= currentQueue.length) {
          return null;
        }
        return currentQueue[effectiveIndex];
      },
    ).distinct().listen(mediaItem.add);

    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        _publishPlayerError('player error', e);
      },
    );
    _player.shuffleModeEnabledStream.listen(
      (_) => _broadcastState(_player.playbackEvent),
    );
    _player.processingStateStream.distinct().listen(
      _handleProcessingStateChanged,
    );
    StartupLog.mark('ListenyAudioHandler listeners/streams installed');
    StartupLog.mark('ListenyAudioHandler._init completed');
  }

  /// just_audio deliberately leaves [AudioPlayer.playing] true when a
  /// non-repeating queue finishes playing the last item — see
  /// [AudioPlayer.play]'s docs, which name exactly this listener as the
  /// supported way to react to that. Never fires while Repeat One/All is
  /// active: the platform player loops internally in those modes and never
  /// reaches [ProcessingState.completed]. This is a cheap pre-filter only —
  /// [handleQueueCompleted] re-checks the *live* state itself before acting,
  /// since [state] here can itself already be stale by the time this runs.
  void _handleProcessingStateChanged(ProcessingState state) {
    _debugLog('processingState -> $state');
    if (!isTerminalQueueCompletion(state)) return;
    unawaited(_restartQueueFromBeginning());
  }

  /// Product rule: when the queue plays out naturally, playback wraps around
  /// to the first track and keeps playing (instead of stopping). Re-checks
  /// the live state first so a stale `completed` event, or one racing a
  /// newer user command, never restarts anything.
  Future<void> _restartQueueFromBeginning() async {
    while (_pendingPlaybackChanges.hasPending) {
      await _pendingPlaybackChanges.whenIdle();
    }
    if (_player.processingState != ProcessingState.completed) return;
    final order = _player.effectiveIndices;
    if (order.isEmpty) return;
    try {
      await _pendingPlaybackChanges.track(
        () => _player.seek(Duration.zero, index: order.first),
      );
      if (!_player.playing) unawaited(_player.play());
    } catch (e) {
      _debugLog('restart from beginning failed: $e');
    }
  }

  /// Whether [state] means the whole queue has genuinely, naturally finished
  /// — extracted for testability. Only [ProcessingState.completed] ever
  /// qualifies: with Repeat One or Repeat All active, just_audio loops
  /// internally at the platform level and never surfaces `completed` at all
  /// (see [AudioPlayer.play]'s docs), so this can't misfire mid-repeat, and
  /// it's unaffected by whether shuffle is on since that only changes which
  /// item is "last".
  @visibleForTesting
  static bool isTerminalQueueCompletion(ProcessingState state) =>
      state == ProcessingState.completed;

  /// The real reaction to a genuine, natural end of a non-repeating queue —
  /// extracted (with its actions injected) so it's testable without a real
  /// platform player. [stop] is expected to be the handler's own [stop]
  /// (i.e. `_player.stop()`, awaited and left to propagate/be caught here),
  /// deliberately *not* [stopAndClear]: `_player.stop()` alone already sets
  /// `playing = false` (synchronously, before its own first await) *and*
  /// drives just_audio to `ProcessingState.idle` — which is what lets
  /// audio_service deactivate the MediaSession and tear down the
  /// notification/foreground state — without touching the loaded sources,
  /// so the queue/current item are preserved and nothing else (no separate
  /// pause/broadcast step) is needed. Never disposes the player.
  ///
  /// Reacts to a genuine, natural queue completion — deferring and
  /// rechecking rather than either stopping unconditionally or permanently
  /// discarding a possibly-stale event:
  ///
  /// 1. [currentProcessingState] — the *live* processingState, read fresh
  ///    each iteration rather than a value captured earlier (e.g. when the
  ///    completion was first observed by [_handleProcessingStateChanged]).
  ///    If it's no longer `completed`, this completion is stale — dropped.
  /// 2. [hasPendingPlaybackChange] — whether any playback-changing command
  ///    (play/replay, seek, skip, queue mutation, queue/source replacement
  ///    — see [PendingPlaybackChangeTracker]) is currently in flight. Live
  ///    processingState alone can't catch every case: with just_audio
  ///    0.10.6, those commands can have real async work of their own (a
  ///    seek's platform round-trip, a queue reload's `setAudioSources`
  ///    call) *before* processingState itself moves away from `completed`.
  ///    Rather than dropping the completion here — which could lose a
  ///    genuine completion that happens to race a pending command that
  ///    ultimately changes nothing — this *defers*: it awaits
  ///    [whenPendingPlaybackChangeSettles] and then loops back to
  ///    recheck both conditions against fresh state. This can't loop
  ///    forever in practice (it only continues while something is
  ///    genuinely still in flight) and never calls [stop] more than once:
  ///    the loop only ever exits by dropping (1) or by the single [stop]
  ///    call below.
  ///
  /// The remaining sub-tick window (between these checks and [stop] itself
  /// taking effect) is covered by just_audio's own platform-activation
  /// versioning, which silently no-ops a superseded deactivation call.
  @visibleForTesting
  static Future<void> handleQueueCompleted({
    required ProcessingState Function() currentProcessingState,
    required bool Function() hasPendingPlaybackChange,
    required Future<void> Function() whenPendingPlaybackChangeSettles,
    required Future<void> Function() stop,
    required void Function(String) debugLog,
  }) async {
    while (true) {
      if (!isTerminalQueueCompletion(currentProcessingState())) {
        debugLog('natural queue completion: stale (state moved on), dropping');
        return;
      }
      if (hasPendingPlaybackChange()) {
        debugLog(
          'natural queue completion: a newer playback-changing command is '
          'in flight, deferring and rechecking once it settles',
        );
        await whenPendingPlaybackChangeSettles();
        continue;
      }
      try {
        await stop();
        debugLog('natural queue completion: stopped (idle), queue preserved');
      } catch (e) {
        debugLog('natural queue completion: stop failed: $e');
      }
      return;
    }
  }

  /// Effective (shuffle-aware) sequence — mirrors just_audio's own shuffle
  /// order so the exposed queue always matches what will actually play next.
  Stream<List<IndexedAudioSource>> get _effectiveSequence =>
      Rx.combineLatest3<
            List<IndexedAudioSource>?,
            List<int>?,
            bool,
            List<IndexedAudioSource>?
          >(
            _player.sequenceStream,
            _player.shuffleIndicesStream,
            _player.shuffleModeEnabledStream,
            (sequence, shuffleIndices, shuffleEnabled) {
              if (sequence == null) return [];
              if (!shuffleEnabled) return sequence;
              if (shuffleIndices == null ||
                  shuffleIndices.length != sequence.length) {
                return null;
              }
              return shuffleIndices.map((i) => sequence[i]).toList();
            },
          )
          .whereType<List<IndexedAudioSource>>();

  int? _effectiveIndex(
    int? currentIndex,
    bool shuffleEnabled,
    List<int>? shuffleIndices,
  ) {
    if (!shuffleEnabled || shuffleIndices == null) return currentIndex;
    final inverse = List.filled(shuffleIndices.length, 0);
    for (var i = 0; i < shuffleIndices.length; i++) {
      inverse[shuffleIndices[i]] = i;
    }
    final idx = currentIndex ?? 0;
    return idx < inverse.length ? inverse[idx] : currentIndex;
  }

  /// Invalidated by every [loadAndPlay] and by pause/stop/interruption, so a
  /// stale or cancelled load never starts playback.
  final _autoPlayIntent = AutoPlayIntent();
  final _autoPlayCancelled = StreamController<String>.broadcast();

  AudioSource _itemToSource(MediaItem item) {
    final filePath = item.extras!['filePath'] as String;
    final source = AudioSource.uri(Uri.file(filePath), tag: item);
    _mediaItemForSource[source] = item;
    return source;
  }

  /// Replaces the whole queue, positioned at [startIndex]. Starts playing
  /// immediately unless [autoPlay] is false, which loads/prepares the queue
  /// (so the UI, MediaSession and notification all reflect it) without ever
  /// transitioning into a playing state — needed for restoring a saved
  /// "paused" session without an audible blip of real playback.
  ///
  /// Completes once the queue is loaded and playback has been *started*
  /// (see [startPlayback]) — never when playback ends. [trace] is perf-only.
  Future<void> loadAndPlay(
    List<MediaItem> items, {
    int startIndex = 0,
    bool autoPlay = true,
    PlayTapTrace? trace,
  }) async {
    final generation = _autoPlayIntent.begin();
    if (trace != null && PerfLog.enabled) {
      final hadSources = _player.audioSources.isNotEmpty;
      final loadedIds = queue.value.map((i) => i.id).toList();
      final sameQueue =
          listEquals(loadedIds, items.map((i) => i.id).toList()) &&
          _player.currentIndex == startIndex;
      trace.mark(
        'player initialized/active=$hadSources '
        'state=${_player.processingState.name} playing=${_player.playing} '
        'requestedQueueMatchesLoaded=$sameQueue',
      );
    }
    StartupLog.restoreMark('setAudioSources START');
    try {
      await runLoadAndPlay(
        intent: _autoPlayIntent,
        generation: generation,
        willAutoPlay: items.isNotEmpty && autoPlay,
        setSources: () {
          final sources = trace == null
              ? items.map(_itemToSource).toList()
              : trace.phase('AudioSource creation', () {
                  return items.map(_itemToSource).toList();
                });
          // Tracked: replacing the queue/sources can have real async work of
          // its own before processingState moves off `completed` — see
          // [PendingPlaybackChangeTracker].
          Future<void> set() => _pendingPlaybackChanges.track(
            () => _player.setAudioSources(
              sources,
              initialIndex: items.isEmpty ? null : startIndex,
              initialPosition: Duration.zero,
            ),
          );
          return trace == null
              ? set()
              : trace.phaseAsync('setAudioSources()', set);
        },
        play: () {
          trace?.mark('play() CALLED');
          if (trace != null && PerfLog.enabled) {
            _logCurrentFile(trace, items[startIndex]);
          }
          return play();
        },
        pauseBeforeLoad: () async {
          if (_player.playing) await _player.pause();
        },
        firstPlaying: () => _player.playingStream.firstWhere((p) => p),
        onLateError: (e, s) =>
            _publishPlayerError('play() failed after start', e),
        trace: trace,
      );
    } finally {
      StartupLog.restoreMark('setAudioSources END');
    }
  }

  /// The testable core of [loadAndPlay]: load via [setSources], then — only if
  /// [willAutoPlay] and [intent] still holds [generation] (no pause, stop,
  /// interruption or newer load happened meanwhile) — start playback with
  /// [startPlayback].
  @visibleForTesting
  static Future<void> runLoadAndPlay({
    required AutoPlayIntent intent,
    required int generation,
    required bool willAutoPlay,
    required Future<void> Function() setSources,
    required Future<void> Function() play,
    required Future<void> Function() firstPlaying,
    required void Function(Object error, StackTrace stack) onLateError,
    Future<void> Function()? pauseBeforeLoad,
    PlayTapTrace? trace,
  }) async {
    // autoPlay:false must end paused even if the player was already playing
    // (just_audio keeps playing=true across source replacement).
    if (!willAutoPlay) {
      await pauseBeforeLoad?.call();
      // A newer load/cancel may have arrived while pausing; this stale
      // request must not replace the newer one's sources.
      if (!intent.isCurrent(generation)) {
        trace?.mark('superseded while pausing; not loading sources');
        return;
      }
    }
    try {
      await setSources();
      trace?.arm();
    } on PlayerInterruptedException {
      // just_audio throws this deliberately when a second loadAndPlay call
      // (e.g. tapping another song before the first finished loading)
      // supersedes this one — the newer call already owns the player state,
      // so this older, now-stale request just backs off silently.
      trace?.mark('superseded during setAudioSources (interrupted)');
      return;
    }
    if (!willAutoPlay) return;
    if (!intent.isCurrent(generation)) {
      // Cancelled (pause/stop/interruption) or superseded while loading: this
      // stale request must never start playback.
      trace?.mark('auto-play cancelled/superseded; not calling play()');
      return;
    }
    await startPlayback(
      play: play,
      firstPlaying: firstPlaying(),
      onLateError: (e, s) {
        // A failure of an old request must never be published into the state
        // of whatever is playing now.
        if (intent.isCurrent(generation)) {
          onLateError(e, s);
        } else {
          trace?.mark('ignored late play() error from a stale request');
        }
      },
    );
    trace?.mark('loadAndPlay completed (playback started, play() not awaited)');
  }

  /// Cancels any pending (still-loading) [loadAndPlay] auto-start. Does not
  /// affect an explicit [play] (a legitimate resume) or later loads.
  void _cancelPendingAutoPlay(String reason) {
    _autoPlayIntent.cancel();
    _autoPlayCancelled.add(reason);
  }

  /// Fires (with a reason) whenever pending auto-play was cancelled by
  /// pause/stop/interruption. Perf diagnostics only.
  Stream<String> get autoPlayCancelled => _autoPlayCancelled.stream;

  /// Perf-only: the player's live state (not cached stream events) for
  /// attributing play-tap milestones to the request whose source is current.
  ({
    int? requestId,
    bool playing,
    bool ready,
    bool completed,
    Duration position,
  })
  liveSnapshot() {
    final i = _player.currentIndex;
    final seq = _player.sequence;
    final item = (i != null && i < seq.length)
        ? _mediaItemForSource[seq[i]]
        : null;
    final ps = _player.processingState;
    return (
      requestId: item?.extras?[playTapRequestExtrasKey] as int?,
      playing: _player.playing,
      ready: ps == ProcessingState.ready,
      completed: ps == ProcessingState.completed,
      position: _player.position,
    );
  }

  /// Publishes a playback failure through the same error state the player's
  /// own event-stream errors use.
  void _publishPlayerError(String where, Object e) {
    _debugLog('$where: $e');
    _autoPlayCancelled.add('error');
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
      ),
    );
  }

  /// Perf-only: logs the extension and size of the file about to play —
  /// nothing else about it (no path, no name).
  void _logCurrentFile(PlayTapTrace trace, MediaItem item) {
    final path = item.extras?['filePath'] as String?;
    if (path == null) return;
    final dot = path.lastIndexOf('.');
    final sep = path.lastIndexOf(RegExp(r'[\\/]'));
    final ext = dot > sep ? path.substring(dot + 1).toLowerCase() : '(none)';
    File(path).length().then(
      (bytes) => trace.mark('track ext=$ext size=${bytes}B'),
      onError: (_) => trace.mark('track ext=$ext size=unknown'),
    );
  }

  /// Starts playback and completes as soon as it has *started* — not when it
  /// ends. just_audio's `play()` Future can stay pending for the whole
  /// playback lifetime, so awaiting it as "queue preparation" is wrong.
  /// Completes at the first of: [play]'s Future settling, or [firstPlaying]
  /// firing (playing became true).
  ///
  /// * An error from [play] before that point propagates to the caller.
  /// * An error after it (the Future is still live) goes to [onLateError]
  ///   instead of becoming an unhandled async error.
  /// * [PlayerInterruptedException] (a newer command cancelled this one) is
  ///   treated as a silent cancellation, not an error.
  @visibleForTesting
  static Future<void> startPlayback({
    required Future<void> Function() play,
    required Future<void> firstPlaying,
    required void Function(Object error, StackTrace stack) onLateError,
  }) {
    final started = Completer<void>();
    firstPlaying.then((_) {
      if (!started.isCompleted) started.complete();
    }, onError: (_) {});
    Future<void> playFuture;
    try {
      playFuture = play();
    } catch (e, s) {
      if (e is PlayerInterruptedException) return Future.value();
      return Future.error(e, s);
    }
    playFuture.then(
      (_) {
        if (!started.isCompleted) started.complete();
      },
      onError: (Object e, StackTrace s) {
        if (e is PlayerInterruptedException) {
          if (!started.isCompleted) started.complete();
        } else if (!started.isCompleted) {
          started.completeError(e, s);
        } else {
          onLateError(e, s);
        }
      },
    );
    return started.future;
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // Appends to the end of the *displayed* order, matching what "add to
    // queue" means visually, instead of leaving the shuffle order to drop it
    // at a random spot (just_audio's default insert behavior).
    _shuffleOrder.pendingDisplayPosition = _shuffleOrder.indices.length;
    // Tracked: extends a queue that may have just been reported `completed`
    // — see [PendingPlaybackChangeTracker].
    await _pendingPlaybackChanges.track(
      () => _player.addAudioSource(_itemToSource(mediaItem)),
    );
  }

  /// Converts a displayed (shuffle-effective) queue index to the underlying
  /// player index — the same mapping [skipToQueueItem] already relies on.
  /// Only ever called with an index of an *existing* displayed item (never
  /// one past the end), so it's always within [AudioPlayer.shuffleIndices]'
  /// bounds.
  int _underlyingIndex(int displayedIndex) => _player.shuffleModeEnabled
      ? _player.shuffleIndices[displayedIndex]
      : displayedIndex;

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    // The displayed position to insert at can legitimately be one past the
    // last item (inserting right after the current track when it's last),
    // which is out of range for a shuffleIndices[] lookup — so unlike
    // [_underlyingIndex], clamp here instead of indexing directly.
    final displayLength = _shuffleOrder.indices.length;
    final displayedIndex = index.clamp(0, displayLength);
    _shuffleOrder.pendingDisplayPosition = displayedIndex;
    // While shuffled, the *displayed* position above is what the user
    // actually asked for; the raw/underlying slot is cosmetic (it only
    // matters once shuffle is turned off later), so just append there
    // rather than translating a possibly-out-of-range displayed index.
    final underlyingIndex = _player.shuffleModeEnabled
        ? _player.audioSources.length
        : displayedIndex;
    // Tracked: can insert right next to (or effectively replace) the
    // current/just-completed item — see [PendingPlaybackChangeTracker].
    await _pendingPlaybackChanges.track(
      () =>
          _player.insertAudioSource(underlyingIndex, _itemToSource(mediaItem)),
    );
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    // Found directly in the player's own (unshuffled) sequence, rather than
    // looking up a displayed-order index and reusing it against the
    // underlying list — that mismatch was what could remove the wrong
    // track (including, via clearUpcoming, the currently playing one).
    final underlyingIndex = _player.sequence.indexWhere(
      (s) => _mediaItemForSource[s] == mediaItem,
    );
    if (underlyingIndex == -1) return;
    // Tracked: this is also how "clear upcoming" removes tracks, and it can
    // remove the current/just-completed item itself — see
    // [PendingPlaybackChangeTracker].
    await _pendingPlaybackChanges.track(
      () => _player.removeAudioSourceAt(underlyingIndex),
    );
  }

  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    final displayLength = _shuffleOrder.indices.length;
    if (displayLength == 0) return;
    final clampedNewIndex = newIndex.clamp(0, displayLength - 1);
    _shuffleOrder.pendingDisplayPosition = clampedNewIndex;
    // Tracked: reordering can shift which source is "current" — see
    // [PendingPlaybackChangeTracker].
    await _pendingPlaybackChanges.track(
      () => _player.moveAudioSource(
        _underlyingIndex(currentIndex),
        _underlyingIndex(clampedNewIndex),
      ),
    );
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _player.audioSources.length) return;
    final target = _player.shuffleModeEnabled
        ? _player.shuffleIndices[index]
        : index;
    // Tracked: goes through the same seek path as skipToNext/Previous —
    // see [PendingPlaybackChangeTracker].
    await _pendingPlaybackChanges.track(
      () => _player.seek(Duration.zero, index: target),
    );
  }

  /// Tracked via [PendingPlaybackChangeTracker.trackTransition], not
  /// [PendingPlaybackChangeTracker.track] — just_audio 0.10.6's
  /// `AudioPlayer.play()` Future is not a reliable bound on "the startup
  /// transition is done": it can remain unresolved well past playback
  /// actually starting (it resolves once its internal `playCompleter`
  /// completes, which in some paths doesn't happen until later player
  /// activity settles). Waiting for the full Future here would hold the
  /// pending-change guard for the rest of the whole playback session,
  /// silently deferring every later genuine completion instead of just the
  /// one this call is actually meant to protect. Released instead as soon
  /// as processingState visibly changes from what it was at call time (or
  /// the call itself settles, whichever comes first) — a bounded signal
  /// that the transition this call represents has actually taken hold.
  @override
  Future<void> play() {
    final stateAtCall = _player.processingState;
    return _pendingPlaybackChanges.trackTransition(
      () => _player.play(),
      _player.processingStateStream.firstWhere((s) => s != stateAtCall),
    );
  }

  @override
  Future<void> pause() {
    _cancelPendingAutoPlay('pause');
    return _player.pause();
  }

  @override
  Future<void> seek(Duration position) =>
      _pendingPlaybackChanges.track(() => _player.seek(position));

  /// The effective (shuffle-aware) index a MANUAL "advance to next" request
  /// should land on — deliberately not just_audio's own [AudioPlayer.
  /// nextIndex], which under [LoopMode.one] returns the current index
  /// unchanged (see its doc comment: `_getRelativeIndex` short-circuits to
  /// `currentIndex` whenever `loopMode == LoopMode.one`). That's the right
  /// answer for a track *naturally* looping, but a user pressing Next
  /// unambiguously means "move on" — not "restart what's already repeating".
  /// This mirrors just_audio's own algorithm exactly, minus that one
  /// short-circuit: Repeat One therefore behaves like Repeat All here
  /// (advances, wrapping at the end), and Repeat Off does not wrap — at the
  /// last item it returns null (nothing to advance to), same as just_audio's
  /// own boundary behavior, so Next never restarts the current track.
  @visibleForTesting
  static int? manualNextIndex({
    required int? currentIndex,
    required List<int> effectiveIndices,
    required LoopMode loopMode,
  }) {
    if (currentIndex == null || effectiveIndices.isEmpty) return null;
    final pos = effectiveIndices.indexOf(currentIndex);
    if (pos == -1) return null;
    var newPos = pos + 1;
    if (newPos >= effectiveIndices.length) {
      if (loopMode == LoopMode.off) return null;
      newPos %= effectiveIndices.length;
    }
    return effectiveIndices[newPos];
  }

  @override
  Future<void> skipToNext() => _pendingPlaybackChanges.track(() async {
    final target = manualNextIndex(
      currentIndex: _player.currentIndex,
      effectiveIndices: _player.effectiveIndices,
      // Next always advances and wraps from the last track to the first,
      // whatever the repeat mode.
      loopMode: LoopMode.all,
    );
    if (target == null) return;
    await _player.seek(Duration.zero, index: target);
  });

  /// Previous deliberately keeps just_audio's own [AudioPlayer.
  /// seekToPrevious] behavior unchanged (including restarting the current
  /// track under Repeat One, via the same `_getRelativeIndex` short-circuit
  /// [skipToNext] above intentionally bypasses) — that's the existing,
  /// intended product behavior for Previous; only Next was reported broken.
  @override
  Future<void> skipToPrevious() => _pendingPlaybackChanges.track(() async {
    final order = _player.effectiveIndices;
    final current = _player.currentIndex;
    final pos = current == null ? -1 : order.indexOf(current);
    if (pos == -1) return;
    // Past the first few seconds: restart this track. Otherwise (a second
    // press right after) go to the previous one, wrapping from the first
    // track to the last.
    if (_player.position > previousRestartThreshold) {
      await _player.seek(Duration.zero);
      return;
    }
    final target = order[(pos - 1 + order.length) % order.length];
    await _player.seek(Duration.zero, index: target);
  });

  /// Previous restarts the current track when it is further in than this.
  @visibleForTesting
  static const previousRestartThreshold = Duration(seconds: 3);

  /// Clamps a relative seek ([offset] from [position]) into `[0, duration]`
  /// — except when [duration] is unknown/zero, in which case the upper
  /// bound is skipped entirely rather than wrongly clamping every forward
  /// seek down to zero (which is what audio_service's own [SeekHandler]
  /// mixin default does: it treats a null `mediaItem.duration` as
  /// `Duration.zero` and then clamps `newPosition > duration` — true for
  /// almost any forward seek — straight back down to zero).
  @visibleForTesting
  static Duration clampedSeekTarget({
    required Duration position,
    required Duration offset,
    required Duration? duration,
  }) {
    var target = position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (duration != null && duration > Duration.zero && target > duration) {
      target = duration;
    }
    return target;
  }

  Future<void> _seekBy(Duration offset) => seek(
    clampedSeekTarget(
      position: _player.position,
      offset: offset,
      duration: _player.duration,
    ),
  );

  /// +10s. Overrides the [SeekHandler] mixin default (see [clampedSeekTarget]
  /// for why) — this is what both the Now Playing ±10 buttons (via
  /// [AudioServicePlaybackService]) and, where the platform exposes it, the
  /// system media notification/Control Center fast-forward action go
  /// through, so they always agree.
  @override
  Future<void> fastForward() => _seekBy(const Duration(seconds: 10));

  /// -10s. See [fastForward].
  @override
  Future<void> rewind() => _seekBy(const Duration(seconds: -10));

  @override
  Future<void> stop() async {
    _cancelPendingAutoPlay('stop');
    await _player.stop();
  }

  /// Stops and clears the loaded queue entirely (not just pausing) — the
  /// audio_service `stop()` above leaves the current item loaded, which
  /// would keep the mini-player showing it; this actually empties the
  /// player so `mediaItem`/`queue` resolve to null/empty.
  Future<void> stopAndClear() async {
    _cancelPendingAutoPlay('stop');
    await _player.stop();
    await _player.setAudioSources(const []);
  }

  /// Called by the OS when the user swipes the app away from Recents.
  ///
  /// Default (the "Keep playing when app is closed" setting is OFF): this
  /// app shuts down completely on swipe-away, same as before this setting
  /// existed. stopAndClear() transitions the player to ProcessingState.idle,
  /// which audio_service's own internals watch for and use as the trigger to
  /// tear down the foreground service, MediaSession and notification — the
  /// same full teardown a real "quit" would do, not just a pause.
  ///
  /// When the setting is ON, a real background-audio app keeping its
  /// foreground service (and playback) alive through this is the normal,
  /// intended use of a foreground service — but only while there's actually
  /// something playing; a paused/idle/completed session has nothing left to
  /// keep alive for, so it still shuts down like the OFF case.
  @override
  Future<void> onTaskRemoved() async {
    final keepPlayingWhenClosed = await _keepPlayingWhenClosed();
    final playing = _player.playing;
    final processingState = _player.processingState;
    final shouldStop = shouldStopOnTaskRemoved(
      keepPlayingWhenClosed: keepPlayingWhenClosed,
      playing: playing,
      processingState: processingState,
    );
    _debugLog(
      'onTaskRemoved: keepPlayingWhenClosed=$keepPlayingWhenClosed '
      'playing=$playing processingState=$processingState '
      'hasMediaItem=${mediaItem.valueOrNull != null} '
      '-> ${shouldStop ? "stop" : "continue playing"}',
    );
    // Delegates the actual decide-then-act call to the same function the
    // tests exercise directly, so a regression that inserts an unconditional
    // stop somewhere in this method (instead of going through this call)
    // would leave the tested code path untouched but still be visible as a
    // behavior change here — there is deliberately no other call to
    // stopAndClear/stop/dispose anywhere in this method.
    await handleTaskRemoved(
      keepPlayingWhenClosed: keepPlayingWhenClosed,
      playing: playing,
      processingState: processingState,
      stopAndClear: stopAndClear,
    );
  }

  Future<bool> _keepPlayingWhenClosed() async {
    final prefs = await SharedPreferences.getInstance();
    return keepPlayingWhenClosedEnabled(prefs);
  }

  /// Pure decision behind [onTaskRemoved], extracted so it's testable
  /// without a real platform player. Stops whenever the setting is off, and
  /// otherwise stops unless audio is genuinely actively playing/buffering —
  /// paused, idle and completed sessions never keep the service alive, and
  /// [processingState] is checked in addition to [playing] because
  /// just_audio can leave `playing` true after a queue naturally completes
  /// (see [_handleProcessingStateChanged]).
  @visibleForTesting
  static bool shouldStopOnTaskRemoved({
    required bool keepPlayingWhenClosed,
    required bool playing,
    required ProcessingState processingState,
  }) {
    if (!keepPlayingWhenClosed) return true;
    if (!playing) return true;
    if (processingState == ProcessingState.idle ||
        processingState == ProcessingState.completed) {
      return true;
    }
    return false;
  }

  /// The real decide-then-act step behind [onTaskRemoved] — computes
  /// [shouldStopOnTaskRemoved] and, only if it says to, calls [stopAndClear]
  /// (injected so this is testable without a real platform player). Both the
  /// real [onTaskRemoved] and its tests call this exact function, so there
  /// is only one place the ordering (decide, then act) can drift from.
  @visibleForTesting
  static Future<void> handleTaskRemoved({
    required bool keepPlayingWhenClosed,
    required bool playing,
    required ProcessingState processingState,
    required Future<void> Function() stopAndClear,
  }) async {
    if (shouldStopOnTaskRemoved(
      keepPlayingWhenClosed: keepPlayingWhenClosed,
      playing: playing,
      processingState: processingState,
    )) {
      await stopAndClear();
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    if (enabled) await _player.shuffle();
    await _player.setShuffleModeEnabled(enabled);
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    const loopModes = {
      AudioServiceRepeatMode.none: LoopMode.off,
      AudioServiceRepeatMode.one: LoopMode.one,
      AudioServiceRepeatMode.all: LoopMode.all,
      AudioServiceRepeatMode.group: LoopMode.all,
    };
    await _player.setLoopMode(loopModes[repeatMode]!);
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final effectiveIndex = _effectiveIndex(
      event.currentIndex,
      _player.shuffleModeEnabled,
      _player.shuffleModeEnabled ? _player.shuffleIndices : null,
    );
    playbackState.add(
      playbackState.value.copyWith(
        // Just previous / play-pause / next. Android 13+ lays the media
        // notification and lock-screen player out itself (previous and next in
        // fixed slots, play/pause as the big button); any extra action
        // (stop, rewind, fast-forward) was squeezed into leftover slots in a
        // jumbled order or dropped, so the controls are kept to these three.
        // Seeking stays available through the progress bar.
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: effectiveIndex,
      ),
    );
  }

  /// Applies [updates] (track id -> a function producing the refreshed
  /// [MediaItem]) to every matching queued item — used to reflect a library
  /// edit (e.g. an album rename) in an already-loaded queue WITHOUT
  /// reloading the audio, resetting playback position, or disturbing
  /// shuffle/order. Updates `queue`/`mediaItem` (and the source-item
  /// mapping used to rebuild them) directly rather than waiting for the
  /// next natural just_audio sequence/shuffle event, which might never come
  /// during a session that makes no further playback changes.
  void refreshTrackMetadata(
    Map<String, MediaItem Function(MediaItem)> updates,
  ) {
    if (updates.isEmpty) return;
    for (final source in _player.sequence) {
      final item = _mediaItemForSource[source];
      if (item == null) continue;
      final updater = updates[item.id];
      if (updater != null) _mediaItemForSource[source] = updater(item);
    }
    final currentQueue = queue.valueOrNull ?? const <MediaItem>[];
    queue.add([
      for (final item in currentQueue) updates[item.id]?.call(item) ?? item,
    ]);
    final current = mediaItem.valueOrNull;
    if (current != null) {
      final currentUpdater = updates[current.id];
      if (currentUpdater != null) mediaItem.add(currentUpdater(current));
    }
  }

  Future<void> disposePlayer() async {
    await _player.dispose();
  }
}
