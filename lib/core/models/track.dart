import '../copy_title.dart';

/// A single local audio track, backed by a real file copied into the app's
/// own storage (never the original picked location — see ImportService).
class Track {
  final String id;

  /// Path to the app-owned copy of the audio file (not the original).
  final String filePath;

  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final Duration duration;

  /// File extension the track was imported as (mp3, flac, ...).
  final String format;
  final int? bitrateKbps;
  final int? sampleRateHz;

  /// Bits per sample, where the source format/parser exposes it (lossless
  /// PCM formats mainly). Null rather than guessed when not available.
  final int? bitDepth;

  final int fileSizeBytes;
  final DateTime dateAdded;

  /// Path to a locally-saved copy of the track's embedded artwork, if it had
  /// any. Null means genuinely no embedded artwork — screens render a
  /// deterministic generated-gradient placeholder from the track/album name
  /// in that case (matching the design's own "abstract CSS artwork" stand-in)
  /// rather than this pipeline manufacturing and storing a placeholder file.
  final String? artworkPath;

  final bool favorite;
  final int playCount;

  const Track({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArtist,
    this.trackNumber,
    this.discNumber,
    this.year,
    required this.duration,
    required this.format,
    this.bitrateKbps,
    this.sampleRateHz,
    this.bitDepth,
    required this.fileSizeBytes,
    required this.dateAdded,
    this.artworkPath,
    this.favorite = false,
    this.playCount = 0,
  });

  /// Seed for the generated placeholder artwork. A copy titled "Name (2)"
  /// uses the same seed as "Name", so it gets the same picture.
  String get artworkSeed => '${stripCopyCounter(title)}|$artist';

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
