import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/audio_formats.dart';
import '../core/models/track.dart';
import 'artwork_validator.dart';
import 'duplicate_detector.dart';
import 'import_models.dart';
import 'library_repository.dart';

/// Turns picked files into real, persisted library [Track]s.
///
/// Every step here is real: the source file is copied byte-for-byte into the
/// app's own storage (the original is never touched or relied upon again),
/// tags and embedded artwork are read from the copy with `audio_metadata_reader`,
/// duplicates are detected against the real database before anything is kept,
/// and successful imports are written straight into [LibraryRepository] — so
/// they're already there on the next launch. Anything that fails is
/// reported, never silently dropped or faked as succeeding.
class ImportService {
  final LibraryRepository _repository;
  final DuplicateDetector _duplicateDetector;
  final Uuid _uuid;

  ImportService(
    this._repository, {
    DuplicateDetector? duplicateDetector,
    Uuid? uuid,
  }) : _duplicateDetector = duplicateDetector ?? DuplicateDetector(),
       _uuid = uuid ?? const Uuid();

  /// Processes [files] one at a time, persisting each success and yielding
  /// progress after each one.
  Stream<ImportProgress> importFiles(List<PickedFile> files) async* {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(appDir.path, 'audio'))
      ..createSync(recursive: true);
    final artworkDir = Directory(p.join(appDir.path, 'artwork'))
      ..createSync(recursive: true);

