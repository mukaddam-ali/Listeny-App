import 'package:rxdart/rxdart.dart';

import '../core/models/track.dart';
import 'playback_state.dart';

/// The single app-wide playback contract.
///
/// The UI (mini-player, Now Playing, queue screen, ...) depends only on this
/// interface, [Track] and the enums in playback_state.dart — never on
/// `audio_service` or `just_audio` types directly. That keeps the real
/// platform audio engine swappable/testable without touching any screen.
///
/// Every getter is a [ValueStream]: a [Stream] that also synchronously
/// exposes `.value` (and `.valueOrNull` before the first event), so widgets
/// can read the current value immediately and also listen for changes.
abstract class PlaybackService {
  /// The track currently loaded (playing or paused). Null once idle/empty.
  ValueStream<Track?> get currentTrack;

  /// Index of [currentTrack] within [queue]. Null when the queue is empty.
  ValueStream<int?> get currentIndex;

  /// The full playback queue, in original (non-shuffled) order.
  ValueStream<List<Track>> get queue;

  /// Human-readable name of what's currently playing from (an album,
  /// playlist, artist or "Library"), shown as "Playing from …" in Now
  /// Playing. Null before anything has ever been loaded.
  ValueStream<String?> get contextName;

  /// Whether audio is actively playing right now.
  ValueStream<bool> get isPlaying;

  /// Live playback position of the current track.
  ValueStream<Duration> get position;

  /// Duration of the current track (Duration.zero if unknown/loading).
  ValueStream<Duration> get duration;

  ValueStream<bool> get shuffleEnabled;
  ValueStream<PlaybackRepeatMode> get repeatMode;
  ValueStream<ProcessingState> get processingState;

  /// Replaces the queue, positioned at [startIndex]. [contextName] is what's
  /// shown as "Playing from …" (an album/playlist/artist name, or "Library");
  /// pass null only when there's genuinely nothing to name. Starts playing
  /// immediately unless [autoPlay] is false — pass false when loading a
  /// queue that should stay paused (e.g. restoring last session's state).
  Future<void> loadQueue(
    List<Track> tracks, {
    int startIndex = 0,
    String? contextName,
    bool autoPlay = true,
  });

  Future<void> play();
  Future<void> pause();
  Future<void> togglePlayPause();

  /// Stops playback and clears the current track/queue entirely, so
  /// [currentTrack] emits null and the mini-player disappears — a real
  /// dismiss, not just a pause.
  Future<void> stop();

  /// Seeks within the current track.
  Future<void> seek(Duration position);

  /// Seeks 10 seconds forward from the current (authoritative, live) player
  /// position — clamped to the track's duration, or unclamped if the
  /// duration isn't known yet rather than wrongly seeking to zero.
  Future<void> seekForward10();

  /// Seeks 10 seconds back from the current (authoritative, live) player
  /// position — clamped to the start of the track.
  Future<void> seekBackward10();

  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> skipToIndex(int index);

  Future<void> setShuffleEnabled(bool enabled);
  Future<void> setRepeatMode(PlaybackRepeatMode mode);

  /// Appends [track] to the end of the queue.
  Future<void> addToQueue(Track track);

  /// Inserts [track] immediately after the currently playing item.
  Future<void> playNext(Track track);

  Future<void> removeFromQueue(int index);
  Future<void> moveQueueItem(int oldIndex, int newIndex);

  /// Removes every queue item after the current one, leaving the current
  /// track playing.
  Future<void> clearUpcoming();

  /// Refreshes the title/artist/album/albumArtist shown for [tracks] that
  /// are currently loaded/queued (matched by id) — e.g. after an album
  /// rename — WITHOUT reloading the audio, resetting playback position, or
  /// disturbing shuffle/order. A no-op for any track not currently loaded.
  Future<void> refreshTrackMetadata(List<Track> tracks);

  Future<void> dispose();
}
