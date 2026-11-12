import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:listeny/core/storage/database.dart';
import 'package:listeny/library/library_repository.dart';

/// Hand-builds the v4 schema (library_sources WITHOUT the fingerprint
/// columns) with a referenced track, a skipped source and a removed source,
/// to prove the v4 -> v5 migration keeps ownership and user data.
void _createV4Schema(String path) {
  final db = sqlite3.sqlite3.open(path);
  db.execute('''
    CREATE TABLE songs (
      id TEXT NOT NULL PRIMARY KEY, file_path TEXT NOT NULL, title TEXT NOT NULL,
      artist TEXT NOT NULL, album TEXT NOT NULL, album_artist TEXT NOT NULL,
      track_number INTEGER NULL, disc_number INTEGER NULL, year INTEGER NULL,
      duration_ms INTEGER NOT NULL, format TEXT NOT NULL,
      bitrate_kbps INTEGER NULL, sample_rate_hz INTEGER NULL, bit_depth INTEGER NULL,
      file_size_bytes INTEGER NOT NULL, date_added_ms INTEGER NOT NULL,
      artwork_path TEXT NULL, favorite INTEGER NOT NULL DEFAULT 0,
      play_count INTEGER NOT NULL DEFAULT 0, last_played_ms INTEGER NULL
    );
  ''');
  db.execute('''
    CREATE TABLE playlists (
      id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
      artwork_path TEXT NULL, created_at_ms INTEGER NOT NULL
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
  db.execute(
    'CREATE UNIQUE INDEX idx_playlist_songs_unique ON playlist_songs (playlist_id, song_id);',
  );
  db.execute('''
    CREATE TABLE download_history_entries (
      id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, source_type TEXT NOT NULL,
      status TEXT NOT NULL, output_format TEXT NULL, message TEXT NULL,
      timestamp_ms INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE library_sources (
      source_key TEXT NOT NULL PRIMARY KEY, track_id TEXT NULL,
      state TEXT NOT NULL, size_bytes INTEGER NOT NULL DEFAULT 0
    );
  ''');
  db.execute('''
    INSERT INTO songs (id, file_path, title, artist, album, album_artist,
      duration_ms, format, file_size_bytes, date_added_ms, favorite, play_count)
    VALUES ('ref', '/storage/emulated/0/Music/a.mp3', 'A', 'X', 'Al', 'X',
      200000, 'mp3', 1000, 1700000000000, 1, 7);
  ''');
  db.execute(
    "INSERT INTO library_sources VALUES ('ms:11', 'ref', 'added', 1000);",
  );
  db.execute(
    "INSERT INTO library_sources VALUES ('ms:12', 'ref', 'skipped', 500);",
  );
  db.execute(
    "INSERT INTO library_sources VALUES ('ms:13', NULL, 'removed', 700);",
  );
  db.execute('PRAGMA user_version = 4;');
  db.close();
}

void main() {
  test('v4 -> v5 keeps referenced ownership + user data, drops ambiguous skips', () async {
    final tempDir = Directory.systemTemp.createTempSync('migration_v5_test_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final dbFile = File(p.join(tempDir.path, 'listeny.sqlite'));
    _createV4Schema(dbFile.path);

    final db = AppDatabase(NativeDatabase(dbFile));
    final library = LibraryRepository(db);
    addTearDown(db.close);

    // The track and its user data survive untouched.
    final tracks = await library.getAllTracksOnce();
    expect(tracks.single.id, 'ref');
    expect(tracks.single.favorite, isTrue);
    expect(tracks.single.playCount, 7);

    final sources = await library.getLibrarySources();
    // 'added' keeps protecting its original, with the path backfilled so the
    // next sync can verify it; volume stays '' (= legacy, never trusted alone).
    final added = sources['ms:11']!;
    expect(added.state, 'added');
    expect(added.trackId, 'ref');
    expect(added.path, '/storage/emulated/0/Music/a.mp3');
    expect(added.volume, '');
    expect(await library.isReferencedTrack('ref'), isTrue);
    // Ambiguous 'skipped' rows are dropped so those sources are reconsidered.
    expect(sources.containsKey('ms:12'), isFalse);
    // 'removed' is kept (never silently re-adds while its identity matches).
    expect(sources['ms:13']!.state, 'removed');
  });
}
