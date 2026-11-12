import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../library/audio_conversion_service.dart';
import '../../library/file_name_sanitizer.dart';
import '../../library/import_models.dart';
import '../../library/import_service.dart';
import '../../library/library_repository.dart';
import '../../library/public_music_saver.dart';

enum _VideoSource { gallery, files }

const _videoExtensions = {'mp4', 'm4v', 'mov', 'mkv', 'webm', '3gp', 'avi'};

/// Picks a local video, extracts its audio to MP3 (tags kept, FFprobe-validated
/// by [AudioConversionService]) and imports the result into the library.
Future<void> runVideoImportFlow(BuildContext context) async {
  final importService = context.read<ImportService>();
  final library = context.read<LibraryRepository>();
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  final source = await showModalBottomSheet<_VideoSource>(
    context: context,
    useRootNavigator: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.importVideoFromGallery),
            onTap: () => Navigator.pop(sheetContext, _VideoSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: Text(l10n.importVideoFromFiles),
            onTap: () => Navigator.pop(sheetContext, _VideoSource.files),
          ),
        ],
      ),
    ),
  );
  if (source == null) return;

  // (display name, path) pairs. The gallery uses the system photo picker,
  // which needs no broad library permission (iOS PHPicker / Android Photo
  // Picker only hand over the videos the user selects).
  final picked = <({String name, String path})>[];
  if (source == _VideoSource.gallery) {
    final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (video != null) picked.add((name: video.name, path: video.path));
  } else {
    final files = await FilePicker.pickFiles(type: FileType.any);
    for (final f in files) {
      final ext = p.extension(f.name).toLowerCase().replaceFirst('.', '');
      if (f.path != null && _videoExtensions.contains(ext)) {
        picked.add((name: f.name, path: f.path!));
      }
    }
  }
  if (picked.isEmpty || !context.mounted) return;

  // Gallery videos are usually named with bare numbers, so ask what to call
  // each track (prefilled from the file name when that looks like a real
  // name). Cancelling skips that video.
  final named = <({String name, String path, String title})>[];
  for (final f in picked) {
    if (!context.mounted) return;
    final title = await _askTrackName(
      context,
      l10n,
      suggestedTrackName(p.basenameWithoutExtension(f.name)),
    );
    if (title != null) named.add((name: f.name, path: f.path, title: title));
  }
  if (named.isEmpty || !context.mounted) return;

  final converter = AudioConversionService();
  var cancelled = false;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(l10n.importVideoConverting)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              cancelled = true;
              converter.cancel();
            },
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    ),
  );

  final tmp = await getTemporaryDirectory();
  var added = 0;
  var duplicates = 0;
  for (final file in named) {
    if (cancelled) break;
    String? mp3;
    try {
      mp3 = await converter.process(inputPath: file.path, outputDir: tmp.path);
      final fileName = '${sanitizeFileName(file.title, fallback: 'Audio')}.mp3';
      // Android 11+: publish into Music/Listeny (visible in file managers)
      // and reference that file in place; elsewhere the import copies it.
      final saved = await PublicMusicSaver().save(path: mp3, name: fileName);
      final results = await importService.importFiles([
        PickedFile(
          name: fileName,
          path: saved?.path ?? mp3,
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
      final latest = results.last.latest;
      switch (latest.outcome) {
        case ImportFileOutcome.added:
          added++;
          // The video's own tags can carry a numeric title; the name the user
          // typed wins.
          await library.renameTrack(latest.track!.id, file.title);
        case ImportFileOutcome.duplicate:
          duplicates++;
          if (saved != null) await PublicMusicSaver().discard(saved);
        default:
          if (saved != null) await PublicMusicSaver().discard(saved);
      }
    } catch (_) {
    } finally {
      if (mp3 != null && mp3 != file.path) {
        try {
          await File(mp3).delete();
        } catch (_) {}
      }
    }
  }
  navigator.pop();
  if (cancelled && added == 0) return;
  final message = added > 0
      ? l10n.importVideoDone
      : duplicates > 0
      ? l10n.importVideoDuplicate
      : l10n.importVideoFailed;
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// A starting name for the track from the video's file name, or '' when that
/// name is just numbers or a camera-style code (1106, VID_2026..., IMG-...).
String suggestedTrackName(String baseName) {
  final cleaned = baseName.replaceAll(RegExp(r'[_\-.]+'), ' ').trim();
  final hasWord = RegExp(r'\p{L}{3,}', unicode: true).hasMatch(cleaned);
  final cameraStyle = RegExp(
    r'^(vid|img|pxl|mov|video|screen\s?recording|screenrecorder)(\W|\d|$).*\d',
    caseSensitive: false,
  ).hasMatch(cleaned);
  return hasWord && !cameraStyle ? cleaned : '';
}

Future<String?> _askTrackName(
  BuildContext context,
  AppLocalizations l10n,
  String suggested,
) {
  final controller = TextEditingController(text: suggested);
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (_, setState) => AlertDialog(
        title: Text(l10n.importVideoNameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.importVideoNameHint),
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.pop(dialogContext, v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: controller.text.trim().isEmpty
                ? null
                : () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    ),
  );
}
