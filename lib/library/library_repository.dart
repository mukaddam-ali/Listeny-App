import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import '../core/diagnostics/perf_log.dart';
import '../core/diagnostics/startup_log.dart';
import '../core/models/track.dart';
import '../core/storage/database.dart';

class Album {
  final String name;
  final String artist;
  final String? artworkPath;
  final int? year;
  final int songCount;

  const Album({
    required this.name,
    required this.artist,
    required this.artworkPath,
    required this.year,
    required this.songCount,
  });
}

class Artist {
  final String name;
  final int songCount;
  final int albumCount;

  const Artist({
    required this.name,
    required this.songCount,
    required this.albumCount,
  });
}

class Playlist {
  final String id;
  final String name;
  final String? artworkPath;
  final DateTime createdAt;
  final int songCount;

  const Playlist({
    required this.id,
    required this.name,
    required this.artworkPath,
    required this.createdAt,
    required this.songCount,
  });
}

/// One completed download/import attempt from the Download tab. Never
/// carries the original URL — see [DownloadHistoryEntries].
class DownloadHistoryEntry {
  final String id;
  final String title;
  final String sourceType;
  final String status;
  final String? outputFormat;
  final String? message;
  final DateTime timestamp;

  const DownloadHistoryEntry({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.status,
    required this.outputFormat,
    required this.message,
    required this.timestamp,
  });

  bool get succeeded => status == 'success';
}

/// Thrown by [LibraryRepository.renameAlbum] when the requested new name
/// would collide with a different, already-existing (album, albumArtist)
/// group — renaming never silently merges two distinct albums.
class AlbumRenameCollisionException implements Exception {
  const AlbumRenameCollisionException();
}

