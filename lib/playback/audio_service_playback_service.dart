import 'package:audio_service/audio_service.dart' as svc;
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../core/diagnostics/perf_log.dart';
import '../core/models/track.dart';
import 'listeny_audio_handler.dart';
import 'play_tap_trace.dart';
import 'playback_service.dart';
import 'playback_state.dart';

/// The real implementation of [PlaybackService], backed by [ListenyAudioHandler]
/// (audio_service + just_audio). Translates between this app's [Track]-based
/// domain model and audio_service's [svc.MediaItem]-based one, so every other
/// part of the app can depend on the plain [PlaybackService] interface only.
class AudioServicePlaybackService implements PlaybackService {
  final ListenyAudioHandler _handler;

  /// track.id -> Track, refreshed whenever the app-side queue changes.
  final Map<String, Track> _tracksById = {};

  final BehaviorSubject<Track?> _currentTrack = BehaviorSubject.seeded(null);
  final BehaviorSubject<int?> _currentIndex = BehaviorSubject.seeded(null);
  final BehaviorSubject<List<Track>> _queue = BehaviorSubject.seeded(const []);
  final BehaviorSubject<bool> _isPlaying = BehaviorSubject.seeded(false);
  // audio_service exposes `AudioService.position` as a plain broadcast
  // Stream<Duration> (no `.value`); re-seed it into a BehaviorSubject so the
  // app-level interface can promise every widget a ValueStream.
  final BehaviorSubject<Duration> _position = BehaviorSubject.seeded(
    Duration.zero,
  );
  final BehaviorSubject<Duration> _duration = BehaviorSubject.seeded(
    Duration.zero,
  );
  final BehaviorSubject<bool> _shuffleEnabled = BehaviorSubject.seeded(false);
  final BehaviorSubject<PlaybackRepeatMode> _repeatMode =
      BehaviorSubject.seeded(PlaybackRepeatMode.off);
  final BehaviorSubject<ProcessingState> _processingState =
      BehaviorSubject.seeded(ProcessingState.idle);
  final BehaviorSubject<String?> _contextName = BehaviorSubject.seeded(null);

  AudioServicePlaybackService(this._handler) {
    svc.AudioService.position.listen((pos) {
      _pollTrace();
      _position.add(pos);
    });
    // Pause/stop/interruption while still loading ends the trace.
    _handler.autoPlayCancelled.listen((reason) {
      _tracker.close('cancelled: $reason');
    });
    _handler.queue.listen((items) {
      _queue.add(
        items.map((i) => _tracksById[i.id]).whereType<Track>().toList(),
      );
    });
    _handler.mediaItem.listen((item) {
      PerfLog.step('skip', 'current item changed');
      PerfLog.end('skip', 'item change landed');
      _currentTrack.add(item == null ? null : _tracksById[item.id]);
      _duration.add(item?.duration ?? Duration.zero);
    });
    _handler.playbackState.listen((state) {
      _pollTrace();
      _isPlaying.add(state.playing);
      _currentIndex.add(state.queueIndex);
      _shuffleEnabled.add(state.shuffleMode == svc.AudioServiceShuffleMode.all);
      _repeatMode.add(_toRepeatMode(state.repeatMode));
      _processingState.add(_toProcessingState(state.processingState));
    });
  }

  @override
  ValueStream<Track?> get currentTrack => _currentTrack.stream;
  @override
  ValueStream<int?> get currentIndex => _currentIndex.stream;
  @override
  ValueStream<List<Track>> get queue => _queue.stream;
  @override
  ValueStream<bool> get isPlaying => _isPlaying.stream;
  @override
  ValueStream<Duration> get position => _position.stream;
  @override
  ValueStream<Duration> get duration => _duration.stream;
  @override
  ValueStream<bool> get shuffleEnabled => _shuffleEnabled.stream;
  @override
  ValueStream<PlaybackRepeatMode> get repeatMode => _repeatMode.stream;
  @override
  ValueStream<ProcessingState> get processingState => _processingState.stream;
  @override
  ValueStream<String?> get contextName => _contextName.stream;

