import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listeny/core/models/track.dart';
import 'package:listeny/l10n/generated/app_localizations.dart';
import 'package:listeny/shared/widgets/song_row.dart';

Track _track() => Track(
  id: 't1',
  filePath: '/tmp/t1.mp3',
  title: 'A Song',
  artist: 'An Artist',
  album: 'An Album',
  albumArtist: 'An Artist',
  duration: const Duration(minutes: 3),
  format: 'mp3',
  fileSizeBytes: 1000,
  dateAdded: DateTime.now(),
);

void main() {
  testWidgets('long press outside selection mode invokes onLongPress', (
    tester,
  ) async {
    var longPressed = false;
    final track = _track();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SongRow(
            track: track,
            playContext: [track],
            onTap: () {},
            onLongPress: () => longPressed = true,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('A Song'));
    await tester.pumpAndSettle();

    expect(longPressed, isTrue);
  });

  testWidgets(
    'selection mode shows a checkbox reflecting `selected` and routes tap through onTap',
    (tester) async {
      var tapped = false;
      final track = _track();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SongRow(
              track: track,
              playContext: [track],
              selectionMode: true,
              selected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      // Trailing actions (favorite heart, duration, "..." menu) are hidden
      // while selecting — nothing there should fight the checkbox tap.
      expect(find.byIcon(Icons.more_horiz), findsNothing);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'tapping the row itself (not just the checkbox) also toggles selection',
    (tester) async {
      var tapped = false;
      final track = _track();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SongRow(
              track: track,
              playContext: [track],
              selectionMode: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('A Song'));
      await tester.pump();

      expect(tapped, isTrue);
    },
  );
}