/// The single source of truth for the real, persistent library. Every screen
/// reads through here — never directly through [AppDatabase] — so the app
/// only ever deals in [Track]/[Album]/[Artist]/[Playlist], not database rows.
class LibraryRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  /// The app's own documents directory (where imported audio lives under
  /// `audio/` and artwork under `artwork/`). Only files provably inside it
  /// are ever physically deleted by the library; injectable for tests.
  final Future<Directory> Function() _appDocsDir;

  LibraryRepository(this._db, {Future<Directory> Function()? appDocsDir})
    : _appDocsDir = appDocsDir ?? getApplicationDocumentsDirectory;

  bool _syncActive = false;

  /// One active local-library sync per library, shared by every sync service
  /// instance (first-launch and Settings alike). Returns false if one is
  /// already running.
  bool tryBeginSync() {
    if (_syncActive) return false;
    _syncActive = true;
    return true;
  }

  void endSync() => _syncActive = false;

  /// Fail closed: true only when [path] is provably inside the app's own
  /// documents directory. Any uncertainty (lookup failure, outside path)
  /// means "not owned" and therefore never authorizes a physical delete.
  Future<bool> _isAppOwned(String path) async {
    try {
      final dir = await _appDocsDir();
      return p.isWithin(p.normalize(dir.path), p.normalize(path));
    } catch (_) {
      return false;
    }
  }

  static Future<LibraryRepository> open() async =>
      LibraryRepository(await AppDatabase.open());

  Track _toTrack(Song row) => Track(
    id: row.id,
    filePath: row.filePath,
    title: row.title,
    artist: row.artist,
    album: row.album,
    albumArtist: row.albumArtist,
    trackNumber: row.trackNumber,
    discNumber: row.discNumber,
    year: row.year,
    duration: Duration(milliseconds: row.durationMs),
    format: row.format,
    bitrateKbps: row.bitrateKbps,
    sampleRateHz: row.sampleRateHz,
    bitDepth: row.bitDepth,
    fileSizeBytes: row.fileSizeBytes,
    dateAdded: DateTime.fromMillisecondsSinceEpoch(row.dateAddedMs),
    artworkPath: row.artworkPath,
    favorite: row.favorite,
    playCount: row.playCount,
  );

  Future<void> insertTrack(Track track) => _db.insertSong(
    SongsCompanion.insert(
      id: track.id,
      filePath: track.filePath,
      title: track.title,
      artist: track.artist,
      album: track.album,
      albumArtist: track.albumArtist,
      trackNumber: Value(track.trackNumber),
      discNumber: Value(track.discNumber),
      year: Value(track.year),
      durationMs: track.duration.inMilliseconds,
      format: track.format,
      bitrateKbps: Value(track.bitrateKbps),
      sampleRateHz: Value(track.sampleRateHz),
      bitDepth: Value(track.bitDepth),
      fileSizeBytes: track.fileSizeBytes,
      dateAddedMs: track.dateAdded.millisecondsSinceEpoch,
      artworkPath: Value(track.artworkPath),
    ),
  );

  ValueStream<List<Track>> watchAllTracks() => StartupLog.traceFirst(
    _db.watchAllSongs().map((rows) => rows.map(_toTrack).toList()),
    'watchAllTracks',
    (tracks) => tracks.length,
  ).shareValueSeeded(const []);

  ValueStream<List<Track>> watchFavorites() => StartupLog.traceFirst(
    _db
        .watchAllSongs(favoritesOnly: true)
        .map((rows) => rows.map(_toTrack).toList()),
    'watchFavorites',
    (tracks) => tracks.length,
  ).shareValueSeeded(const []);

  Future<List<Track>> getAllTracksOnce() async =>
      (await _db.getAllSongsOnce()).map(_toTrack).toList();

  ValueStream<List<Track>> watchRecentlyAdded({int limit = 15}) =>
      StartupLog.traceFirst(
        _db
            .watchRecentlyAdded(limit: limit)
            .map((rows) => rows.map(_toTrack).toList()),
        'watchRecentlyAdded',
        (tracks) => tracks.length,
      ).shareValueSeeded(const []);

  ValueStream<List<Track>> watchRecentlyPlayed({int limit = 15}) =>
      StartupLog.traceFirst(
        _db
            .watchRecentlyPlayed(limit: limit)
            .map((rows) => rows.map(_toTrack).toList()),
        'watchRecentlyPlayed',
        (tracks) => tracks.length,
      ).shareValueSeeded(const []);

  Future<void> setFavorite(String trackId, bool favorite) =>
      _db.setFavorite(trackId, favorite);

  Future<void> renameTrack(String trackId, String title) =>
      _db.renameSong(trackId, title);

  Future<void> recordPlay(String trackId) => _db.recordPlay(trackId);

  /// Removes the song from the library AND deletes its on-disk copy (audio +
  /// artwork) — a real, complete delete that frees the storage it used.
  /// Returns false when the track was kept (see [deleteTracksFromDevice]).
  Future<bool> deleteTrackFromDevice(Track track) async =>
      (await deleteTracksFromDevice([track])).isNotEmpty;

  /// Deletes [tracks] from the device and the library; returns the ids that
  /// were removed.
  ///
  /// A track the local-library sync merely REFERENCES (the user's original
  /// file) has its original deleted only through Android's own confirmation
  /// dialog, ONE dialog for the whole batch, and only when the recorded
  /// MediaStore identity (volume, id, path, size) still matches. If the user
  /// declines, or the identity is uncertain, the track stays in the library.
  Future<Set<String>> deleteTracksFromDevice(List<Track> tracks) async {
    final sources = <String, LibrarySource>{};
    for (final t in tracks) {
      final row = await _db.librarySourceForTrack(t.id);
      if (row != null) sources[t.id] = row;
    }
    final kept = <String>{};
    final requests = <Track>[];
    final payload = <Map<String, Object?>>[];
    for (final t in tracks) {
      final row = sources[t.id];
      if (row == null) continue;
      final parts = row.sourceKey.split(':');
      final id = parts.length == 3 ? int.tryParse(parts[2]) : null;
      if (id == null || row.volume.isEmpty || row.path != t.filePath) {
        kept.add(t.id); // legacy/ambiguous identity: never guess a target
        continue;
      }
      requests.add(t);
      payload.add({
        'volume': row.volume,
        'id': id,
        'path': row.path,
        'size': row.sizeBytes,
      });
    }
    if (requests.isNotEmpty) {
      try {
        final res = await _mediaStoreChannel.invokeMethod<List<Object?>>(
          'deleteMediaFiles',
          {'items': payload},
        );
        for (var i = 0; i < requests.length; i++) {
          if (res == null || i >= res.length || res[i] != true) {
            kept.add(requests[i].id);
          }
        }
      } on MissingPluginException {
        // Not running on Android: library-only removal, original untouched.
      } catch (_) {
        kept.addAll(requests.map((t) => t.id));
      }
    }
    final removed = <String>{};
    for (final track in tracks) {
      if (kept.contains(track.id)) continue;
      final referenced = sources.containsKey(track.id);
      // Physical deletion needs POSITIVE proof the file is app-owned (inside
      // the app's own directory) and not a synced reference; if ownership is
      // uncertain for any reason, the file is left alone.
      final deleteAudio = !referenced && await _isAppOwned(track.filePath);
      await _db.deleteSong(track.id);
      if (referenced) await _db.markLibrarySourceRemoved(track.id);
      if (deleteAudio) await _deleteQuietly(track.filePath);
      // Artwork goes through the coordinated, reference-aware delete: shared
      // files survive, external files are never physically deleted.
      final art = track.artworkPath;
      if (art != null) await deleteArtworkIfUnreferenced(art);
      removed.add(track.id);
    }
    return removed;
  }

  static const _mediaStoreChannel = MethodChannel('listeny/media_store');

  /// Removes the song from the library only — the row disappears from the
  /// app, but its copied audio/artwork files are left on disk untouched.
  Future<void> removeTrackFromLibraryOnly(Track track) async {
    final referenced = await isReferencedTrack(track.id);
    await _db.deleteSong(track.id);
    if (referenced) await _db.markLibrarySourceRemoved(track.id);
  }

  // Serializes the only writers that can point a record at an ARBITRARY
  // existing artwork file (playlist artwork) against the check-then-delete
  // below. (A database transaction does not queue other writers, so it can't
  // provide this.) Tracks only ever reference brand-new unique files.
  Future<void> _artworkLock = Future.value();

  Future<T> _withArtworkLock<T>(Future<T> Function() action) {
    final previous = _artworkLock;
    final done = Completer<void>();
    _artworkLock = done.future;
    return previous.then((_) => action()).whenComplete(done.complete);
  }

  /// Deletes an artwork file ONLY if nothing references it. The reference
  /// check and [deleteFile] run under the artwork lock that every
  /// playlist-artwork writer also takes, so no new reference can start between
  /// the check and the physical delete. Returns true if deleted, false if
  /// retained (still referenced).
  Future<bool> _deleteArtworkFileIfUnreferenced(
    String path,
    Future<void> Function() deleteFile,
  ) => _withArtworkLock(() async {
    if (await _db.artworkPathReferenced(path)) return false;
    await deleteFile();
    return true;
  });

  // Extensions an artwork file can have (the picker keeps the original one).
  static const _artworkExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.bmp',
    '.heic',
    '.heif',
  };

  /// True only for a verified app-owned ARTWORK file: it exists, has an image
  /// extension, and its REAL (symlink-resolved) location is inside the
  /// canonical `<appDocs>/artwork` directory — nowhere else in app storage
  /// (so never the audio folder, the database, its journals or preferences),
  /// and nothing outside it. Any uncertainty or error means false.
  Future<bool> _isOwnedArtworkFile(String path) async {
    try {
      if (!_artworkExtensions.contains(p.extension(path).toLowerCase())) {
        return false;
      }
      final docs = await _appDocsDir();
      final artworkReal = await Directory(p.join(docs.path, 'artwork'))
          .resolveSymbolicLinks();
      final real = await File(path).resolveSymbolicLinks();
      return p.isWithin(artworkReal, real);
    } catch (_) {
      return false;
    }
  }

  /// The single, coordinated way to physically remove an artwork file that a
  /// track or playlist used to reference (track deletion, playlist artwork
  /// replace/remove). Call it AFTER the database no longer points at [path].
  /// It deletes ONLY verified app-owned artwork files inside the canonical
  /// artwork directory (never audio, the database, preferences, or anything
  /// external) and never one that a track or playlist still references; when
  /// in doubt the file is kept. Returns true only if it was deleted.
  Future<bool> deleteArtworkIfUnreferenced(String path) async {
    if (!await _isOwnedArtworkFile(path)) return false;
    try {
      return await _deleteArtworkFileIfUnreferenced(path, () async {
        final f = File(path);
        if (await f.exists()) await f.delete();
      });
    } catch (_) {
      return false; // best-effort: a leftover file beats a risky delete
    }
  }

  /// An artwork file can be stored as a reference only if it exists and can
  /// be opened right now.
  Future<bool> _artworkAccessible(String path) async {
    try {
      final f = File(path);
      if (!await f.exists()) return false;
      final raf = await f.open();
      await raf.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Automatic local-library sync support ---

  /// True when [trackId] is an in-place reference to a user's original file
  /// (created by the local-library sync) rather than an app-owned copy.
  Future<bool> isReferencedTrack(String trackId) async {
    final row = await _db.librarySourceForTrack(trackId);
    return row != null && row.state == 'added';
  }

  /// Every source the sync has already evaluated, by source key.
  Future<Map<String, LibrarySource>> getLibrarySources() async => {
    for (final r in await _db.allLibrarySources()) r.sourceKey: r,
  };

  Future<LibrarySource?> getLibrarySource(String sourceKey) =>
      _db.librarySource(sourceKey);

  /// Atomically claims [sourceKey] AND inserts its referenced [track] in one
  /// transaction. Returns false (inserting nothing) when the source is
  /// already owned/removed, or a track already points at this path — so two
  /// concurrent syncs can never both insert it, and a track can never exist
  /// without its owning source row. A 'skipped' row is overwritten
  /// (reconsideration).
  Future<bool> claimReferencedTrack(
    Track track, {
    required String sourceKey,
    required String volume,
    required int sizeBytes,
    required int modifiedSec,
  }) => _db.transaction(() async {
    final existing = await _db.librarySource(sourceKey);
    if (existing != null && existing.state != 'skipped') return false;
    if (await _db.songExistsWithPath(track.filePath)) return false;
    await insertTrack(track);
    await _db.upsertLibrarySource(
      sourceKey: sourceKey,
      trackId: track.id,
      state: 'added',
      sizeBytes: sizeBytes,
      volume: volume,
      path: track.filePath,
      modifiedSec: modifiedSec,
    );
    return true;
  });

  /// Remembers a source evaluated and deliberately not added because it
  /// duplicates [duplicateOfTrackId] (same title/artist/duration AND size).
  /// No-op if the source meanwhile became owned.
  Future<void> recordSkippedSource(
    String sourceKey, {
    required String duplicateOfTrackId,
    required String volume,
    required String path,
    required int sizeBytes,
    required int modifiedSec,
  }) => _db.transaction(() async {
    final existing = await _db.librarySource(sourceKey);
    if (existing != null && existing.state != 'skipped') return;
    await _db.upsertLibrarySource(
      sourceKey: sourceKey,
      trackId: duplicateOfTrackId,
      state: 'skipped',
      sizeBytes: sizeBytes,
      volume: volume,
      path: path,
      modifiedSec: modifiedSec,
    );
  });

  /// A referenced file moved or changed: update where the track points (and
  /// its size) together with the source fingerprint, atomically.
  Future<void> refreshReferencedSource(
    String sourceKey, {
    required String trackId,
    required String volume,
    required String path,
    required int sizeBytes,
    required int modifiedSec,
  }) => _db.transaction(() async {
    await _db.updateSongLocation(trackId, path, sizeBytes);
    await _db.upsertLibrarySource(
      sourceKey: sourceKey,
      trackId: trackId,
      state: 'added',
      sizeBytes: sizeBytes,
      volume: volume,
      path: path,
      modifiedSec: modifiedSec,
    );
  });

  /// The id was reused by a different file: keep the OLD row (so its track
  /// stays protected as a referenced original) under an orphan key, freeing
  /// the key for the new file.
  Future<void> detachSource(String sourceKey) => _db.renameLibrarySource(
    sourceKey,
    'orphan:$sourceKey:${DateTime.now().microsecondsSinceEpoch}',
  );

  /// Drops a stale 'removed'/'skipped' row so a genuinely different file
  /// that reuses its id can be evaluated afresh.
  Future<void> forgetSource(String sourceKey) =>
      _db.deleteLibrarySource(sourceKey);

  /// Adopts a v4 (volume-less) 'added' row under the new volume-qualified key
  /// — only called after verifying its path matches the entry's.
  Future<void> adoptLegacySource(
    String legacyKey,
    String newKey, {
    required String volume,
    required String path,
    required int sizeBytes,
    required int modifiedSec,
  }) => _db.transaction(() async {
    final legacy = await _db.librarySource(legacyKey);
    if (legacy == null || legacy.state != 'added' || legacy.trackId == null) {
      return;
    }
    if (await _db.librarySource(newKey) != null) return;
    await _db.deleteLibrarySource(legacyKey);
    await _db.upsertLibrarySource(
      sourceKey: newKey,
      trackId: legacy.trackId,
      state: 'added',
      sizeBytes: sizeBytes,
      volume: volume,
      path: path,
      modifiedSec: modifiedSec,
    );
  });

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Real "Rescan Library" action: verifies every song's file is still on
  /// disk and removes library entries whose file has disappeared (e.g. the
  /// app's storage was cleared by the OS, or the user tampered with it
  /// directly) rather than leaving dead rows that fail to play. Returns how
  /// many were removed.
  Future<int> rescanForMissingFiles() async {
    final tracks = await getAllTracksOnce();
    final referencedIds = {
      for (final r in (await getLibrarySources()).values)
        if (r.state == 'added' && r.trackId != null) r.trackId!,
    };
    var removed = 0;
    for (final track in tracks) {
      // Referenced originals can be temporarily unreachable (unmounted card,
      // permission change); never delete their records for that.
      if (referencedIds.contains(track.id)) continue;
      if (!await File(track.filePath).exists()) {
        await _db.deleteSong(track.id);
        removed++;
      }
    }
    return removed;
  }

  /// Total bytes on disk across every song's real audio file.
  Future<int> totalStorageBytes() async {
    final sw = Stopwatch()..start();
    StartupLog.note('Settings totalStorageBytes START');
    PerfLog.db('totalStorageBytes');
    final tracks = await getAllTracksOnce();
    final total = tracks.fold<int>(0, (sum, t) => sum + t.fileSizeBytes);
    StartupLog.note(
      'Settings totalStorageBytes END rows=${tracks.length} '
      '(${sw.elapsedMilliseconds}ms)',
    );
    return total;
  }

  ValueStream<List<Album>> watchAlbums() =>
      PerfLog.traced('watchAlbums created', _db)
          .watchAlbums()
          .map(
            (rows) => rows
                .map(
                  (r) => Album(
                    name: r.album,
                    artist: r.albumArtist,
                    artworkPath: r.artworkPath,
                    year: r.year,
                    songCount: r.songCount,
                  ),
                )
                .toList(),
          )
          .shareValueSeeded(const []);

  ValueStream<List<Track>> watchSongsForAlbum(
    String album,
    String albumArtist,
  ) => _db
      .watchSongsForAlbum(album, albumArtist)
      .map((rows) => rows.map(_toTrack).toList())
      .shareValueSeeded(const []);

  /// One-shot (non-reactive) read of the exact (album, albumArtist) group —
  /// see [AppDatabase.getSongsForAlbumOnce]. Use this (not `.first` on
  /// [watchSongsForAlbum], which is seeded with `[]`) whenever the actual
  /// current rows are needed right now, e.g. right after [renameAlbum].
  Future<List<Track>> getSongsForAlbumOnce(String album, String albumArtist) =>
      _db
          .getSongsForAlbumOnce(album, albumArtist)
          .then((rows) => rows.map(_toTrack).toList());

  /// Renames every track in the exact (album, albumArtist) group to
  /// [newAlbum] — database/library only, never the on-disk audio files'
  /// embedded tags. Trims [newAlbum]; an empty result is rejected, and a
  /// name that's unchanged after trimming is a silent no-op. Throws
  /// [AlbumRenameCollisionException] instead of merging if a *different*
  /// existing group already has that exact (newAlbum, albumArtist) — the
  /// collision check and the write happen in one database transaction (see
  /// [AppDatabase.renameAlbumAtomic]), so two concurrent renames targeting
  /// the same destination can never both succeed and silently merge.
  Future<void> renameAlbum({
    required String album,
    required String albumArtist,
    required String newAlbum,
  }) async {
    final trimmed = newAlbum.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        newAlbum,
        'newAlbum',
        'Album name cannot be empty',
      );
    }
    if (trimmed == album) return;
    try {
      await _db.renameAlbumAtomic(album, albumArtist, trimmed);
    } on AlbumRenameCollision {
      throw const AlbumRenameCollisionException();
    }
  }

  ValueStream<List<Artist>> watchArtists() => _db
      .watchArtists()
      .map(
        (rows) => rows
            .map(
              (r) => Artist(
                name: r.artist,
                songCount: r.songCount,
                albumCount: r.albumCount,
              ),
            )
            .toList(),
      )
      .shareValueSeeded(const []);

  ValueStream<List<Track>> watchSongsForArtist(String artist) => _db
      .watchSongsForArtist(artist)
      .map((rows) => rows.map(_toTrack).toList())
      .shareValueSeeded(const []);

  ValueStream<List<Track>> watchMostPlayedForArtist(
    String artist, {
    int limit = 5,
  }) => _db
      .watchMostPlayedForArtist(artist, limit: limit)
      .map((rows) => rows.map(_toTrack).toList())
      .shareValueSeeded(const []);

  // --- Playlists ---

  Future<String> createPlaylist(String name, {String? artworkPath}) async {
    final id = _uuid.v4();
    if (artworkPath == null) {
      await _db.createPlaylist(id, name);
    } else {
      await _withArtworkLock(() async {
        // Re-checked under the lock: a file deleted while this writer waited
        // is never stored as a reference (the playlist just has no artwork).
        final usable = await _artworkAccessible(artworkPath);
        await _db.createPlaylist(
          id,
          name,
          artworkPath: usable ? artworkPath : null,
        );
      });
    }
    return id;
  }

  Future<void> renamePlaylist(String id, String name) =>
      _db.renamePlaylist(id, name);

  /// Sets (or clears, with null) a playlist's artwork. Returns false — and
  /// stores nothing — if [artworkPath] no longer exists / can't be opened when
  /// the write finally runs under the artwork lock.
  Future<bool> updatePlaylistArtwork(String id, String? artworkPath) async {
    if (artworkPath == null) {
      await _db.updatePlaylistArtwork(id, null);
      return true;
    }
    return _withArtworkLock(() async {
      if (!await _artworkAccessible(artworkPath)) return false;
      await _db.updatePlaylistArtwork(id, artworkPath);
      return true;
    });
  }

  Future<void> deletePlaylist(String id) => _db.deletePlaylist(id);

  ValueStream<List<Playlist>> watchPlaylists() {
    StartupLog.tick('watchPlaylists stream created');
    PerfLog.db('watchPlaylists created');
    final sw = Stopwatch();
    var firstResultLogged = false;
    var source = _db.watchPlaylists();
    if (StartupLog.enabled) {
      source = source.doOnListen(() {
        if (!sw.isRunning) sw.start();
        StartupLog.note('watchPlaylists subscribed');
        PerfLog.db('watchPlaylists subscribed');
      });
    }
    return source
        .asyncMap((rows) async {
          final playlists = <Playlist>[];
          var membershipQueries = 0;
          final batchSw = Stopwatch()..start();
          for (final row in rows) {
            membershipQueries++;
            PerfLog.db('playlist membership query');
            final songs = await _db.watchPlaylistSongs(row.id).first;
            playlists.add(
              Playlist(
                id: row.id,
                name: row.name,
                artworkPath: row.artworkPath,
                createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
                songCount: songs.length,
              ),
            );
          }
          if (StartupLog.enabled) {
            StartupLog.note(
              'watchPlaylists batch: playlists=${rows.length} '
              'membership queries=$membershipQueries '
              'batch=${batchSw.elapsedMilliseconds}ms'
              '${firstResultLogged ? '' : ' | initial data ready '
                        '${sw.elapsedMilliseconds}ms after subscribe'}',
            );
            firstResultLogged = true;
          }
          return playlists;
        })
        .shareValueSeeded(const []);
  }

  ValueStream<List<Track>> watchPlaylistSongs(String playlistId) =>
      PerfLog.traced('watchPlaylistSongs created', _db)
          .watchPlaylistSongs(playlistId)
          .map((rows) => rows.map(_toTrack).toList())
          .shareValueSeeded(const []);

  Future<void> addSongToPlaylist(String playlistId, String songId) =>
      _db.addSongToPlaylist(playlistId, songId);

  Future<void> removeSongFromPlaylist(String playlistId, String songId) =>
      _db.removeSongFromPlaylist(playlistId, songId);

  Future<void> reorderPlaylistSongs(
    String playlistId,
    List<String> orderedSongIds,
  ) => _db.reorderPlaylistSongs(playlistId, orderedSongIds);

  // --- Download history ---

  Future<void> recordDownloadHistory({
    required String title,
    required String sourceType,
    required String status,
    String? outputFormat,
    String? message,
  }) => _db.insertDownloadHistoryEntry(
    DownloadHistoryEntriesCompanion.insert(
      id: _uuid.v4(),
      title: title,
      sourceType: sourceType,
      status: status,
      outputFormat: Value(outputFormat),
      message: Value(message),
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    ),
  );

  ValueStream<List<DownloadHistoryEntry>> watchDownloadHistory({
    int limit = 50,
  }) => StartupLog.traceFirst(
    _db
        .watchDownloadHistory(limit: limit)
        .map(
          (rows) => rows
              .map(
                (r) => DownloadHistoryEntry(
                  id: r.id,
                  title: r.title,
                  sourceType: r.sourceType,
                  status: r.status,
                  outputFormat: r.outputFormat,
                  message: r.message,
                  timestamp: DateTime.fromMillisecondsSinceEpoch(r.timestampMs),
                ),
              )
              .toList(),
        ),
    'watchDownloadHistory',
    (entries) => entries.length,
  ).shareValueSeeded(const []);

  Future<void> clearDownloadHistory() => _db.clearDownloadHistory();
}
