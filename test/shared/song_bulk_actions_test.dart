import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import 'package:listeny/core/models/track.dart';
// database.dart's generated Playlist (a raw table row) collides by name
// with library_repository.dart's own Playlist (the public value type) —
// this test only ever needs AppDatabase/NativeDatabase from here.
import 'package:listeny/core/storage/database.dart' hide Playlist;
import 'package:listeny/l10n/generated/app_localizations.dart';
import 'package:listeny/library/library_repository.dart';
import 'package:listeny/shared/song_bulk_actions.dart';

Track _track(String id) => Track(
  id: id,
  filePath: '/tmp/$id.mp3',
  title: 'Song $id',
  artist: 'Artist',
  album: 'Album',
  albumArtist: 'Artist',
  duration: const Duration(minutes: 3),
  format: 'mp3',
  fileSizeBytes: 1000,
  dateAdded: DateTime.now(),
);

/// A real Track/Playlist model layer with no reactive Drift queries behind
/// it — [showAddToPlaylistSheet]/[confirmAndBulkDelete] only ever call the
/// handful of methods overridden here, so this avoids spinning up a real
/// watched database connection just to drive a widget test.
class _FakeLibraryRepository extends LibraryRepository {
  final _playlists = BehaviorSubject<List<Playlist>>.seeded(const []);
  final addedMemberships = <(String playlistId, String trackId)>[];
  final removedFromLibraryOnly = <Track>[];
  final deletedFromDevice = <Track>[];

  _FakeLibraryRepository._(super.db) : _db = db;

  final AppDatabase _db;

  factory _FakeLibraryRepository() {
    final repo = _FakeLibraryRepository._(AppDatabase(NativeDatabase.memory()));
    addTearDown(repo._db.close);
    return repo;
  }

  void seedPlaylists(List<Playlist> playlists) => _playlists.add(playlists);

  @override
  ValueStream<List<Playlist>> watchPlaylists() => _playlists;

  @override
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    addedMemberships.add((playlistId, songId));
  }

  @override
  Future<void> removeTrackFromLibraryOnly(Track track) async {
    removedFromLibraryOnly.add(track);
  }

  @override
  Future<bool> deleteTrackFromDevice(Track track) async {
    deletedFromDevice.add(track);
    return true;
  }

  @override
  Future<Set<String>> deleteTracksFromDevice(List<Track> tracks) async {
    deletedFromDevice.addAll(tracks);
    return {for (final t in tracks) t.id};
  }
}

Widget _harness(
  LibraryRepository library,
  Widget Function(BuildContext) builder,
) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Provider<LibraryRepository>.value(
      value: library,
      child: Builder(builder: builder),
    ),
  );
}

void main() {
  group('showAddToPlaylistSheet', () {
    testWidgets(
      'lists existing playlists and adds every selected track on tap',
      (tester) async {
        final library = _FakeLibraryRepository();
        library.seedPlaylists([
          Playlist(
            id: 'p1',
            name: 'Road Trip',
            artworkPath: null,
            createdAt: DateTime.now(),
            songCount: 0,
          ),
        ]);
        final a = _track('a');
        final b = _track('b');

        await tester.pumpWidget(
          _harness(library, (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => showAddToPlaylistSheet(
                  context,
                  library: library,
                  tracks: [a, b],
                ),
                child: const Text('open'),
              ),
            );
          }),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Add 2 tracks to Playlist'), findsOneWidget);
        expect(find.text('Road Trip'), findsOneWidget);

        await tester.tap(find.text('Road Trip'));
        await tester.pumpAndSettle();

        expect(library.addedMemberships, [('p1', 'a'), ('p1', 'b')]);
      },
    );

    testWidgets('a single track gets the singular header', (tester) async {
      final library = _FakeLibraryRepository();
      library.seedPlaylists([
        Playlist(
          id: 'p1',
          name: 'Mix',
          artworkPath: null,
          createdAt: DateTime.now(),
          songCount: 0,
        ),
      ]);
      final a = _track('a');

      await tester.pumpWidget(
        _harness(library, (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => showAddToPlaylistSheet(
                context,
                library: library,
                tracks: [a],
              ),
              child: const Text('open'),
            ),
          );
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Add to Playlist'), findsOneWidget);
    });
  });

  group('confirmAndBulkDelete', () {
    testWidgets(
      '"Remove from Library" removes every selected track but keeps their files',
      (tester) async {
        final library = _FakeLibraryRepository();
        final a = _track('a');
        final b = _track('b');
        var deletedCalled = false;

        await tester.pumpWidget(
          _harness(library, (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => confirmAndBulkDelete(
                  context,
                  library: library,
                  tracks: [a, b],
                  onDeleted: () => deletedCalled = true,
                ),
                child: const Text('open'),
              ),
            );
          }),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Delete 2 tracks?'), findsOneWidget);
        await tester.tap(find.text('Remove from Library'));
        await tester.pumpAndSettle();

        expect(deletedCalled, isTrue);
        expect(library.removedFromLibraryOnly, [a, b]);
        expect(library.deletedFromDevice, isEmpty);
      },
    );

    testWidgets('"Delete from Device" deletes every selected track\'s file', (
      tester,
    ) async {
      final library = _FakeLibraryRepository();
      final a = _track('a');
      var deletedCalled = false;

      await tester.pumpWidget(
        _harness(library, (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => confirmAndBulkDelete(
                context,
                library: library,
                tracks: [a],
                onDeleted: () => deletedCalled = true,
              ),
              child: const Text('open'),
            ),
          );
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete from Device'));
      await tester.pumpAndSettle();

      expect(deletedCalled, isTrue);
      expect(library.deletedFromDevice, [a]);
    });

    testWidgets(
      'cancelling leaves everything untouched and does not call onDeleted',
      (tester) async {
        final library = _FakeLibraryRepository();
        final a = _track('a');
        var deletedCalled = false;

        await tester.pumpWidget(
          _harness(library, (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => confirmAndBulkDelete(
                  context,
                  library: library,
                  tracks: [a],
                  onDeleted: () => deletedCalled = true,
                ),
                child: const Text('open'),
              ),
            );
          }),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(deletedCalled, isFalse);
        expect(library.removedFromLibraryOnly, isEmpty);
        expect(library.deletedFromDevice, isEmpty);
      },
    );
  });
}
