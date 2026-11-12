import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:listeny/features/now_playing/now_playing_screen.dart';
import 'package:listeny/l10n/generated/app_localizations.dart';
import 'package:listeny/library/library_repository.dart';
import 'package:listeny/playback/playback_service.dart';
import 'package:listeny/playback/playback_state.dart';

import '../../support/fake_library_repository.dart';
import '../../support/fake_playback_service.dart';
import '../../support/tracks.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Widget wrap(FakePlaybackService playback, FakeLibraryRepository library) =>
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiProvider(
          providers: [
            Provider<PlaybackService>.value(value: playback),
            Provider<LibraryRepository>.value(value: library),
          ],
          child: const NowPlayingScreen(),
        ),
      );

  testWidgets('a very long "playing from" source name does not overflow', (
    tester,
  ) async {
    final playback = FakePlaybackService();
    final library = FakeLibraryRepository();
    playback.currentTrackSubject.add(testTrack('a'));
    playback.contextNameSubject.add('A' * 300);

    await tester.pumpWidget(wrap(playback, library));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'repeat control exposes selected semantics matching repeat state',
    (tester) async {
      final playback = FakePlaybackService();
      final library = FakeLibraryRepository();
      playback.currentTrackSubject.add(testTrack('a'));
      playback.repeatModeSubject.add(PlaybackRepeatMode.all);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(playback, library));
      await tester.pump();

      // "Queue" is the corrected Repeat All label (previously said "Album",
      // which described the wrong scope) — find it specifically on the
      // repeat button, not just anywhere on screen.
      final repeatSemanticsFinder = find.byKey(
        const Key('repeat-mode-semantics'),
      );
      expect(
        find.descendant(
          of: repeatSemanticsFinder,
          matching: find.text('Queue'),
        ),
        findsOneWidget,
      );

      final semantics = tester.getSemantics(repeatSemanticsFinder);
      expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);

      handle.dispose();
    },
  );
}
