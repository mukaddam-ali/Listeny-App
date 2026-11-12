import 'package:drift/native.dart';
import 'package:rxdart/rxdart.dart';

import 'package:listeny/core/models/track.dart';
import 'package:listeny/core/storage/database.dart' hide Playlist;
import 'package:listeny/library/library_repository.dart';

/// A [LibraryRepository] backed by an in-memory Drift database, but with the
/// watch* streams widget tests actually touch overridden to plain
/// [BehaviorSubject]s instead of real Drift watch queries — those queries
/// use a [Timer] internally that outlives a `tester.pumpWidget` test unless
/// carefully drained, tripping flutter_test's "Timer still pending" check.
/// Matches the pattern already used in search_screen_test.dart.
class FakeLibraryRepository extends LibraryRepository {
  FakeLibraryRepository._(super.db);
  factory FakeLibraryRepository() =>
      FakeLibraryRepository._(AppDatabase(NativeDatabase.memory()));

  final favoritesSubject = BehaviorSubject<List<Track>>.seeded(const []);
  final allTracksSubject = BehaviorSubject<List<Track>>.seeded(const []);

  @override
  ValueStream<List<Track>> watchFavorites() => favoritesSubject.stream;

  @override
  ValueStream<List<Track>> watchAllTracks() => allTracksSubject.stream;
}
