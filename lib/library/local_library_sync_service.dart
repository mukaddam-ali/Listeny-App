import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../core/models/track.dart';
import '../core/storage/database.dart' show LibrarySource;
import 'artwork_validator.dart';
import 'duplicate_detector.dart';
import 'library_repository.dart';

/// One MP3 exposed by Android's MediaStore (never a filesystem walk).
class DeviceMp3 {
  final int id;
  final String name;
  final String path;
  final int sizeBytes;
  final int durationMs;
  final int modifiedSec;

  /// Storage volume the row lives on; an id is only unique per volume.
  final String volume;

  const DeviceMp3({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.durationMs,
    this.modifiedSec = 0,
    this.volume = 'primary',
  });

  /// Stable source identity: storage volume + MediaStore row id (never a
  /// file name, and never the bare id).
  String get sourceKey => 'ms:$volume:$id';

  /// The v4 (volume-less) key an earlier build may have recorded.
  String get legacySourceKey => 'ms:$id';
}

/// The audio permission was missing/revoked while querying MediaStore.
class MediaStorePermissionException implements Exception {
  const MediaStorePermissionException();
}

/// Where the sync gets its device facts from (injectable for tests).
/// Thrown by a [DeviceMp3Source] query when the caller asked it to stop.
class MediaStoreQueryCancelled implements Exception {
  const MediaStoreQueryCancelled();
}

abstract class DeviceMp3Source {
  Future<int> sdkInt();

  /// Every MP3 on every storage volume. [shouldStop] is polled between pages;
  /// when it returns true the query throws [MediaStoreQueryCancelled].
  Future<List<DeviceMp3>> queryMp3Files({bool Function()? shouldStop});
}

class MediaStoreMp3Source implements DeviceMp3Source {
  MediaStoreMp3Source({MethodChannel? channel, this.pageSize = 500})
    : _channel = channel ?? const MethodChannel('listeny/media_store');

  final MethodChannel _channel;

  /// Raw rows per native call (keyset paging by MediaStore id), so no single
  /// query or reply payload grows with the size of the library.
  final int pageSize;

  @override
  Future<int> sdkInt() async => await _channel.invokeMethod<int>('sdkInt') ?? 0;

  /// Volumes are enumerated and paged INDEPENDENTLY: a MediaStore `_ID` is
  /// only unique within one volume, so paging the combined collection by `_ID`
  /// alone could skip rows. Completion comes from the native side's explicit
  /// `hasMore` (raw cursor progress), never from how many usable rows a page
  /// held, and `lastId` must strictly advance or the volume stops (no
  /// infinite loops).
  @override
  Future<List<DeviceMp3>> queryMp3Files({bool Function()? shouldStop}) async {
    final volumes =
        (await _invoke<List<Object?>>('mp3Volumes'))?.cast<String>() ??
        const <String>[];
    final out = <DeviceMp3>[];
    for (final volume in volumes) {
      var afterId = 0;
      while (true) {
        if (shouldStop?.call() ?? false) throw const MediaStoreQueryCancelled();
        final page = await _invoke<Map<Object?, Object?>>('queryMp3Files', {
          'volume': volume,
          'afterId': afterId,
          'limit': pageSize,
        });
        if (page == null) break;
        for (final entry in (page['rows'] as List<Object?>? ?? const [])) {
          final m = Map<Object?, Object?>.from(entry as Map);
          final id = (m['id'] as num?)?.toInt();
          final path = m['path'] as String?;
          if (path == null || path.isEmpty || id == null) continue;
          out.add(
            DeviceMp3(
              id: id,
              name: m['name'] as String? ?? p.basename(path),
              path: path,
              sizeBytes: (m['sizeBytes'] as num?)?.toInt() ?? 0,
              durationMs: (m['durationMs'] as num?)?.toInt() ?? 0,
              modifiedSec: (m['modifiedSec'] as num?)?.toInt() ?? 0,
              volume: volume,
            ),
          );
        }
        final hasMore = page['hasMore'] == true;
        final lastId = (page['lastId'] as num?)?.toInt() ?? afterId;
        if (!hasMore || lastId <= afterId) break;
        afterId = lastId;
      }
    }
    return out;
  }

  Future<T?> _invoke<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        throw const MediaStorePermissionException();
      }
      rethrow;
    }
  }
}

/// Plain, isolate-transferable result of reading one file's tags/artwork.
class ExtractedMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final Duration? duration;
  final int? bitrateKbps;
  final int? sampleRateHz;
  final Uint8List? artworkBytes;
  final bool artworkIsPng;

  const ExtractedMetadata({
    this.title,
    this.artist,
    this.album,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.duration,
    this.bitrateKbps,
    this.sampleRateHz,
    this.artworkBytes,
    this.artworkIsPng = false,
  });
}

