import 'package:listeny/core/models/track.dart';

/// A minimal, valid [Track] for widget/unit tests where the exact metadata
/// doesn't matter — only [id] (and optionally [duration]) need to vary.
Track testTrack(String id, {Duration duration = const Duration(minutes: 3)}) =>
    Track(
      id: id,
      filePath: '/tmp/$id.mp3',
      title: 'Song $id',
      artist: 'Artist',
      album: 'Album',
      albumArtist: 'Artist',
      duration: duration,
      format: 'mp3',
      fileSizeBytes: 1000,
      dateAdded: DateTime.now(),
    );
