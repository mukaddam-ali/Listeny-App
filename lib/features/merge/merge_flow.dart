import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../core/copy_title.dart';
import '../../core/models/track.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/audio_merge_service.dart';
import '../../library/file_name_sanitizer.dart';
import '../../library/import_models.dart';
import '../../library/import_service.dart';
import '../../library/library_repository.dart';
import '../../library/public_music_saver.dart';

/// Asks for the order and a name, joins [tracks] (exactly two) into one new
/// MP3, saves it into Music/Listeny and adds it to the library. The two
/// originals are left untouched. Returns true when a merged track was added.
Future<bool> runMergeFlow(BuildContext context, List<Track> tracks) async {
  if (tracks.length != 2) return false;
  final library = context.read<LibraryRepository>();
  final importService = context.read<ImportService>();
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final existing = (await library.getAllTracksOnce())
      .map((t) => t.title)
      .toList();
  if (!context.mounted) return false;

  final choice = await showDialog<_MergeChoice>(
    context: context,
    builder: (_) => _MergeDialog(tracks: tracks, existingTitles: existing),
  );
  if (choice == null) return false;

  unawaited(
    showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(l10n.mergeWorking)),
            ],
          ),
        ),
      ),
    ),
  );

  String? output;
  SavedMusicFile? saved;
  var added = false;
  var message = l10n.mergeFailed;
  try {
    output = await AudioMergeService().merge(
      inputPaths: [for (final t in choice.ordered) t.filePath],
      title: choice.name,
    );
    final fileName =
        '${sanitizeFileName(choice.name, fallback: 'Merged')}${p.extension(output)}';
    saved = await PublicMusicSaver().save(path: output, name: fileName);
    final cover = choice.ordered
        .map((t) => t.artworkPath)
        .firstWhere((a) => a != null, orElse: () => null);
    final results = await importService.importFiles([
      PickedFile(
        name: fileName,
        path: saved?.path ?? output,
        externalArtworkPath: cover,
        preferExternalArtwork: cover != null,
        referencedSource: saved == null
            ? null
            : ReferencedSource(
                sourceKey: saved.sourceKey,
                volume: saved.volume,
                sizeBytes: saved.sizeBytes,
                modifiedSec: saved.modifiedSec,
              ),
      ),
    ]).toList();
    final result = results.last.latest;
    if (result.outcome == ImportFileOutcome.added) {
      added = true;
      message = l10n.mergeSaved;
    } else {
      if (saved != null) await PublicMusicSaver().discard(saved);
      if (result.outcome == ImportFileOutcome.duplicate) {
        message = l10n.mergeDuplicate;
      }
    }
  } catch (_) {
    if (saved != null) {
      try {
        await PublicMusicSaver().discard(saved);
      } catch (_) {}
    }
  } finally {
    if (output != null) {
      try {
        await File(output).delete();
      } catch (_) {}
    }
  }
  navigator.pop(); // progress dialog
  messenger.showSnackBar(SnackBar(content: Text(message)));
  return added;
}

class _MergeChoice {
  final List<Track> ordered;
  final String name;
  const _MergeChoice(this.ordered, this.name);
}

class _MergeDialog extends StatefulWidget {
  final List<Track> tracks;
  final List<String> existingTitles;
  const _MergeDialog({required this.tracks, required this.existingTitles});

  @override
  State<_MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends State<_MergeDialog> {
  late List<Track> _ordered = List.of(widget.tracks);
  late final TextEditingController _name = TextEditingController(
    text: _suggest(),
  );
  var _nameEdited = false;

  String _suggest() => nextCopyTitle(
    '${stripCopyCounter(_ordered[0].title)} + ${stripCopyCounter(_ordered[1].title)}',
    widget.existingTitles,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _swap() {
    setState(() {
      _ordered = _ordered.reversed.toList();
      if (!_nameEdited) _name.text = _suggest();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget row(String label, Track t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(color: NocturneColors.neutral400, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
    return AlertDialog(
      title: Text(l10n.mergeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    row(l10n.mergeFirst, _ordered[0]),
                    row(l10n.mergeSecond, _ordered[1]),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_vert),
                tooltip: l10n.mergeSwap,
                onPressed: _swap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            onChanged: (_) => _nameEdited = true,
            decoration: InputDecoration(labelText: l10n.mergeNameLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () {
            final name = _name.text.trim();
            Navigator.pop(
              context,
              _MergeChoice(_ordered, name.isEmpty ? _suggest() : name),
            );
          },
          child: Text(l10n.mergeConfirm),
        ),
      ],
    );
  }
}
