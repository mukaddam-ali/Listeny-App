import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import 'package:listeny/core/storage/database.dart' hide DownloadHistoryEntry;
import 'package:listeny/features/download/download_screen.dart';
import 'package:listeny/l10n/generated/app_localizations.dart';
import 'package:listeny/library/import_models.dart';
import 'package:listeny/library/import_service.dart';
import 'package:listeny/library/library_repository.dart';
import 'package:listeny/library/link_import_models.dart';
import 'package:listeny/library/link_import_service.dart';
import 'package:listeny/library/media_url_resolver.dart';

/// No real Drift watch behind it, so it can live inside a widget test
/// without the reactive-query machinery a real database connection needs.
class _FakeLibraryRepository extends LibraryRepository {
  _FakeLibraryRepository._(super.db);

  factory _FakeLibraryRepository() =>
      _FakeLibraryRepository._(AppDatabase(NativeDatabase.memory()));

  @override
  ValueStream<List<DownloadHistoryEntry>> watchDownloadHistory({
    int limit = 50,
  }) => BehaviorSubject<List<DownloadHistoryEntry>>.seeded(const []);
}

/// Overrides `run()`/`cancel()` entirely, so this never touches a real
/// resolver, download, or database watch — the constructor args just need
/// to satisfy the real constructor's required parameters. Every `run()`
/// gets its own stream, so tests can drive several downloads independently.
class _FakeLinkImportService extends LinkImportService {
  final controllers = <Uri, StreamController<LinkImportProgress>>{};
  final started = <Uri>[];

  _FakeLinkImportService()
    : super(
        resolvers: const MediaUrlResolverRegistry([]),
        importService: ImportService(
          LibraryRepository(AppDatabase(NativeDatabase.memory())),
        ),
        libraryRepository: LibraryRepository(
          AppDatabase(NativeDatabase.memory()),
        ),
      );

  @override
  Stream<LinkImportProgress> run({
    required Uri url,
    LinkImportHandle? handle,
  }) {
    final controller = StreamController<LinkImportProgress>();
    controllers[url] = controller;
    started.add(url);
    handle?.attach(() {
      controller.add(const LinkImportProgress(stage: DownloadStage.cancelled));
      controller.close();
    });
    return controller.stream;
  }

  @override
  void cancel() {}

  void emit(String url, LinkImportProgress progress) =>
      controllers[Uri.parse(url)]?.add(progress);
  void finish(String url) => controllers[Uri.parse(url)]?.close();
}

Widget _harness(LinkImportService service) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiProvider(
      providers: [
        Provider<LinkImportService>.value(value: service),
        Provider<LibraryRepository>.value(value: _FakeLibraryRepository()),
      ],
      child: const DownloadScreen(),
    ),
  );
}

const _completedSummary = ImportSummary(
  addedTracks: [],
  duplicates: [],
  unsupported: [],
  corrupt: [],
);

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Future<void> paste(WidgetTester tester, String url) async {
    await tester.enterText(find.byType(TextField), url);
    await tester.tap(find.text('Download Audio'));
    await tester.pump();
  }

  testWidgets('starting a download frees the field for the next link', (
    tester,
  ) async {
    final service = _FakeLinkImportService();
    await tester.pumpWidget(_harness(service));

    await paste(tester, 'https://a.example.com/one.mp3');

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(service.started, hasLength(1));
  });

  testWidgets('several links download at the same time', (tester) async {
    final service = _FakeLinkImportService();
    await tester.pumpWidget(_harness(service));

    await paste(tester, 'https://a.example.com/one.mp3');
    await paste(tester, 'https://b.example.com/two.mp3');

    expect(service.started, hasLength(2));
    expect(find.text('a.example.com'), findsOneWidget);
    expect(find.text('b.example.com'), findsOneWidget);
  });

  testWidgets('only three run at once; the rest wait for a free slot', (
    tester,
  ) async {
    final service = _FakeLinkImportService();
    await tester.pumpWidget(_harness(service));

    for (final host in ['a', 'b', 'c', 'd']) {
      await paste(tester, 'https://$host.example.com/x.mp3');
    }

    expect(service.started, hasLength(3));
    expect(find.text('Waiting for a free slot…'), findsOneWidget);

    // Finishing one hands its slot to the waiting link.
    service.emit(
      'https://a.example.com/x.mp3',
      const LinkImportProgress(
        stage: DownloadStage.completed,
        summary: _completedSummary,
      ),
    );
    service.finish('https://a.example.com/x.mp3');
    // Other downloads are still running (their progress indicators animate
    // forever), so pumpAndSettle would never settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.started, hasLength(4));
    expect(find.text('Waiting for a free slot…'), findsNothing);
  });

  testWidgets('the same link is not started twice while it is active', (
    tester,
  ) async {
    final service = _FakeLinkImportService();
    await tester.pumpWidget(_harness(service));

    await paste(tester, 'https://a.example.com/one.mp3');
    await paste(tester, 'https://a.example.com/one.mp3');

    expect(service.started, hasLength(1));
  });

  testWidgets('cancel stops only its own download', (tester) async {
    final service = _FakeLinkImportService();
    await tester.pumpWidget(_harness(service));

    await paste(tester, 'https://a.example.com/one.mp3');
    await paste(tester, 'https://b.example.com/two.mp3');
    service.emit(
      'https://a.example.com/one.mp3',
      const LinkImportProgress(stage: DownloadStage.downloading, fraction: .5),
    );
    await tester.pump();

    // Newest first: the first close button belongs to b.example.com.
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('Cancelled.'), findsOneWidget);
    expect(find.text('Downloading 50%'), findsOneWidget);
  });

  testWidgets('a finished card is removed with the trash button', (
    tester,
  ) async {
    final service = _FakeLinkImportService();
    await tester.pumpWidget(_harness(service));

    await paste(tester, 'https://a.example.com/one.mp3');
    service.emit(
      'https://a.example.com/one.mp3',
      const LinkImportProgress(
        stage: DownloadStage.failed,
        message: 'Something went wrong.',
      ),
    );
    service.finish('https://a.example.com/one.mp3');
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong.'), findsNothing);
  });

  testWidgets('an invalid link shows an error and keeps the text', (
    tester,
  ) async {
    final service = _FakeLinkImportService();
    await tester.pumpWidget(_harness(service));

    await paste(tester, 'not a link');

    expect(service.started, isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'not a link',
    );
  });
}
