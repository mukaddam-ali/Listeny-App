import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import 'package:listeny/core/models/track.dart';
import 'package:listeny/core/storage/database.dart' hide Playlist;
import 'package:listeny/features/search/search_screen.dart';
import 'package:listeny/l10n/generated/app_localizations.dart';
import 'package:listeny/library/library_repository.dart';
import 'package:listeny/playback/playback_service.dart';

Track _track(String id, String title) => Track(
  id: id,
  filePath: '/tmp/$id.mp3',
  title: title,
  artist: 'Artist',
  album: 'Album',
  albumArtist: 'Artist',
  duration: const Duration(minutes: 3),
  format: 'mp3',
  fileSizeBytes: 1000,
  dateAdded: DateTime.now(),
);

/// No real Drift watch behind it, so it's safe inside a widget test.
class _FakeLibraryRepository extends LibraryRepository {
  _FakeLibraryRepository._(super.db);
  factory _FakeLibraryRepository() =>
      _FakeLibraryRepository._(AppDatabase(NativeDatabase.memory()));

  final _tracks = BehaviorSubject<List<Track>>.seeded(const []);

  void seedTracks(List<Track> tracks) => _tracks.add(tracks);

  @override
  ValueStream<List<Track>> watchAllTracks() => _tracks;

  @override
  ValueStream<List<Playlist>> watchPlaylists() =>
      BehaviorSubject<List<Playlist>>.seeded(const []);
}

/// Only the members SearchScreen's widget tree actually touches at build
/// time need a real value — everything else is unused in this test.
class _FakePlaybackService implements PlaybackService {
  @override
  ValueStream<Track?> get currentTrack => BehaviorSubject<Track?>.seeded(null);

  @override
  Future<void> loadQueue(
    List<Track> tracks, {
    int startIndex = 0,
    String? contextName,
    bool autoPlay = true,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets(
    'clearing the field before the debounce fires keeps the full library visible',
    (tester) async {
      final library = _FakeLibraryRepository();
      library.seedTracks([_track('a', 'Track One'), _track('b', 'Track Two')]);
      final playback = _FakePlaybackService();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              Provider<LibraryRepository>.value(value: library),
              Provider<PlaybackService>.value(value: playback),
            ],
            child: const SearchScreen(),
          ),
        ),
      );

      // First query settles so the clear ("X") button actually renders.
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 300));

      // A second keystroke schedules a fresh, still-pending debounce...
      await tester.enterText(
        find.byType(TextField),
        'zzz-does-not-match-anything',
      );
      await tester.pump();
      // ...cleared right away, before that debounce has any chance to fire.
      await tester.tap(find.byIcon(Icons.close));
      // Let the cancelled debounce's original window fully elapse.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Track One'), findsOneWidget);
      expect(find.text('Track Two'), findsOneWidget);
      expect(find.text('No results'), findsNothing);
    },
  );
}