  svc.MediaItem _toMediaItem(Track t, [int? playTapRequest]) => svc.MediaItem(
    id: t.id,
    title: t.title,
    artist: t.artist,
    album: t.album,
    duration: t.duration,
    artUri: t.artworkPath == null ? null : Uri.file(t.artworkPath!),
    extras: {'filePath': t.filePath, playTapRequestExtrasKey: ?playTapRequest},
  );

  PlaybackRepeatMode _toRepeatMode(svc.AudioServiceRepeatMode mode) {
    switch (mode) {
      case svc.AudioServiceRepeatMode.none:
        return PlaybackRepeatMode.off;
      case svc.AudioServiceRepeatMode.one:
        return PlaybackRepeatMode.one;
      case svc.AudioServiceRepeatMode.all:
      case svc.AudioServiceRepeatMode.group:
        return PlaybackRepeatMode.all;
    }
  }

  svc.AudioServiceRepeatMode _fromRepeatMode(PlaybackRepeatMode mode) {
    switch (mode) {
      case PlaybackRepeatMode.off:
        return svc.AudioServiceRepeatMode.none;
      case PlaybackRepeatMode.one:
        return svc.AudioServiceRepeatMode.one;
      case PlaybackRepeatMode.all:
        return svc.AudioServiceRepeatMode.all;
    }
  }

  ProcessingState _toProcessingState(svc.AudioProcessingState state) {
    switch (state) {
      case svc.AudioProcessingState.idle:
        return ProcessingState.idle;
      case svc.AudioProcessingState.loading:
        return ProcessingState.loading;
      case svc.AudioProcessingState.buffering:
        return ProcessingState.buffering;
      case svc.AudioProcessingState.ready:
        return ProcessingState.ready;
      case svc.AudioProcessingState.completed:
        return ProcessingState.completed;
      case svc.AudioProcessingState.error:
        return ProcessingState.error;
    }
  }

  /// Perf-only: times [call] (handler round trip) under [name].
  Future<void> _timed(String name, Future<void> Function() call) async {
    if (!PerfLog.enabled) return call();
    PerfLog.begin(name);
    try {
      await call();
    } finally {
      PerfLog.end(name, 'handler call returned');
    }
  }

  /// Perf-only: like [_timed], but also logs when the current item actually
  /// changes (the 'skip' interaction stays open until then).
  Future<void> _timedSkip(String name, Future<void> Function() call) async {
    if (!PerfLog.enabled) return call();
    PerfLog.end('skip', 'superseded');
    PerfLog.begin('skip', name);
    try {
      await call();
    } finally {
      PerfLog.step('skip', '$name handler call returned');
    }
  }

  @override
  Future<void> loadQueue(
    List<Track> tracks, {
    int startIndex = 0,
    String? contextName,
    bool autoPlay = true,
  }) async {
    for (final t in tracks) {
      _tracksById[t.id] = t;
    }
    _contextName.add(contextName);
    final trace = PerfLog.enabled
        ? _tracker.beginForLoad(
            autoPlay: autoPlay,
            detail: 'queue=${tracks.length}',
          )
        : null;
    try {
      final items = trace == null
          ? tracks.map(_toMediaItem).toList()
          : trace.phase('MediaItem mapping', () {
              return tracks.map((t) => _toMediaItem(t, trace.id)).toList();
            });
      await _handler.loadAndPlay(
        items,
        startIndex: startIndex,
        autoPlay: autoPlay,
        trace: trace,
      );
      if (trace != null) _tracker.closeIfUnarmed(trace);
    } catch (e) {
      if (trace != null) {
        _tracker.close('failed: ${e.runtimeType}', only: trace);
      }
      rethrow;
    }
  }

  /// Perf-only: owns the active play-tap trace and its lifecycle.
  final PlayTapTracker _tracker = PlayTapTracker();

