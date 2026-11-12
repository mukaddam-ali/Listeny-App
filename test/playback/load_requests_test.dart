import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:listeny/playback/listeny_audio_handler.dart';
import 'package:listeny/playback/play_tap_trace.dart';

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  group('runLoadAndPlay (shared-player request/cancellation behavior)', () {
    late AutoPlayIntent intent;
    late List<String> calls;
    setUp(() {
      intent = AutoPlayIntent();
      calls = [];
    });

    Future<void> request(
      String name, {
      required Completer<void> load,
      bool autoPlay = true,
      Completer<void>? playing,
    }) {
      final g = intent.begin();
      return ListenyAudioHandler.runLoadAndPlay(
        intent: intent,
        generation: g,
        willAutoPlay: autoPlay,
        setSources: () => load.future,
        play: () async {
          calls.add('play:$name');
        },
        firstPlaying: () => (playing ?? Completer<void>()).future,
        onLateError: (_, _) => calls.add('late:$name'),
      );
    }

    test('pause during loading prevents play()', () async {
      final load = Completer<void>();
      final f = request('a', load: load);
      intent.cancel();
      load.complete();
      await f;
      expect(calls, isEmpty);
    });

    test('stop/interruption during loading prevents play()', () async {
      final load = Completer<void>();
      final f = request('a', load: load);
      intent.cancel();
      load.complete();
      await f;
      expect(calls, isEmpty);
    });

    test('interrupted setAudioSources backs off without play()', () async {
      final load = Completer<void>();
      final f = request('a', load: load);
      load.completeError(PlayerInterruptedException('newer load'));
      await f;
      expect(calls, isEmpty);
    });

    test('rapid/out-of-order requests: only the newest plays', () async {
      final l1 = Completer<void>();
      final l2 = Completer<void>();
      final l3 = Completer<void>();
      final f1 = request('1', load: l1);
      final f2 = request('2', load: l2);
      final f3 = request('3', load: l3);
      l3.complete();
      await f3;
      l1.complete();
      l2.complete();
      await Future.wait([f1, f2]);
      expect(calls, ['play:3']);
    });

    test('valid resume after cancellation', () async {
      final l1 = Completer<void>();
      final f1 = request('1', load: l1);
      intent.cancel();
      l1.complete();
      await f1;
      expect(calls, isEmpty);

      final l2 = Completer<void>()..complete();
      await request('2', load: l2, playing: Completer<void>()..complete());
      expect(calls, ['play:2']);
      expect(intent.isCurrent(intent.begin()), isTrue);
    });

    test('autoPlay=false never plays (restore)', () async {
      await request('r', load: Completer<void>()..complete(), autoPlay: false);
      expect(calls, isEmpty);
    });

    test('late non-cancellation play() error reaches onLateError', () async {
      final play = Completer<void>();
      final playing = Completer<void>();
      final errors = <Object>[];
      final f = ListenyAudioHandler.runLoadAndPlay(
        intent: intent,
        generation: intent.begin(),
        willAutoPlay: true,
        setSources: () async {},
        play: () => play.future,
        firstPlaying: () => playing.future,
        onLateError: (e, _) => errors.add(e),
      );
      await _tick();
      playing.complete();
      await f;
      play.completeError(StateError('decoder died'));
      await _tick();
      expect(errors.single, isA<StateError>());
    });

    test('late cancellation exception is not reported as an error', () async {
      final play = Completer<void>();
      final playing = Completer<void>();
      final f = ListenyAudioHandler.runLoadAndPlay(
        intent: intent,
        generation: intent.begin(),
        willAutoPlay: true,
        setSources: () async {},
        play: () => play.future,
        firstPlaying: () => playing.future,
        onLateError: (_, _) => fail('cancellation is not an error'),
      );
      await _tick();
      playing.complete();
      await f;
      play.completeError(PlayerInterruptedException('superseded'));
      await _tick();
    });
  });

  group('runLoadAndPlay: autoPlay:false and stale late errors', () {
    test(
      'autoPlay:false pauses an already-playing player, never plays',
      () async {
        final intent = AutoPlayIntent();
        final order = <String>[];
        await ListenyAudioHandler.runLoadAndPlay(
          intent: intent,
          generation: intent.begin(),
          willAutoPlay: false,
          pauseBeforeLoad: () async => order.add('pause'),
          setSources: () async => order.add('load'),
          play: () async => order.add('play'),
          firstPlaying: () => Completer<void>().future,
          onLateError: (_, _) {},
        );
        expect(order, ['pause', 'load'], reason: 'paused before sources swap');
      },
    );

    test('autoPlay:true does not pause first', () async {
      final intent = AutoPlayIntent();
      final order = <String>[];
      await ListenyAudioHandler.runLoadAndPlay(
        intent: intent,
        generation: intent.begin(),
        willAutoPlay: true,
        pauseBeforeLoad: () async => order.add('pause'),
        setSources: () async => order.add('load'),
        play: () async => order.add('play'),
        firstPlaying: () => Future<void>.value(),
        onLateError: (_, _) {},
      );
      expect(order, ['load', 'play']);
    });

    test(
      'old play() failing after a newer request started is ignored',
      () async {
        final intent = AutoPlayIntent();
        final oldPlay = Completer<void>();
        final oldPlaying = Completer<void>();
        final published = <Object>[];
        final f = ListenyAudioHandler.runLoadAndPlay(
          intent: intent,
          generation: intent.begin(),
          willAutoPlay: true,
          setSources: () async {},
          play: () => oldPlay.future,
          firstPlaying: () => oldPlaying.future,
          onLateError: (e, _) => published.add(e),
        );
        await _tick();
        oldPlaying.complete();
        await f;
        intent.begin(); // newer request now owns playback
        oldPlay.completeError(StateError('old failure'));
        await _tick();
        expect(published, isEmpty);
      },
    );

    test('current request late failure is still published', () async {
      final intent = AutoPlayIntent();
      final play = Completer<void>();
      final playing = Completer<void>();
      final published = <Object>[];
      final f = ListenyAudioHandler.runLoadAndPlay(
        intent: intent,
        generation: intent.begin(),
        willAutoPlay: true,
        setSources: () async {},
        play: () => play.future,
        firstPlaying: () => playing.future,
        onLateError: (e, _) => published.add(e),
      );
      await _tick();
      playing.complete();
      await f;
      play.completeError(StateError('real'));
      await _tick();
      expect(published, hasLength(1));
    });

    test(
      'trace is armed only after its own setAudioSources succeeds',
      () async {
        final intent = AutoPlayIntent();
        final load = Completer<void>();
        final trace = PlayTapTrace();
        final f = ListenyAudioHandler.runLoadAndPlay(
          intent: intent,
          generation: intent.begin(),
          willAutoPlay: true,
          setSources: () => load.future,
          play: () async {},
          firstPlaying: () => Future<void>.value(),
          onLateError: (_, _) {},
          trace: trace,
        );
        await _tick();
        expect(trace.armed, isFalse);
        load.complete();
        await f;
        expect(trace.armed, isTrue);

        final failed = PlayTapTrace();
        await ListenyAudioHandler.runLoadAndPlay(
          intent: intent,
          generation: intent.begin(),
          willAutoPlay: true,
          setSources: () => Future<void>.error(PlayerInterruptedException('x')),
          play: () async {},
          firstPlaying: () => Future<void>.value(),
          onLateError: (_, _) {},
          trace: failed,
        );
        expect(failed.armed, isFalse);
      },
    );
  });

  group('stale autoPlay:false and trace supersession', () {
    test(
      'newer load while pauseBeforeLoad pending: old never sets sources',
      () async {
        final intent = AutoPlayIntent();
        final pausing = Completer<void>();
        final calls = <String>[];
        final old = ListenyAudioHandler.runLoadAndPlay(
          intent: intent,
          generation: intent.begin(),
          willAutoPlay: false,
          pauseBeforeLoad: () => pausing.future,
          setSources: () async => calls.add('old-load'),
          play: () async {},
          firstPlaying: () => Future<void>.value(),
          onLateError: (_, _) {},
        );
        await _tick();
        final newer = ListenyAudioHandler.runLoadAndPlay(
          intent: intent,
          generation: intent.begin(),
          willAutoPlay: true,
          setSources: () async => calls.add('new-load'),
          play: () async => calls.add('new-play'),
          firstPlaying: () => Future<void>.value(),
          onLateError: (_, _) {},
        );
        pausing.complete();
        await Future.wait([old, newer]);
        expect(calls, ['new-load', 'new-play']);
      },
    );

    test('cancel while pauseBeforeLoad pending also stops the load', () async {
      final intent = AutoPlayIntent();
      final pausing = Completer<void>();
      var loaded = false;
      final f = ListenyAudioHandler.runLoadAndPlay(
        intent: intent,
        generation: intent.begin(),
        willAutoPlay: false,
        pauseBeforeLoad: () => pausing.future,
        setSources: () async => loaded = true,
        play: () async {},
        firstPlaying: () => Future<void>.value(),
        onLateError: (_, _) {},
      );
      intent.cancel();
      pausing.complete();
      await f;
      expect(loaded, isFalse);
    });

    test('autoPlay:false load closes the active autoplay trace', () {
      final t = PlayTapTracker();
      final auto = t.beginForLoad(autoPlay: true, detail: 'a')!;
      expect(t.active, same(auto));
      final restore = t.beginForLoad(autoPlay: false, detail: 'r');
      expect(restore, isNull);
      expect(t.active, isNull);
      expect(t.lastCloseReason, contains('non-autoplay'));
    });

    test('autoPlay:false with no active trace is a no-op', () {
      final t = PlayTapTracker();
      expect(t.beginForLoad(autoPlay: false, detail: 'r'), isNull);
      expect(t.lastCloseReason, isNull);
    });

    test('old trace cannot close or affect a newer one', () {
      final t = PlayTapTracker();
      final a = t.beginForLoad(autoPlay: true, detail: 'a')!..arm();
      final b = t.beginForLoad(autoPlay: true, detail: 'b')!..arm();
      t.close('failed', only: a);
      expect(t.active, same(b));
      t.onLive(
        boundRequestId: a.id,
        playing: true,
        ready: true,
        completed: true,
        position: const Duration(seconds: 1),
      );
      expect(t.active, same(b));
      t.close('done', only: b);
      expect(t.active, isNull);
    });
  });

  group('PlayTapTracker (arming, live binding, lifecycle)', () {
    late PlayTapTracker t;
    setUp(() => t = PlayTapTracker());

    void live(
      PlayTapTrace trace, {
      int? bound,
      bool useBound = false,
      bool playing = true,
      bool ready = true,
      bool completed = false,
      Duration position = Duration.zero,
    }) => t.onLive(
      boundRequestId: useBound ? bound : trace.id,
      playing: playing,
      ready: ready,
      completed: completed,
      position: position,
    );

    test('unarmed trace ignores everything (previous source still loaded)', () {
      final trace = t.begin('x');
      live(trace, position: const Duration(seconds: 30));
      expect(t.active, same(trace));
      expect(trace.hasSeen('playing'), isFalse);
    });

    test(
      'new MediaItem before old state events: previous-source data ignored',
      () {
        final trace = t.begin('x')..arm();
        live(trace, useBound: true, position: const Duration(seconds: 90));
        live(
          trace,
          useBound: true,
          bound: trace.id - 1,
          position: const Duration(seconds: 90),
        );
        expect(t.active, same(trace));
        expect(trace.hasSeen('advance'), isFalse);
        live(trace, position: const Duration(milliseconds: 30));
        expect(t.active, isNull);
        expect(t.lastCloseReason, 'position advancing');
      },
    );

    test('correct milestones: playing, ready, then advance closes', () {
      final trace = t.begin('x')..arm();
      live(trace, ready: false);
      expect(trace.hasSeen('playing'), isTrue);
      expect(trace.hasSeen('ready'), isFalse);
      live(trace);
      expect(trace.hasSeen('ready'), isTrue);
      expect(t.active, same(trace));
      live(trace, position: const Duration(milliseconds: 5));
      expect(t.active, isNull);
    });

    test('supersession replaces; stale request cannot close newer', () {
      final a = t.begin('a');
      final b = t.begin('b');
      expect(t.active, same(b));
      t.close('failed', only: a);
      expect(t.active, same(b));
      t.close('failed', only: b);
      expect(t.active, isNull);
    });

    test('cancel/terminal/pause/error each close; close is idempotent', () {
      t.begin('x');
      t.close('cancelled: pause');
      expect(t.lastCloseReason, 'cancelled: pause');

      var trace = t.begin('x')..arm();
      live(trace, completed: true, playing: false, ready: false);
      expect(t.active, isNull);
      expect(t.lastCloseReason, contains('terminal'));

      trace = t.begin('x')..arm();
      live(trace, ready: false);
      live(trace, playing: false, ready: false);
      expect(t.active, isNull);
      expect(t.lastCloseReason, contains('paused'));

      t.begin('x');
      t.close('cancelled: error');
      t.close('again');
      expect(t.lastCloseReason, 'cancelled: error');
    });

    test('rapid repeated traces: only the latest can be completed', () {
      final a = t.begin('a')..arm();
      final b = t.begin('b')..arm();
      live(a, position: const Duration(seconds: 1));
      expect(t.active, same(b));
      live(b, position: const Duration(seconds: 1));
      expect(t.active, isNull);
    });
  });

  group('PlayTapTracker.closeIfUnarmed', () {
    test('closes a request that ended before its own sources were ready', () {
      final t = PlayTapTracker();
      final trace = t.begin('x');
      t.closeIfUnarmed(trace);
      expect(t.active, isNull);
      expect(t.lastCloseReason, contains('before its sources were ready'));
    });

    test('keeps armed traces and never closes a newer trace', () {
      final t = PlayTapTracker();
      final armed = t.begin('a')..arm();
      t.closeIfUnarmed(armed);
      expect(t.active, same(armed));
      final old = armed;
      final newer = t.begin('b');
      t.closeIfUnarmed(old);
      expect(t.active, same(newer));
    });
  });
}