typedef MetadataExtractor = Future<ExtractedMetadata> Function(String path);

/// Default extractor: reads tags + embedded artwork in a short-lived
/// background isolate so no file parsing happens on the UI isolate.
Future<ExtractedMetadata> extractMetadataInBackground(String path) =>
    Isolate.run(() => _extractSync(path));

ExtractedMetadata _extractSync(String path) {
  final metadata = readMetadata(File(path), getImage: true);
  final picture = metadata.pictures.isNotEmpty ? metadata.pictures.first : null;
  return ExtractedMetadata(
    title: metadata.title,
    artist: metadata.artist,
    album: metadata.album,
    trackNumber: metadata.trackNumber,
    discNumber: metadata.discNumber,
    year: (metadata.year != null && metadata.year!.year > 0)
        ? metadata.year!.year
        : null,
    duration: metadata.duration,
    bitrateKbps: metadata.bitrate == null
        ? null
        : (metadata.bitrate! / 1000).round(),
    sampleRateHz: metadata.sampleRate,
    artworkBytes: picture?.bytes,
    artworkIsPng: picture?.mimetype.contains('png') ?? false,
  );
}

/// Requests the audio read permission: READ_MEDIA_AUDIO on Android 13+,
/// READ_EXTERNAL_STORAGE before that (same pattern as the music browser).
Future<bool> requestAudioLibraryPermission() async {
  if ((await Permission.audio.request()).isGranted) return true;
  return (await Permission.storage.request()).isGranted;
}

class SyncCancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

enum SyncOutcome {
  completed,
  cancelled,
  permissionDenied,

  /// Android 10 (API 29): scoped storage blocks reading other apps' audio by
  /// path, and the app only supports path-based playback — so referencing
  /// originals can't work there. Reported rather than forced.
  unsupportedAndroidVersion,
  alreadyRunning,
  failed,
}

class SyncProgress {
  final int processed;
  final int total;
  final int added;
  const SyncProgress({
    required this.processed,
    required this.total,
    required this.added,
  });
}

class SyncSummary {
  final SyncOutcome outcome;
  final int scanned;
  final int added;
  final int alreadyKnown;
  final int duplicatesSkipped;
  final int unreadable;

  const SyncSummary(
    this.outcome, {
    this.scanned = 0,
    this.added = 0,
    this.alreadyKnown = 0,
    this.duplicatesSkipped = 0,
    this.unreadable = 0,
  });
}

/// Automatic local MP3 sync: finds MP3s Android's MediaStore already knows
/// about and adds them to the library as in-place REFERENCES to the original
/// files (nothing is copied or moved; only the small artwork image is
/// extracted into app storage).
///
/// Safe by construction:
/// - Idempotent/incremental: each MediaStore id is recorded once (added or
///   skipped-as-duplicate) and never re-read; each track is committed as it
///   is processed, so a cancel or crash keeps everything done so far and the
///   next run just continues.
/// - Never deletes anything: items missing from MediaStore, unreadable files
///   and inaccessible paths are left alone (unreadable ones retried next
///   sync). Library records are never removed by a scan.
/// - Dedupes by stable MediaStore id, by existing track path, and — against
///   manually imported copies and downloads — by title/artist/duration via
///   the same [DuplicateDetector] the manual import uses.
/// - Metadata is parsed in a background isolate.
class LocalLibrarySyncService {
  final LibraryRepository _library;
  final DeviceMp3Source _source;
  final Future<bool> Function() _ensurePermission;
  final MetadataExtractor _extract;
  final Future<Directory> Function() _artworkDir;
  final Future<bool> Function(String path) _fileExists;
  final DuplicateDetector _duplicates;
  final Future<bool> Function(String a, String b) _contentEquals;
  final Uuid _uuid;

  LocalLibrarySyncService(
    this._library, {
    DeviceMp3Source? source,
    Future<bool> Function()? ensurePermission,
    MetadataExtractor? extractor,
    Future<Directory> Function()? artworkDir,
    Future<bool> Function(String path)? fileExists,
    DuplicateDetector? duplicateDetector,
    Future<bool> Function(String a, String b)? contentEquals,
    Uuid? uuid,
  }) : _source = source ?? MediaStoreMp3Source(),
       _ensurePermission = ensurePermission ?? requestAudioLibraryPermission,
       _extract = extractor ?? extractMetadataInBackground,
       _artworkDir = artworkDir ?? _defaultArtworkDir,
       _fileExists = fileExists ?? ((path) => File(path).exists()),
       _duplicates = duplicateDetector ?? DuplicateDetector(),
       _contentEquals = contentEquals ?? filesHaveIdenticalContent,
       _uuid = uuid ?? const Uuid();

