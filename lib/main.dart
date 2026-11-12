import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/theme/nocturne_colors.dart';
import 'app/theme/theme_mode_controller.dart';
import 'core/diagnostics/startup_log.dart';
import 'library/direct_media_url_resolver.dart';
import 'library/google_drive_client.dart';
import 'library/google_drive_resolver.dart';
import 'library/import_service.dart';
import 'library/library_repository.dart';
import 'library/local_library_sync_service.dart';
import 'library/link_import_service.dart';
import 'library/public_music_saver.dart';
import 'library/media_url_resolver.dart';
import 'playback/audio_service_playback_service.dart';
import 'playback/listeny_audio_handler.dart';
import 'playback/play_record_gate.dart';
import 'playback/playback_service.dart';
import 'playback/playback_state_persistence.dart';

void main() {
  StartupLog.init();
  StartupLog.installErrorHooks();
  WidgetsFlutterBinding.ensureInitialized();
  StartupLog.mark('WidgetsFlutterBinding ready');
  // Show a frame immediately instead of leaving the engine's blank surface
  // on screen while _bootstrap() runs — opening the database, starting the
  // background audio service, and restoring the last queue are all real
  // work (frequently over a second combined on a loaded device) and none of
  // it can render anything if it blocks runApp() itself.
  StartupLog.mark('runApp called');
  runApp(const _BootstrapApp());
  StartupLog.trackFirstFrame();
}

/// Everything the real app needs before it can be built.
class _AppDependencies {
  final LibraryRepository library;
  final ImportService importService;
  final LinkImportService linkImportService;
  final PlaybackService playbackService;
  final PlaybackStatePersistence statePersistence;
  final ThemeModeController themeModeController;

  const _AppDependencies({
    required this.library,
    required this.importService,
    required this.linkImportService,
    required this.playbackService,
    required this.statePersistence,
    required this.themeModeController,
  });
}

Future<_AppDependencies> _bootstrap() async {
  if (kDebugMode) {
    // Debug-only: helps correlate reports of lost media controls/playback
    // with the exact app build and OS version they happened on.
    AudioService.asyncError.listen(
      (error) => debugPrint('[AudioService] asyncError: $error'),
    );
    unawaited(
      PackageInfo.fromPlatform().then(
        (info) => debugPrint(
          '[Bootstrap] app=${info.version}+${info.buildNumber} '
          'platform=${Platform.operatingSystem} '
          '${Platform.operatingSystemVersion}',
        ),
      ),
    );
  }

  final library = await StartupLog.stage(
    'database open (LibraryRepository.open)',
    LibraryRepository.open,
  );
  StartupLog.mark('service construction (sync) START');
  final importService = ImportService(library);
  final directResolver = DirectMediaUrlResolver();
  // Public "anyone with the link" files via a restricted API key, when one
  // is configured (--dart-define=GOOGLE_DRIVE_API_KEY=...); otherwise Drive
  // links report that authorization is required.
  const driveApiKey = String.fromEnvironment('GOOGLE_DRIVE_API_KEY');
  final GoogleDriveClient driveClient = driveApiKey.isEmpty
      ? const UnauthenticatedGoogleDriveClient()
      : ApiKeyGoogleDriveClient(apiKey: driveApiKey);
  final linkImportService = LinkImportService(
    resolvers: MediaUrlResolverRegistry([
      // Drive links belong to the Drive resolver (official API only).
      GoogleDriveUrlResolver(client: driveClient),
      directResolver,
    ]),
    importService: importService,
    libraryRepository: library,
    publicMusicSaver: PublicMusicSaver(),
  );
  StartupLog.mark('service construction (sync) END');

  final handler = await StartupLog.stage(
    'AudioService.init',
    () => AudioService.init(
      builder: () => ListenyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.listeny.lite.audio',
        androidNotificationChannelName: 'Playback',
        androidNotificationOngoing: true,
      ),
    ),
  );

  final PlaybackService playbackService = AudioServicePlaybackService(handler);
  final statePersistence = PlaybackStatePersistence();

  final themeModeController = ThemeModeController();
  await StartupLog.stage('ThemeModeController.load', themeModeController.load);

  // Every time the current track genuinely CHANGES (a real playback
  // transition), record a real play against the library (drives Recently
  // Played / Most Played) — kept at this level so PlaybackService itself
  // never needs to know the library exists. See PlayRecordGate's doc
  // comment for why this is gated on track id, not just on `currentTrack`
  // emitting at all (a metadata-only refresh, e.g. after an album rename,
  // also emits — and must not count as a new play).
  final playRecordGate = PlayRecordGate();
  playbackService.currentTrack.listen((track) {
    final idToRecord = playRecordGate.onCurrentTrackChanged(track?.id);
    if (idToRecord != null) library.recordPlay(idToRecord);
  });

  // Test 8 (queue persistence): restoring whatever was playing last time is
  // deliberately NOT started here — see _BootstrapAppState, which kicks it
  // off after the real UI's first frame is on screen instead of racing it
  // for CPU during bootstrap (preparing the restored track's real
  // decoder/codec is genuine work, confirmed slow on a loaded device via
  // timing instrumentation).

  return _AppDependencies(
    library: library,
    importService: importService,
    linkImportService: linkImportService,
    playbackService: playbackService,
    statePersistence: statePersistence,
    themeModeController: themeModeController,
  );
}

