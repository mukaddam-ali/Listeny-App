import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../core/audio_formats.dart';
import '../../core/utilities/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/import_models.dart';
import '../../library/media_store_audio_source.dart';

enum _LoadState { loading, permissionDenied, error, loaded }

/// Lets the user pick audio files to import from the device's own media
/// index, without ever launching the system document picker — see
/// MainActivity.kt for why (that picker crashes on some devices). Returns
/// the chosen files as [PickedFile]s via [Navigator.pop] when the user taps
/// Import, or null if they back out.
class DeviceMusicBrowserScreen extends StatefulWidget {
  const DeviceMusicBrowserScreen({super.key});

  @override
  State<DeviceMusicBrowserScreen> createState() =>
      _DeviceMusicBrowserScreenState();
}

class _DeviceMusicBrowserScreenState extends State<DeviceMusicBrowserScreen> {
  final _source = MediaStoreAudioSource();
  final _searchController = TextEditingController();

  _LoadState _state = _LoadState.loading;
  List<DeviceAudioFile> _allFiles = const [];
  Map<String, List<DeviceAudioFile>> _byFolder = const {};
  String? _errorMessage;
  String? _openFolder;
  String _query = '';
  final Set<String> _selectedPaths = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Android 13+ scopes this to audio specifically; older versions fall
    // back to the broader storage permission — same pattern already used by
    // the debug import bypass in settings_screen.dart.
    final audioStatus = await Permission.audio.request();
    final granted =
        audioStatus.isGranted || (await Permission.storage.request()).isGranted;
    if (!granted) {
      if (!mounted) return;
      setState(() => _state = _LoadState.permissionDenied);
      return;
    }

    try {
      final files = (await _source.queryAudioFiles())
          .where((f) => isSupportedAudioFile(f.name))
          .toList();
      final byFolder = <String, List<DeviceAudioFile>>{};
      for (final f in files) {
        byFolder.putIfAbsent(f.folder, () => []).add(f);
      }
      if (!mounted) return;
      setState(() {
        _allFiles = files;
        _byFolder = byFolder;
        _state = _LoadState.loaded;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$e';
        _state = _LoadState.error;
      });
    }
  }

  void _confirmSelection() {
    final picked = _allFiles
        .where((f) => _selectedPaths.contains(f.path))
        .map((f) => PickedFile(name: f.name, path: f.path))
        .toList();
    Navigator.of(context).pop(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(
        leading: _openFolder != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _openFolder = null),
              )
            : null,
        title: Text(_openFolder ?? l10n.deviceBrowserTitle),
      ),
      body: _buildBody(l10n),
      bottomNavigationBar: _selectedPaths.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _confirmSelection,
                    child: Text(
                      l10n.deviceBrowserImportButton(_selectedPaths.length),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_state) {
      case _LoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case _LoadState.permissionDenied:
        return _MessageState(
          icon: Icons.lock_outline,
          title: l10n.deviceBrowserPermissionTitle,
          message: l10n.deviceBrowserPermissionMessage,
          actionLabel: l10n.deviceBrowserOpenSettings,
          onAction: openAppSettings,
        );
      case _LoadState.error:
        return _MessageState(
          icon: Icons.error_outline,
          title: l10n.deviceBrowserErrorTitle,
          message: _errorMessage ?? l10n.deviceBrowserUnknownError,
          actionLabel: l10n.deviceBrowserRetry,
          onAction: () {
            setState(() => _state = _LoadState.loading);
            _load();
          },
        );
      case _LoadState.loaded:
        if (_allFiles.isEmpty) {
          return _MessageState(
            icon: Icons.music_off,
            title: l10n.deviceBrowserNoAudioTitle,
            message: l10n.deviceBrowserNoAudioMessage,
          );
        }
        return _buildLoadedBody(l10n);
    }
  }

  Widget _buildLoadedBody(AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: l10n.deviceBrowserSearchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: NocturneColors.neutral900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: _query.isNotEmpty
              ? _buildSearchResults(l10n)
              : _buildFolderOrFiles(l10n),
        ),
      ],
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n) {
    final q = _query.toLowerCase();
    final matches = _allFiles
        .where((f) => f.name.toLowerCase().contains(q))
        .toList();
    if (matches.isEmpty) {
      return _MessageState(
        icon: Icons.search_off,
        title: l10n.deviceBrowserNoMatches,
        message: '',
      );
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, i) => _FileRow(
        file: matches[i],
        selected: _selectedPaths.contains(matches[i].path),
        showFolder: true,
        onToggle: () => setState(() {
          final path = matches[i].path;
          _selectedPaths.contains(path)
              ? _selectedPaths.remove(path)
              : _selectedPaths.add(path);
        }),
      ),
    );
  }

  Widget _buildFolderOrFiles(AppLocalizations l10n) {
    if (_openFolder != null) {
      final files = _byFolder[_openFolder] ?? const [];
      final allSelected =
          files.isNotEmpty &&
          files.every((f) => _selectedPaths.contains(f.path));
      return ListView(
        children: [
          ListTile(
            dense: true,
            title: Text(
              l10n.commonTrackCount(files.length),
              style: TextStyle(
                fontSize: 12.5,
                color: NocturneColors.textMuted(0.5),
              ),
            ),
            trailing: TextButton(
              onPressed: () => setState(() {
                if (allSelected) {
                  for (final f in files) {
                    _selectedPaths.remove(f.path);
                  }
                } else {
                  for (final f in files) {
                    _selectedPaths.add(f.path);
                  }
                }
              }),
              child: Text(
                allSelected
                    ? l10n.deviceBrowserDeselectAll
                    : l10n.deviceBrowserSelectAll,
              ),
            ),
          ),
          for (final f in files)
            _FileRow(
              file: f,
              selected: _selectedPaths.contains(f.path),
              onToggle: () => setState(() {
                _selectedPaths.contains(f.path)
                    ? _selectedPaths.remove(f.path)
                    : _selectedPaths.add(f.path);
              }),
            ),
        ],
      );
    }

    final folders = _byFolder.keys.toList()..sort();
    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, i) {
        final folder = folders[i];
        final files = _byFolder[folder]!;
        final selectedInFolder = files
            .where((f) => _selectedPaths.contains(f.path))
            .length;
        return ListTile(
          leading: Icon(Icons.folder_outlined, color: NocturneColors.accent300),
          title: Text(folder, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(l10n.commonTrackCount(files.length)),
          trailing: selectedInFolder == 0
              ? const Icon(Icons.chevron_right, size: 18)
              : CircleAvatar(
                  radius: 11,
                  backgroundColor: NocturneColors.accent400,
                  child: Text(
                    '$selectedInFolder',
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
          onTap: () => setState(() => _openFolder = folder),
        );
      },
    );
  }
}

class _FileRow extends StatelessWidget {
  final DeviceAudioFile file;
  final bool selected;
  final bool showFolder;
  final VoidCallback onToggle;

  const _FileRow({
    required this.file,
    required this.selected,
    required this.onToggle,
    this.showFolder = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(value: selected, onChanged: (_) => onToggle()),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        showFolder
            ? '${file.folder} · ${formatFileSize(file.sizeBytes)}'
            : formatFileSize(file.sizeBytes),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5, color: NocturneColors.textMuted(0.5)),
      ),
      trailing: Text(
        formatDuration(file.duration),
        style: TextStyle(fontSize: 12.5, color: NocturneColors.textMuted(0.4)),
      ),
      onTap: onToggle,
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: NocturneColors.iconMuted),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: NocturneColors.textMuted(0.55),
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
