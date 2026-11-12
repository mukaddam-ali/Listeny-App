import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../diagnostics/startup_log.dart';

part 'database.g.dart';

/// Real, persistent song rows. Everything the import pipeline reads about a
/// file lives here, so the library survives app restarts.
class Songs extends Table {
  TextColumn get id => text()();
  TextColumn get filePath => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get album => text()();
  TextColumn get albumArtist => text()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get year => integer().nullable()();
  IntColumn get durationMs => integer()();
  TextColumn get format => text()();
  IntColumn get bitrateKbps => integer().nullable()();
  IntColumn get sampleRateHz => integer().nullable()();
  IntColumn get bitDepth => integer().nullable()();
  IntColumn get fileSizeBytes => integer()();
  IntColumn get dateAddedMs => integer()();
  TextColumn get artworkPath => text().nullable()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  IntColumn get lastPlayedMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Bookkeeping for the automatic local-library sync (MediaStore scan).
///
/// One row per MediaStore item the sync has already evaluated, keyed by a
/// stable source identity (never a filename). `state`:
/// - 'added'   — a library [Songs] row (`trackId`) references the ORIGINAL
///               file in place (nothing was copied).
/// - 'skipped' — evaluated and deliberately not added (e.g. it duplicates a
///               track already in the library), remembered so repeated syncs
///               don't re-read it.
/// - 'removed' — the user removed that referenced track; never re-added.
/// A row is never deleted just because the item vanished from MediaStore.
class LibrarySources extends Table {
  TextColumn get sourceKey => text()();
  TextColumn get trackId => text().nullable()();
  TextColumn get state => text()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();

