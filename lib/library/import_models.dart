import '../core/models/track.dart';

/// A file to import, named `PickedFile` (not `PlatformFile`) so
/// [ImportService] never depends on `file_picker`'s type directly — it just
/// needs a name and a real path, regardless of where that path came from
/// (the system picker, a test file pushed via `adb push`, or anything else).
class PickedFile {
  final String name;
  final String path;

  /// A locally-saved cover image to use when the file itself has no
  /// embedded artwork (e.g. a downloaded source's thumbnail) — ignored
  /// entirely when embedded artwork is found, which always wins.
  final String? externalArtworkPath;

  /// Use [externalArtworkPath] even when the file has its own embedded
  /// artwork (a trimmed copy keeps the original track's cover this way,
  /// including one the user picked in the app).
  final bool preferExternalArtwork;

  /// When set, [path] is a file the app owns in the public Music folder and
  /// the track REFERENCES it in place (no copy into app storage), registered
  /// under this MediaStore identity so the library sync treats it as already
  /// known.
  final ReferencedSource? referencedSource;

  const PickedFile({
    required this.name,
    required this.path,
    this.externalArtworkPath,
    this.preferExternalArtwork = false,
    this.referencedSource,
  });
}

/// MediaStore identity of an in-place referenced file.
class ReferencedSource {
  final String sourceKey;
  final String volume;
  final int sizeBytes;
  final int modifiedSec;

  const ReferencedSource({
    required this.sourceKey,
    required this.volume,
    required this.sizeBytes,
    required this.modifiedSec,
  });
}

enum ImportFileOutcome { added, duplicate, unsupported, corrupt }

class ImportFileResult {
  final String fileName;
  final ImportFileOutcome outcome;
  final String? detail;
  final Track? track;

  const ImportFileResult({
    required this.fileName,
    required this.outcome,
    this.detail,
    this.track,
  });
}

/// Emitted once per file as the import runs, so the UI can show real
/// per-file and overall progress instead of a spinner with no information.
class ImportProgress {
  final int processed;
  final int total;
  final ImportFileResult latest;

  const ImportProgress({
    required this.processed,
    required this.total,
    required this.latest,
  });
}

/// The final tally once every picked file has been processed.
class ImportSummary {
  final List<Track> addedTracks;
  final List<ImportFileResult> duplicates;
  final List<ImportFileResult> unsupported;
  final List<ImportFileResult> corrupt;

  const ImportSummary({
    required this.addedTracks,
    required this.duplicates,
    required this.unsupported,
    required this.corrupt,
  });

  int get songsAdded => addedTracks.length;
  int get albumsAdded => addedTracks.map((t) => t.album).toSet().length;
  int get artistsAdded => addedTracks.map((t) => t.artist).toSet().length;
  int get bytesAdded => addedTracks.fold(0, (sum, t) => sum + t.fileSizeBytes);
}
