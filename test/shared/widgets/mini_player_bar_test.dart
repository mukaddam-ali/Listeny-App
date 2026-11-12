import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:listeny/l10n/generated/app_localizations.dart';
import 'package:listeny/playback/playback_service.dart';
import 'package:listeny/shared/widgets/mini_player_bar.dart';

import '../../support/fake_playback_service.dart';
import '../../support/tracks.dart';

Widget _wrap(FakePlaybackService playback) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Provider<PlaybackService>.value(
      value: playback,
      child: const MiniPlayerBar(),
    ),
  ),
);

double _progressValue(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
    .value!;

void main() {
  testWidgets('reacts to a duration-only update, not just position changes', (
    tester,
  ) async {
    final playback = FakePlaybackService();
    playback.currentTrackSubject.add(testTrack('a'));
    playback.durationSubject.add(const Duration(seconds: 100));
    playback.positionSubject.add(const Duration(seconds: 50));

    await tester.pumpWidget(_wrap(playback));
    await tester.pump();
    expect(_progressValue(tester), closeTo(0.5, 0.001));

    // Duration changes on its own (e.g. the real duration for a newly-loaded
    // track arrives) with no fresh position event — the fraction must still
    // recompute against the new duration instead of staying stuck on the
    // stale duration.value captured at the last position tick.
    playback.durationSubject.add(const Duration(seconds: 200));
    // A rebuild triggered purely from a stream event needs a second pump
    // in this harness to actually land in the tree (the first pump's frame
    // check runs before the microtask-delivered event marks it dirty).
    await tester.pump();
    await tester.pump();
    expect(_progressValue(tester), closeTo(0.25, 0.001));
  });

  testWidgets('resets to zero when a real zero-position event arrives', (
    tester,
  ) async {
    final playback = FakePlaybackService();
    playback.currentTrackSubject.add(testTrack('a'));
    playback.durationSubject.add(const Duration(seconds: 100));
    playback.positionSubject.add(const Duration(seconds: 99));

    await tester.pumpWidget(_wrap(playback));
    await tester.pump();
    expect(_progressValue(tester), closeTo(0.99, 0.001));

    // A genuine backward jump to zero (e.g. Repeat One looping) must be
    // reflected immediately, not clamped/stuck near the previous value.
    playback.positionSubject.add(Duration.zero);
    await tester.pump();
    await tester.pump();
    expect(_progressValue(tester), 0.0);
  });
}
