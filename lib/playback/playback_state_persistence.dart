import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/diagnostics/startup_log.dart';
import '../core/models/track.dart';
import '../library/library_repository.dart';
import 'playback_service.dart';
import 'playback_state.dart';

const rememberPositionPrefKey = 'remember_playback_position';

class SavedPlaybackState {
  final List<String> trackIds;
  final int currentIndex;
  final int positionMs;
  final bool shuffle;
  final PlaybackRepeatMode repeatMode;
  final String? contextName;

  const SavedPlaybackState({
    required this.trackIds,
    required this.currentIndex,
    required this.positionMs,
    required this.shuffle,
    required this.repeatMode,
    required this.contextName,
  });
}

/// Persists/restores "what was playing" across app restarts (Test 8 in the
/// spec's checklist) — a small JSON blob in SharedPreferences, not a
/// database concern. Only the queue's *song ids* are stored; the real Track
/// objects are re-resolved from [LibraryRepository] on restore, so a track
/// that was removed from the library in the meantime is silently dropped
/// rather than crashing playback restoration.
class PlaybackStatePersistence {
  static const _key = 'saved_playback_state';

  Future<void> save(PlaybackService playback) async {
    final queue = playback.queue.value;
    if (queue.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'trackIds': queue.map((t) => t.id).toList(),
      'currentIndex': playback.currentIndex.value ?? 0,
      'positionMs': playback.position.value.inMilliseconds,
      'shuffle': playback.shuffleEnabled.value,
      'repeatMode': playback.repeatMode.value.name,
      'contextName': playback.contextName.value,
    });
    await prefs.setString(_key, json);
  }

  Future<SavedPlaybackState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SavedPlaybackState(
        trackIds: (map['trackIds'] as List).cast<String>(),
        currentIndex: map['currentIndex'] as int,
        positionMs: map['positionMs'] as int,
        shuffle: map['shuffle'] as bool,
        repeatMode: PlaybackRepeatMode.values.byName(
          map['repeatMode'] as String,
        ),
        contextName: map['contextName'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Restores the saved queue/position into [playback], paused (never
  /// auto-plays on launch). No-op if nothing was saved, the setting is off,
  /// or none of the saved tracks still exist in the library.
  Future<void> restore(
    PlaybackService playback,
    LibraryRepository library,
  ) async {
    StartupLog.inRestore = true;
    final restoreSw = Stopwatch()..start();
    StartupLog.mark('playback restore START');
    try {
      await _restore(playback, library);
    } finally {
      StartupLog.inRestore = false;
      StartupLog.mark(
        'playback restore END (${restoreSw.elapsedMilliseconds}ms)',
      );
    }
  }

  Future<void> _restore(
    PlaybackService playback,
    LibraryRepository library,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(rememberPositionPrefKey) ?? true;
    StartupLog.mark('restore: preferences loaded (remember=$remember)');
    if (!remember) return;

    final saved = await load();
    StartupLog.mark(
      'restore: saved queue size=${saved?.trackIds.length ?? 'none'}',
    );
    if (saved == null) return;

    final allTracks = await library.getAllTracksOnce();
    StartupLog.mark(
      'restore: all database tracks loaded count=${allTracks.length}',
    );
    final byId = {for (final t in allTracks) t.id: t};
    final tracks = saved.trackIds
        .map((id) => byId[id])
        .whereType<Track>()
        .toList();
    StartupLog.mark(
      'restore: queue reconstruction complete count=${tracks.length}',
    );
    if (tracks.isEmpty) return;

    // Restore by the track that was actually playing, not its old numeric
    // position — filtering out deleted tracks above can shift every later
    // index, so reusing the raw saved index against the (possibly shorter)
    // filtered list could resume a completely different track. Falls back
    // to the start if that exact track was itself deleted.
    final playingTrackId =
        saved.currentIndex >= 0 && saved.currentIndex < saved.trackIds.length
        ? saved.trackIds[saved.currentIndex]
        : null;
    final restoredIndex = playingTrackId == null
        ? -1
        : tracks.indexWhere((t) => t.id == playingTrackId);
    final foundSavedTrack = restoredIndex >= 0;
    final startIndex = foundSavedTrack ? restoredIndex : 0;
    // autoPlay: false — this used to call loadQueue() (which always starts
    // playback) and immediately pause() right after, which meant every
    // restore briefly, audibly played the track before pausing it. That
    // blip was hidden while restore() blocked the loading screen; once it
    // was moved to run in the background (so it can't freeze the UI on a
    // slow device), the same blip became a visible/audible "it just started
    // playing by itself" bug.
    await playback.loadQueue(
      tracks,
      startIndex: startIndex,
      contextName: saved.contextName,
      autoPlay: false,
    );
    // Only apply the saved seek position when the saved track itself is the
    // one that's playing — that position was recorded for that exact song,
    // and applying it to a different, fallback track would resume it
    // partway through for no reason the user would recognize.
    StartupLog.mark('restore: loadQueue returned');
    if (foundSavedTrack) {
      await playback.seek(Duration(milliseconds: saved.positionMs));
    }
    StartupLog.mark('restore: saved position seek complete');
    await playback.setShuffleEnabled(saved.shuffle);
    await playback.setRepeatMode(saved.repeatMode);
    StartupLog.mark('restore: shuffle/repeat restore complete');
  }
}