  static Future<Directory> _defaultArtworkDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDir.path, 'artwork'))
      ..createSync(recursive: true);
  }

  /// Runs one sync. Only one runs per library at a time — enforced on the
  /// [LibraryRepository] itself, so the first-launch sync and the Settings
  /// sync (separate service instances) can never overlap.
  Future<SyncSummary> sync({
    SyncCancelToken? cancel,
    void Function(SyncProgress progress)? onProgress,
  }) async {
    if (!_library.tryBeginSync()) {
      return const SyncSummary(SyncOutcome.alreadyRunning);
    }
    try {
      return await _run(cancel, onProgress);
    } on MediaStorePermissionException {
      return const SyncSummary(SyncOutcome.permissionDenied);
    } on MediaStoreQueryCancelled {
      return const SyncSummary(SyncOutcome.cancelled);
    } catch (_) {
      return const SyncSummary(SyncOutcome.failed);
    } finally {
      _library.endSync();
    }
  }

  Future<SyncSummary> _run(
    SyncCancelToken? cancel,
    void Function(SyncProgress)? onProgress,
  ) async {
    final sdk = await _source.sdkInt();
    if (sdk == 29) {
      return const SyncSummary(SyncOutcome.unsupportedAndroidVersion);
    }

    if (!await _ensurePermission()) {
      return const SyncSummary(SyncOutcome.permissionDenied);
    }

    final entries = await _source.queryMp3Files(
      shouldStop: () => cancel?.isCancelled ?? false,
    );
    final library = await _library.getAllTracksOnce();
    final libraryIds = {for (final t in library) t.id};
    final knownPaths = {for (final t in library) t.filePath};
    final artworkDir = await _artworkDir();

    var added = 0, alreadyKnown = 0, duplicates = 0, unreadable = 0;
    var processed = 0;

    SyncSummary summary(SyncOutcome o) => SyncSummary(
      o,
      scanned: entries.length,
      added: added,
      alreadyKnown: alreadyKnown,
      duplicatesSkipped: duplicates,
      unreadable: unreadable,
    );

    for (final entry in entries) {
      if (cancel?.isCancelled ?? false) return summary(SyncOutcome.cancelled);
      processed++;

      final decision = await _decide(entry, libraryIds, knownPaths);
      switch (decision) {
        case _Known():
          alreadyKnown++;
        case _New():
          final outcome = await _addOne(entry, artworkDir, library);
          switch (outcome) {
            case _Added(:final track):
              library.add(track);
              libraryIds.add(track.id);
              knownPaths.add(track.filePath);
              added++;
            case _Duplicate():
              duplicates++;
            case _Unreadable():
              unreadable++;
            case _LostRace():
              alreadyKnown++;
          }
      }
      onProgress?.call(
        SyncProgress(processed: processed, total: entries.length, added: added),
      );
      // Let the UI isolate breathe between files.
      await Future<void>.delayed(Duration.zero);
    }
    return summary(SyncOutcome.completed);
  }

  /// Decides what to do with [entry] given everything recorded about its
  /// source. Never deletes a track or a user's file; uncertain identities
  /// are re-evaluated rather than trusted.
  Future<_Decision> _decide(
    DeviceMp3 entry,
    Set<String> libraryIds,
    Set<String> knownPaths,
  ) async {
    var row = await _library.getLibrarySource(entry.sourceKey);

    if (row == null) {
      // Adopt a v4 (volume-less) record ONLY when its recorded path proves it
      // is this very file; otherwise its bare id is ambiguous and ignored.
      final legacy = await _library.getLibrarySource(entry.legacySourceKey);
      if (legacy != null &&
          legacy.volume.isEmpty &&
          legacy.state == 'added' &&
          legacy.trackId != null &&
          legacy.path == entry.path &&
          libraryIds.contains(legacy.trackId)) {
        await _library.adoptLegacySource(
          entry.legacySourceKey,
          entry.sourceKey,
          volume: entry.volume,
          path: entry.path,
          sizeBytes: entry.sizeBytes,
          modifiedSec: entry.modifiedSec,
        );
        row = await _library.getLibrarySource(entry.sourceKey);
      }
    }

    if (row == null) {
      // A track already pointing at this exact path is the same reference.
      return knownPaths.contains(entry.path) ? const _Known() : const _New();
    }

    final samePath = row.path == entry.path;
    final sameSize = row.sizeBytes == entry.sizeBytes;
    final sameFingerprint =
        samePath && sameSize && row.modifiedSec == entry.modifiedSec;

    switch (row.state) {
      case 'added':
        final trackId = row.trackId;
        if (trackId == null || !libraryIds.contains(trackId)) {
          // Owner record without a live track: keep the row, never re-add
          // silently.
          return const _Known();
        }
        if (sameFingerprint) return const _Known();
        if (samePath) {
          // Same id, same path, new size/time: the same file edited in
          // place. Refresh the fingerprint; keep the track and its user data.
          await _library.refreshReferencedSource(
            entry.sourceKey,
            trackId: trackId,
            volume: entry.volume,
            path: entry.path,
            sizeBytes: entry.sizeBytes,
            modifiedSec: entry.modifiedSec,
          );
          return const _Known();
        }
        if (await _isVerifiedMove(row, entry)) {
          await _library.refreshReferencedSource(
            entry.sourceKey,
            trackId: trackId,
            volume: entry.volume,
            path: entry.path,
            sizeBytes: entry.sizeBytes,
            modifiedSec: entry.modifiedSec,
          );
          knownPaths.remove(row.path);
          knownPaths.add(entry.path);
          return const _Known();
        }
        // Identity is uncertain (a reused id, or a rename we can't prove):
        // never re-point the old track. Keep it, protected, under an orphan
        // key and handle this file as a brand-new source.
        await _library.detachSource(entry.sourceKey);
        return const _New();
      case 'skipped':
        final dupOf = row.trackId;
        if (sameFingerprint && dupOf != null && libraryIds.contains(dupOf)) {
          return const _Known();
        }
        // Fingerprint changed, or the track it duplicated is gone:
        // reconsider (claiming overwrites the skipped row).
        return const _New();
      case 'removed':
        if (samePath || await _isVerifiedMove(row, entry)) {
          return const _Known();
        }
        await _library.forgetSource(entry.sourceKey); // reused id
        return const _New();
      default:
        return const _Known();
    }
  }

  /// A changed path counts as a MOVE of the same file only with strong,
  /// independent evidence: identical size AND modified time AND file name,
  /// the old location is really gone, and the new one is really there.
  /// Matching size alone (or anything less) is NOT enough — MediaStore ids can
  /// be reused by unrelated files.
  Future<bool> _isVerifiedMove(LibrarySource row, DeviceMp3 entry) async {
    if (row.sizeBytes != entry.sizeBytes) return false;
    if (row.modifiedSec != entry.modifiedSec || entry.modifiedSec == 0) {
      return false;
    }
    if (p.basename(row.path) != p.basename(entry.path)) return false;
    if (await _fileExists(row.path)) return false;
    return _fileExists(entry.path);
  }

  Future<_AddResult> _addOne(
    DeviceMp3 entry,
    Directory artworkDir,
    List<Track> library,
  ) async {
    String? artworkPath;
    try {
      if (!await _fileExists(entry.path)) return const _Unreadable();
      final meta = await _extract(entry.path);
      final id = _uuid.v4();

      // Only content-verified images are ever written (never raw metadata
      // bytes), with the extension of the VERIFIED format.
      final raw = meta.artworkBytes;
      final art = (raw == null || raw.isEmpty)
          ? null
          : await decodeVerifiedArtwork(raw);
      if (art != null) {
        final f = File(p.join(artworkDir.path, '$id.${art.extension}'));
        await f.writeAsBytes(art.bytes);
        artworkPath = f.path;
      }

      String orFallback(String? v, String fallback) =>
          (v != null && v.trim().isNotEmpty) ? v.trim() : fallback;
      final nameNoExt = p.basenameWithoutExtension(entry.name);

      final track = Track(
        id: id,
        filePath: entry.path,
        title: orFallback(meta.title, nameNoExt),
        artist: orFallback(meta.artist, 'Unknown Artist'),
        album: orFallback(meta.album, 'Unknown Album'),
        albumArtist: orFallback(meta.artist, 'Unknown Artist'),
        trackNumber: meta.trackNumber,
        discNumber: meta.discNumber,
        year: meta.year,
        duration: meta.duration ?? Duration(milliseconds: entry.durationMs),
        format: 'mp3',
        bitrateKbps: meta.bitrateKbps,
        sampleRateHz: meta.sampleRateHz,
        fileSizeBytes: entry.sizeBytes,
        dateAdded: DateTime.now(),
        artworkPath: artworkPath,
      );

      // A duplicate is only a file with VERIFIED identical content. Similar
      // metadata (even with the same size) is just a candidate: the bytes
      // must be exactly equal (cheap early-exit compare, only run for such
      // candidates) before anything is treated as the same recording.
      Track? duplicateOf;
      final candidates = [
        for (final t in library)
          if (t.fileSizeBytes == track.fileSizeBytes &&
              _duplicates.findDuplicate(track, [t]) != null)
            t,
      ];
      for (final candidate in candidates) {
        if (await _contentEquals(candidate.filePath, entry.path)) {
          duplicateOf = candidate;
          break;
        }
      }
      if (duplicateOf != null) {
        await _deleteQuietly(artworkPath);
        await _library.recordSkippedSource(
          entry.sourceKey,
          duplicateOfTrackId: duplicateOf.id,
          volume: entry.volume,
          path: entry.path,
          sizeBytes: entry.sizeBytes,
          modifiedSec: entry.modifiedSec,
        );
        return const _Duplicate();
      }

      final claimed = await _library.claimReferencedTrack(
        track,
        sourceKey: entry.sourceKey,
        volume: entry.volume,
        sizeBytes: entry.sizeBytes,
        modifiedSec: entry.modifiedSec,
      );
      if (!claimed) {
        await _deleteQuietly(artworkPath);
        return const _LostRace();
      }
      return _Added(track);
    } catch (_) {
      // Unreadable / corrupt / permission revoked mid-scan: leave no trace
      // (no record, no orphan artwork) so a later sync can retry.
      await _deleteQuietly(artworkPath);
      return const _Unreadable();
    }
  }

  Future<void> _deleteQuietly(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}

