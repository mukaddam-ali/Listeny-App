import 'fake_drive_client.dart';
import 'fake_ffmpeg.dart';

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:listeny/core/models/track.dart';
// database.dart's generated DownloadHistoryEntry (a raw table row) collides
// by name with library_repository.dart's own DownloadHistoryEntry (the
// public value type) — this test only ever needs the latter.
import 'package:listeny/core/storage/database.dart' hide DownloadHistoryEntry;
import 'package:listeny/library/audio_conversion_service.dart';
import 'package:listeny/library/direct_media_url_resolver.dart';
import 'package:listeny/library/google_drive_client.dart';
import 'package:listeny/library/google_drive_resolver.dart';
import 'package:listeny/library/import_models.dart';
import 'package:listeny/library/import_service.dart';
import 'package:listeny/library/library_repository.dart';
import 'package:listeny/library/link_import_models.dart';
import 'package:listeny/library/link_import_service.dart';
import 'package:listeny/library/media_download_service.dart';
import 'package:listeny/library/safe_http.dart';
import 'package:listeny/library/media_url_resolver.dart';
import 'package:listeny/library/thumbnail_fetcher.dart';

/// [LinkImportService] asks `path_provider` for a scratch directory; this
/// swaps in a real temp folder without needing a platform channel, which
/// isn't available under plain `flutter test`.
class _FakePathProviderPlatform extends PathProviderPlatform {
  final String tempPath;
  _FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

class _FakeResolver implements MediaUrlResolver {
  final ResolvedMedia? media;
  _FakeResolver(this.media);

  @override
  bool supports(Uri url) => true;

  @override
  Future<ResolvedMedia> resolve(Uri url, {CancelToken? cancelToken}) async {
    final result = media;
    if (result == null) throw const UnsupportedLinkException();
    return result;
  }
}

/// Writes real bytes to [destinationPath] (like dio streaming to disk) and
/// reports progress, without any actual network call.
class _ImmediateDownloadService extends MediaDownloadService {
  String? lastDestinationPath;

  @override
  Future<void> download({
    required Uri url,
    required String destinationPath,
    required CancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
    DestinationPolicy? destinationPolicy,
    Map<String, String>? headers,
  }) async {
    lastDestinationPath = destinationPath;
    onProgress?.call(50, 100);
    await File(destinationPath).writeAsBytes([1, 2, 3]);
    onProgress?.call(100, 100);
  }
}

class _FailingDownloadService extends MediaDownloadService {
  final DownloadFailedException error;
  _FailingDownloadService(this.error);

  @override
  Future<void> download({
    required Uri url,
    required String destinationPath,
    required CancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
    DestinationPolicy? destinationPolicy,
    Map<String, String>? headers,
  }) async {
    throw error;
  }
}

/// Writes partial bytes to disk immediately (simulating a stream already in
/// flight), then blocks on [gate] before checking whether it was cancelled —
/// lets a test control exactly when, mid-download, cancellation lands.
class _GatedDownloadService extends MediaDownloadService {
  final Future<void> gate;
  String? lastDestinationPath;
  _GatedDownloadService(this.gate);

  @override
  Future<void> download({
    required Uri url,
    required String destinationPath,
    required CancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
    DestinationPolicy? destinationPolicy,
    Map<String, String>? headers,
  }) async {
    lastDestinationPath = destinationPath;
    await File(destinationPath).writeAsBytes([1, 2, 3]);
    await gate;
    if (cancelToken.isCancelled) throw const DownloadCancelledException();
  }
}

class _FakeImportService extends ImportService {
  final ImportSummary summary;
  final List<PickedFile> receivedFiles = [];
  _FakeImportService(this.summary, LibraryRepository repo) : super(repo);

