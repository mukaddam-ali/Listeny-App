import 'dart:io';
import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

import 'package:listeny/core/models/track.dart';
import 'package:listeny/core/storage/database.dart';
import 'package:listeny/library/library_repository.dart';

Track _track(String id, {String title = 'Song'}) => Track(
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

/// Every [LibraryRepository] `watch*` stream is seeded (`shareValueSeeded`)
/// so the UI never has to handle "no value yet" — a fresh subscription's
/// very first event is that seed, not real data, so a bare `.first` in a
/// test can grab the seed instead of waiting for the actual query to run.
/// This polls [stream]'s live `.value` until [predicate] matches (or times
/// out), which is what an active listener naturally converges to once
/// drift's reactive query actually executes.
Future<T> _waitFor<T>(ValueStream<T> stream, bool Function(T) predicate) async {
  final sub = stream.listen((_) {});
  try {
    for (var i = 0; i < 200; i++) {
      if (predicate(stream.value)) return stream.value;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw TimeoutException('condition never met on ${stream.runtimeType}');
  } finally {
    await sub.cancel();
  }
}

void main() {
  setUpAll(() {
    // Every test opens its own throwaway in-memory database on purpose.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  LibraryRepository open() =>
      LibraryRepository(AppDatabase(NativeDatabase.memory()));

  group('recently played', () {
    test(
      'orders by most recently played first and updates on each play',
      () async {
        final library = open();
        await library.insertTrack(_track('a'));
        await library.insertTrack(_track('b'));
        await library.insertTrack(_track('c'));

        await library.recordPlay('a');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await library.recordPlay('b');

        final firstOrder = await _waitFor(
          library.watchRecentlyPlayed(),
          (l) => l.length == 2,
        );
        expect(firstOrder.map((t) => t.id).toList(), ['b', 'a']);
        // Never played, so absent entirely.
        expect(firstOrder.any((t) => t.id == 'c'), isFalse);

        await Future<void>.delayed(const Duration(milliseconds: 5));
        await library.recordPlay('a');
        final secondOrder = await _waitFor(
          library.watchRecentlyPlayed(),
          (l) => l.length == 2 && l.first.id == 'a',
        );
        expect(secondOrder.map((t) => t.id).toList(), ['a', 'b']);
      },
    );

    test('empty when nothing has ever been played', () async {
      final library = open();
      await library.insertTrack(_track('a'));
      final result = await library.watchRecentlyPlayed().first;
      expect(result, isEmpty);
    });
  });

  group('download history', () {
    test(
      'records, orders newest first, and persists across repository instances',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final library = LibraryRepository(db);

        await library.recordDownloadHistory(
          title: 'First download',
          sourceType: 'direct',
          status: 'success',
          outputFormat: 'm4a',
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await library.recordDownloadHistory(
          title: 'Broken link',
          sourceType: 'direct',
          status: 'failed',
          message: "Couldn't reach that link.",
        );

        final entries = await _waitFor(
          library.watchDownloadHistory(),
          (l) => l.length == 2,
        );
        expect(entries.first.title, 'Broken link');
        expect(entries.first.succeeded, isFalse);
        expect(entries.first.message, "Couldn't reach that link.");
        expect(entries.last.title, 'First download');
        expect(entries.last.succeeded, isTrue);
        expect(entries.last.outputFormat, 'm4a');

        // Re-wrapping the same underlying database (simulating a restart that
        // reopens the same file) still sees the same rows.
        final reopened = LibraryRepository(db);
        final afterReopen = await _waitFor(
          reopened.watchDownloadHistory(),
          (l) => l.length == 2,
        );
        expect(afterReopen, hasLength(2));
      },
    );

    test('clear removes every entry', () async {
      final library = open();
      await library.recordDownloadHistory(
        title: 'x',
        sourceType: 'direct',
        status: 'success',
      );
      await _waitFor(library.watchDownloadHistory(), (l) => l.length == 1);

      await library.clearDownloadHistory();
      await _waitFor(library.watchDownloadHistory(), (l) => l.isEmpty);
    });
  });

  group('playlist artwork', () {
    // The artwork must really exist (a missing file is never stored).
    final coverDir = Directory.systemTemp.createTempSync('listeny_covers');
    tearDownAll(() => coverDir.deleteSync(recursive: true));
    String coverPath(String name) {
      final f = File('${coverDir.path}/$name');
      if (!f.existsSync()) f.writeAsBytesSync([1, 2, 3]);
      return f.path;
    }

    test(
      'set, replace, and remove, with collage fallback when absent',
      () async {
        final library = open();
        final id = await library.createPlaylist('My Mix');

        var playlist = (await _waitFor(
          library.watchPlaylists(),
          (l) => l.length == 1,
        )).single;
        expect(playlist.artworkPath, isNull);

        await library.updatePlaylistArtwork(id, coverPath('cover1.jpg'));
        playlist = (await _waitFor(
          library.watchPlaylists(),
          (l) =>
              l.isNotEmpty && l.single.artworkPath == coverPath('cover1.jpg'),
        )).single;
        expect(playlist.artworkPath, coverPath('cover1.jpg'));

        await library.updatePlaylistArtwork(id, coverPath('cover2.jpg'));
        playlist = (await _waitFor(
          library.watchPlaylists(),
          (l) =>
              l.isNotEmpty && l.single.artworkPath == coverPath('cover2.jpg'),
        )).single;
        expect(playlist.artworkPath, coverPath('cover2.jpg'));

        await library.updatePlaylistArtwork(id, null);
        playlist = (await _waitFor(
          library.watchPlaylists(),
          (l) => l.isNotEmpty && l.single.artworkPath == null,
        )).single;
        expect(playlist.artworkPath, isNull);
      },
    );

    test('createPlaylist accepts an initial artwork path', () async {
      final library = open();
      final id = await library.createPlaylist(
        'Road Trip',
        artworkPath: coverPath('cover.jpg'),
      );
      final playlist = (await _waitFor(
        library.watchPlaylists(),
        (l) => l.length == 1,
      )).single;
      expect(playlist.id, id);
      expect(playlist.artworkPath, coverPath('cover.jpg'));
    });
  });

  group('playlist membership', () {
    test('adding the same song twice does not duplicate membership', () async {
      final library = open();
      final playlistId = await library.createPlaylist('List');
      await library.insertTrack(_track('a'));

      await library.addSongToPlaylist(playlistId, 'a');
      await library.addSongToPlaylist(playlistId, 'a');

      final songs = await _waitFor(
        library.watchPlaylistSongs(playlistId),
        (l) => l.isNotEmpty,
      );
      expect(songs, hasLength(1));
    });

    test('concurrent adds of the same song do not create duplicates', () async {
      final library = open();
      final playlistId = await library.createPlaylist('List');
      await library.insertTrack(_track('a'));

      // Fired without awaiting each other first, so both requests are truly
      // in flight at once — this is what a check-then-insert can race on;
      // the DB-level unique index is what keeps this safe.
      await Future.wait([
        library.addSongToPlaylist(playlistId, 'a'),
        library.addSongToPlaylist(playlistId, 'a'),
        library.addSongToPlaylist(playlistId, 'a'),
      ]);

      final songs = await _waitFor(
        library.watchPlaylistSongs(playlistId),
        (l) => l.isNotEmpty,
      );
      expect(songs, hasLength(1));
    });
  });

  group('renameAlbum', () {
    Track albumTrack(String id, {String album = 'Original', int n = 1}) =>
        Track(
          id: id,
          filePath: '/tmp/$id.mp3',
          title: 'Track $n',
          artist: 'Some Artist',
          album: album,
          albumArtist: 'Some Artist',
          trackNumber: n,
          duration: const Duration(minutes: 3),
          format: 'mp3',
          fileSizeBytes: 1000,
          dateAdded: DateTime.now(),
        );

    test('renames every track in the exact (album, albumArtist) group, '
        'preserving ids/artist/favorites/play counts', () async {
      final library = open();
      await library.insertTrack(albumTrack('a', n: 1));
      await library.insertTrack(albumTrack('b', n: 2));
      await library.setFavorite('a', true);
      await library.recordPlay('b');

      await library.renameAlbum(
        album: 'Original',
        albumArtist: 'Some Artist',
        newAlbum: 'Renamed',
      );

      final renamed = await _waitFor(
        library.watchSongsForAlbum('Renamed', 'Some Artist'),
        (l) => l.length == 2,
      );
      expect(renamed.map((t) => t.id).toSet(), {'a', 'b'});
      expect(renamed.every((t) => t.artist == 'Some Artist'), isTrue);
      expect(renamed.firstWhere((t) => t.id == 'a').favorite, isTrue);
      expect(renamed.firstWhere((t) => t.id == 'b').playCount, 1);

      final old = await library
          .watchSongsForAlbum('Original', 'Some Artist')
          .first;
      expect(old, isEmpty);
    });

    test('never touches a different album group with the same name but a '
        'different albumArtist', () async {
      final library = open();
      await library.insertTrack(albumTrack('a', album: 'Original'));
      await library.insertTrack(
        Track(
          id: 'other',
          filePath: '/tmp/other.mp3',
          title: 'Other',
          artist: 'Different Artist',
          album: 'Original',
          albumArtist: 'Different Artist',
          duration: const Duration(minutes: 3),
          format: 'mp3',
          fileSizeBytes: 1000,
          dateAdded: DateTime.now(),
        ),
      );

      await library.renameAlbum(
        album: 'Original',
        albumArtist: 'Some Artist',
        newAlbum: 'Renamed',
      );

      final untouched = await _waitFor(
        library.watchSongsForAlbum('Original', 'Different Artist'),
        (l) => l.isNotEmpty,
      );
      expect(untouched.map((t) => t.id), ['other']);
    });

    test('rejects renaming onto an existing DIFFERENT (newAlbum, albumArtist) '
        'group instead of silently merging', () async {
      final library = open();
      await library.insertTrack(albumTrack('a', album: 'Alpha'));
      await library.insertTrack(albumTrack('b', album: 'Beta'));

      expect(
        () => library.renameAlbum(
          album: 'Alpha',
          albumArtist: 'Some Artist',
          newAlbum: 'Beta',
        ),
        throwsA(isA<AlbumRenameCollisionException>()),
      );

      // Neither group was touched.
      final alpha = await _waitFor(
        library.watchSongsForAlbum('Alpha', 'Some Artist'),
        (l) => l.isNotEmpty,
      );
      final beta = await _waitFor(
        library.watchSongsForAlbum('Beta', 'Some Artist'),
        (l) => l.isNotEmpty,
      );
      expect(alpha.map((t) => t.id), ['a']);
      expect(beta.map((t) => t.id), ['b']);
    });

    test('an unchanged name (after trimming) is a silent no-op', () async {
      final library = open();
      await library.insertTrack(albumTrack('a', album: 'Original'));

      await library.renameAlbum(
        album: 'Original',
        albumArtist: 'Some Artist',
        newAlbum: '  Original  ',
      );

      final tracks = await _waitFor(
        library.watchSongsForAlbum('Original', 'Some Artist'),
        (l) => l.isNotEmpty,
      );
      expect(tracks, hasLength(1));
    });

    test('trims surrounding whitespace from the new name', () async {
      final library = open();
      await library.insertTrack(albumTrack('a', album: 'Original'));

      await library.renameAlbum(
        album: 'Original',
        albumArtist: 'Some Artist',
        newAlbum: '  Renamed  ',
      );

      final renamed = await _waitFor(
        library.watchSongsForAlbum('Renamed', 'Some Artist'),
        (l) => l.isNotEmpty,
      );
      expect(renamed, hasLength(1));
    });

    test('rejects an empty (post-trim) name', () async {
      final library = open();
      await library.insertTrack(albumTrack('a', album: 'Original'));

      expect(
        () => library.renameAlbum(
          album: 'Original',
          albumArtist: 'Some Artist',
          newAlbum: '   ',
        ),
        throwsArgumentError,
      );

      final tracks = await _waitFor(
        library.watchSongsForAlbum('Original', 'Some Artist'),
        (l) => l.isNotEmpty,
      );
      expect(tracks, hasLength(1));
    });

    test('getSongsForAlbumOnce returns the actual just-renamed rows '
        'immediately, not a seeded-empty placeholder — this is the fix for '
        "the stale-playback-metadata bug: watchSongsForAlbum's stream is "
        'shareValueSeeded(const []), so `.first` on a fresh subscription can '
        'race the real query and grab the empty seed instead', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final library = LibraryRepository(db);
      await library.insertTrack(albumTrack('a', album: 'Original'));
      await library.insertTrack(albumTrack('b', album: 'Original', n: 2));

      await library.renameAlbum(
        album: 'Original',
        albumArtist: 'Some Artist',
        newAlbum: 'Renamed',
      );

      // A brand new repository instance wrapping the SAME underlying
      // database connection (not a fresh, separate in-memory database) so
      // its watchSongsForAlbum stream has never been subscribed before
      // this point -- exactly the scenario that exposes the seeded-empty
      // race. getSongsForAlbumOnce must not depend on any stream having
      // been "warmed up" already.
      final freshLibrary = LibraryRepository(db);
      final rows = await freshLibrary.getSongsForAlbumOnce(
        'Renamed',
        'Some Artist',
      );
      expect(rows.map((t) => t.id).toSet(), {'a', 'b'});
      expect(rows.every((t) => t.album == 'Renamed'), isTrue);
    });

    test(
      'two concurrent renames targeting the same destination '
      '(newAlbum, albumArtist): exactly one succeeds, the other gets '
      'AlbumRenameCollisionException, and no data is silently merged',
      () async {
        final library = open();
        await library.insertTrack(albumTrack('a', album: 'Alpha'));
        await library.insertTrack(albumTrack('x', album: 'Bravo', n: 1));
        // A pre-existing "Shared" group under a DIFFERENT albumArtist, to
        // confirm the collision is scoped correctly and this is untouched.
        await library.insertTrack(
          Track(
            id: 'z',
            filePath: '/tmp/z.mp3',
            title: 'Z',
            artist: 'Other Artist',
            album: 'Shared',
            albumArtist: 'Other Artist',
            duration: const Duration(minutes: 3),
            format: 'mp3',
            fileSizeBytes: 1000,
            dateAdded: DateTime.now(),
          ),
        );

        var successes = 0;
        var collisions = 0;
        await Future.wait([
          library
              .renameAlbum(
                album: 'Alpha',
                albumArtist: 'Some Artist',
                newAlbum: 'Shared',
              )
              .then((_) {
                successes++;
              })
              .catchError((Object e) {
                expect(e, isA<AlbumRenameCollisionException>());
                collisions++;
              }),
          library
              .renameAlbum(
                album: 'Bravo',
                albumArtist: 'Some Artist',
                newAlbum: 'Shared',
              )
              .then((_) {
                successes++;
              })
              .catchError((Object e) {
                expect(e, isA<AlbumRenameCollisionException>());
                collisions++;
              }),
        ]);

        // Exactly one of the two competing renames won; the other was
        // rejected instead of both silently merging into "Shared".
        expect(successes, 1);
        expect(collisions, 1);

        final sharedGroup = await _waitFor(
          library.watchSongsForAlbum('Shared', 'Some Artist'),
          (l) => l.isNotEmpty,
        );
        // Only the winner's single track ended up in the destination group
        // — never both (which would mean a silent merge happened).
        expect(sharedGroup, hasLength(1));

        // The loser's original group is untouched (still exists, unrenamed)
        // since its rename was rejected before any write happened. A
        // one-shot read, not `.first` on the (seeded-empty) watch stream.
        final alphaStillThere = await library.getSongsForAlbumOnce(
          'Alpha',
          'Some Artist',
        );
        final bravoStillThere = await library.getSongsForAlbumOnce(
          'Bravo',
          'Some Artist',
        );
        expect(alphaStillThere.length + bravoStillThere.length, 1);

        // The unrelated different-albumArtist "Shared" group was never
        // touched by either rename attempt.
        final otherShared = await _waitFor(
          library.watchSongsForAlbum('Shared', 'Other Artist'),
          (l) => l.isNotEmpty,
        );
        expect(otherShared.map((t) => t.id), ['z']);
      },
    );
  });
}
