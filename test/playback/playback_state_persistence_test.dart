import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:listeny/core/models/track.dart';
import 'package:listeny/core/storage/database.dart';
import 'package:listeny/library/library_repository.dart';
import 'package:listeny/playback/playback_service.dart';
import 'package:listeny/playback/playback_state.dart';
import 'package:listeny/playback/playback_state_persistence.dart';

Track _track(String id) => Track(
  id: id,
  filePath: '/tmp/$id.mp3',
  title: 'Song $id',
  artist: 'Artist',
  album: 'Album',
  albumArtist: 'Artist',
  duration: const Duration(minutes: 3),
  format: 'mp3',
  fileSizeBytes: 1000,
  dateAdded: DateTime.now(),
);

/// Records exactly what [restore] asks it to load — everything else falls
/// through to a no-op via [noSuchMethod], matching the pattern already used
/// elsewhere in this repo for a minimal fake [PlaybackService].
class _RecordingPlaybackService implements PlaybackService {
  List<Track>? loadedTracks;
  int? loadedStartIndex;
  Duration? seekedTo;

  @override
  Future<void> loadQueue(
    List<Track> tracks, {
    int startIndex = 0,
    String? contextName,
    bool autoPlay = true,
  }) async {
    loadedTracks = tracks;
    loadedStartIndex = startIndex;
  }

  @override
  ValueStream<Track?> get currentTrack => BehaviorSubject<Track?>.seeded(null);

  @override
  Future<void> seek(Duration position) async {
    seekedTo = position;
  }

  @override
  Future<void> setShuffleEnabled(bool enabled) async {}

  @override
  Future<void> setRepeatMode(PlaybackRepeatMode mode) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  LibraryRepository openLibrary() =>
      LibraryRepository(AppDatabase(NativeDatabase.memory()));

  Future<void> seedSavedState({
    required List<String> trackIds,
    required int currentIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'saved_playback_state',
      jsonEncode({
        'trackIds': trackIds,
        'currentIndex': currentIndex,
        'positionMs': 5000,
        'shuffle': false,
        'repeatMode': 'off',
        'contextName': 'Library',
      }),
    );
  }

  test('restores the track that was actually playing, not its old numeric position, after an earlier track is deleted', () async {
    SharedPreferences.setMockInitialValues({});
    final library = openLibrary();
    final a = _track('a');
    final b = _track('b');
    final c = _track('c');
    final d = _track('d');
    await library.insertTrack(a);
    await library.insertTrack(b);
    await library.insertTrack(c);
    await library.insertTrack(d);

    // Saved while playing 'b' (position 1 in the original 4-track queue).
    await seedSavedState(trackIds: ['a', 'b', 'c', 'd'], currentIndex: 1);

    // 'a' is deleted before restore — the filtered queue is [b, c, d]. The
    // old logic clamped the raw saved index (1) against the new (shorter)
    // list and landed on 'c' by coincidence of position, not identity —
    // this reproduces that exact mismatch.
    await library.removeTrackFromLibraryOnly(a);

    final playback = _RecordingPlaybackService();
    await PlaybackStatePersistence().restore(playback, library);

    expect(playback.loadedTracks?.map((t) => t.id).toList(), ['b', 'c', 'd']);
    expect(playback.loadedStartIndex, 0);
    expect(playback.loadedTracks![playback.loadedStartIndex!].id, 'b');
    // The saved track ('b') still exists, so its saved position is restored.
    expect(playback.seekedTo, const Duration(milliseconds: 5000));
  });

  test('falls back to the start when the previously-playing track was itself deleted', () async {
    SharedPreferences.setMockInitialValues({});
    final library = openLibrary();
    final a = _track('a');
    final b = _track('b');
    await library.insertTrack(a);
    await library.insertTrack(b);

    // Saved while playing 'a' (position 0).
    await seedSavedState(trackIds: ['a', 'b'], currentIndex: 0);
    await library.removeTrackFromLibraryOnly(a);

    final playback = _RecordingPlaybackService();
    await PlaybackStatePersistence().restore(playback, library);

    expect(playback.loadedTracks?.map((t) => t.id).toList(), ['b']);
    expect(playback.loadedStartIndex, 0);
    // The saved track ('a') was deleted — its saved position must NOT be
    // applied to the fallback track ('b').
    expect(playback.seekedTo, isNull);
  });
}