    final existingLibrary = await _repository.getAllTracksOnce();
    final addedSoFar = <Track>[];

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final result = await _importOne(
        file,
        audioDir: audioDir,
        artworkDir: artworkDir,
        existingLibrary: [...existingLibrary, ...addedSoFar],
      );
      var latest = result;
      if (result.track != null) {
        final ref = file.referencedSource;
        if (ref == null) {
          addedSoFar.add(result.track!);
          await _repository.insertTrack(result.track!);
        } else if (await _repository.claimReferencedTrack(
          result.track!,
          sourceKey: ref.sourceKey,
          volume: ref.volume,
          sizeBytes: ref.sizeBytes,
          modifiedSec: ref.modifiedSec,
        )) {
          addedSoFar.add(result.track!);
        } else {
          // Source or path already owned: nothing was inserted.
          final art = result.track!.artworkPath;
          if (art != null) await _deleteQuietly(art);
          latest = ImportFileResult(
            fileName: file.name,
            outcome: ImportFileOutcome.duplicate,
            detail: 'Already in your library.',
          );
        }
      }
      yield ImportProgress(
        processed: i + 1,
        total: files.length,
        latest: latest,
      );
    }
  }

  /// Convenience wrapper that runs [importFiles] to completion and returns
  /// just the final [ImportSummary], for callers that don't need live
  /// per-file progress.
  Future<ImportSummary> importAndSummarize(List<PickedFile> files) async {
    final added = <Track>[];
    final duplicates = <ImportFileResult>[];
    final unsupported = <ImportFileResult>[];
    final corrupt = <ImportFileResult>[];

    await for (final progress in importFiles(files)) {
      final r = progress.latest;
      switch (r.outcome) {
        case ImportFileOutcome.added:
          added.add(r.track!);
        case ImportFileOutcome.duplicate:
          duplicates.add(r);
        case ImportFileOutcome.unsupported:
          unsupported.add(r);
        case ImportFileOutcome.corrupt:
          corrupt.add(r);
      }
    }

    return ImportSummary(
      addedTracks: added,
      duplicates: duplicates,
      unsupported: unsupported,
      corrupt: corrupt,
    );
  }

  Future<ImportFileResult> _importOne(
    PickedFile file, {
    required Directory audioDir,
    required Directory artworkDir,
    required List<Track> existingLibrary,
  }) async {
    final sourcePath = file.path;
    if (!isSupportedAudioFile(file.name)) {
      return ImportFileResult(
        fileName: file.name,
        outcome: ImportFileOutcome.unsupported,
        detail:
            'Format not supported. Supported: '
            '${supportedAudioExtensions.join(', ').toUpperCase()}.',
      );
    }

    final id = _uuid.v4();
    final ext = extensionOf(file.name);
    final inPlace = file.referencedSource != null;
    final destPath = inPlace ? sourcePath : p.join(audioDir.path, '$id.$ext');
    String? artworkPath;

    try {
      if (!inPlace) await File(sourcePath).copy(destPath);
      final destFile = File(destPath);
      final fileSize = await destFile.length();

      final metadata = readMetadata(destFile, getImage: true);

      final picture = metadata.pictures.isNotEmpty
          ? metadata.pictures.first
          : null;
      // Only content-verified images are written, with the verified format's
      // extension; a damaged/non-image picture is ignored (and never retried).
      var art = picture == null || file.preferExternalArtwork
          ? null
          : await decodeVerifiedArtwork(Uint8List.fromList(picture.bytes));
      if (file.preferExternalArtwork && file.externalArtworkPath != null) {
        art =
            await _verifiedExternalArtwork(file.externalArtworkPath!) ??
            (picture == null
                ? null
                : await decodeVerifiedArtwork(
                    Uint8List.fromList(picture.bytes),
                  ));
      }
      if (art == null && file.externalArtworkPath != null) {
        // No usable embedded artwork — fall back to a source-supplied cover
        // (e.g. a downloaded track's thumbnail), verified the same way and
        // copied into our own storage so Listeny never depends on that file.
        final externalFile = File(file.externalArtworkPath!);
        if (await externalFile.exists() &&
            await externalFile.length() <= artworkMaxBytes) {
          art = await decodeVerifiedArtwork(await externalFile.readAsBytes());
        }
      }
      if (art != null) {
        final artworkFile = File(
          p.join(artworkDir.path, '$id.${art.extension}'),
        );
        await artworkFile.writeAsBytes(art.bytes);
        artworkPath = artworkFile.path;
      }

      final nameWithoutExt = file.name.contains('.')
          ? file.name.substring(0, file.name.lastIndexOf('.'))
          : file.name;
      String orFallback(String? value, String fallback) =>
          (value != null && value.trim().isNotEmpty) ? value.trim() : fallback;

      final track = Track(
        id: id,
        filePath: destPath,
        title: orFallback(metadata.title, nameWithoutExt),
        artist: orFallback(metadata.artist, 'Unknown Artist'),
        album: orFallback(metadata.album, 'Unknown Album'),
        albumArtist: orFallback(metadata.artist, 'Unknown Artist'),
        trackNumber: metadata.trackNumber,
        discNumber: metadata.discNumber,
        year: (metadata.year != null && metadata.year!.year > 0)
            ? metadata.year!.year
            : null,
        duration: metadata.duration ?? Duration.zero,
        format: ext,
        // audio_metadata_reader reports bitrate in bits per second (confirmed
        // against a known-128kbps test encode, which came back as 128000) —
        // convert to kbps here so Track's own field name stays honest.
        bitrateKbps: metadata.bitrate == null
            ? null
            : (metadata.bitrate! / 1000).round(),
        sampleRateHz: metadata.sampleRate,
        fileSizeBytes: fileSize,
        dateAdded: DateTime.now(),
        artworkPath: artworkPath,
      );

      final duplicateOf = _duplicateDetector.findDuplicate(
        track,
        existingLibrary,
      );
      if (duplicateOf != null) {
        // An in-place file belongs to the caller (it published it), never
        // deleted here.
        if (!inPlace) await _deleteQuietly(destPath);
        if (artworkPath != null) await _deleteQuietly(artworkPath);
        return ImportFileResult(
          fileName: file.name,
          outcome: ImportFileOutcome.duplicate,
          detail: 'Already in your library as "${duplicateOf.title}".',
        );
      }

      return ImportFileResult(
        fileName: file.name,
        outcome: ImportFileOutcome.added,
        track: track,
      );
    } catch (e) {
      if (!inPlace) await _deleteQuietly(destPath);
      if (artworkPath != null) await _deleteQuietly(artworkPath);
      return ImportFileResult(
        fileName: file.name,
        outcome: ImportFileOutcome.corrupt,
        detail: 'Could not read this file: $e',
      );
    }
  }

  Future<ValidatedArtwork?> _verifiedExternalArtwork(String path) async {
    final f = File(path);
    if (!await f.exists() || await f.length() > artworkMaxBytes) return null;
    return decodeVerifiedArtwork(await f.readAsBytes());
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Best-effort cleanup only; a leftover temp file isn't worth surfacing.
    }
  }
}
