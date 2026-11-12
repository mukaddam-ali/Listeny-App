import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/diagnostics/startup_log.dart';
import '../../app/theme/nocturne_colors.dart';
import '../../app/theme/nocturne_spacing.dart';
import '../../app/theme/theme_mode_controller.dart';
import '../../core/utilities/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/import_models.dart';
import '../../library/import_service.dart';
import '../../library/library_repository.dart';
import '../../library/local_library_sync_service.dart';
import '../../playback/listeny_audio_handler.dart';
import '../../playback/playback_state_persistence.dart';
import '../import/import_flow.dart';
import '../import/video_import_flow.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _rememberPosition = true;
  bool _keepPlayingWhenClosed = false;
  PackageInfo? _packageInfo;
  // Created once (not in build) so ordinary rebuilds don't re-run the
  // storage scan; refreshed explicitly after a sync.
  late Future<int> _storageBytes;

  @override
  void initState() {
    super.initState();
    _storageBytes = context.read<LibraryRepository>().totalStorageBytes();
    _loadPrefs();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _rememberPosition = prefs.getBool(rememberPositionPrefKey) ?? true;
      _keepPlayingWhenClosed = keepPlayingWhenClosedEnabled(prefs);
    });
  }

  Future<void> _setRememberPosition(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(rememberPositionPrefKey, value);
    if (!mounted) return;
    setState(() => _rememberPosition = value);
  }

  Future<void> _setKeepPlayingWhenClosed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keepPlayingWhenClosedPrefKey, value);
    if (!mounted) return;
    setState(() => _keepPlayingWhenClosed = value);
  }

  // Sync Library: one run at a time; tapping while running cancels (what was
  // already added is kept).
  SyncCancelToken? _syncCancel;

  Future<void> _syncLibrary(LibraryRepository library) async {
    final running = _syncCancel;
    if (running != null) {
      running.cancel();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final token = _syncCancel = SyncCancelToken();
    setState(() {});
    final summary = await LocalLibrarySyncService(library).sync(cancel: token);
    _syncCancel = null;
    if (!mounted) return;
    setState(() => _storageBytes = library.totalStorageBytes());
    final message = switch (summary.outcome) {
      SyncOutcome.completed =>
        summary.added == 0
            ? l10n.syncLibraryUpToDate
            : l10n.syncLibraryAdded(summary.added),
      SyncOutcome.cancelled => l10n.syncLibraryStopped,
      SyncOutcome.permissionDenied => l10n.syncLibraryPermissionDenied,
      SyncOutcome.unsupportedAndroidVersion => l10n.syncLibraryUnsupported,
      SyncOutcome.alreadyRunning => null,
      SyncOutcome.failed => l10n.syncLibraryFailed,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    StartupLog.markOnce('tab-Settings', 'tab Settings first build');
    final library = context.watch<LibraryRepository>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionCard(
            title: l10n.libraryTitle,
            children: [
              _Row(
                icon: Icons.file_download_outlined,
                label: l10n.libraryImportAudioButton,
                onTap: () => runImportFlow(context),
              ),
              _Row(
                icon: Icons.video_file_outlined,
                label: l10n.importVideoButton,
                onTap: () => runVideoImportFlow(context),
              ),
              _Row(
                icon: Icons.sync,
                label: _syncCancel == null
                    ? l10n.settingsSyncLibrary
                    : l10n.settingsSyncLibraryRunning,
                onTap: () => _syncLibrary(library),
              ),
              FutureBuilder<int>(
                future: _storageBytes,
                builder: (context, snapshot) => _Row(
                  icon: Icons.sd_storage_outlined,
                  label: l10n.settingsStorageUsed,
                  value: snapshot.hasData
                      ? formatFileSize(snapshot.data!)
                      : '…',
                ),
              ),
            ],
          ),
          _SectionCard(
            title: l10n.settingsSectionPlayback,
            children: [
              _SwitchRow(
                label: l10n.settingsRememberPosition,
                value: _rememberPosition,
                onChanged: _setRememberPosition,
              ),
              // Android-only: relies on Android's foreground-service model,
              // which iOS's task-termination behavior doesn't guarantee the
              // same way, so the toggle would be misleading there.
              if (defaultTargetPlatform == TargetPlatform.android)
                _SwitchRow(
                  label: l10n.settingsKeepPlayingWhenClosed,
                  value: _keepPlayingWhenClosed,
                  onChanged: _setKeepPlayingWhenClosed,
                ),
            ],
          ),
          const _AppearanceSection(),
          if (kDebugMode)
            _SectionCard(
              title: l10n.settingsSectionDebug,
              children: [
                _Row(
                  icon: Icons.bug_report,
                  label: l10n.settingsImportTestFiles,
                  onTap: () async {
                    // Debug-only path: reads a fixture directly by filesystem
                    // path (not via the SAF picker), so it needs the storage
                    // read permission the real picker flow never has to ask
                    // for (SAF grants access implicitly per-file).
                    final importService = context.read<ImportService>();
                    await Permission.audio.request();
                    await Permission.storage.request();
                    const dir = '/storage/emulated/0/Music/';
                    final summary = await importService.importAndSummarize([
                      const PickedFile(
                        name: 'track1.mp3',
                        path: '${dir}track1.mp3',
                      ),
                      const PickedFile(
                        name: 'track2.mp3',
                        path: '${dir}track2.mp3',
                      ),
                      const PickedFile(
                        name: 'track3.flac',
                        path: '${dir}track3.flac',
                      ),
                      const PickedFile(
                        name: 'listeny_test_tone.mp3',
                        path: '${dir}listeny_test_tone.mp3',
                      ),
                    ]);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.settingsDebugAddedSkipped(
                            summary.songsAdded,
                            summary.duplicates.length +
                                summary.corrupt.length +
                                summary.unsupported.length,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          _SectionCard(
            title: l10n.settingsSectionAbout,
            children: [
              _Row(
                icon: Icons.info_outline,
                label: l10n.settingsVersion,
                value: _packageInfo == null ? '…' : _packageInfo!.version,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Text(
              l10n.settingsFooterNote,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: NocturneColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.09,
              color: NocturneColors.textMuted(0.45),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(NocturneRadius.xl),
            child: DecoratedBox(
              // Shows through as the 1px line between rows below — lighter
              // than the rows' own surface fill, matching the reference
              // design's hairline row separators. Plain ColoredBox (not
              // ListTile.tileColor) for each row: tileColor's Ink-based
              // painting was what caused a stray rectangle to show through
              // the rounded corners on this device.
              decoration: BoxDecoration(color: NocturneColors.neutral900),
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 1),
                    ColoredBox(
                      color: NocturneColors.surface,
                      child: children[i],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  const _Row({required this.icon, required this.label, this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: NocturneColors.accent300, size: 20),
      title: Text(
        label,
        style: TextStyle(fontSize: 15.5, color: NocturneColors.text),
      ),
      trailing: value != null
          ? Text(
              value!,
              style: TextStyle(
                fontSize: 14.5,
                color: NocturneColors.textMuted(0.5),
              ),
            )
          : (onTap != null
                ? Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: NocturneColors.iconMuted,
                  )
                : null),
      onTap: onTap,
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeModeController>();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsAppearance,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.09,
              color: NocturneColors.textMuted(0.45),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: NocturneColors.neutral900,
            ),
            child: Row(
              children: [
                for (final entry in {
                  ThemeMode.light: l10n.settingsThemeLight,
                  ThemeMode.dark: l10n.settingsThemeDark,
                  ThemeMode.system: l10n.settingsThemeSystem,
                }.entries)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: entry.key == controller.mode,
                      label: entry.value,
                      child: GestureDetector(
                        onTap: () => controller.setMode(entry.key),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: entry.key == controller.mode
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                  color: NocturneColors.surface,
                                  border: Border.all(
                                    color: NocturneColors.accent800,
                                  ),
                                )
                              : null,
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: entry.key == controller.mode
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: entry.key == controller.mode
                                  ? NocturneColors.accent200
                                  : NocturneColors.textMuted(0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 15.5)),
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}
