import '../core/models/track.dart';

/// Flags a candidate track as already in the library by matching on title,
/// artist and duration — the same fields the design's own "Already in your
/// library" screen names ("Matched on title, artist and duration").
class DuplicateDetector {
  /// Two re-encodes of the same recording rarely land on the exact same
  /// millisecond; a couple of seconds of slack avoids false negatives while
  /// staying far tighter than the gap between two genuinely different songs.
  static const _durationTolerance = Duration(seconds: 2);

  Track? findDuplicate(Track candidate, List<Track> existing) {
    for (final track in existing) {
      final sameTitle =
          track.title.toLowerCase() == candidate.title.toLowerCase();
      final sameArtist =
          track.artist.toLowerCase() == candidate.artist.toLowerCase();
      final durationDiff = (track.duration - candidate.duration).abs();
      if (sameTitle && sameArtist && durationDiff <= _durationTolerance) {
        return track;
      }
    }
    return null;
  }
}
