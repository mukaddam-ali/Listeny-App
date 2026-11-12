import 'package:flutter/foundation.dart';

/// Decides whether a `PlaybackService.currentTrack` emission represents a
/// genuine playback transition (worth recording a play for) or a
/// metadata-only refresh of the same track id — e.g.
/// [PlaybackService.refreshTrackMetadata] pushing an updated album name
/// after a rename also emits a new `currentTrack` value with the same id,
/// which must NOT increment play count or touch Recently Played.
///
/// Extracted out of main.dart's bootstrap so this decision is unit-testable
/// without a real PlaybackService/LibraryRepository/audio_service stack.
/// Deliberately stateful (remembers the last id it recorded a play for),
/// not a pure function — that's exactly what distinguishing "same track,
/// metadata only" from "genuinely a different track" requires.
@visibleForTesting
class PlayRecordGate {
  String? _lastRecordedTrackId;

  /// Call on every `currentTrack` emission. Returns the track id to record
  /// a play for, or null when this emission should NOT record one
  /// (metadata-only refresh of the already-current track, or `trackId` is
  /// null). Resets its memory on null so a later replay of the same track
  /// id — a genuine new play, after playback actually stopped/cleared — is
  /// still counted.
  String? onCurrentTrackChanged(String? trackId) {
    if (trackId == null) {
      _lastRecordedTrackId = null;
      return null;
    }
    if (trackId == _lastRecordedTrackId) return null;
    _lastRecordedTrackId = trackId;
    return trackId;
  }
}