  @override
  Future<ImportSummary> importAndSummarize(List<PickedFile> files) async {
    receivedFiles.addAll(files);
    return summary;
  }
}

LibraryRepository _inMemoryRepository() =>
    LibraryRepository(AppDatabase(NativeDatabase.memory()));

/// [LibraryRepository.watchDownloadHistory] is a seeded (shareValueSeeded)
/// stream, so a bare `.first` on a fresh subscription can return the empty
/// seed instead of waiting for the real post-write query — this polls the
/// live value until [predicate] matches.
Future<List<DownloadHistoryEntry>> _waitForHistory(
  LibraryRepository library,
  bool Function(List<DownloadHistoryEntry>) predicate,
) async {
  final stream = library.watchDownloadHistory();
  final sub = stream.listen((_) {});
  try {
    for (var i = 0; i < 200; i++) {
      if (predicate(stream.value)) return stream.value;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw TimeoutException('download history condition never met');
  } finally {
    await sub.cancel();
  }
}

/// Never touches the network — succeeds by writing fixed bytes when
/// [shouldSucceed] is true, otherwise returns null exactly like the real
/// [ThumbnailFetcher] does on any failure.
class _FakeThumbnailFetcher extends ThumbnailFetcher {
  final bool shouldSucceed;
  Uri? lastRequestedUrl;
  _FakeThumbnailFetcher({required this.shouldSucceed});

  @override
  Future<String?> fetch(
    Uri url,
    String destinationPath, {
    CancelToken? cancelToken,
  }) async {
    lastRequestedUrl = url;
    if (!shouldSucceed) return null;
    await File(destinationPath).writeAsBytes([9, 9, 9]);
    return destinationPath;
  }
}

/// Writes to [destinationPath] immediately (so a test can tell the fetch has
/// started) then blocks on [gate] before returning — lets a test cancel the
/// service while a thumbnail fetch is genuinely in flight.
class _GatedThumbnailFetcher extends ThumbnailFetcher {
  final Future<void> gate;
  String? lastDestinationPath;
  _GatedThumbnailFetcher(this.gate);

  @override
  Future<String?> fetch(
    Uri url,
    String destinationPath, {
    CancelToken? cancelToken,
  }) async {
    lastDestinationPath = destinationPath;
    await File(destinationPath).writeAsBytes([1, 2, 3]);
    await gate;
    return destinationPath;
  }
}

/// Fakes one provider-style [ByteStreamSource] candidate: an
/// in-test-controlled stream plus a configurable extension.
class _FakeByteStreamSource implements ByteStreamSource {
  final Stream<List<int>> Function() opener;
  @override
  final int? contentLength;
  @override
  final String fileExtension;

  _FakeByteStreamSource({
    required this.opener,
    this.contentLength,
    this.fileExtension = 'm4a',
  });

  @override
  Stream<List<int>> open() => opener();
}

/// Fakes a [ByteStreamSourceProvider] serving a fixed, ordered list of
/// candidates — [next] hands them out one at a time, then returns null.
/// Tracks how many candidates were actually requested and whether
/// [dispose] was called, so tests can verify the fallback/retry loop and
/// resource cleanup without needing a real manifest refresh.
class _FakeByteStreamSourceProvider implements ByteStreamSourceProvider {
  final List<ByteStreamSource> candidates;
  int callCount = 0;
  bool disposed = false;

  _FakeByteStreamSourceProvider(this.candidates);

  @override
  Future<ByteStreamSource?> next() async {
    callCount++;
    if (callCount > candidates.length) return null;
    return candidates[callCount - 1];
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

/// Files left behind in the scratch dir after a run — should always be
/// empty, since [LinkImportService] cleans up unconditionally in `finally`
/// regardless of how the run ended.
List<FileSystemEntity> _scratchDirLeftovers(Directory tempDir) {
  final dir = Directory(p.join(tempDir.path, 'link_downloads'));
  return dir.existsSync() ? dir.listSync() : const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('link_import_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    // Each test opens its own throwaway in-memory database on purpose —
    // drift's "opened twice" heuristic assumes that's always a mistake,
    // which isn't true here.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  // Every run now decodes/converts through FFmpeg; groups that inspect the
  // native calls install their own FakeFfmpeg over this default.
  setUp(() => FakeFfmpeg().install());

  test('happy path resolves, downloads, converts (no-op) and imports, then cleans up', () async {
    final native = FakeFfmpeg()..install();
    final url = Uri.parse('https://example.com/song.mp3');
    final download = _ImmediateDownloadService();
    final summary = ImportSummary(
      addedTracks: [],
      duplicates: const [],
      unsupported: const [],
      corrupt: const [],
    );
    final service = LinkImportService(
      libraryRepository: _inMemoryRepository(),
      resolvers: MediaUrlResolverRegistry([
        _FakeResolver(
          ResolvedMedia(
            origin: MediaSourceOrigin.direct,
            downloadUrl: url,
            suggestedFileName: 'song.mp3',
            kind: MediaSourceKind.audio,
          ),
        ),
      ]),
      importService: _FakeImportService(summary, _inMemoryRepository()),
      downloadService: download,
      conversionService: AudioConversionService(),
    );

    final events = await service.run(url: url).toList();

    expect(events.map((e) => e.stage).toList(), [
      DownloadStage.resolving,
      DownloadStage.downloading,
      DownloadStage.downloading,
      DownloadStage.downloading,
      DownloadStage.converting,
      DownloadStage.importing,
      DownloadStage.completed,
    ]);
    expect(events.last.summary, same(summary));
    // Every import is decode-validated and ends as a validated MP3.
    // (fake bytes aren't MP3, so: validate, transcode, validate output)
    expect(native.commands, hasLength(3));
    expect(native.commands.first, containsAllInOrder(['-map', '0:a:0']));
    // The scratch file dio would have streamed to is gone once the real
    // ImportService (or, here, its fake) has taken what it needs.
    expect(File(download.lastDestinationPath!).existsSync(), isFalse);
  });

  test('an unsupported link fails immediately with a friendly message, no download attempted', () async {
    final download = _ImmediateDownloadService();
    final service = LinkImportService(
      libraryRepository: _inMemoryRepository(),
      resolvers: MediaUrlResolverRegistry([_FakeResolver(null)]),
      importService: _FakeImportService(
        const ImportSummary(
          addedTracks: [],
          duplicates: [],
          unsupported: [],
          corrupt: [],
        ),
        _inMemoryRepository(),
      ),
      downloadService: download,
    );

    final events = await service
        .run(url: Uri.parse('https://example.com/page'))
        .toList();

    expect(events.map((e) => e.stage).toList(), [
      DownloadStage.resolving,
      DownloadStage.failed,
    ]);
    expect(events.last.message, 'This link is not supported yet.');
    expect(download.lastDestinationPath, isNull);
  });

  test(
    'a download failure surfaces its friendly message as the failure stage',
    () async {
      final url = Uri.parse('https://example.com/song.mp3');
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'song.mp3',
              kind: MediaSourceKind.audio,
            ),
          ),
        ]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
        downloadService: _FailingDownloadService(
          const DownloadFailedException(
            "Couldn't connect. Check your internet connection.",
          ),
        ),
      );

      final events = await service.run(url: url).toList();

      expect(events.map((e) => e.stage).toList(), [
        DownloadStage.resolving,
        DownloadStage.downloading,
        DownloadStage.failed,
      ]);
      expect(
        events.last.message,
        "Couldn't connect. Check your internet connection.",
      );
    },
  );

  test(
    'cancelling mid-download stops the run and deletes the partial file',
    () async {
      final url = Uri.parse('https://example.com/song.mp3');
      final gate = Completer<void>();
      final download = _GatedDownloadService(gate.future);
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'song.mp3',
              kind: MediaSourceKind.audio,
            ),
          ),
        ]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
        downloadService: download,
      );

      final events = <DownloadStage>[];
      final done = Completer<void>();
      service
          .run(url: url)
          .listen((p) => events.add(p.stage), onDone: done.complete);

      // Let the run actually reach the (gated) download call before cancelling
      // it — this is what proves cancellation stops real in-flight work,
      // rather than just a run that never started.
      for (
        var i = 0;
        i < 100 && (events.isEmpty || events.last != DownloadStage.downloading);
        i++
      ) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        events.last,
        DownloadStage.downloading,
        reason: 'download never started',
      );

      service.cancel();
      gate.complete();
      await done.future;

      expect(events.last, DownloadStage.cancelled);
      expect(File(download.lastDestinationPath!).existsSync(), isFalse);
    },
  );

  group('muxed production fallback', () {
    late FakeFfmpeg native;
    late _FakeImportService importer;
    setUp(() {
      native = FakeFfmpeg()..install();
      importer = _FakeImportService(
        const ImportSummary(
          addedTracks: [],
          duplicates: [],
          unsupported: [],
          corrupt: [],
        ),
        _inMemoryRepository(),
      );
    });

    LinkImportService create(_FakeByteStreamSourceProvider provider) =>
        LinkImportService(
          libraryRepository: _inMemoryRepository(),
          resolvers: MediaUrlResolverRegistry([
            _FakeResolver(
              ResolvedMedia(
                origin: MediaSourceOrigin.direct,
                downloadUrl: Uri.parse('https://media.example.com/6zvnTuPiDPQ'),
                suggestedFileName: 'Title.m4a',
                kind: MediaSourceKind.audio,
                byteSourceProvider: provider,
              ),
            ),
          ]),
          importService: importer,
        );

    for (final _ in [1]) {
      test(
        'audio rejection -> muxed -> MP3 conversion -> exactly one import',
        () async {
          final provider = _FakeByteStreamSourceProvider([
            _FakeByteStreamSource(
              opener: () => Stream.error(Exception('HTTP 403')),
            ),
            _FakeByteStreamSource(
              fileExtension: 'mp4',
              contentLength: 4,
              opener: () => Stream.value([1, 2, 3, 4]),
            ),
          ]);
          final events = await create(provider)
              .run(url: Uri.parse('https://media.example.com/6zvnTuPiDPQ'))
              .toList();
          expect(events.last.stage, DownloadStage.completed);
          expect(provider.callCount, 2);
          expect(
            native.commands.first[native.commands.first.indexOf('-i') + 1],
            endsWith('.mp4'),
          );
          expect(importer.receivedFiles, hasLength(1));
          expect(importer.receivedFiles.single.name, 'Title.mp3');
          expect(_scratchDirLeftovers(tempDir), isEmpty);
        },
      );
    }

    for (final bytes in <List<int>>[
      [],
      [1, 2],
      [1, 2, 3, 4, 5],
    ]) {
      test(
        'reject incomplete/overlong candidate $bytes and clean partial file',
        () async {
          final provider = _FakeByteStreamSourceProvider([
            _FakeByteStreamSource(
              fileExtension: 'mp4',
              contentLength: 4,
              opener: () => Stream.value(bytes),
            ),
          ]);
          final events = await create(provider)
              .run(url: Uri.parse('https://media.example.com/6zvnTuPiDPQ'))
              .toList();
          expect(events.last.stage, DownloadStage.failed);
          expect(importer.receivedFiles, isEmpty);
          expect(native.commands, isEmpty);
          expect(_scratchDirLeftovers(tempDir), isEmpty);
        },
      );
    }

    test('short audio candidate is discarded before muxed fallback', () async {
      final provider = _FakeByteStreamSourceProvider([
        _FakeByteStreamSource(
          contentLength: 4,
          opener: () => Stream.value([1, 2]),
        ),
        _FakeByteStreamSource(
          fileExtension: 'mp4',
          contentLength: 4,
          opener: () => Stream.value([1, 2, 3, 4]),
        ),
      ]);
      final events = await create(provider)
          .run(url: Uri.parse('https://media.example.com/6zvnTuPiDPQ'))
          .toList();
      expect(events.last.stage, DownloadStage.completed);
      expect(importer.receivedFiles, hasLength(1));
      expect(_scratchDirLeftovers(tempDir), isEmpty);
    });

    test(
      'cancel during muxed transfer stops stream and deletes partial MP4',
      () async {
        final stream = StreamController<List<int>>();
        final provider = _FakeByteStreamSourceProvider([
          _FakeByteStreamSource(
            opener: () => Stream.error(Exception('HTTP 403')),
          ),
          _FakeByteStreamSource(
            fileExtension: 'mp4',
            contentLength: 100,
            opener: () => stream.stream,
          ),
        ]);
        final service = create(provider);
        final events = <LinkImportProgress>[];
        final done = Completer<void>();
        service.run(url: Uri.parse('https://media.example.com/6zvnTuPiDPQ')).listen((
          event,
        ) {
          events.add(event);
          if (event.fraction != null && event.fraction! > 0) {
            service.cancel();
          }
        }, onDone: done.complete);
        while (!stream.hasListener) {
          await Future<void>.delayed(Duration.zero);
        }
        stream.add([1, 2, 3]);
        await done.future;
        expect(events.last.stage, DownloadStage.cancelled);
        expect(stream.hasListener, isFalse);
        expect(importer.receivedFiles, isEmpty);
        expect(native.commands, isEmpty);
        expect(provider.disposed, isTrue);
        expect(_scratchDirLeftovers(tempDir), isEmpty);
        await stream.close();
      },
    );
  });

  group('byte-stream sources', () {
    test('a successful byte stream downloads, converts, and imports, reporting real progress', () async {
      final url = Uri.parse('https://media.example.com/abc123');
      final byteController = StreamController<List<int>>();
      final provider = _FakeByteStreamSourceProvider([
        _FakeByteStreamSource(
          opener: () => byteController.stream,
          contentLength: 10,
        ),
      ]);
      final summary = ImportSummary(
        addedTracks: [],
        duplicates: const [],
        unsupported: const [],
        corrupt: const [],
      );
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'Some Song.m4a',
              kind: MediaSourceKind.audio,
              byteSourceProvider: provider,
            ),
          ),
        ]),
        importService: _FakeImportService(summary, _inMemoryRepository()),
        conversionService: AudioConversionService(),
      );

      final events = <LinkImportProgress>[];
      final done = Completer<void>();
      service.run(url: url).listen(events.add, onDone: done.complete);

      for (
        var i = 0;
        i < 100 &&
            events.where((e) => e.stage == DownloadStage.downloading).isEmpty;
        i++
      ) {
        await Future<void>.delayed(Duration.zero);
      }

      byteController.add(List.filled(5, 1));
      await Future<void>.delayed(Duration.zero);
      byteController.add(List.filled(5, 1));
      await byteController.close();
      await done.future;

      final stages = events.map((e) => e.stage).toList();
      expect(stages.first, DownloadStage.resolving);
      expect(stages, contains(DownloadStage.converting));
      expect(stages, contains(DownloadStage.importing));
      expect(stages.last, DownloadStage.completed);
      expect(events.last.summary, same(summary));

      // Real, incremental byte-based progress — not a fake percentage.
      final fractions = events
          .where((e) => e.stage == DownloadStage.downloading)
          .map((e) => e.fraction)
          .whereType<double>()
          .toList();
      expect(fractions, contains(0.5));
      expect(fractions.last, 1.0);

      expect(_scratchDirLeftovers(tempDir), isEmpty);
      expect(
        provider.disposed,
        isTrue,
        reason: "the source client's resource must be released after use",
      );
    });

    test('cancelling a byte-stream download stops it, closes the sink, and deletes the partial file', () async {
      final url = Uri.parse('https://media.example.com/xyz789');
      final byteController = StreamController<List<int>>();
      final provider = _FakeByteStreamSourceProvider([
        _FakeByteStreamSource(
          opener: () => byteController.stream,
          contentLength: 100,
        ),
      ]);
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'Some Video.m4a',
              kind: MediaSourceKind.audio,
              byteSourceProvider: provider,
            ),
          ),
        ]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
      );

      final events = <DownloadStage>[];
      final done = Completer<void>();
      service
          .run(url: url)
          .listen((p) => events.add(p.stage), onDone: done.complete);

      for (
        var i = 0;
        i < 100 && !events.contains(DownloadStage.downloading);
        i++
      ) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        events,
        contains(DownloadStage.downloading),
        reason: 'byte stream never started',
      );

      // Some real bytes already landed on disk before cancellation.
      byteController.add(List.filled(10, 1));
      await Future<void>.delayed(Duration.zero);

      service.cancel();
      await done.future;

      expect(events.last, DownloadStage.cancelled);
      // No half-downloaded file left around, and (since LinkImportService
      // never got past `downloading`) no library entry was ever attempted.
      expect(_scratchDirLeftovers(tempDir), isEmpty);
      expect(byteController.hasListener, isFalse);
      expect(
        provider.disposed,
        isTrue,
        reason: "cancellation must still release the source client's resource",
      );

      await byteController.close();
    });

    test('a failed byte stream (exhausting the only candidate) surfaces a friendly message', () async {
      final url = Uri.parse('https://media.example.com/broken');
      final byteController = StreamController<List<int>>();
      final provider = _FakeByteStreamSourceProvider([
        _FakeByteStreamSource(
          opener: () => byteController.stream,
          contentLength: 100,
        ),
      ]);
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'Broken.m4a',
              kind: MediaSourceKind.audio,
              byteSourceProvider: provider,
            ),
          ),
        ]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
      );

      final events = <LinkImportProgress>[];
      final done = Completer<void>();
      service.run(url: url).listen(events.add, onDone: done.complete);

      for (
        var i = 0;
        i < 100 &&
            events.where((e) => e.stage == DownloadStage.downloading).isEmpty;
        i++
      ) {
        await Future<void>.delayed(Duration.zero);
      }

      // A genuine mid-transfer error (some bytes already flowed): a hard
      // failure, not a candidate to fall back away from.
      byteController.add(List.filled(3, 1));
      await Future<void>.delayed(Duration.zero);
      byteController.addError(Exception('connection dropped'));
      await done.future;

      expect(events.last.stage, DownloadStage.failed);
      expect(
        events.last.message,
        "Couldn't download audio for this link right now. Please try again.",
      );
      expect(_scratchDirLeftovers(tempDir), isEmpty);
      expect(
        provider.disposed,
        isTrue,
        reason: "a failure must still release the source client's resource",
      );
    });

    test('a candidate that never sends a first byte times out, and the next candidate succeeds', () async {
      final url = Uri.parse('https://media.example.com/fallback-timeout');
      // Never emits and never closes — only the first-byte timeout ends it.
      final stalledController = StreamController<List<int>>();
      final goodController = StreamController<List<int>>();
      final provider = _FakeByteStreamSourceProvider([
        _FakeByteStreamSource(
          opener: () => stalledController.stream,
          contentLength: 100,
          fileExtension: 'webm',
        ),
        _FakeByteStreamSource(
          opener: () => goodController.stream,
          contentLength: 10,
          fileExtension: 'm4a',
        ),
      ]);
      final summary = ImportSummary(
        addedTracks: [],
        duplicates: const [],
        unsupported: const [],
        corrupt: const [],
      );
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'Song.m4a',
              kind: MediaSourceKind.audio,
              byteSourceProvider: provider,
            ),
          ),
        ]),
        importService: _FakeImportService(summary, _inMemoryRepository()),
        conversionService: AudioConversionService(),
        firstByteTimeout: const Duration(milliseconds: 200),
      );

      final events = <LinkImportProgress>[];
      final done = Completer<void>();
      service.run(url: url).listen(events.add, onDone: done.complete);

      // Wait for the first candidate's timeout to actually fire and the
      // second candidate to be requested (rather than a fixed sleep, which
      // races against the first candidate's own timeout under load), then
      // feed the second candidate real bytes.
      for (var i = 0; i < 200 && provider.callCount < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      goodController.add(List.filled(10, 1));
      await goodController.close();
      await done.future;

      final stages = events.map((e) => e.stage).toList();
      expect(stages.first, DownloadStage.resolving);
      expect(stages, contains(DownloadStage.completed));
      expect(events.last.summary, same(summary));
      expect(
        events.any((e) => e.message == 'Trying another media stream...'),
        isTrue,
        reason: 'the UI should be told a fallback is happening',
      );
      expect(
        provider.callCount,
        2,
        reason: 'both candidates should have been requested',
      );
      expect(provider.disposed, isTrue);
      expect(_scratchDirLeftovers(tempDir), isEmpty);

      await stalledController.close();
    });

    test('when every candidate fails, the download fails with a friendly message and cleans up', () async {
      final url = Uri.parse('https://media.example.com/fallback-all-fail');
      final c1 = StreamController<List<int>>();
      final c2 = StreamController<List<int>>();
      final provider = _FakeByteStreamSourceProvider([
        _FakeByteStreamSource(
          opener: () => c1.stream,
          contentLength: 100,
          fileExtension: 'm4a',
        ),
        _FakeByteStreamSource(
          opener: () => c2.stream,
          contentLength: 100,
          fileExtension: 'webm',
        ),
      ]);
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'Song.m4a',
              kind: MediaSourceKind.audio,
              byteSourceProvider: provider,
            ),
          ),
        ]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
        firstByteTimeout: const Duration(milliseconds: 100),
      );

      final events = await service.run(url: url).toList();

      expect(events.first.stage, DownloadStage.resolving);
      expect(events.last.stage, DownloadStage.failed);
      expect(
        events.last.message,
        "Couldn't download audio for this link right now. Please try again.",
      );
      expect(
        events
            .where((e) => e.message == 'Trying another media stream...')
            .length,
        2,
        reason: 'a fallback message should appear after each failed candidate',
      );
      expect(
        provider.callCount,
        3,
        reason: 'candidate 1, candidate 2, then the exhausted null',
      );
      expect(provider.disposed, isTrue);
      expect(_scratchDirLeftovers(tempDir), isEmpty);

      await c1.close();
      await c2.close();
    });

    test('a provider that needs several next() calls (simulating a manifest refresh) still succeeds', () async {
      final url = Uri.parse('https://media.example.com/fallback-refresh');
      final c1 = StreamController<List<int>>();
      final c2 = StreamController<List<int>>();
      final goodController = StreamController<List<int>>();
      final provider = _FakeByteStreamSourceProvider([
        _FakeByteStreamSource(
          opener: () => c1.stream,
          contentLength: 100,
          fileExtension: 'm4a',
        ),
        _FakeByteStreamSource(
          opener: () => c2.stream,
          contentLength: 100,
          fileExtension: 'webm',
        ),
        _FakeByteStreamSource(
          opener: () => goodController.stream,
          contentLength: 6,
          fileExtension: 'm4a',
        ),
      ]);
      final summary = ImportSummary(
        addedTracks: [],
        duplicates: const [],
        unsupported: const [],
        corrupt: const [],
      );
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'Song.m4a',
              kind: MediaSourceKind.audio,
              byteSourceProvider: provider,
            ),
          ),
        ]),
        importService: _FakeImportService(summary, _inMemoryRepository()),
        conversionService: AudioConversionService(),
        firstByteTimeout: const Duration(milliseconds: 200),
      );

      final events = <LinkImportProgress>[];
      final done = Completer<void>();
      service.run(url: url).listen(events.add, onDone: done.complete);

      // Wait for both of the first manifest's candidates to time out and
      // the third (post-"refresh") candidate to be requested, rather than a
      // fixed sleep racing against two cascading timeouts under load.
      for (var i = 0; i < 200 && provider.callCount < 3; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      goodController.add(List.filled(6, 1));
      await goodController.close();
      await done.future;

      expect(events.last.stage, DownloadStage.completed);
      expect(events.last.summary, same(summary));
      expect(provider.callCount, 3);

      await c1.close();
      await c2.close();
    });

    test('cancelling during the first candidate stops immediately and never tries a fallback', () async {
      final url = Uri.parse('https://media.example.com/fallback-cancel');
      final c1 = StreamController<List<int>>();
      final c2 = StreamController<List<int>>();
      final provider = _FakeByteStreamSourceProvider([
        _FakeByteStreamSource(
          opener: () => c1.stream,
          contentLength: 100,
          fileExtension: 'm4a',
        ),
        _FakeByteStreamSource(
          opener: () => c2.stream,
          contentLength: 100,
          fileExtension: 'webm',
        ),
      ]);
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'Song.m4a',
              kind: MediaSourceKind.audio,
              byteSourceProvider: provider,
            ),
          ),
        ]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
        // Long enough that cancel(), not the timeout, is what stops this.
        firstByteTimeout: const Duration(seconds: 5),
      );

      final events = <DownloadStage>[];
      final done = Completer<void>();
      service
          .run(url: url)
          .listen((p) => events.add(p.stage), onDone: done.complete);

      for (var i = 0; i < 100 && provider.callCount < 1; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      c1.add(List.filled(5, 1));
      await Future<void>.delayed(Duration.zero);
      service.cancel();
      await done.future;

      expect(events.last, DownloadStage.cancelled);
      expect(
        provider.callCount,
        1,
        reason: 'a second candidate must never be requested after cancel()',
      );
      expect(_scratchDirLeftovers(tempDir), isEmpty);
      expect(provider.disposed, isTrue);

      await c1.close();
      // c2's source was never opened/listened to (candidate 2 must never be
      // requested after cancel()), and closing an un-listened
      // single-subscription StreamController never completes its `close()`
      // future, so this must not be awaited.
      unawaited(c2.close());
    });

    test("a failed candidate's partial temp file is deleted immediately, before the next candidate is tried", () async {
      final url = Uri.parse('https://media.example.com/fallback-cleanup');
      final stalledController = StreamController<List<int>>();
      final pendingController = StreamController<List<int>>();
      final provider = _FakeByteStreamSourceProvider([
        _FakeByteStreamSource(
          opener: () => stalledController.stream,
          contentLength: 100,
          fileExtension: 'webm',
        ),
        _FakeByteStreamSource(
          opener: () => pendingController.stream,
          contentLength: 100,
          fileExtension: 'm4a',
        ),
      ]);
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'Song.m4a',
              kind: MediaSourceKind.audio,
              byteSourceProvider: provider,
            ),
          ),
        ]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
        firstByteTimeout: const Duration(milliseconds: 100),
      );

      final done = Completer<void>();
      service.run(url: url).listen((_) {}, onDone: done.complete);

      // Wait until the first candidate has timed out and the second has
      // definitely been requested (proving the retry happened), while the
      // second is deliberately left hanging so we can inspect state before
      // it resolves either way.
      for (var i = 0; i < 100 && provider.callCount < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(
        provider.callCount,
        2,
        reason: 'second candidate was never requested',
      );
      // The delete is awaited before the next candidate is even requested,
      // so callCount reaching 2 should already imply it happened — but give
      // the OS a few extra scheduling turns to release the file handle
      // before asserting, since that release isn't necessarily synchronous
      // with the Dart-level close.
      for (var i = 0; i < 50 && _scratchDirLeftovers(tempDir).isNotEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(
        _scratchDirLeftovers(tempDir),
        isEmpty,
        reason:
            "the first candidate's empty scratch file should already be gone",
      );

      service.cancel();
      await done.future;
      await stalledController.close();
      await pendingController.close();
    });

    test('a successful fallback imports exactly one library entry, not one per attempt', () async {
      final url = Uri.parse('https://media.example.com/fallback-single-import');
      final failingController = StreamController<List<int>>();
      final goodController = StreamController<List<int>>();
      final provider = _FakeByteStreamSourceProvider([
        _FakeByteStreamSource(
          opener: () => failingController.stream,
          contentLength: 100,
          fileExtension: 'webm',
        ),
        _FakeByteStreamSource(
          opener: () => goodController.stream,
          contentLength: 6,
          fileExtension: 'm4a',
        ),
      ]);
      final summary = ImportSummary(
        addedTracks: [],
        duplicates: const [],
        unsupported: const [],
        corrupt: const [],
      );
      final importService = _FakeImportService(summary, _inMemoryRepository());
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'Song.m4a',
              kind: MediaSourceKind.audio,
              byteSourceProvider: provider,
            ),
          ),
        ]),
        importService: importService,
        conversionService: AudioConversionService(),
        firstByteTimeout: const Duration(milliseconds: 200),
      );

      final done = Completer<void>();
      service.run(url: url).listen((_) {}, onDone: done.complete);

      for (var i = 0; i < 200 && provider.callCount < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      goodController.add(List.filled(6, 1));
      await goodController.close();
      await done.future;

      expect(importService.receivedFiles.length, 1);

      await failingController.close();
    });
  });

  group('thumbnail fetching', () {
    test(
      'a successful thumbnail is threaded into the imported PickedFile',
      () async {
        final url = Uri.parse('https://example.com/song.mp3');
        final thumbnailUrl = Uri.parse(
          'https://img.example.com/vi/x/hqdefault.jpg',
        );
        final importService = _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        );
        final fetcher = _FakeThumbnailFetcher(shouldSucceed: true);
        final service = LinkImportService(
          libraryRepository: _inMemoryRepository(),
          resolvers: MediaUrlResolverRegistry([
            _FakeResolver(
              ResolvedMedia(
                origin: MediaSourceOrigin.direct,
                downloadUrl: url,
                suggestedFileName: 'Song.mp3',
                kind: MediaSourceKind.audio,
                thumbnailUrl: thumbnailUrl,
              ),
            ),
          ]),
          importService: importService,
          downloadService: _FixtureDownloadService('tone.m4a'),
          conversionService: AudioConversionService(),
          thumbnailFetcher: fetcher,
        );

        final events = await service.run(url: url).toList();

        expect(events.last.stage, DownloadStage.completed);
        expect(fetcher.lastRequestedUrl, thumbnailUrl);
        expect(
          importService.receivedFiles.single.externalArtworkPath,
          isNotNull,
        );
      },
    );

    test('a failed thumbnail fetch does not fail the download, and no artwork is passed', () async {
      final url = Uri.parse('https://example.com/song.mp3');
      final importService = _FakeImportService(
        const ImportSummary(
          addedTracks: [],
          duplicates: [],
          unsupported: [],
          corrupt: [],
        ),
        _inMemoryRepository(),
      );
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'Song.mp3',
              kind: MediaSourceKind.audio,
              thumbnailUrl: Uri.parse(
                'https://img.example.com/vi/x/hqdefault.jpg',
              ),
            ),
          ),
        ]),
        importService: importService,
        downloadService: _ImmediateDownloadService(),
        conversionService: AudioConversionService(),
        thumbnailFetcher: _FakeThumbnailFetcher(shouldSucceed: false),
      );

      final events = await service.run(url: url).toList();

      expect(events.last.stage, DownloadStage.completed);
      expect(importService.receivedFiles.single.externalArtworkPath, isNull);
    });

    test('no thumbnail is fetched when the resolver has none', () async {
      final url = Uri.parse('https://example.com/song.mp3');
      final fetcher = _FakeThumbnailFetcher(shouldSucceed: true);
      final service = LinkImportService(
        libraryRepository: _inMemoryRepository(),
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'song.mp3',
              kind: MediaSourceKind.audio,
            ),
          ),
        ]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
        downloadService: _ImmediateDownloadService(),
        conversionService: AudioConversionService(),
        thumbnailFetcher: fetcher,
      );

      await service.run(url: url).drain<void>();

      expect(fetcher.lastRequestedUrl, isNull);
    });

    test('cancelling mid-thumbnail-fetch ends the run cancelled, not completed, with no history row and the temp file cleaned up', () async {
      final url = Uri.parse('https://example.com/song.mp3');
      final library = _inMemoryRepository();
      final gate = Completer<void>();
      final fetcher = _GatedThumbnailFetcher(gate.future);
      final service = LinkImportService(
        libraryRepository: library,
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'Song.mp3',
              kind: MediaSourceKind.audio,
              thumbnailUrl: Uri.parse(
                'https://img.example.com/vi/x/hqdefault.jpg',
              ),
            ),
          ),
        ]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
        downloadService: _FixtureDownloadService('tone.m4a'),
        conversionService: AudioConversionService(),
        thumbnailFetcher: fetcher,
      );

      final events = <DownloadStage>[];
      final done = Completer<void>();
      service
          .run(url: url)
          .listen((p) => events.add(p.stage), onDone: done.complete);

      // Wait for the thumbnail fetch to actually start (its file is
      // written synchronously before it blocks on the gate) before
      // cancelling — proves this stops real in-flight work, not a run
      // that never got there.
      for (var i = 0; i < 400 && fetcher.lastDestinationPath == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(fetcher.lastDestinationPath, isNotNull);

      service.cancel();
      gate.complete();
      await done.future;

      expect(events.last, DownloadStage.cancelled);
      expect(File(fetcher.lastDestinationPath!).existsSync(), isFalse);
      expect(await library.watchDownloadHistory().first, isEmpty);
    });
  });

  group('download history', () {
    test(
      'a successful run records a success row with the output format',
      () async {
        final url = Uri.parse('https://example.com/song.mp3');
        final library = _inMemoryRepository();
        final service = LinkImportService(
          libraryRepository: library,
          resolvers: MediaUrlResolverRegistry([
            _FakeResolver(
              ResolvedMedia(
                origin: MediaSourceOrigin.direct,
                downloadUrl: url,
                suggestedFileName: 'My Video.mp3',
                kind: MediaSourceKind.audio,
              ),
            ),
          ]),
          importService: _FakeImportService(
            ImportSummary(
              addedTracks: [
                Track(
                  id: 't1',
                  filePath: '/tmp/t1.mp3',
                  title: 'My Video',
                  artist: 'Artist',
                  album: 'Album',
                  albumArtist: 'Artist',
                  duration: const Duration(minutes: 3),
                  format: 'mp3',
                  fileSizeBytes: 1000,
                  dateAdded: DateTime.now(),
                ),
              ],
              duplicates: const [],
              unsupported: const [],
              corrupt: const [],
            ),
            _inMemoryRepository(),
          ),
          downloadService: _ImmediateDownloadService(),
          conversionService: AudioConversionService(),
        );

        await service.run(url: url).drain<void>();

        final history = await _waitForHistory(library, (h) => h.isNotEmpty);
        expect(history, hasLength(1));
        expect(history.single.status, 'success');
        expect(history.single.sourceType, 'direct');
        expect(history.single.title, 'My Video');
        expect(history.single.outputFormat, 'mp3');
      },
    );

    test('a duplicate import outcome still counts as history success (existing app semantics)', () async {
      final url = Uri.parse('https://example.com/song.mp3');
      final library = _inMemoryRepository();
      final service = LinkImportService(
        libraryRepository: library,
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'song.mp3',
              kind: MediaSourceKind.audio,
            ),
          ),
        ]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [
              ImportFileResult(
                fileName: 'song.mp3',
                outcome: ImportFileOutcome.duplicate,
                detail: 'Already in your library as "song".',
              ),
            ],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
        downloadService: _ImmediateDownloadService(),
        conversionService: AudioConversionService(),
      );

      await service.run(url: url).drain<void>();

      final history = await _waitForHistory(library, (h) => h.isNotEmpty);
      expect(history.single.status, 'success');
    });

    test(
      'a corrupt import outcome records a failed history row, not success',
      () async {
        final url = Uri.parse('https://example.com/song.mp3');
        final library = _inMemoryRepository();
        final service = LinkImportService(
          libraryRepository: library,
          resolvers: MediaUrlResolverRegistry([
            _FakeResolver(
              ResolvedMedia(
                origin: MediaSourceOrigin.direct,
                downloadUrl: url,
                suggestedFileName: 'song.mp3',
                kind: MediaSourceKind.audio,
              ),
            ),
          ]),
          importService: _FakeImportService(
            const ImportSummary(
              addedTracks: [],
              duplicates: [],
              unsupported: [],
              corrupt: [
                ImportFileResult(
                  fileName: 'song.mp3',
                  outcome: ImportFileOutcome.corrupt,
                  detail: 'Could not read this file.',
                ),
              ],
            ),
            _inMemoryRepository(),
          ),
          downloadService: _ImmediateDownloadService(),
          conversionService: AudioConversionService(),
        );

        final events = await service.run(url: url).toList();
        // The UI still shows this under "completed" (the pipeline itself
        // didn't error) — only the recorded history status changes.
        expect(events.last.stage, DownloadStage.completed);

        final history = await _waitForHistory(library, (h) => h.isNotEmpty);
        expect(history.single.status, 'failed');
        expect(history.single.message, 'Could not read this file.');
      },
    );

    test(
      'an unsupported import outcome records a failed history row, not success',
      () async {
        final url = Uri.parse('https://example.com/song.mp3');
        final library = _inMemoryRepository();
        final service = LinkImportService(
          libraryRepository: library,
          resolvers: MediaUrlResolverRegistry([
            _FakeResolver(
              ResolvedMedia(
                origin: MediaSourceOrigin.direct,
                downloadUrl: url,
                suggestedFileName: 'song.xyz',
                kind: MediaSourceKind.audio,
              ),
            ),
          ]),
          importService: _FakeImportService(
            const ImportSummary(
              addedTracks: [],
              duplicates: [],
              unsupported: [
                ImportFileResult(
                  fileName: 'song.xyz',
                  outcome: ImportFileOutcome.unsupported,
                  detail: 'Format not supported.',
                ),
              ],
              corrupt: [],
            ),
            _inMemoryRepository(),
          ),
          downloadService: _ImmediateDownloadService(),
          conversionService: AudioConversionService(),
        );

        await service.run(url: url).drain<void>();

        final history = await _waitForHistory(library, (h) => h.isNotEmpty);
        expect(history.single.status, 'failed');
        expect(history.single.message, 'Format not supported.');
      },
    );

    test('an unsupported link records a failed row', () async {
      final library = _inMemoryRepository();
      final service = LinkImportService(
        libraryRepository: library,
        resolvers: MediaUrlResolverRegistry([_FakeResolver(null)]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
      );

      final events = await service
          .run(url: Uri.parse('https://unsupported.example/x'))
          .toList();
      expect(events.last.stage, DownloadStage.failed);

      final history = await _waitForHistory(library, (h) => h.isNotEmpty);
      expect(history, hasLength(1));
      expect(history.single.status, 'failed');
      expect(history.single.outputFormat, isNull);
    });

    test('a cancelled run is not recorded', () async {
      final url = Uri.parse('https://example.com/song.mp3');
      final library = _inMemoryRepository();
      final gate = Completer<void>();
      final service = LinkImportService(
        libraryRepository: library,
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: 'song.mp3',
              kind: MediaSourceKind.audio,
            ),
          ),
        ]),
        importService: _FakeImportService(
          const ImportSummary(
            addedTracks: [],
            duplicates: [],
            unsupported: [],
            corrupt: [],
          ),
          _inMemoryRepository(),
        ),
        downloadService: _GatedDownloadService(gate.future),
      );

      final events = <DownloadStage>[];
      final done = Completer<void>();
      service
          .run(url: url)
          .listen((p) => events.add(p.stage), onDone: done.complete);

      for (
        var i = 0;
        i < 100 && (events.isEmpty || events.last != DownloadStage.downloading);
        i++
      ) {
        await Future<void>.delayed(Duration.zero);
      }
      service.cancel();
      gate.complete();
      await done.future;

      expect(events.last, DownloadStage.cancelled);
      expect(await library.watchDownloadHistory().first, isEmpty);
    });
  });

  group('direct import: validation and cancellation', () {
    late FakeFfmpeg native;
    late _CountingDownloadService download;
    late _FakeImportService importer;
    final hostUrl = Uri.parse('https://cdn.example.com/stream/1');

    setUp(() {
      native = FakeFfmpeg()..install();
      download = _CountingDownloadService();
      importer = _FakeImportService(
        const ImportSummary(
          addedTracks: [],
          duplicates: [],
          unsupported: [],
          corrupt: [],
        ),
        _inMemoryRepository(),
      );
    });

    LinkImportService create(HttpClientAdapter adapter) => LinkImportService(
      libraryRepository: _inMemoryRepository(),
      resolvers: MediaUrlResolverRegistry([
        DirectMediaUrlResolver(
          dio: Dio()..httpClientAdapter = adapter,
          hostResolver: (_) async => [InternetAddress('93.184.216.34')],
        ),
      ]),
      importService: importer,
      downloadService: download,
      conversionService: AudioConversionService(),
    );

    void expectNothingFollowed() {
      expect(download.calls, 0, reason: 'no download after cancel');
      expect(native.commands, isEmpty, reason: 'no conversion after cancel');
      expect(importer.receivedFiles, isEmpty, reason: 'no import after cancel');
      expect(_scratchDirLeftovers(tempDir), isEmpty);
    }

    Future<List<LinkImportProgress>> cancelWhen(
      LinkImportService service,
      bool Function() reached,
    ) async {
      final events = <LinkImportProgress>[];
      final done = Completer<void>();
      service.run(url: hostUrl).listen(events.add, onDone: done.complete);
      for (var i = 0; i < 200 && !reached(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      service.cancel();
      await done.future.timeout(const Duration(seconds: 5));
      return events;
    }

    test(
      'cancel while HEAD is in flight ends as cancelled, aborts the request',
      () async {
        final adapter = _HangingAdapter(hangOn: {'HEAD'});
        final events = await cancelWhen(
          create(adapter),
          () => adapter.started > 0,
        );
        expect(events.last.stage, DownloadStage.cancelled);
        expect(adapter.cancelled, 1, reason: 'stalled request was aborted');
        expectNothingFollowed();
      },
    );

    test('cancel while the probe is in flight ends as cancelled', () async {
      final adapter = _HangingAdapter(hangOn: {'GET'});
      final events = await cancelWhen(
        create(adapter),
        () => adapter.started > 1,
      );
      expect(events.last.stage, DownloadStage.cancelled);
      expect(adapter.cancelled, 1);
      expectNothingFollowed();
    });

    test('a file with no decodable audio is rejected before import', () async {
      native.returnCodes.add(1); // decode validation fails
      final url = Uri.parse('https://cdn.example.com/song.mp3');
      final events = await create(_HangingAdapter(hangOn: {}))
          .run(url: url)
          .toList();
      expect(events.last.stage, DownloadStage.failed);
      expect(download.calls, 1);
      expect(native.commands, hasLength(1), reason: 'only the validation ran');
      expect(importer.receivedFiles, isEmpty);
      expect(_scratchDirLeftovers(tempDir), isEmpty);
    });

    test(
      'a decodable raw AAC is validated, converted to MP3, then imported',
      () async {
        final url = Uri.parse('https://cdn.example.com/song.aac');
        final events = await create(_HangingAdapter(hangOn: {}))
            .run(url: url)
            .toList();
        expect(events.last.stage, DownloadStage.completed);
        expect(native.commands, hasLength(3));
        expect(native.commands.first, containsAllInOrder(['-map', '0:a:0']));
        expect(native.commands[1], contains('libmp3lame'));
        expect(
          native.commands.expand((c) => c),
          isNot(contains('aac_adtstoasc')),
        );
        expect(importer.receivedFiles.single.name, 'song.mp3');
        expect(_scratchDirLeftovers(tempDir), isEmpty);
      },
    );

    test(
      'cancel during decode validation stops before conversion/import',
      () async {
        native.returnCodes.add(255);
        final url = Uri.parse('https://cdn.example.com/song.mp3');
        final events = await create(_HangingAdapter(hangOn: {}))
            .run(url: url)
            .toList();
        expect(events.last.stage, DownloadStage.cancelled);
        expect(native.commands, hasLength(1));
        expect(importer.receivedFiles, isEmpty);
        expect(_scratchDirLeftovers(tempDir), isEmpty);
      },
    );
  });
  group('MP3 contract, metadata and artwork through the import flow', () {
    late FakeFfmpeg native;
    late _CapturingImportService importer;
    late LibraryRepository library;

    setUp(() {
      native = FakeFfmpeg()..install();
      library = _inMemoryRepository();
      importer = _CapturingImportService(_inMemoryRepository());
    });

    LinkImportService create(
      String fixture, {
      required String name,
      String? title,
      String? artist,
      String? album,
      ThumbnailFetcher? thumbnails,
    }) {
      final url = Uri.parse('https://example.com/x/$name');
      return LinkImportService(
        libraryRepository: library,
        resolvers: MediaUrlResolverRegistry([
          _FakeResolver(
            ResolvedMedia(
              origin: MediaSourceOrigin.direct,
              downloadUrl: url,
              suggestedFileName: name,
              kind: MediaSourceKind.audio,
              title: title,
              artist: artist,
              album: album,
              thumbnailUrl: thumbnails == null
                  ? null
                  : Uri.parse('https://img.example.com/t.jpg'),
            ),
          ),
        ]),
        importService: importer,
        downloadService: _FixtureDownloadService(fixture),
        conversionService: AudioConversionService(),
        thumbnailFetcher: thumbnails,
      );
    }

    Future<LinkImportProgress> run(LinkImportService s) async =>
        (await s.run(url: Uri.parse('https://example.com/x/f')).toList()).last;

    test('an MP3 source is passed through and imported as .mp3', () async {
      final last = await run(create('tone.mp3', name: 'Song.mp3'));
      expect(last.stage, DownloadStage.completed);
      expect(native.commands, hasLength(1), reason: 'validation only');
      expect(importer.names, ['Song.mp3']);
      expect(_scratchDirLeftovers(tempDir), isEmpty);
    });

    test('non-MP3 sources import under exactly one .mp3 extension', () async {
      for (final c in {
        'tone.m4a': 'song.m4a',
        'video_with_audio.mp4': 'song.mp4',
        'tone.webm': 'song.webm',
        'tone.aac': 'song.aac',
        'tone.ogg': 'song.ogg',
        'tone.flac': 'song.flac',
        'tone.wav': 'song.wav',
      }.entries) {
        importer.names.clear();
        final last = await run(create(c.key, name: c.value));
        expect(last.stage, DownloadStage.completed, reason: c.key);
        expect(importer.names, ['song.mp3'], reason: c.key);
      }
    });

    test('Unicode, dotted and sanitized names keep one clean .mp3', () async {
      for (final c in {
        'أغنية 歌曲 é.m4a': 'أغنية 歌曲 é.mp3',
        'Vol. 2 - Live.m4a': 'Vol. 2 - Live.mp3',
        'track.m4a.m4a': 'track.m4a.mp3',
      }.entries) {
        importer.names.clear();
        await run(create('tone.m4a', name: c.key));
        expect(importer.names, [c.value], reason: c.key);
      }
    });

    test('history records mp3 as the final format', () async {
      await run(create('tone.m4a', name: 'song.m4a'));
      final history = await _waitForHistory(library, (h) => h.isNotEmpty);
      expect(history.single.status, 'success');
      expect(history.single.outputFormat, 'mp3');
    });

    test(
      'source cover art is preserved through the artwork pipeline',
      () async {
        await run(create('tone_tagged_art.m4a', name: 'song.m4a'));
        expect(importer.artworkExistedAtImport.single, isTrue);
        expect(_scratchDirLeftovers(tempDir), isEmpty);
      },
    );

    test(
      'embedded source artwork wins: no remote thumbnail is fetched',
      () async {
        final fetcher = _FakeThumbnailFetcher(shouldSucceed: true);
        await run(
          create('tone_tagged_art.m4a', name: 'song.m4a', thumbnails: fetcher),
        );
        expect(fetcher.lastRequestedUrl, isNull);
        expect(importer.artworkExistedAtImport.single, isTrue);
      },
    );

    test('without embedded art the resolver thumbnail is still used', () async {
      final fetcher = _FakeThumbnailFetcher(shouldSucceed: true);
      await run(create('tone.m4a', name: 'song.m4a', thumbnails: fetcher));
      expect(fetcher.lastRequestedUrl, isNotNull);
      expect(importer.artworkExistedAtImport.single, isTrue);
    });

    test(
      'with no artwork anywhere nothing is passed (placeholder behavior)',
      () async {
        await run(create('tone.m4a', name: 'song.m4a'));
        expect(importer.artworkPaths.single, isNull);
      },
    );

    test('resolver tags fill only what the file lacks (transcode)', () async {
      // tone.m4a has no title/artist/album.
      await run(
        create(
          'tone.m4a',
          name: 'song.m4a',
          title: 'Résumé 歌',
          artist: 'أحمد',
          album: 'Álbum',
        ),
      );
      expect(
        native.commands[1],
        containsAll(['title=Résumé 歌', 'artist=أحمد', 'album=Álbum']),
      );
    });

    test('resolver tags never override embedded tags', () async {
      // tone_tagged_art.m4a already has all three tags.
      await run(
        create(
          'tone_tagged_art.m4a',
          name: 'song.m4a',
          title: 'Resolver Title',
          artist: 'Resolver Artist',
          album: 'Resolver Album',
        ),
      );
      final all = native.commands.expand((c) => c);
      expect(all.any((a) => a.startsWith('title=')), isFalse);
      expect(all.any((a) => a.startsWith('artist=')), isFalse);
      expect(all.any((a) => a.startsWith('album=')), isFalse);
    });

    test(
      'a partially tagged MP3 gets only the missing tags (stream-copy remux)',
      () async {
        // tone_art.mp3 has a title but no artist/album.
        await run(
          create(
            'tone_art.mp3',
            name: 'song.mp3',
            title: 'Resolver Title',
            artist: 'Resolver Artist',
          ),
        );
        // (the first command extracts the cover; find the remux itself)
        final remux = native.commands.firstWhere(
          (c) =>
              c.contains('-metadata') || c.contains('artist=Resolver Artist'),
        );
        expect(remux, containsAllInOrder(['-c:a', 'copy']));
        expect(remux, contains('artist=Resolver Artist'));
        expect(remux.any((a) => a.startsWith('title=')), isFalse);
      },
    );

    test(
      'no resolver metadata means no tag arguments and no invented values',
      () async {
        await run(create('tone.m4a', name: 'song.m4a'));
        expect(native.commands[1], isNot(contains('-metadata')));
      },
    );

    test('cancelling during MP3 conversion removes the partial file and never imports', () async {
      native.returnCodes.addAll([0, 255]);
      final last = await run(create('tone.m4a', name: 'song.m4a'));
      expect(last.stage, DownloadStage.cancelled);
      expect(importer.names, isEmpty);
      expect(File(native.commands[1].last).existsSync(), isFalse);
      expect(_scratchDirLeftovers(tempDir), isEmpty);
      expect(await library.watchDownloadHistory().first, isEmpty);
    });

    test(
      'a conversion failure prevents import and records a failure',
      () async {
        native.returnCodes.addAll([0, 1]);
        final last = await run(create('tone.m4a', name: 'song.m4a'));
        expect(last.stage, DownloadStage.failed);
        expect(importer.names, isEmpty);
        expect(_scratchDirLeftovers(tempDir), isEmpty);
        final history = await _waitForHistory(library, (h) => h.isNotEmpty);
        expect(history.single.status, 'failed');
      },
    );

    test('a corrupt MP3 output never reaches import', () async {
      native.returnCodes.addAll([0, 0, 1]);
      final last = await run(create('tone.m4a', name: 'song.m4a'));
      expect(last.stage, DownloadStage.failed);
      expect(importer.names, isEmpty);
      expect(_scratchDirLeftovers(tempDir), isEmpty);
    });

    test('artwork in a container the Dart reader cannot read still outranks the resolver thumbnail', () async {
      final fetcher = _FakeThumbnailFetcher(shouldSucceed: true);
      final last = await run(
        create('tone_art.mka', name: 'song.mka', thumbnails: fetcher),
      );
      expect(last.stage, DownloadStage.completed);
      expect(fetcher.lastRequestedUrl, isNull, reason: 'thumbnail not used');
      expect(importer.artworkExistedAtImport.single, isTrue);
    });

    test(
      'unknown embedded artwork never falls back to a remote thumbnail',
      () async {
        native.probeHandler = (path) =>
            path.endsWith('.mka') ? Future.value(null) : native.realProbe(path);
        final fetcher = _FakeThumbnailFetcher(shouldSucceed: true);
        final last = await run(
          create('tone_art.mka', name: 'song.mka', thumbnails: fetcher),
        );
        expect(last.stage, DownloadStage.completed);
        expect(fetcher.lastRequestedUrl, isNull);
        expect(importer.artworkPaths.single, isNull);
      },
    );

    test('oversized embedded artwork: stopped, UNKNOWN, and no remote thumbnail is substituted', () async {
      var written = 0;
      native.outputWriter = (path, cancelled) async {
        final chunk = List<int>.filled(1024 * 1024, 0xFF);
        final raf = File(path).openSync(mode: FileMode.write);
        try {
          raf.writeFromSync([0xFF, 0xD8, 0xFF, 0xE0]);
          for (var i = 0; i < 300 && !cancelled(); i++) {
            raf.writeFromSync(chunk);
            written += chunk.length;
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
        } finally {
          raf.closeSync();
        }
      };
      final fetcher = _FakeThumbnailFetcher(shouldSucceed: true);
      final last = await run(
        create('tone_art.mka', name: 'song.mka', thumbnails: fetcher),
      );
      expect(last.stage, DownloadStage.completed);
      expect(native.cancelledSessions, hasLength(1));
      expect(written, lessThan(20 * 1024 * 1024));
      expect(fetcher.lastRequestedUrl, isNull, reason: 'no remote fallback');
      expect(importer.artworkPaths.single, isNull);
      expect(_scratchDirLeftovers(tempDir), isEmpty);
    });

    test('truncated/corrupt embedded artwork is UNKNOWN: no thumbnail substituted, no bad art imported', () async {
      final jpeg = File('test/fixtures/audio/cover_valid.jpg')
          .readAsBytesSync();
      native.coverBytes = jpeg.sublist(0, jpeg.length ~/ 2);
      final fetcher = _FakeThumbnailFetcher(shouldSucceed: true);
      final last = await run(
        create('tone_art.mka', name: 'song.mka', thumbnails: fetcher),
      );
      expect(last.stage, DownloadStage.completed);
      expect(fetcher.lastRequestedUrl, isNull);
      expect(importer.artworkPaths.single, isNull);
      expect(_scratchDirLeftovers(tempDir), isEmpty);
    });

    test(
      'a complete embedded image survives until the importer reads it',
      () async {
        native.coverBytes = File('test/fixtures/audio/cover_valid.png')
            .readAsBytesSync();
        await run(create('tone_art.mka', name: 'song.mka'));
        expect(importer.artworkExistedAtImport.single, isTrue);
      },
    );

    test('a previous cancel cannot poison the next import', () async {
      native.returnCodes.add(255);
      final first = await run(create('tone_art.mka', name: 'song.mka'));
      expect(first.stage, DownloadStage.cancelled);
      final second = await run(create('tone_art.mka', name: 'song.mka'));
      expect(second.stage, DownloadStage.completed);
      expect(importer.artworkExistedAtImport.single, isTrue);
    });

    test('user cancel during artwork extraction never reaches conversion or import', () async {
      native.returnCodes.add(255);
      final last = await run(create('tone_art.mka', name: 'song.mka'));
      expect(last.stage, DownloadStage.cancelled);
      expect(importer.names, isEmpty);
      expect(native.commands, hasLength(1), reason: 'only the extraction ran');
      expect(_scratchDirLeftovers(tempDir), isEmpty);
    });

    test('WebM embedded tags are preserved: conflicting resolver tags are not written', () async {
      final last = await run(
        create(
          'tone_tagged.webm',
          name: 'song.webm',
          title: 'Resolver Title',
          artist: 'Resolver Artist',
          album: 'Resolver Album',
        ),
      );
      expect(last.stage, DownloadStage.completed);
      expect(native.commands.expand((c) => c), isNot(contains('-metadata')));
    });

    test('an uninspectable source is never given resolver tags', () async {
      native.probeHandler = (path) =>
          path.endsWith('.webm') ? Future.value(null) : native.realProbe(path);
      await run(
        create(
          'tone_tagged.webm',
          name: 'song.webm',
          title: 'Resolver Title',
          artist: 'Resolver Artist',
        ),
      );
      expect(native.commands.expand((c) => c), isNot(contains('-metadata')));
    });

    test('a no-audio video is rejected before conversion', () async {
      native.returnCodes.add(1);
      final last = await run(create('video_no_audio.mp4', name: 'clip.mp4'));
      expect(last.stage, DownloadStage.failed);
      expect(native.commands, hasLength(1));
      expect(importer.names, isEmpty);
    });
  });
  group('Google Drive through the shared pipeline', () {
    late FakeFfmpeg native;
    late _CapturingImportService importer;
    late LibraryRepository library;
    final driveUrl = Uri.parse(
      'https://drive.google.com/file/d/$driveTestId/view',
    );
    const apiUrl =
        'https://www.googleapis.com/drive/v3/files/$driveTestId?alt=media';

    setUp(() {
      native = FakeFfmpeg()..install();
      library = _inMemoryRepository();
      importer = _CapturingImportService(_inMemoryRepository());
    });

    List<int> fixture(String n) =>
        File('test/fixtures/audio/$n').readAsBytesSync();

    LinkImportService create(
      FakeDriveClient client,
      HttpClientAdapter adapter, {
      DirectMediaLimits limits = const DirectMediaLimits(),
    }) {
      Future<List<InternetAddress>> publicHost(String _) async => [
        InternetAddress('142.250.80.1'),
      ];
      return LinkImportService(
        libraryRepository: library,
        resolvers: MediaUrlResolverRegistry([
          GoogleDriveUrlResolver(client: client, limits: limits),
        ]),
        importService: importer,
        downloadService: MediaDownloadService(
          dio: Dio()..httpClientAdapter = adapter,
          hostResolver: publicHost,
          limits: limits,
        ),
        conversionService: AudioConversionService(),
      );
    }

    Future<LinkImportProgress> run(LinkImportService s) async =>
        (await s.run(url: driveUrl).toList()).last;

    void expectNothingImported(_SeqAdapter a) {
      expect(a.providerRequests, 0, reason: 'other provider never contacted');
      expect(importer.names, isEmpty);
      expect(_scratchDirLeftovers(tempDir), isEmpty);
    }

    test('an MP3 downloads over the API (headers dropped on the CDN redirect) and stays MP3', () async {
      final a = _SeqAdapter({
        'GET $apiUrl': [
          _SeqRes(302, {
            'location': 'https://lh3.googleusercontent.com/dl',
          }, const []),
        ],
        'GET https://lh3.googleusercontent.com/dl': [
          _SeqRes(200, {'content-type': 'audio/mpeg'}, fixture('tone.mp3')),
        ],
      });
      final last = await run(
        create(FakeDriveClient(metadata: driveFile(size: 1412)), a),
      );
      expect(last.stage, DownloadStage.completed);
      expect(a.requests.first.headers['Authorization'], 'Bearer test-token');
      expect(a.requests.last.uri.host, 'lh3.googleusercontent.com');
      expect(a.requests.last.headers['Authorization'], isNull);
      expect(importer.names, ['Song.mp3']);
      // Validated and (to add the Drive title tag) stream-copied, never
      // re-encoded.
      expect(native.commands.expand((c) => c), isNot(contains('libmp3lame')));
      final history = await _waitForHistory(library, (h) => h.isNotEmpty);
      expect(history.single.status, 'success');
      expect(history.single.outputFormat, 'mp3');
    });

    test('an MP4 from Drive becomes an MP3', () async {
      final a = _SeqAdapter({
        'GET $apiUrl': [
          _SeqRes(200, {
            'content-type': 'video/mp4',
          }, fixture('video_with_audio.mp4')),
        ],
      });
      final last = await run(
        create(
          FakeDriveClient(
            metadata: driveFile(name: 'clip.mp4', mimeType: 'video/mp4'),
          ),
          a,
        ),
      );
      expect(last.stage, DownloadStage.completed);
      expect(importer.names, ['clip.mp3']);
      expect(native.commands.expand((c) => c), contains('libmp3lame'));
    });

    for (final target in [
      'https://www.instagram.com/reel/abc/',
      'https://www.facebook.com/reel/123',
      'https://example.com/a.mp3',
      'http://192.168.1.5/a.mp3',
    ]) {
      test(
        'a download redirect to $target is blocked before contact',
        () async {
          final a = _SeqAdapter({
            'GET $apiUrl': [
              _SeqRes(302, {'location': target}, const []),
            ],
            'GET $target': [
              _SeqRes(200, {'content-type': 'audio/mpeg'}, fixture('tone.mp3')),
            ],
          });
          final last = await run(
            create(FakeDriveClient(metadata: driveFile()), a),
          );
          expect(last.stage, DownloadStage.failed);
          expect(a.count('GET $target'), 0, reason: 'target never contacted');
          expectNothingImported(a);
          expect(native.commands, isEmpty);
          final history = await _waitForHistory(library, (h) => h.isNotEmpty);
          expect(history.single.status, 'failed');
        },
      );
    }

    test(
      'the streamed size limit still applies regardless of metadata size',
      () async {
        final a = _SeqAdapter({
          'GET $apiUrl': [
            // Metadata claims 500 bytes; the stream is larger and undeclared.
            _SeqRes(200, {'content-type': 'audio/mpeg'}, fixture('tone.mp3')),
          ],
        });
        final last = await run(
          create(
            FakeDriveClient(metadata: driveFile(size: 500)),
            a,
            limits: const DirectMediaLimits(maxBytes: 1000),
          ),
        );
        expect(last.stage, DownloadStage.failed);
        expectNothingImported(a);
        expect(native.commands, isEmpty);
      },
    );

    test(
      'a file over the limit per metadata is rejected before any download',
      () async {
        final a = _SeqAdapter({});
        final client = FakeDriveClient(metadata: driveFile(size: 999999));
        final last = await run(
          create(client, a, limits: const DirectMediaLimits(maxBytes: 1000)),
        );
        expect(last.stage, DownloadStage.failed);
        expect(a.requests, isEmpty);
        expect(client.downloadCalls, 0);
      },
    );

    test('a restricted file never reaches the download stage', () async {
      final a = _SeqAdapter({});
      final last = await run(
        create(FakeDriveClient(metadata: driveFile(canDownload: false)), a),
      );
      expect(last.stage, DownloadStage.failed);
      expect(a.requests, isEmpty);
      expectNothingImported(a);
    });

    test(
      'authorization required ends as a clean failure with no requests',
      () async {
        final a = _SeqAdapter({});
        final last = await run(
          create(
            FakeDriveClient(
              authenticated: false,
              metadataError: const DriveApiException(
                DriveApiError.unauthenticated,
              ),
            ),
            a,
          ),
        );
        expect(last.stage, DownloadStage.failed);
        expect(a.requests, isEmpty);
      },
    );

    test('cancel during the metadata request stops everything', () async {
      final client = FakeDriveClient(hangMetadata: true);
      final service = create(client, _SeqAdapter({}));
      final events = <LinkImportProgress>[];
      final done = Completer<void>();
      service.run(url: driveUrl).listen(events.add, onDone: done.complete);
      for (var i = 0; i < 200 && client.metadataCalls == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      service.cancel();
      await done.future.timeout(const Duration(seconds: 5));
      expect(events.last.stage, DownloadStage.cancelled);
      expect(client.downloadCalls, 0);
      expect(importer.names, isEmpty);
      expect(native.commands, isEmpty);
      expect(_scratchDirLeftovers(tempDir), isEmpty);
      expect(await library.watchDownloadHistory().first, isEmpty);
    });

    test(
      'cancel during the Drive download stops it, cleans up, never imports',
      () async {
        final adapter = _HangingAdapter(hangOn: {'GET'});
        final service = create(FakeDriveClient(metadata: driveFile()), adapter);
        final events = <LinkImportProgress>[];
        final done = Completer<void>();
        service.run(url: driveUrl).listen(events.add, onDone: done.complete);
        for (var i = 0; i < 200 && adapter.started == 0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        service.cancel();
        await done.future.timeout(const Duration(seconds: 5));
        expect(events.last.stage, DownloadStage.cancelled);
        expect(adapter.cancelled, 1);
        expect(importer.names, isEmpty);
        expect(native.commands, isEmpty);
        expect(_scratchDirLeftovers(tempDir), isEmpty);
      },
    );
  });
}

/// Writes fixed bytes like the immediate fake and counts invocations.
class _CountingDownloadService extends MediaDownloadService {
  int calls = 0;

  @override
  Future<void> download({
    required Uri url,
    required String destinationPath,
    required CancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
    DestinationPolicy? destinationPolicy,
    Map<String, String>? headers,
  }) async {
    calls++;
    await File(destinationPath).writeAsBytes([1, 2, 3]);
  }
}

/// Answers every request except the methods in [hangOn], which stall until
/// the request is cancelled (like a socket that never responds).
class _HangingAdapter implements HttpClientAdapter {
  final Set<String> hangOn;
  int started = 0;
  int cancelled = 0;
  _HangingAdapter({required this.hangOn});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    started++;
    if (hangOn.contains(options.method)) {
      await cancelFuture;
      cancelled++;
      throw DioException.requestCancelled(
        requestOptions: options,
        reason: 'cancelled',
      );
    }
    return ResponseBody.fromBytes(const [], 200);
  }

  @override
  void close({bool force = false}) {}
}

/// One scripted response; the last response for a key repeats.
class _SeqRes {
  final int status;
  final Map<String, String> headers;
  final List<int> body;
  const _SeqRes(this.status, this.headers, this.body);
}

/// Serves per-request responses in order ("METHOD url" -> list), so the same
/// URL can answer differently at probe time and at download time. Counts
/// requests to provider hosts.
class _SeqAdapter implements HttpClientAdapter {
  final Map<String, List<_SeqRes>> script;
  final requests = <RequestOptions>[];
  final _served = <String, int>{};
  _SeqAdapter(this.script);

  int count(String key) =>
      requests.where((r) => '${r.method} ${r.uri}' == key).length;

  int get providerRequests => requests.where((r) {
    final h = r.uri.host;
    return h.endsWith('instagram.com') ||
        h.endsWith('facebook.com') ||
        h == 'drive.google.com';
  }).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = '${options.method} ${options.uri}';
    final list = script[key];
    if (list == null) return ResponseBody.fromBytes(const [], 404);
    final i = _served[key] ?? 0;
    _served[key] = i + 1;
    final r = list[i < list.length ? i : list.length - 1];
    return ResponseBody(
      Stream.value(Uint8List.fromList(r.body)),
      r.status,
      headers: r.headers.map((k, v) => MapEntry(k, [v])),
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Writes a real fixture file as the "download".
class _FixtureDownloadService extends MediaDownloadService {
  final String fixture;
  _FixtureDownloadService(this.fixture);

  @override
  Future<void> download({
    required Uri url,
    required String destinationPath,
    required CancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
    DestinationPolicy? destinationPolicy,
    Map<String, String>? headers,
  }) async {
    await File(destinationPath)
        .writeAsBytes(File('test/fixtures/audio/$fixture').readAsBytesSync());
  }
}

/// Records what the importer was handed, including whether the artwork file
/// still existed at import time (it is deleted afterwards).
class _CapturingImportService extends ImportService {
  final names = <String>[];
  final artworkPaths = <String?>[];
  final artworkExistedAtImport = <bool>[];
  _CapturingImportService(super.repo);

  @override
  Future<ImportSummary> importAndSummarize(List<PickedFile> files) async {
    for (final f in files) {
      names.add(f.name);
      artworkPaths.add(f.externalArtworkPath);
      artworkExistedAtImport.add(
        f.externalArtworkPath != null &&
            File(f.externalArtworkPath!).existsSync(),
      );
    }
    // A duplicate counts as a successful import for history purposes.
    return ImportSummary(
      addedTracks: const [],
      duplicates: [
        for (final f in files)
          ImportFileResult(
            fileName: f.name,
            outcome: ImportFileOutcome.duplicate,
            detail: 'Already in your library.',
          ),
      ],
      unsupported: const [],
      corrupt: const [],
    );
  }
}
