import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../core/diagnostics/startup_log.dart';
import '../../core/utilities/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/import_models.dart';
import '../../library/library_repository.dart';
import '../../library/link_import_models.dart';
import '../../library/link_import_service.dart';
import 'download_controller.dart';

/// The Download tab: paste a direct media link, pick a format, and let it
/// flow into the same library every other import does. All UI here just
/// renders [DownloadController]'s state — no separate booleans, no logic
/// about *how* the download happens (that's [LinkImportService]).
class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  late final DownloadController _controller;
  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = DownloadController(context.read<LinkImportService>());
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || !mounted) return;
    _urlController.text = text.trim();
    _urlController.selection = TextSelection.collapsed(
      offset: _urlController.text.length,
    );
  }

  /// Queues the pasted link and frees the field right away, so the next
  /// link can be pasted while this one is still downloading.
  void _start() {
    if (_controller.start(_urlController.text)) {
      _urlController.clear();
      _urlFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    StartupLog.markOnce('tab-Download', 'tab Download first build');
    final l10n = AppLocalizations.of(context);
    final jobs = _controller.jobs;

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(title: Text(l10n.navDownload)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.downloadInstructions,
                style: TextStyle(
                  fontSize: 13,
                  color: NocturneColors.textMuted(0.55),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                focusNode: _urlFocusNode,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _start(),
                onChanged: (_) => _controller.clearValidationError(),
                decoration: InputDecoration(
                  hintText: l10n.downloadUrlHint,
                  filled: true,
                  fillColor: NocturneColors.neutral900,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste, size: 19),
                    tooltip: l10n.downloadPasteTooltip,
                    onPressed: _pasteFromClipboard,
                  ),
                ),
              ),
              if (_controller.validationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.downloadInvalidUrlError,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: NocturneColors.error,
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(l10n.downloadAudioButton),
                ),
              ),
              if (jobs.isNotEmpty) ...[
                const SizedBox(height: 26),
                for (final job in jobs)
                  Padding(
                    key: ValueKey(job.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _JobCard(
                      job: job,
                      onCancel: () => _controller.cancel(job),
                      onDismiss: () => _controller.dismiss(job),
                    ),
                  ),
              ],
              const SizedBox(height: 22),
              const _DownloadHistorySection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// One link in the list: its host, its live status, and a button on the
/// side — cancel while it waits or runs, trash once it has finished.
class _JobCard extends StatelessWidget {
  final DownloadJob job;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;
  const _JobCard({
    required this.job,
    required this.onCancel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final url = job.url;
    final Widget status = job.isQueued
        ? _StatusRow(label: l10n.downloadQueued)
        : _StatusSection(progress: job.progress);
    final Widget? action = job.isFinished
        ? IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: l10n.downloadRemoveTooltip,
            onPressed: onDismiss,
          )
        : job.canCancel
        ? IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: l10n.commonCancel,
            onPressed: onCancel,
          )
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NocturneColors.neutral900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      url.host.isNotEmpty ? url.host : url.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: NocturneColors.textMuted(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    status,
                  ],
                ),
              ),
            ),
            SizedBox(width: 40, height: 40, child: action),
          ],
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final LinkImportProgress progress;
  const _StatusSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (progress.stage) {
      case DownloadStage.idle:
        return const SizedBox.shrink();

      case DownloadStage.resolving:
        return _StatusRow(label: l10n.downloadResolvingLink);

      case DownloadStage.downloading:
        final fraction = progress.fraction;
        // A transient status (e.g. "Trying another audio stream...") takes
        // over the label when a candidate failed and a fallback is about
        // to start — the fraction resets to null right along with it, so
        // this never shows a stale percentage from the failed attempt.
        // progress.message itself comes from LinkImportService (no locale
        // access there) and stays untranslated — see the l10n audit note.
        final label =
            progress.message ??
            (fraction == null
                ? l10n.downloadDownloadingIndeterminate
                : l10n.downloadDownloadingPercent((fraction * 100).round()));
        return _StatusRow(label: label, progress: fraction);

      case DownloadStage.converting:
        return _StatusRow(label: l10n.downloadConverting);

      case DownloadStage.importing:
        return _StatusRow(label: l10n.downloadImporting);

      case DownloadStage.cancelled:
        return Text(
          l10n.downloadCancelled,
          style: TextStyle(fontSize: 14, color: NocturneColors.textMuted(0.6)),
        );

      case DownloadStage.failed:
        return _MessageCard(
          icon: Icons.error_outline,
          iconColor: NocturneColors.error,
          text: progress.message ?? l10n.downloadGenericError,
        );

      case DownloadStage.completed:
        return _CompletedCard(summary: progress.summary!);
    }
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final double? progress;
  const _StatusRow({required this.label, this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: NocturneColors.neutral900,
            valueColor: AlwaysStoppedAnimation(NocturneColors.accent),
          ),
        ),
      ],
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final ImportSummary summary;
  const _CompletedCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (summary.songsAdded > 0) {
      final title = summary.addedTracks.first.title;
      return _MessageCard(
        icon: Icons.check_circle,
        iconColor: NocturneColors.accent400,
        text: l10n.downloadAddedToLibrary(title),
      );
    }
    final detail = summary.duplicates.isNotEmpty
        ? summary.duplicates.first.detail
        : summary.corrupt.isNotEmpty
        ? summary.corrupt.first.detail
        : null;
    return _MessageCard(
      icon: Icons.info_outline,
      iconColor: NocturneColors.neutral400,
      text: detail ?? l10n.downloadNothingNewAdded,
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  const _MessageCard({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // Sits inside a job card, which already provides the background.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.35)),
        ),
      ],
    );
  }
}

