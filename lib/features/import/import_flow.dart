import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../core/utilities/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/import_models.dart';
import '../../library/import_service.dart';
import '../../playback/playback_service.dart';
import 'device_music_browser_screen.dart';

/// Entry point for the real import flow — matches the design's 1b/1c
/// screens. Every number shown is real (from [ImportSummary]), and "Play
/// what's new" plays the actual tracks that were actually added, not a
/// placeholder.
///
/// On Android this opens Listeny's own in-app music browser instead of the
/// system document picker: that picker (com.android.documentsui) crashes
/// with a SecurityException on some devices — confirmed via logcat on the
/// Work-Profile-enabled Galaxy A50 this was tested on — and takes our
/// activity down with it when it dies mid-transition. See MainActivity.kt
/// for the full explanation. iOS's system picker (UIDocumentPickerViewController)
/// has no such known issue, so it keeps using file_picker there.
Future<void> runImportFlow(BuildContext context) async {
  if (Platform.isAndroid) {
    final picked = await Navigator.of(context).push<List<PickedFile>>(
      MaterialPageRoute(builder: (_) => const DeviceMusicBrowserScreen()),
    );
    if (picked == null || picked.isEmpty || !context.mounted) return;
    await _runImportForPickedFiles(context, picked);
    return;
  }

  // FileType.any: see the comment in the vendored android_file_picker patch
  // and CHANGES.md for why — .audio/.custom both hit real OEM picker bugs.
  final files = await FilePicker.pickFiles(type: FileType.any);
  if (files.isEmpty || !context.mounted) return;
  final picked = files
      .where((f) => f.path != null)
      .map((f) => PickedFile(name: f.name, path: f.path!))
      .toList();
  if (picked.isEmpty) return;
  await _runImportForPickedFiles(context, picked);
}

Future<void> _runImportForPickedFiles(
  BuildContext context,
  List<PickedFile> picked,
) async {
  final importService = context.read<ImportService>();
  final playback = context.read<PlaybackService>();
  final l10n = AppLocalizations.of(context);

  final summary = await showModalBottomSheet<ImportSummary>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: NocturneColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) =>
        _ImportProgressSheet(importService: importService, files: picked),
  );

  if (summary == null || !context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: NocturneColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) => _ImportSummarySheet(
      summary: summary,
      onPlayNew: () {
        Navigator.pop(sheetContext);
        if (summary.addedTracks.isNotEmpty) {
          playback.loadQueue(
            summary.addedTracks,
            contextName: l10n.importFlowContextWhatsNew,
          );
        }
      },
    ),
  );
}

class _ImportProgressSheet extends StatefulWidget {
  final ImportService importService;
  final List<PickedFile> files;
  const _ImportProgressSheet({
    required this.importService,
    required this.files,
  });

  @override
  State<_ImportProgressSheet> createState() => _ImportProgressSheetState();
}

