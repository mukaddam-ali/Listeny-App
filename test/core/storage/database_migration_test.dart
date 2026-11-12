import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:listeny/core/storage/database.dart';

/// Hand-builds the exact v1 schema (the three tables that existed before
/// Download History was added), so this test can confirm the real
/// [AppDatabase] migration path preserves a pre-existing user's data instead
/// of wiping it — the one thing that must never happen to a migration.
void _createV1Schema(String path) {
  final db = sqlite3.sqlite3.open(path);
  db.execute('''
    CREATE TABLE songs (
      id TEXT NOT NULL PRIMARY KEY,
      file_path TEXT NOT NULL,
      title TEXT NOT NULL,
      artist TEXT NOT NULL,
      album TEXT NOT NULL,
      album_artist TEXT NOT NULL,
      track_number INTEGER NULL,
      disc_number INTEGER NULL,
      year INTEGER NULL,
      duration_ms INTEGER NOT NULL,
      format TEXT NOT NULL,
      bitrate_kbps INTEGER NULL,
      sample_rate_hz INTEGER NULL,
      bit_depth INTEGER NULL,
      file_size_bytes INTEGER NOT NULL,
      date_added_ms INTEGER NOT NULL,
      artwork_path TEXT NULL,
      favorite INTEGER NOT NULL DEFAULT 0,
      play_count INTEGER NOT NULL DEFAULT 0,
      last_played_ms INTEGER NULL
    );
  ''');
  db.execute('''
    CREATE TABLE playlists (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      artwork_path TEXT NULL,
      created_at_ms INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE playlist_songs (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      playlist_id TEXT NOT NULL REFERENCES playlists (id) ON DELETE CASCADE,
      song_id TEXT NOT NULL REFERENCES songs (id) ON DELETE CASCADE,
      position INTEGER NOT NULL
    );
  ''');
  db.execute('''
    INSERT INTO songs (
      id, file_path, title, artist, album, album_artist, duration_ms, format,
      file_size_bytes, date_added_ms, favorite, play_count
    ) VALUES (
      'existing-song', '/music/old.mp3', 'Old Favorite', 'Old Artist', 'Old Album',
      'Old Artist', 200000, 'mp3', 5000000, 1700000000000, 1, 42
    );
  ''');
  db.execute('PRAGMA user_version = 1;');
  db.close();
}

/// v2 schema (post download-history, pre unique-membership-index) with two
/// duplicate playlist_songs rows already present — the exact "old data"
/// shape a real user could have if a race created a duplicate before this
/// fix existed.
void _createV2SchemaWithDuplicateMembership(String path) {
  final db = sqlite3.sqlite3.open(path);
  db.execute('''
    CREATE TABLE songs (
      id TEXT NOT NULL PRIMARY KEY, file_path TEXT NOT NULL, title TEXT NOT NULL,
      artist TEXT NOT NULL, album TEXT NOT NULL, album_artist TEXT NOT NULL,
      track_number INTEGER NULL, disc_number INTEGER NULL, year INTEGER NULL,
      duration_ms INTEGER NOT NULL, format TEXT NOT NULL, bitrate_kbps INTEGER NULL,
      sample_rate_hz INTEGER NULL, bit_depth INTEGER NULL, file_size_bytes INTEGER NOT NULL,
      date_added_ms INTEGER NOT NULL, artwork_path TEXT NULL,
      favorite INTEGER NOT NULL DEFAULT 0, play_count INTEGER NOT NULL DEFAULT 0,
      last_played_ms INTEGER NULL
    );
  ''');
  db.execute('''
    CREATE TABLE playlists (
      id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, artwork_path TEXT NULL,
      created_at_ms INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE playlist_songs (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      playlist_id TEXT NOT NULL REFERENCES playlists (id) ON DELETE CASCADE,
      song_id TEXT NOT NULL REFERENCES songs (id) ON DELETE CASCADE,
      position INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE download_history_entries (
      id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, source_type TEXT NOT NULL,
      status TEXT NOT NULL, output_format TEXT NULL, message TEXT NULL,
      timestamp_ms INTEGER NOT NULL
    );
  ''');
  db.execute('''
    INSERT INTO songs (id, file_path, title, artist, album, album_artist, duration_ms, format, file_size_bytes, date_added_ms)
    VALUES ('song-a', '/music/a.mp3', 'A', 'Artist', 'Album', 'Artist', 200000, 'mp3', 5000000, 1700000000000);
  ''');
  db.execute('''
    INSERT INTO playlists (id, name, created_at_ms) VALUES ('pl-1', 'My Mix', 1700000000000);
  ''');
  // Two duplicate rows for the same (playlist, song) — exactly what the
  // pre-fix race could leave behind.
  db.execute('''
    INSERT INTO playlist_songs (playlist_id, song_id, position) VALUES ('pl-1', 'song-a', 0);
  ''');
  db.execute('''
    INSERT INTO playlist_songs (playlist_id, song_id, position) VALUES ('pl-1', 'song-a', 1);
  ''');
  db.execute('PRAGMA user_version = 2;');
  db.close();
}

void main() {
  test('upgrading from v2 to v3 collapses pre-existing duplicate playlist membership without crashing', () async {
    final tempDir = Directory.systemTemp.createTempSync('migration_v3_test_');
    final dbFile = File(p.join(tempDir.path, 'listeny.sqlite'));
    addTearDown(() => tempDir.deleteSync(recursive: true));

    _createV2SchemaWithDuplicateMembership(dbFile.path);

    final db = AppDatabase(NativeDatabase(dbFile));
    final members = await db.watchPlaylistSongs('pl-1').first;
    expect(members, hasLength(1));
    expect(members.single.id, 'song-a');

    // The unique index now really exists and is enforced going forward.
    await db.addSongToPlaylist('pl-1', 'song-a');
    final afterReAdd = await db.watchPlaylistSongs('pl-1').first;
    expect(afterReAdd, hasLength(1));

    await db.close();
  });

  test(
    'upgrading from v1 to v2 keeps existing songs and adds download history',
    () async {
      final tempDir = Directory.systemTemp.createTempSync('migration_test_');
      final dbFile = File(p.join(tempDir.path, 'listeny.sqlite'));
      addTearDown(() => tempDir.deleteSync(recursive: true));

      _createV1Schema(dbFile.path);

      // Opening the REAL AppDatabase against this pre-existing v1 file is what
      // exercises the real MigrationStrategy, not a hand-rolled substitute.
      final db = AppDatabase(NativeDatabase(dbFile));
      final songs = await db.getAllSongsOnce();

      expect(songs, hasLength(1));
      final existing = songs.single;
      expect(existing.id, 'existing-song');
      expect(existing.title, 'Old Favorite');
      expect(existing.favorite, isTrue);
      expect(existing.playCount, 42);

      // The new table exists and is usable post-migration.
      await db.insertDownloadHistoryEntry(
        DownloadHistoryEntriesCompanion.insert(
          id: 'h1',
          title: 'New download',
          sourceType: 'direct',
          status: 'success',
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      final history = await db.watchDownloadHistory().first;
      expect(history, hasLength(1));

      await db.close();

      final raw = sqlite3.sqlite3.open(dbFile.path);
      final version =
          raw.select('PRAGMA user_version;').first['user_version'] as int;
      final hasSources = raw
          .select(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name='library_sources'",
          )
          .isNotEmpty;
      raw.close();
      // Migrates all the way through to the current schema (v3 added the
      // playlist-membership unique index, v4 the library_sources table for
      // the local-library sync), not just v2.
      expect(version, 5);
      expect(hasSources, isTrue);
    },
  );
}