/// Recent completed download/import attempts — deliberately not the same
/// thing as Recently Played (that's what you listened to; this is what you
/// downloaded, success or failure). Lives entirely off [LibraryRepository.
/// watchDownloadHistory], so it survives app restarts for free.
class _DownloadHistorySection extends StatefulWidget {
  const _DownloadHistorySection();

  @override
  State<_DownloadHistorySection> createState() =>
      _DownloadHistorySectionState();
}

class _DownloadHistorySectionState extends State<_DownloadHistorySection> {
  late final _history = context
      .read<LibraryRepository>()
      .watchDownloadHistory();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryRepository>();
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<DownloadHistoryEntry>>(
      stream: _history,
      initialData: _history.value,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.downloadHistoryTitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: NocturneColors.textMuted(0.55),
                  ),
                ),
                if (entries.isNotEmpty)
                  TextButton(
                    onPressed: () => _confirmClear(context, library),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.commonClear,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              Text(
                l10n.downloadHistoryEmpty,
                style: TextStyle(
                  fontSize: 13.5,
                  color: NocturneColors.textMuted(0.45),
                ),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: NocturneColors.neutral900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      _HistoryRow(
                        entry: entries[i],
                        isLast: i == entries.length - 1,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    LibraryRepository library,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.downloadClearHistoryDialogTitle),
        content: Text(l10n.downloadClearHistoryDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.commonClear,
              style: TextStyle(color: NocturneColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await library.clearDownloadHistory();
  }
}

class _HistoryRow extends StatelessWidget {
  final DownloadHistoryEntry entry;
  final bool isLast;
  const _HistoryRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sourceLabel = l10n.downloadSourceDirectLink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: NocturneColors.neutral800)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            entry.succeeded ? Icons.check_circle_outline : Icons.error_outline,
            size: 17,
            color: entry.succeeded
                ? NocturneColors.accent400
                : NocturneColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    sourceLabel,
                    if (entry.outputFormat != null)
                      entry.outputFormat!.toUpperCase(),
                    formatRelativeTime(l10n, entry.timestamp),
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: NocturneColors.textMuted(0.5),
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