  // Source fingerprint (v5). `sourceKey` is 'ms:<volume>:<id>'; rows from v4
  // have volume '' (legacy, ambiguous identity — never trusted on their own).
  TextColumn get volume => text().withDefault(const Constant(''))();
  TextColumn get path => text().withDefault(const Constant(''))();
  IntColumn get modifiedSec => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {sourceKey};
}

class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Custom artwork path if the user chose one; null means "generate a
  /// collage from member songs" (computed at read time, not stored).
  TextColumn get artworkPath => text().nullable()();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ordered membership of songs within a playlist.
class PlaylistSongs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId =>
      text().references(Playlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get songId =>
      text().references(Songs, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
}

/// A record of one completed download/import attempt from the Download tab.
/// Deliberately holds no URL column — the original link isn't useful once
/// the attempt is done, so it's never persisted (see [AppDatabase.
/// insertDownloadHistoryEntry]).
class DownloadHistoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();

  /// 'direct' | 'googleDrive'.
  TextColumn get sourceType => text()();

  /// 'success' | 'failed'.
  TextColumn get status => text()();

  /// The output file's extension (e.g. 'm4a', 'mp3') — only set on success.
  TextColumn get outputFormat => text().nullable()();

  /// Short failure reason — only set on failure.
  TextColumn get message => text().nullable()();
  IntColumn get timestampMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class AlbumSummary {
  final String album;
  final String albumArtist;
  final String? artworkPath;
  final int? year;
  final int songCount;

  const AlbumSummary({
    required this.album,
    required this.albumArtist,
    required this.artworkPath,
    required this.year,
    required this.songCount,
  });
}

/// Thrown from inside [AppDatabase.renameAlbumAtomic]'s transaction when the
/// destination (newAlbum, albumArtist) group already exists as a DIFFERENT
/// group than the one being renamed — rolls the transaction back. Storage-
/// layer internal; callers (LibraryRepository.renameAlbum) translate this
/// into the public AlbumRenameCollisionException.
class AlbumRenameCollision implements Exception {
  const AlbumRenameCollision();
}

class ArtistSummary {
  final String artist;
  final int songCount;
  final int albumCount;

  const ArtistSummary({
    required this.artist,
    required this.songCount,
    required this.albumCount,
  });
}

@DriftDatabase(
  tables: [
    Songs,
    Playlists,
    PlaylistSongs,
    DownloadHistoryEntries,
    LibrarySources,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static Future<AppDatabase> open() async {
    final dir = await StartupLog.stage(
      'application documents directory',
      getApplicationDocumentsDirectory,
    );
    final file = File(p.join(dir.path, 'listeny.sqlite'));
    // Drift opens the connection lazily on the first query; migration and
    // readiness are logged from [migration] below (onCreate/onUpgrade/
    // beforeOpen).
    final db = StartupLog.stageSync(
      'database construction (lazy; not yet opened)',
      () => AppDatabase(NativeDatabase.createInBackground(file)),
    );
    StartupLog.mark('database first query will trigger open + migration');
    return db;
  }

  @override
  int get schemaVersion => 5;

  static const _uniquePlaylistSongIndex =
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_playlist_songs_unique '
      'ON playlist_songs (playlist_id, song_id)';

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      StartupLog.mark(
        'database ready (beforeOpen) created=${details.wasCreated} '
        'schema ${details.versionBefore}->${details.versionNow}',
      );
    },
    onCreate: (m) async {
      StartupLog.mark('database migration onCreate START');
      await m.createAll();
      await m.database.customStatement(_uniquePlaylistSongIndex);
      StartupLog.mark('database migration onCreate END');
    },
    onUpgrade: (m, from, to) async {
      StartupLog.mark('database migration onUpgrade $from->$to START');
      // v1 -> v2: added DownloadHistoryEntries. Every earlier table is
      // untouched, so existing songs/playlists/favorites/history survive
      // the upgrade unchanged.
      if (from < 2) await m.createTable(downloadHistoryEntries);
      // v2 -> v3: enforce playlist membership uniqueness at the DB level
      // (addSongToPlaylist used to check-then-insert, which isn't safe
      // against concurrent calls). Existing duplicate rows are collapsed
      // first — keeping the earliest one per (playlist, song), which
      // preserves every surviving row's original position — since the
      // unique index itself can't be created over data that violates it.
      if (from < 3) {
        await m.database.customStatement('''
          DELETE FROM playlist_songs
          WHERE id NOT IN (
            SELECT MIN(id) FROM playlist_songs GROUP BY playlist_id, song_id
          )
        ''');
        await m.database.customStatement(_uniquePlaylistSongIndex);
      }
      // v3 -> v4: added LibrarySources (automatic local-library sync). Purely
      // additive; every existing table and row is untouched.
      if (from < 4) await m.createTable(librarySources);
      // v4 -> v5: source fingerprint (volume, path, modified time). Legacy v4
      // rows had only a bare MediaStore id (ambiguous across volumes / reused
      // ids): keep 'added' rows (they protect their referenced originals) and
      // backfill their path from the track so they can be re-verified, but
      // drop 'skipped' rows so those sources are reconsidered.
      if (from == 4) {
        await m.addColumn(librarySources, librarySources.volume);
        await m.addColumn(librarySources, librarySources.path);
        await m.addColumn(librarySources, librarySources.modifiedSec);
        await m.database.customStatement(
          "UPDATE library_sources SET path = COALESCE((SELECT file_path "
          "FROM songs WHERE songs.id = library_sources.track_id), '') "
          "WHERE state = 'added' AND track_id IS NOT NULL",
        );
        await m.database.customStatement(
          "DELETE FROM library_sources WHERE state = 'skipped'",
        );
      }
      StartupLog.mark('database migration onUpgrade END');
    },
  );

  // --- Library sources (automatic local sync) ---

  Future<List<LibrarySource>> allLibrarySources() =>
      select(librarySources).get();

  Future<LibrarySource?> librarySourceForTrack(String trackId) =>
      (select(librarySources)
            ..where((r) => r.trackId.equals(trackId) & r.state.equals('added')))
          .getSingleOrNull();

  Future<LibrarySource?> librarySource(String sourceKey) => (select(
    librarySources,
  )..where((r) => r.sourceKey.equals(sourceKey))).getSingleOrNull();

  Future<void> upsertLibrarySource({
    required String sourceKey,
    required String? trackId,
    required String state,
    required int sizeBytes,
    String volume = '',
    String path = '',
    int modifiedSec = 0,
  }) => into(librarySources).insertOnConflictUpdate(
    LibrarySourcesCompanion.insert(
      sourceKey: sourceKey,
      trackId: Value(trackId),
      state: state,
      sizeBytes: Value(sizeBytes),
      volume: Value(volume),
      path: Value(path),
      modifiedSec: Value(modifiedSec),
    ),
  );

  Future<void> deleteLibrarySource(String sourceKey) => (delete(
    librarySources,
  )..where((r) => r.sourceKey.equals(sourceKey))).go();

  /// Re-keys a source row (keeps its state/track, so ownership of a
  /// referenced track is never lost when an identity turns out stale).
  Future<void> renameLibrarySource(String from, String to) =>
      (update(librarySources)..where((r) => r.sourceKey.equals(from))).write(
        LibrarySourcesCompanion(sourceKey: Value(to)),
      );

  /// Whether any song or playlist still points at artwork file [path].
  Future<bool> artworkPathReferenced(String path) async {
    final inSongs =
        await (select(songs)
              ..where((r) => r.artworkPath.equals(path))
              ..limit(1))
            .get();
    if (inSongs.isNotEmpty) return true;
    final inPlaylists =
        await (select(playlists)
              ..where((r) => r.artworkPath.equals(path))
              ..limit(1))
            .get();
    return inPlaylists.isNotEmpty;
  }

  Future<bool> songExistsWithPath(String path) async => (await (select(
    songs,
  )..where((s) => s.filePath.equals(path))).get()).isNotEmpty;

  Future<void> updateSongLocation(String id, String path, int sizeBytes) =>
      (update(songs)..where((s) => s.id.equals(id))).write(
        SongsCompanion(filePath: Value(path), fileSizeBytes: Value(sizeBytes)),
      );

  /// Marks the referenced track's source 'removed' (kept so a later sync
  /// doesn't silently re-add something the user deleted). Only the row that
  /// OWNS the track ('added'), never skipped rows that merely point at it.
  Future<void> markLibrarySourceRemoved(String trackId) =>
      (update(librarySources)
            ..where((r) => r.trackId.equals(trackId) & r.state.equals('added')))
          .write(
            const LibrarySourcesCompanion(
              trackId: Value(null),
              state: Value('removed'),
            ),
          );

  // --- Songs ---

  Future<void> insertSong(SongsCompanion song) => into(songs).insert(song);

  Stream<List<Song>> watchAllSongs({bool favoritesOnly = false}) {
    final query = select(songs)..orderBy([(s) => OrderingTerm.asc(s.title)]);
    if (favoritesOnly) query.where((s) => s.favorite.equals(true));
    return query.watch();
  }

  Future<List<Song>> getAllSongsOnce() => select(songs).get();

  Future<void> setFavorite(String id, bool favorite) =>
      (update(songs)..where((s) => s.id.equals(id))).write(
        SongsCompanion(favorite: Value(favorite)),
      );

  Future<void> renameSong(String id, String title) => (update(
    songs,
  )..where((s) => s.id.equals(id))).write(SongsCompanion(title: Value(title)));

  // customUpdate (not customStatement): declaring `updates: {songs}` is what
  // tells drift's reactive watch queries (watchRecentlyPlayed, etc.) to
  // refresh — a plain customStatement bypasses that invalidation entirely.
  Future<void> recordPlay(String id) => customUpdate(
    'UPDATE songs SET play_count = play_count + 1, last_played_ms = ? WHERE id = ?',
    variables: [
      Variable.withInt(DateTime.now().millisecondsSinceEpoch),
      Variable.withString(id),
    ],
    updates: {songs},
  );

  Future<void> deleteSong(String id) =>
      (delete(songs)..where((s) => s.id.equals(id))).go();

  Stream<List<Song>> watchRecentlyAdded({int limit = 15}) =>
      (select(songs)
            ..orderBy([(s) => OrderingTerm.desc(s.dateAddedMs)])
            ..limit(limit))
          .watch();

  Stream<List<Song>> watchRecentlyPlayed({int limit = 15}) =>
      (select(songs)
            ..where((s) => s.lastPlayedMs.isNotNull())
            ..orderBy([(s) => OrderingTerm.desc(s.lastPlayedMs)])
            ..limit(limit))
          .watch();

  // --- Albums / Artists (derived, no separate tables) ---

  Stream<List<AlbumSummary>> watchAlbums() {
    final countExp = songs.id.count();
    final query = selectOnly(songs)
      ..addColumns([
        songs.album,
        songs.albumArtist,
        songs.artworkPath,
        songs.year,
        countExp,
      ])
      ..groupBy([songs.album, songs.albumArtist])
      ..orderBy([OrderingTerm.asc(songs.album)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => AlbumSummary(
              album: row.read(songs.album)!,
              albumArtist: row.read(songs.albumArtist)!,
              artworkPath: row.read(songs.artworkPath),
              year: row.read(songs.year),
              songCount: row.read(countExp)!,
            ),
          )
          .toList(),
    );
  }

  Stream<List<Song>> watchSongsForAlbum(String album, String albumArtist) =>
      (select(songs)
            ..where(
              (s) => s.album.equals(album) & s.albumArtist.equals(albumArtist),
            )
            ..orderBy([
              (s) => OrderingTerm.asc(s.discNumber),
              (s) => OrderingTerm.asc(s.trackNumber),
            ]))
          .watch();

  /// One-shot (non-reactive) read of the exact (album, albumArtist) group —
  /// unlike [watchSongsForAlbum], never seeded with `[]`, so a caller that
  /// needs the actual current rows right now (e.g. right after a rename, to
  /// refresh an in-flight playback queue) can await this directly instead of
  /// racing a seeded stream's placeholder first value.
  Future<List<Song>> getSongsForAlbumOnce(String album, String albumArtist) =>
      (select(songs)
            ..where(
              (s) => s.album.equals(album) & s.albumArtist.equals(albumArtist),
            )
            ..orderBy([
              (s) => OrderingTerm.asc(s.discNumber),
              (s) => OrderingTerm.asc(s.trackNumber),
            ]))
          .get();

  /// Whether any song already belongs to the (album, albumArtist) group —
  /// used to detect a rename collision before it happens.
  Future<bool> albumGroupExists(String album, String albumArtist) async {
    final row =
        await (select(songs)
              ..where(
                (s) =>
                    s.album.equals(album) & s.albumArtist.equals(albumArtist),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Renames every song in the exact (album, albumArtist) group — the only
  /// thing that changes is the `album` column; track ids, files, artist/
  /// albumArtist, favorites, playlist membership and play counts are all
  /// untouched since they live on the same, unmoved rows.
  Future<void> renameAlbum(String album, String albumArtist, String newAlbum) =>
      (update(songs)..where(
            (s) => s.album.equals(album) & s.albumArtist.equals(albumArtist),
          ))
          .write(SongsCompanion(album: Value(newAlbum)));

  /// Checks for a destination-group collision and performs the rename in
  /// ONE transaction, so two concurrent renames targeting the same
  /// (newAlbum, albumArtist) can never both pass the check and silently
  /// merge: drift serializes transactions on a given database connection,
  /// so the second call's [albumGroupExists] check only ever runs once the
  /// first transaction has fully committed (or rolled back) — there is no
  /// window where both can observe "no collision yet". Throws
  /// [AlbumRenameCollision] (which rolls the transaction back) if a
  /// DIFFERENT existing group already has (newAlbum, albumArtist).
  Future<void> renameAlbumAtomic(
    String album,
    String albumArtist,
    String newAlbum,
  ) => transaction(() async {
    if (await albumGroupExists(newAlbum, albumArtist)) {
      throw const AlbumRenameCollision();
    }
    await renameAlbum(album, albumArtist, newAlbum);
  });

  Stream<List<ArtistSummary>> watchArtists() {
    final songCountExp = songs.id.count();
    final albumCountExp = songs.album.count(distinct: true);
    final query = selectOnly(songs)
      ..addColumns([songs.artist, songCountExp, albumCountExp])
      ..groupBy([songs.artist])
      ..orderBy([OrderingTerm.asc(songs.artist)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => ArtistSummary(
              artist: row.read(songs.artist)!,
              songCount: row.read(songCountExp)!,
              albumCount: row.read(albumCountExp)!,
            ),
          )
          .toList(),
    );
  }

  Stream<List<Song>> watchSongsForArtist(String artist) =>
      (select(songs)..where((s) => s.artist.equals(artist))).watch();

  Stream<List<Song>> watchMostPlayedForArtist(String artist, {int limit = 5}) =>
      (select(songs)
            ..where(
              (s) => s.artist.equals(artist) & s.playCount.isBiggerThanValue(0),
            )
            ..orderBy([(s) => OrderingTerm.desc(s.playCount)])
            ..limit(limit))
          .watch();

  // --- Playlists ---

  Future<void> createPlaylist(String id, String name, {String? artworkPath}) =>
      into(playlists).insert(
        PlaylistsCompanion.insert(
          id: id,
          name: name,
          artworkPath: Value(artworkPath),
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  Future<void> renamePlaylist(String id, String name) =>
      (update(playlists)..where((p) => p.id.equals(id))).write(
        PlaylistsCompanion(name: Value(name)),
      );

  Future<void> updatePlaylistArtwork(String id, String? artworkPath) =>
      (update(playlists)..where((p) => p.id.equals(id))).write(
        PlaylistsCompanion(artworkPath: Value(artworkPath)),
      );

  Future<void> deletePlaylist(String id) =>
      (delete(playlists)..where((p) => p.id.equals(id))).go();

  Stream<List<Playlist>> watchPlaylists() => (select(
    playlists,
  )..orderBy([(p) => OrderingTerm.asc(p.createdAtMs)])).watch();

  /// A no-op when [songId] is already a member of [playlistId] — enforced by
  /// a real unique index (see [_uniquePlaylistSongIndex]) rather than a
  /// check-then-insert, so it stays correct even under concurrent calls and
  /// never trips over pre-existing duplicate rows from older data.
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final current = await (select(
      playlistSongs,
    )..where((ps) => ps.playlistId.equals(playlistId))).get();
    final nextPosition = current.isEmpty
        ? 0
        : current.map((e) => e.position).reduce((a, b) => a > b ? a : b) + 1;
    await into(playlistSongs).insert(
      PlaylistSongsCompanion.insert(
        playlistId: playlistId,
        songId: songId,
        position: nextPosition,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) =>
      (delete(playlistSongs)..where(
            (ps) => ps.playlistId.equals(playlistId) & ps.songId.equals(songId),
          ))
          .go();

  Future<void> reorderPlaylistSongs(
    String playlistId,
    List<String> orderedSongIds,
  ) async {
    await transaction(() async {
      for (var i = 0; i < orderedSongIds.length; i++) {
        await (update(playlistSongs)..where(
              (ps) =>
                  ps.playlistId.equals(playlistId) &
                  ps.songId.equals(orderedSongIds[i]),
            ))
            .write(PlaylistSongsCompanion(position: Value(i)));
      }
    });
  }

  Stream<List<Song>> watchPlaylistSongs(String playlistId) {
    final query =
        select(playlistSongs)
            .join([innerJoin(songs, songs.id.equalsExp(playlistSongs.songId))])
          ..where(playlistSongs.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(playlistSongs.position)]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(songs)).toList(),
    );
  }

  // --- Download history ---

  Future<void> insertDownloadHistoryEntry(
    DownloadHistoryEntriesCompanion entry,
  ) => into(downloadHistoryEntries).insert(entry);

  Stream<List<DownloadHistoryEntry>> watchDownloadHistory({int limit = 50}) =>
      (select(downloadHistoryEntries)
            ..orderBy([(e) => OrderingTerm.desc(e.timestampMs)])
            ..limit(limit))
          .watch();

  Future<void> clearDownloadHistory() => delete(downloadHistoryEntries).go();
}
