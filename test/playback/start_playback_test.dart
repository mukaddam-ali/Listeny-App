import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:listeny/playback/listeny_audio_handler.dart';

void main() {
  group('ListenyAudioHandler.startPlayback (loadAndPlay completion)', () {
    test(
      'completes on first playing=true while play() stays pending',
      () async {
        final playLifetime = Completer<void>(); // never completes in the test
        final playing = Completer<void>();
        var done = false;
        final f = ListenyAudioHandler.startPlayback(
          play: () => playLifetime.future,
          firstPlaying: playing.future,
          onLateError: (_, _) => fail('no late error expected'),
        ).then((_) => done = true);
        await Future<void>.delayed(Duration.zero);
        expect(
          done,
          isFalse,
          reason: 'must not complete before playback starts',
        );
        playing.complete();
        await f;
        expect(done, isTrue);
        expect(playLifetime.isCompleted, isFalse);
      },
    );

    test('completes when play() itself settles first', () async {
      await ListenyAudioHandler.startPlayback(
        play: () async {},
        firstPlaying: Completer<void>().future,
        onLateError: (_, _) => fail('no late error expected'),
      );
    });

    test('play() error before start propagates to the caller', () async {
      final play = Completer<void>();
      final f = ListenyAudioHandler.startPlayback(
        play: () => play.future,
        firstPlaying: Completer<void>().future,
        onLateError: (_, _) => fail('should propagate, not log'),
      );
      play.completeError(StateError('boom'));
      await expectLater(f, throwsStateError);
    });

    test('synchronous play() throw propagates', () async {
      await expectLater(
        ListenyAudioHandler.startPlayback(
          play: () => throw StateError('sync'),
          firstPlaying: Completer<void>().future,
          onLateError: (_, _) {},
        ),
        throwsStateError,
      );
    });

    test(
      'play() error after start goes to onLateError, not unhandled',
      () async {
        final play = Completer<void>();
        final playing = Completer<void>();
        final late = <Object>[];
        final f = ListenyAudioHandler.startPlayback(
          play: () => play.future,
          firstPlaying: playing.future,
          onLateError: (e, _) => late.add(e),
        );
        playing.complete();
        await f;
        play.completeError(StateError('late'));
        await Future<void>.delayed(Duration.zero);
        expect(late, hasLength(1));
        expect(late.single, isA<StateError>());
      },
    );

    test('cancellation (PlayerInterruptedException) is silent', () async {
      final play = Completer<void>();
      final f = ListenyAudioHandler.startPlayback(
        play: () => play.future,
        firstPlaying: Completer<void>().future,
        onLateError: (_, _) => fail('cancellation is not an error'),
      );
      play.completeError(PlayerInterruptedException('superseded'));
      await f; // completes normally

      // Also silent if it arrives after start.
      final play2 = Completer<void>();
      final playing2 = Completer<void>();
      final f2 = ListenyAudioHandler.startPlayback(
        play: () => play2.future,
        firstPlaying: playing2.future,
        onLateError: (_, _) => fail('cancellation is not an error'),
      );
      playing2.complete();
      await f2;
      play2.completeError(PlayerInterruptedException('superseded'));
      await Future<void>.delayed(Duration.zero);
    });

    test('rapid repeated starts each complete independently', () async {
      final lifetimes = List.generate(3, (_) => Completer<void>());
      final playings = List.generate(3, (_) => Completer<void>());
      final futures = [
        for (var i = 0; i < 3; i++)
          ListenyAudioHandler.startPlayback(
            play: () => lifetimes[i].future,
            firstPlaying: playings[i].future,
            onLateError: (_, _) => fail('no late error expected'),
          ),
      ];
      // Complete out of order; none depends on another's lifetime Future.
      playings[2].complete();
      playings[0].complete();
      playings[1].complete();
      await Future.wait(futures);
      expect(lifetimes.any((c) => c.isCompleted), isFalse);
    });

    test('a failing firstPlaying signal is ignored (play() decides)', () async {
      await ListenyAudioHandler.startPlayback(
        play: () async {},
        firstPlaying: Future<void>.error(StateError('stream closed')),
        onLateError: (_, _) => fail('no late error expected'),
      );
    });
  });
}