  /// Evaluates the active trace against the player's live state. Stream
  /// events are only triggers; their (possibly stale) values are not used.
  void _pollTrace() {
    if (_tracker.active == null) return;
    final live = _handler.liveSnapshot();
    _tracker.onLive(
      boundRequestId: live.requestId,
      playing: live.playing,
      ready: live.ready,
      completed: live.completed,
      position: live.position,
    );
  }

  @override
  Future<void> play() => _timed('resume', _handler.play);

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> stop() => _handler.stopAndClear();

  @override
  Future<void> togglePlayPause() => _isPlaying.value ? pause() : play();

  @override
  Future<void> seek(Duration position) => _handler.seek(position);

  @override
  Future<void> seekForward10() => _timed('seek+10', _handler.fastForward);

  @override
  Future<void> seekBackward10() => _timed('seek-10', _handler.rewind);

  @override
  Future<void> skipToNext() => _timedSkip('next', _handler.skipToNext);

  @override
  Future<void> skipToPrevious() =>
      _timedSkip('previous', _handler.skipToPrevious);

  @override
  Future<void> skipToIndex(int index) => _handler.skipToQueueItem(index);

  @override
  Future<void> setShuffleEnabled(bool enabled) => _handler.setShuffleMode(
    enabled
        ? svc.AudioServiceShuffleMode.all
        : svc.AudioServiceShuffleMode.none,
  );

  @override
  Future<void> setRepeatMode(PlaybackRepeatMode mode) =>
      _handler.setRepeatMode(_fromRepeatMode(mode));

  @override
  Future<void> addToQueue(Track track) async {
    _tracksById[track.id] = track;
    await _handler.addQueueItem(_toMediaItem(track));
  }

  @override
  Future<void> playNext(Track track) async {
    _tracksById[track.id] = track;
    final insertAt = (_currentIndex.value ?? -1) + 1;
    await _handler.insertQueueItem(insertAt, _toMediaItem(track));
  }

  @override
  Future<void> removeFromQueue(int index) async {
    final items = _handler.queue.value;
    if (index < 0 || index >= items.length) return;
    await _handler.removeQueueItem(items[index]);
  }

  @override
  Future<void> moveQueueItem(int oldIndex, int newIndex) =>
      _handler.moveQueueItem(oldIndex, newIndex);

  /// The displayed items "clear upcoming" should remove — everything after
  /// [currentIndex], furthest-from-current first, so removing one never
  /// shifts the display position of the next one still to be removed.
  /// Never includes [currentIndex] itself, however it's called, which is
  /// what guarantees the current track is never removed by mistake.
  /// Extracted as a pure function so that guarantee is testable without a
  /// real audio player.
  @visibleForTesting
  static List<svc.MediaItem> itemsToClearAfter(
    List<svc.MediaItem> items,
    int currentIndex,
  ) => [for (var i = items.length - 1; i > currentIndex; i--) items[i]];

  @override
  Future<void> clearUpcoming() async {
    final items = _handler.queue.value;
    final current = _currentIndex.value ?? -1;
    for (final item in itemsToClearAfter(items, current)) {
      await _handler.removeQueueItem(item);
    }
  }

  @override
  Future<void> refreshTrackMetadata(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    for (final t in tracks) {
      _tracksById[t.id] = t;
    }
    final byId = {for (final t in tracks) t.id: t};
    _handler.refreshTrackMetadata({
      for (final t in tracks) t.id: (item) => _toMediaItem(byId[t.id]!),
    });
  }

  @override
  Future<void> dispose() async {
    await _handler.disposePlayer();
    await _currentTrack.close();
    await _currentIndex.close();
    await _queue.close();
    await _isPlaying.close();
    await _position.close();
    await _duration.close();
    await _shuffleEnabled.close();
    await _repeatMode.close();
    await _processingState.close();
    await _contextName.close();
  }
}