/// Runs [_bootstrap] after the first frame, showing a themed loading screen
/// until it resolves, then swaps in the real provider tree + [ListenyApp].
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<_AppDependencies> _dependencies = StartupLog.watchBootstrap(
    _bootstrap(),
  );
  bool _restoreScheduled = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppDependencies>(
      future: _dependencies,
      builder: (context, snapshot) {
        final deps = snapshot.data;
        if (deps == null) {
          StartupLog.markOnce(
            'loading-screen-build',
            'Flutter loading screen build (bootstrap pending)',
          );
          return const _LoadingScreen();
        }
        StartupLog.markOnce(
          'real-ui-build',
          'bootstrap dependencies ready; building real UI tree',
        );

        if (!_restoreScheduled) {
          _restoreScheduled = true;
          // Runs after this build's frame actually paints, so the real
          // UI's first frame gets full priority instead of competing with
          // restore()'s real codec/decoder work for CPU.
          StartupLog.mark('playback restore scheduled (post-frame)');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Android 13+ runtime consent (POST_NOTIFICATIONS). Media-session
            // notifications are exempt, so playback doesn't depend on it;
            // requested here, after the first real frame, so it never
            // blocks startup. No-op on iOS and Android <13.
            unawaited(
              StartupLog.logFailure(
                    'notification permission request',
                    Permission.notification.request(),
                  )
                  .catchError((Object _) => PermissionStatus.denied)
                  .then(
                    // Sequenced after the notification prompt closes (two
                    // overlapping permission requests would collide).
                    (_) => runInitialLocalSyncIfNeeded(deps.library),
                  ),
            );
            unawaited(
              StartupLog.logFailure(
                'playback restore',
                deps.statePersistence.restore(
                  deps.playbackService,
                  deps.library,
                ),
              ),
            );
          });
        }

        return MultiProvider(
          providers: [
            Provider<LibraryRepository>.value(value: deps.library),
            Provider<ImportService>.value(value: deps.importService),
            Provider<LinkImportService>.value(value: deps.linkImportService),
            Provider<PlaybackService>.value(value: deps.playbackService),
            Provider<PlaybackStatePersistence>.value(
              value: deps.statePersistence,
            ),
            ChangeNotifierProvider<ThemeModeController>.value(
              value: deps.themeModeController,
            ),
          ],
          child: _LifecycleAwareApp(
            playback: deps.playbackService,
            statePersistence: deps.statePersistence,
          ),
        );
      },
    );
  }
}

/// Matches the app's dark background so there's no color flash between the
/// native launch screen, this, and the real themed app underneath.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: NocturneColors.bg,
        body: Center(
          child: CircularProgressIndicator(
            color: NocturneColors.accent,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}

/// Saves the current queue/position whenever the app is backgrounded, so a
/// real relaunch (not just a hot reload) finds the same state — the actual
/// save side of what [PlaybackStatePersistence.restore] reads back on boot.
class _LifecycleAwareApp extends StatefulWidget {
  final PlaybackService playback;
  final PlaybackStatePersistence statePersistence;
  const _LifecycleAwareApp({
    required this.playback,
    required this.statePersistence,
  });

  @override
  State<_LifecycleAwareApp> createState() => _LifecycleAwareAppState();
}

class _LifecycleAwareAppState extends State<_LifecycleAwareApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    StartupLog.trackFirstRealFrame();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      debugPrint('[Lifecycle] didChangeAppLifecycleState: $state');
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      widget.statePersistence.save(widget.playback);
    }
  }

  @override
  Widget build(BuildContext context) => const ListenyApp();
}