class _ImportProgressSheetState extends State<_ImportProgressSheet> {
  final List<ImportFileResult> _results = [];
  ImportProgress? _progress;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await for (final progress in widget.importService.importFiles(
      widget.files,
    )) {
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _results.add(progress.latest);
      });
    }
    if (!mounted) return;
    final summary = ImportSummary(
      addedTracks: [
        for (final r in _results)
          if (r.outcome == ImportFileOutcome.added) r.track!,
      ],
      duplicates: _results
          .where((r) => r.outcome == ImportFileOutcome.duplicate)
          .toList(),
      unsupported: _results
          .where((r) => r.outcome == ImportFileOutcome.unsupported)
          .toList(),
      corrupt: _results
          .where((r) => r.outcome == ImportFileOutcome.corrupt)
          .toList(),
    );
    Navigator.pop(context, summary);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = widget.files.length;
    final processed = _progress?.processed ?? 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 5,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: NocturneColors.neutral700,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Text(
              l10n.importFlowImportingTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.02,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 20),
              child: Text(
                l10n.importFlowProcessedOfTotal(processed, total),
                style: TextStyle(
                  fontSize: 13,
                  color: NocturneColors.textMuted(0.52),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : processed / total,
                minHeight: 4,
                backgroundColor: NocturneColors.neutral900,
                valueColor: AlwaysStoppedAnimation(NocturneColors.accent),
              ),
            ),
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final r = _results[_results.length - 1 - i];
                  final icon = switch (r.outcome) {
                    ImportFileOutcome.added => Icon(
                      Icons.check_circle,
                      color: NocturneColors.accent400,
                      size: 18,
                    ),
                    ImportFileOutcome.duplicate => Icon(
                      Icons.copy,
                      color: NocturneColors.neutral400,
                      size: 18,
                    ),
                    ImportFileOutcome.unsupported => Icon(
                      Icons.block,
                      color: NocturneColors.neutral400,
                      size: 18,
                    ),
                    ImportFileOutcome.corrupt => Icon(
                      Icons.error_outline,
                      color: NocturneColors.error,
                      size: 18,
                    ),
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: NocturneColors.neutral900,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: NocturneColors.iconMuted,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (r.detail != null)
                                Text(
                                  r.detail!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: NocturneColors.textMuted(0.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        icon,
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 13,
                    color: NocturneColors.textMuted(0.42),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    l10n.importFlowCopiedNote,
                    style: TextStyle(
                      fontSize: 12,
                      color: NocturneColors.textMuted(0.42),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportSummarySheet extends StatelessWidget {
  final ImportSummary summary;
  final VoidCallback onPlayNew;
  const _ImportSummarySheet({required this.summary, required this.onPlayNew});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 5,
              margin: const EdgeInsets.only(bottom: 26),
              decoration: BoxDecoration(
                color: NocturneColors.neutral700,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NocturneColors.accent900,
                border: Border.all(color: NocturneColors.accent700),
              ),
              child: Icon(
                Icons.check,
                color: NocturneColors.accent300,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.importFlowAddedCount(summary.songsAdded),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.02,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.artistAlbumCount(summary.albumsAdded)} · '
              '${l10n.importFlowArtistsCount(summary.artistsAdded)} · '
              '${formatFileSize(summary.bytesAdded)}',
              style: TextStyle(
                fontSize: 13.5,
                color: NocturneColors.textMuted(0.52),
              ),
            ),
            if (summary.duplicates.isNotEmpty ||
                summary.unsupported.isNotEmpty ||
                summary.corrupt.isNotEmpty) ...[
              const SizedBox(height: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: NocturneColors.neutral900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (summary.duplicates.isNotEmpty)
                      _SkipRow(
                        icon: Icons.copy,
                        title: l10n.importFlowDuplicatesSkipped(
                          summary.duplicates.length,
                        ),
                        subtitle: l10n.importFlowAlreadyInLibrary,
                      ),
                    if (summary.unsupported.isNotEmpty)
                      _SkipRow(
                        icon: Icons.block,
                        title: l10n.importFlowUnsupportedSkipped(
                          summary.unsupported.length,
                        ),
                        subtitle: summary.unsupported
                            .map((r) => r.fileName)
                            .join(', '),
                      ),
                    if (summary.corrupt.isNotEmpty)
                      _SkipRow(
                        icon: Icons.error_outline,
                        title: l10n.importFlowCorruptSkipped(
                          summary.corrupt.length,
                        ),
                        subtitle: summary.corrupt
                            .map((r) => r.fileName)
                            .join(', '),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            if (summary.songsAdded > 0)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPlayNew,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: Text(l10n.importFlowPlayWhatsNew),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.commonDone,
                  style: TextStyle(
                    fontSize: 16,
                    color: NocturneColors.textMuted(0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkipRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SkipRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 19, color: NocturneColors.neutral400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: NocturneColors.textMuted(0.48),
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