sealed class _Decision {
  const _Decision();
}

class _Known extends _Decision {
  const _Known();
}

class _New extends _Decision {
  const _New();
}

sealed class _AddResult {
  const _AddResult();
}

class _Added extends _AddResult {
  final Track track;
  const _Added(this.track);
}

class _Duplicate extends _AddResult {
  const _Duplicate();
}

class _Unreadable extends _AddResult {
  const _Unreadable();
}

/// Another sync (or an earlier step) already owns this source/path.
class _LostRace extends _AddResult {
  const _LostRace();
}

const _initialSyncDonePrefKey = 'local_sync_initial_done';

/// First launch only: after the audio permission is granted (requested by the
/// sync itself), scan MediaStore once. Marked done after any definitive
/// outcome — including a denied permission, so the app never nags — and left
/// pending after a failure or cancel so the next launch retries. The user can
/// always run "Sync Library" manually. Never throws; runs off the startup path.
Future<void> runInitialLocalSyncIfNeeded(
  LibraryRepository library, {
  LocalLibrarySyncService? service,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_initialSyncDonePrefKey) ?? false) return;
    final summary = await (service ?? LocalLibrarySyncService(library)).sync();
    switch (summary.outcome) {
      case SyncOutcome.completed:
      case SyncOutcome.permissionDenied:
      case SyncOutcome.unsupportedAndroidVersion:
        await prefs.setBool(_initialSyncDonePrefKey, true);
      case SyncOutcome.cancelled:
      case SyncOutcome.alreadyRunning:
      case SyncOutcome.failed:
        break;
    }
  } catch (_) {}
}

