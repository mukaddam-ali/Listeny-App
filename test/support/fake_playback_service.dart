import 'package:rxdart/rxdart.dart';

import 'package:listeny/core/models/track.dart';
import 'package:listeny/playback/playback_service.dart';
import 'package:listeny/playback/playback_state.dart';

/// A controllable [PlaybackService] double for widget tests: every stream is
/// a [BehaviorSubject] the test can push fresh values onto directly, so a
/// test can simulate exactly the event sequence it wants (e.g. a real
/// position value dropping back to zero) without needing a real player.
/// Unused members fall through to a no-op via [noSuchMethod], matching the
/// minimal-fake pattern already used elsewhere in this repo's tests.
class FakePlaybackService implements PlaybackService {
  final currentTrackSubject = BehaviorSubject<Track?>.seeded(null);
  final contextNameSubject = BehaviorSubject<String?>.seeded(null);
  final positionSubject = BehaviorSubject<Duration>.seeded(Duration.zero);
  final durationSubject = BehaviorSubject<Duration>.seeded(Duration.zero);
  final isPlayingSubject = BehaviorSubject<bool>.seeded(false);
  final shuffleEnabledSubject = BehaviorSubject<bool>.seeded(false);
  final repeatModeSubject = BehaviorSubject<PlaybackRepeatMode>.seeded(
    PlaybackRepeatMode.off,
  );

  @override
  ValueStream<Track?> get currentTrack => currentTrackSubject.stream;
  @override
  ValueStream<String?> get contextName => contextNameSubject.stream;
  @override
  ValueStream<Duration> get position => positionSubject.stream;
  @override
  ValueStream<Duration> get duration => durationSubject.stream;
  @override
  ValueStream<bool> get isPlaying => isPlayingSubject.stream;
  @override
  ValueStream<bool> get shuffleEnabled => shuffleEnabledSubject.stream;
  @override
  ValueStream<PlaybackRepeatMode> get repeatMode => repeatModeSubject.stream;

  @override
  Future<void> togglePlayPause() async {}

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setShuffleEnabled(bool enabled) async {}

  @override
  Future<void> setRepeatMode(PlaybackRepeatMode mode) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
