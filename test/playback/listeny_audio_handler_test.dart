import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:listeny/playback/listeny_audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('keepPlayingWhenClosedEnabled (setting default + persistence)', () {
    test('defaults to OFF on first launch (nothing saved)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(keepPlayingWhenClosedEnabled(prefs), isFalse);
    });

    test('an explicitly saved ON value round-trips as ON', () async {
      SharedPreferences.setMockInitialValues({
        keepPlayingWhenClosedPrefKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(keepPlayingWhenClosedEnabled(prefs), isTrue);
    });

    test('an explicitly saved OFF value round-trips as OFF', () async {
      SharedPreferences.setMockInitialValues({
        keepPlayingWhenClosedPrefKey: false,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(keepPlayingWhenClosedEnabled(prefs), isFalse);
    });

    test('an actual write/read round trip (not just a seeded initial value) '
        'persists and reflects a live change', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(keepPlayingWhenClosedEnabled(prefs), isFalse);

      await prefs.setBool(keepPlayingWhenClosedPrefKey, true);
      expect(keepPlayingWhenClosedEnabled(prefs), isTrue);

      await prefs.setBool(keepPlayingWhenClosedPrefKey, false);
      expect(keepPlayingWhenClosedEnabled(prefs), isFalse);
    });
  });

  group('shouldStopOnTaskRemoved (keep-playing-when-closed setting)', () {
    test('setting OFF always stops, even while actively playing', () {
      expect(
        ListenyAudioHandler.shouldStopOnTaskRemoved(
          keepPlayingWhenClosed: false,
          playing: true,
          processingState: ProcessingState.ready,
        ),
        isTrue,
      );
    });

    test('setting OFF stops while paused', () {
      expect(
        ListenyAudioHandler.shouldStopOnTaskRemoved(
          keepPlayingWhenClosed: false,
          playing: false,
          processingState: ProcessingState.ready,
        ),
        isTrue,
      );
    });

    test('setting ON + actively playing (ready) continues', () {
      expect(
        ListenyAudioHandler.shouldStopOnTaskRemoved(
          keepPlayingWhenClosed: true,
          playing: true,
          processingState: ProcessingState.ready,
        ),
        isFalse,
      );
    });

    test('setting ON + buffering while playing continues', () {
      expect(
        ListenyAudioHandler.shouldStopOnTaskRemoved(
          keepPlayingWhenClosed: true,
          playing: true,
          processingState: ProcessingState.buffering,
        ),
        isFalse,
      );
    });

    test('setting ON + paused stops', () {
      expect(
        ListenyAudioHandler.shouldStopOnTaskRemoved(
          keepPlayingWhenClosed: true,
          playing: false,
          processingState: ProcessingState.ready,
        ),
        isTrue,
      );
    });

    test('setting ON + idle stops', () {
      expect(
        ListenyAudioHandler.shouldStopOnTaskRemoved(
          keepPlayingWhenClosed: true,
          playing: false,
          processingState: ProcessingState.idle,
        ),
        isTrue,
      );
    });

    test(
      'setting ON + completed stops even if playing is still (wrongly) true',
      () {
        // just_audio leaves `playing` true across natural queue completion
        // by design; this is what stops that from being mistaken for
        // "actively playing" and keeping the service alive forever.
        expect(
          ListenyAudioHandler.shouldStopOnTaskRemoved(
            keepPlayingWhenClosed: true,
            playing: true,
            processingState: ProcessingState.completed,
          ),
          isTrue,
        );
      },
    );

    test('setting ON + loading while playing continues', () {
      expect(
        ListenyAudioHandler.shouldStopOnTaskRemoved(
          keepPlayingWhenClosed: true,
          playing: true,
          processingState: ProcessingState.loading,
        ),
        isFalse,
      );
    });
  });

  group('handleTaskRemoved (the real decide-then-act path onTaskRemoved '
      'delegates to)', () {
    // A regression that inserted an unconditional stopAndClear() before the
    // keep-playing decision would make every one of these fail: cases A/B
    // assert zero stop calls, and every case relies on stopAndClear only
    // ever being invoked from behind the shouldStopOnTaskRemoved check
    // inside handleTaskRemoved itself.
    Future<int> run({
      required bool keepPlayingWhenClosed,
      required bool playing,
      required ProcessingState processingState,
    }) async {
      var stopAndClearCalls = 0;
      await ListenyAudioHandler.handleTaskRemoved(
        keepPlayingWhenClosed: keepPlayingWhenClosed,
        playing: playing,
        processingState: processingState,
        stopAndClear: () async {
          stopAndClearCalls++;
        },
      );
      return stopAndClearCalls;
    }

    test('A: ON + actively playing + ready -> no stop/clear', () async {
      final calls = await run(
        keepPlayingWhenClosed: true,
        playing: true,
        processingState: ProcessingState.ready,
      );
      expect(calls, 0);
    });

    test(
      'B: ON + actively playing + buffering/loading -> no stop/clear',
      () async {
        expect(
          await run(
            keepPlayingWhenClosed: true,
            playing: true,
            processingState: ProcessingState.buffering,
          ),
          0,
        );
        expect(
          await run(
            keepPlayingWhenClosed: true,
            playing: true,
            processingState: ProcessingState.loading,
          ),
          0,
        );
      },
    );

    test('C: OFF + active playback -> stops/clears', () async {
      final calls = await run(
        keepPlayingWhenClosed: false,
        playing: true,
        processingState: ProcessingState.ready,
      );
      expect(calls, 1);
    });

    test('D: ON + paused -> stops/clears', () async {
      final calls = await run(
        keepPlayingWhenClosed: true,
        playing: false,
        processingState: ProcessingState.ready,
      );
      expect(calls, 1);
    });

    test('E: ON + idle/completed -> stops/clears', () async {
      expect(
        await run(
          keepPlayingWhenClosed: true,
          playing: false,
          processingState: ProcessingState.idle,
        ),
        1,
      );
      expect(
        await run(
          keepPlayingWhenClosed: true,
          playing: true,
          processingState: ProcessingState.completed,
        ),
        1,
      );
    });
  });

  group('isTerminalQueueCompletion (natural end-of-queue handling)', () {
    test('only ProcessingState.completed is treated as terminal', () {
      for (final state in ProcessingState.values) {
        expect(
          ListenyAudioHandler.isTerminalQueueCompletion(state),
          state == ProcessingState.completed,
          reason:
              '$state should ${state == ProcessingState.completed ? '' : 'not '}'
              'be treated as terminal completion',
        );
      }
    });

    test('never fires for the states Repeat One/All/shuffle actually produce '
        '(just_audio loops internally and never emits completed for them)', () {
      expect(
        ListenyAudioHandler.isTerminalQueueCompletion(ProcessingState.ready),
        isFalse,
      );
      expect(
        ListenyAudioHandler.isTerminalQueueCompletion(
          ProcessingState.buffering,
        ),
        isFalse,
      );
    });
  });

  group('PendingPlaybackChangeTracker (the real seam play/seek/skip/reload '
      'use to mark themselves in flight)', () {
    test('hasPending is false with nothing tracked', () {
      expect(PendingPlaybackChangeTracker().hasPending, isFalse);
    });

    test('hasPending is true for the whole duration of track(), including '
        'before the tracked operation itself resolves', () async {
      final tracker = PendingPlaybackChangeTracker();
      final completer = Completer<void>();

      final future = tracker.track(() => completer.future);
      // Not awaited yet — the increment happens synchronously, before the
      // tracked operation's first await, so this is already true here.
      expect(tracker.hasPending, isTrue);

      completer.complete();
      await future;
      expect(tracker.hasPending, isFalse);
    });

    test('hasPending stays true after a failed operation only until its '
        'finally block runs, same as a successful one', () async {
      final tracker = PendingPlaybackChangeTracker();
      final completer = Completer<void>();

      final future = tracker.track(() => completer.future);
      expect(tracker.hasPending, isTrue);

      completer.completeError(StateError('platform failure'));
      await expectLater(future, throwsStateError);
      expect(tracker.hasPending, isFalse);
    });

    test('E: overlapping operations — an earlier one finishing does not clear '
        'the guard while a later one is still pending (this is exactly why '
        'a counter is used instead of a boolean flag)', () async {
      final tracker = PendingPlaybackChangeTracker();
      final completerA = Completer<void>();
      final completerB = Completer<void>();

      final futureA = tracker.track(() => completerA.future);
      final futureB = tracker.track(() => completerB.future);
      expect(tracker.hasPending, isTrue);

      completerA.complete();
      await futureA;
      // B is still pending — a boolean flag would have been wrongly
      // cleared by A's `finally` here.
      expect(tracker.hasPending, isTrue);

      completerB.complete();
      await futureB;
      expect(tracker.hasPending, isFalse);
    });

    test(
      'trackTransition releases on the first sign of change, even while '
      'the tracked operation itself is still completely unresolved — this '
      'is the mechanism play() uses so a stuck/slow play() Future (see its '
      'doc comment) cannot hold this guard for the whole playback session',
      () async {
        final tracker = PendingPlaybackChangeTracker();
        final operation = Completer<void>(); // deliberately never completed
        final firstSignOfChange = Completer<void>();

        final future = tracker.trackTransition(
          () => operation.future,
          firstSignOfChange.future,
        );
        expect(tracker.hasPending, isTrue);

        firstSignOfChange.complete();
        // Let the release's microtask run without waiting on `operation`,
        // which never resolves.
        await Future<void>.delayed(Duration.zero);
        expect(tracker.hasPending, isFalse);
        expect(operation.isCompleted, isFalse);

        // The caller's Future (mirrors play()'s own return value) is
        // unaffected by the race and only settles when the real operation
        // does.
        operation.complete();
        await future;
      },
    );

    test('trackTransition releases on the operation settling first, if that '
        'happens before any sign of change', () async {
      final tracker = PendingPlaybackChangeTracker();
      final operation = Completer<void>();
      final firstSignOfChange = Completer<void>(); // never fires

      final future = tracker.trackTransition(
        () => operation.future,
        firstSignOfChange.future,
      );
      expect(tracker.hasPending, isTrue);

      operation.complete();
      await future;
      expect(tracker.hasPending, isFalse);
    });
  });

  group('handleQueueCompleted (the real natural-completion reaction '
      '_handleProcessingStateChanged delegates to)', () {
    // Every call below supplies whenPendingPlaybackChangeSettles even when
    // nothing is pending, matching how the real call site always provides
    // it (ListenyAudioHandler._pendingPlaybackChanges.whenIdle).
    Future<void> neverSettles() => Completer<void>().future;

    test('D: genuine completion with nothing pending: stops once (which is '
        'what reaches idle + playing=false — see the doc comment on '
        'handleQueueCompleted), never clears or disposes (only `stop` is ever '
        'called, never stopAndClear/dispose)', () async {
      var stopCalls = 0;

      await ListenyAudioHandler.handleQueueCompleted(
        currentProcessingState: () => ProcessingState.completed,
        hasPendingPlaybackChange: () => false,
        whenPendingPlaybackChangeSettles: neverSettles,
        stop: () async => stopCalls++,
        debugLog: (_) {},
      );

      expect(stopCalls, 1);
    });

    test('Repeat One (never reaches completed): no reaction at all', () async {
      var stopCalls = 0;
      await ListenyAudioHandler.handleQueueCompleted(
        currentProcessingState: () => ProcessingState.ready,
        hasPendingPlaybackChange: () => false,
        whenPendingPlaybackChangeSettles: neverSettles,
        stop: () async => stopCalls++,
        debugLog: (_) {},
      );
      expect(stopCalls, 0);
    });

    test('Repeat All (never reaches completed): no reaction at all', () async {
      var stopCalls = 0;
      await ListenyAudioHandler.handleQueueCompleted(
        currentProcessingState: () => ProcessingState.buffering,
        hasPendingPlaybackChange: () => false,
        whenPendingPlaybackChangeSettles: neverSettles,
        stop: () async => stopCalls++,
        debugLog: (_) {},
      );
      expect(stopCalls, 0);
    });

    test('a shuffled non-repeating queue stops when its actual final item '
        'completes, same as unshuffled (shuffle is not an input to this '
        'decision at all — only ProcessingState is)', () async {
      var stopCalls = 0;
      await ListenyAudioHandler.handleQueueCompleted(
        currentProcessingState: () => ProcessingState.completed,
        hasPendingPlaybackChange: () => false,
        whenPendingPlaybackChangeSettles: neverSettles,
        stop: () async => stopCalls++,
        debugLog: (_) {},
      );
      expect(stopCalls, 1);
    });

    test('a stale completion delivered once the live processingState has '
        'already moved on (loading/buffering/idle) is rejected, with no '
        'pending command needed to catch this case', () async {
      for (final state in [
        ProcessingState.loading,
        ProcessingState.buffering,
        ProcessingState.idle,
      ]) {
        var stopCalls = 0;
        await ListenyAudioHandler.handleQueueCompleted(
          currentProcessingState: () => state,
          hasPendingPlaybackChange: () => false,
          whenPendingPlaybackChangeSettles: neverSettles,
          stop: () async => stopCalls++,
          debugLog: (_) {},
        );
        expect(stopCalls, 0, reason: 'state=$state');
      }
    });

    test('a failing stop() is caught, not left to propagate', () async {
      await ListenyAudioHandler.handleQueueCompleted(
        currentProcessingState: () => ProcessingState.completed,
        hasPendingPlaybackChange: () => false,
        whenPendingPlaybackChangeSettles: neverSettles,
        stop: () async => throw StateError('platform channel failure'),
        debugLog: (_) {},
      );
      // Reaching here (no uncaught exception/test failure) is the assertion.
      // stop() is also only ever called once per call to
      // handleQueueCompleted (the loop returns immediately after it,
      // success or caught failure) — see the "genuine completion" cases
      // below for the deferred-then-one-shot path.
    });

    // A/B/C below are the actual regressions Codex flagged, tested through
    // the real production seam (PendingPlaybackChangeTracker), not a
    // hand-set boolean, and through the real deferred-then-recheck
    // handleQueueCompleted path — not by manually re-invoking it with a
    // later completion, which is exactly what would miss the bug: calling
    // handleQueueCompleted itself blocks (via
    // whenPendingPlaybackChangeSettles) until the tracked operation
    // settles, then re-reads fresh state to decide. Each scenario is
    // exercised twice: once where the operation turns out to have moved
    // playback on (old completion correctly dropped), and once where the
    // queue genuinely had just ended (cleanup correctly still runs,
    // exactly once, after the deferral).
    test('A: SEEK — a completion that arrives mid-seek is deferred, not '
        'discarded, and correctly dropped once state has moved on after the '
        'seek settles', () async {
      final tracker = PendingPlaybackChangeTracker();
      final seekPlatformCall = Completer<void>();
      var stopCalls = 0;
      var liveState = ProcessingState.completed;

      // Mirrors ListenyAudioHandler.seek().
      final seekFuture = tracker.track(() => seekPlatformCall.future);

      final completionFuture = ListenyAudioHandler.handleQueueCompleted(
        currentProcessingState: () => liveState,
        hasPendingPlaybackChange: () => tracker.hasPending,
        whenPendingPlaybackChangeSettles: tracker.whenIdle,
        stop: () async => stopCalls++,
        debugLog: (_) {},
      );
      // Synchronous prefix of handleQueueCompleted already ran (Dart
      // runs an async function up to its first await eagerly) — it's
      // provably deferred, not decided, by this point.
      expect(stopCalls, 0);

      // CASE B: the seek actually resulted in newer playback.
      liveState = ProcessingState.ready;
      seekPlatformCall.complete();
      await seekFuture;

      await completionFuture; // resolves only after the recheck
      expect(stopCalls, 0);
    });

    test('A2: SEEK — same deferral, but the queue genuinely had just ended: '
        'cleanup still runs exactly once after the seek settles', () async {
      final tracker = PendingPlaybackChangeTracker();
      final seekPlatformCall = Completer<void>();
      var stopCalls = 0;

      final seekFuture = tracker.track(() => seekPlatformCall.future);

      final completionFuture = ListenyAudioHandler.handleQueueCompleted(
        currentProcessingState: () => ProcessingState.completed,
        hasPendingPlaybackChange: () => tracker.hasPending,
        whenPendingPlaybackChangeSettles: tracker.whenIdle,
        stop: () async => stopCalls++,
        debugLog: (_) {},
      );
      expect(stopCalls, 0);

      // CASE A: state is still completed once the seek settles.
      seekPlatformCall.complete();
      await seekFuture;

      await completionFuture;
      expect(stopCalls, 1);
    });

    test('B: REPLAY/PLAY — a completion that arrives while play() is starting '
        'is deferred and correctly dropped once the startup transition is '
        'observed, even though play()\'s own Future (tracked via '
        'trackTransition, per its doc comment) remains completely unresolved '
        'the whole time — this is the exact production bug: tracking the '
        'full play() Future would have held this guard, and therefore kept '
        'deferring, for the rest of the session', () async {
      final tracker = PendingPlaybackChangeTracker();
      final playPlatformCall = Completer<void>(); // never resolved below
      final firstStateChange = Completer<void>();
      var stopCalls = 0;
      var liveState = ProcessingState.completed;

      // Mirrors ListenyAudioHandler.play(): trackTransition, not track().
      final playFuture = tracker.trackTransition(
        () => playPlatformCall.future,
        firstStateChange.future,
      );

      final completionFuture = ListenyAudioHandler.handleQueueCompleted(
        currentProcessingState: () => liveState,
        hasPendingPlaybackChange: () => tracker.hasPending,
        whenPendingPlaybackChangeSettles: tracker.whenIdle,
        stop: () async => stopCalls++,
        debugLog: (_) {},
      );
      expect(stopCalls, 0);

      // The replay actually took hold — state visibly moved on — and
      // that alone releases the guard, without play()'s own Future ever
      // resolving.
      liveState = ProcessingState.ready;
      firstStateChange.complete();
      await completionFuture;

      expect(stopCalls, 0);
      expect(
        playPlatformCall.isCompleted,
        isFalse,
        reason:
            "play()'s own Future is still unresolved — proves the guard "
            "wasn't tied to its full lifetime",
      );

      // Cleanup: resolve play()'s Future so nothing is left dangling.
      playPlatformCall.complete();
      await playFuture;
    });

    test('C: QUEUE/SOURCE REPLACEMENT — a completion that arrives mid-reload '
        'is deferred and correctly dropped once state has moved on after the '
        'reload settles', () async {
      final tracker = PendingPlaybackChangeTracker();
      final setSourcesPlatformCall = Completer<void>();
      var stopCalls = 0;
      var liveState = ProcessingState.completed;

      // Mirrors ListenyAudioHandler.loadAndPlay()'s tracked
      // setAudioSources call.
      final loadFuture = tracker.track(() => setSourcesPlatformCall.future);

      final completionFuture = ListenyAudioHandler.handleQueueCompleted(
        currentProcessingState: () => liveState,
        hasPendingPlaybackChange: () => tracker.hasPending,
        whenPendingPlaybackChangeSettles: tracker.whenIdle,
        stop: () async => stopCalls++,
        debugLog: (_) {},
      );
      expect(stopCalls, 0);

      liveState = ProcessingState.loading;
      setSourcesPlatformCall.complete();
      await loadFuture;

      await completionFuture;
      expect(stopCalls, 0);
    });

    // Item 5: queue-mutation paths.
    test('queue mutation — inserting into a just-completed queue (e.g. '
        '"play next") defers a stale completion, which correctly drops once '
        'the newly inserted item is what ends up current', () async {
      final tracker = PendingPlaybackChangeTracker();
      final insertPlatformCall = Completer<void>();
      var stopCalls = 0;
      var liveState = ProcessingState.completed;

      // Mirrors ListenyAudioHandler.insertQueueItem/addQueueItem.
      final insertFuture = tracker.track(() => insertPlatformCall.future);

      final completionFuture = ListenyAudioHandler.handleQueueCompleted(
        currentProcessingState: () => liveState,
        hasPendingPlaybackChange: () => tracker.hasPending,
        whenPendingPlaybackChangeSettles: tracker.whenIdle,
        stop: () async => stopCalls++,
        debugLog: (_) {},
      );
      expect(stopCalls, 0);

      liveState = ProcessingState.ready;
      insertPlatformCall.complete();
      await insertFuture;

      await completionFuture;
      expect(stopCalls, 0);
    });

    test(
      'queue mutation — removing the current/just-completed item defers a '
      'stale completion; if the queue genuinely ends up with nothing left '
      'pending and still-completed state, cleanup still runs exactly once',
      () async {
        final tracker = PendingPlaybackChangeTracker();
        final removePlatformCall = Completer<void>();
        var stopCalls = 0;

        // Mirrors ListenyAudioHandler.removeQueueItem (also how "clear
        // upcoming" removes tracks).
        final removeFuture = tracker.track(() => removePlatformCall.future);

        final completionFuture = ListenyAudioHandler.handleQueueCompleted(
          currentProcessingState: () => ProcessingState.completed,
          hasPendingPlaybackChange: () => tracker.hasPending,
          whenPendingPlaybackChangeSettles: tracker.whenIdle,
          stop: () async => stopCalls++,
          debugLog: (_) {},
        );
        expect(stopCalls, 0);

        removePlatformCall.complete();
        await removeFuture;

        await completionFuture;
        expect(stopCalls, 1);
      },
    );

    test('once the pending command actually finishes before the completion is '
        'even observed, it is handled immediately, normally, without any '
        'deferral (the guard does not get stuck)', () async {
      final tracker = PendingPlaybackChangeTracker();
      final seekPlatformCall = Completer<void>();
      var stopCalls = 0;

      final seekFuture = tracker.track(() => seekPlatformCall.future);
      seekPlatformCall.complete();
      await seekFuture;
      expect(tracker.hasPending, isFalse);

      await ListenyAudioHandler.handleQueueCompleted(
        currentProcessingState: () => ProcessingState.completed,
        hasPendingPlaybackChange: () => tracker.hasPending,
        whenPendingPlaybackChangeSettles: tracker.whenIdle,
        stop: () async => stopCalls++,
        debugLog: (_) {},
      );
      expect(stopCalls, 1);
    });
  });

  group('manualNextIndex (the real Next-button/system-Next fix — bypasses '
      "just_audio's own nextIndex, which restarts the current track under "
      'Repeat One instead of advancing)', () {
    test('normal queue, Repeat Off: advances to the next index', () {
      expect(
        ListenyAudioHandler.manualNextIndex(
          currentIndex: 0,
          effectiveIndices: [0, 1, 2],
          loopMode: LoopMode.off,
        ),
        1,
      );
    });

    test('normal queue, Repeat Off, at the last item: returns null — no '
        'wrap, and critically no restart of the current track', () {
      expect(
        ListenyAudioHandler.manualNextIndex(
          currentIndex: 2,
          effectiveIndices: [0, 1, 2],
          loopMode: LoopMode.off,
        ),
        isNull,
      );
    });

    test('Repeat All: advances normally mid-queue', () {
      expect(
        ListenyAudioHandler.manualNextIndex(
          currentIndex: 0,
          effectiveIndices: [0, 1, 2],
          loopMode: LoopMode.all,
        ),
        1,
      );
    });

    test('Repeat All, at the last item: wraps to the first', () {
      expect(
        ListenyAudioHandler.manualNextIndex(
          currentIndex: 2,
          effectiveIndices: [0, 1, 2],
          loopMode: LoopMode.all,
        ),
        0,
      );
    });

    test('Repeat One + manual Next: still advances to the next queue item '
        "(this is the actual bug fix — just_audio's own nextIndex would "
        'return the current index unchanged here, causing Next to restart '
        'the current track instead of moving on)', () {
      expect(
        ListenyAudioHandler.manualNextIndex(
          currentIndex: 0,
          effectiveIndices: [0, 1, 2],
          loopMode: LoopMode.one,
        ),
        1,
      );
    });

    test('Repeat One, at the last item: wraps (treated like Repeat All for '
        'a manual advance, matching normal music-player UX)', () {
      expect(
        ListenyAudioHandler.manualNextIndex(
          currentIndex: 2,
          effectiveIndices: [0, 1, 2],
          loopMode: LoopMode.one,
        ),
        0,
      );
    });

    test('shuffle: follows the effective (shuffled) order, not the '
        'underlying/original index order', () {
      // Underlying index 2 is playing first in this shuffle order; its
      // shuffled-order successor is underlying index 0, NOT index 3.
      expect(
        ListenyAudioHandler.manualNextIndex(
          currentIndex: 2,
          effectiveIndices: [2, 0, 3, 1],
          loopMode: LoopMode.off,
        ),
        0,
      );
    });

    test('a single-item queue with Repeat Off returns null (nothing to '
        'advance to)', () {
      expect(
        ListenyAudioHandler.manualNextIndex(
          currentIndex: 0,
          effectiveIndices: [0],
          loopMode: LoopMode.off,
        ),
        isNull,
      );
    });

    test('empty queue or null current index: returns null', () {
      expect(
        ListenyAudioHandler.manualNextIndex(
          currentIndex: null,
          effectiveIndices: [0, 1, 2],
          loopMode: LoopMode.off,
        ),
        isNull,
      );
      expect(
        ListenyAudioHandler.manualNextIndex(
          currentIndex: 0,
          effectiveIndices: [],
          loopMode: LoopMode.off,
        ),
        isNull,
      );
    });
  });

  group('clampedSeekTarget (the real ±10s seek math)', () {
    test('a forward seek within bounds moves normally', () {
      expect(
        ListenyAudioHandler.clampedSeekTarget(
          position: const Duration(seconds: 30),
          offset: const Duration(seconds: 10),
          duration: const Duration(minutes: 3),
        ),
        const Duration(seconds: 40),
      );
    });

    test('a backward seek within bounds moves normally', () {
      expect(
        ListenyAudioHandler.clampedSeekTarget(
          position: const Duration(seconds: 30),
          offset: const Duration(seconds: -10),
          duration: const Duration(minutes: 3),
        ),
        const Duration(seconds: 20),
      );
    });

    test('-10s near the start clamps at zero, never negative', () {
      expect(
        ListenyAudioHandler.clampedSeekTarget(
          position: const Duration(seconds: 4),
          offset: const Duration(seconds: -10),
          duration: const Duration(minutes: 3),
        ),
        Duration.zero,
      );
    });

    test('+10s near the end clamps at the known duration', () {
      expect(
        ListenyAudioHandler.clampedSeekTarget(
          position: const Duration(minutes: 3) - const Duration(seconds: 4),
          offset: const Duration(seconds: 10),
          duration: const Duration(minutes: 3),
        ),
        const Duration(minutes: 3),
      );
    });

    test('+10s with an unknown duration (null) is NOT clamped down to zero — '
        "this is the exact bug in audio_service's own SeekHandler mixin "
        'default (it treats a null duration as Duration.zero and then clamps '
        "\"newPosition > duration\" — true for almost any forward seek — "
        'straight back to zero)', () {
      expect(
        ListenyAudioHandler.clampedSeekTarget(
          position: const Duration(seconds: 30),
          offset: const Duration(seconds: 10),
          duration: null,
        ),
        const Duration(seconds: 40),
      );
    });

    test('+10s with a zero (unknown) duration is also not wrongly clamped', () {
      expect(
        ListenyAudioHandler.clampedSeekTarget(
          position: const Duration(seconds: 30),
          offset: const Duration(seconds: 10),
          duration: Duration.zero,
        ),
        const Duration(seconds: 40),
      );
    });

    test('-10s still clamps at zero even with an unknown duration', () {
      expect(
        ListenyAudioHandler.clampedSeekTarget(
          position: const Duration(seconds: 4),
          offset: const Duration(seconds: -10),
          duration: null,
        ),
        Duration.zero,
      );
    });
  });
}