/// Exact byte-for-byte comparison of two files (streamed, early exit at the
/// first difference). Any read problem means "not verified identical".
Future<bool> filesHaveIdenticalContent(String a, String b) async {
  try {
    final fa = File(a), fb = File(b);
    if (await fa.length() != await fb.length()) return false;
    final ia = StreamIterator(fa.openRead());
    final ib = StreamIterator(fb.openRead());
    try {
      var bufA = <int>[], bufB = <int>[];
      var offA = 0, offB = 0;
      while (true) {
        if (offA >= bufA.length) {
          if (!await ia.moveNext()) {
            // a exhausted: identical only if b is too.
            return offB >= bufB.length && !await ib.moveNext();
          }
          bufA = ia.current;
          offA = 0;
        }
        if (offB >= bufB.length) {
          if (!await ib.moveNext()) return false;
          bufB = ib.current;
          offB = 0;
        }
        final n = (bufA.length - offA) < (bufB.length - offB)
            ? bufA.length - offA
            : bufB.length - offB;
        for (var i = 0; i < n; i++) {
          if (bufA[offA + i] != bufB[offB + i]) return false;
        }
        offA += n;
        offB += n;
      }
    } finally {
      await ia.cancel();
      await ib.cancel();
    }
  } catch (_) {
    return false;
  }
}
