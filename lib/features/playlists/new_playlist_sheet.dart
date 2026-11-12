import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/artwork_picker.dart';
import '../../library/library_repository.dart';
import 'playlist_detail_screen.dart';

class _NewPlaylistResult {
  final String name;
  final String? artworkPath;
  const _NewPlaylistResult(this.name, this.artworkPath);
}

Future<void> showNewPlaylistSheet(BuildContext context) async {
  final library = context.read<LibraryRepository>();
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  String? artworkPath;

  final result = await showModalBottomSheet<_NewPlaylistResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NocturneColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text(
                        l10n.commonCancel,
                        style: TextStyle(color: NocturneColors.textMuted(0.62)),
                      ),
                    ),
                    Text(
                      l10n.newPlaylistTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final trimmed = controller.text.trim();
                        if (trimmed.isNotEmpty) {
                          Navigator.pop(
                            sheetContext,
                            _NewPlaylistResult(trimmed, artworkPath),
                          );
                        }
                      },
                      child: Text(
                        l10n.newPlaylistCreate,
                        style: TextStyle(
                          color: NocturneColors.accent300,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await pickAndSaveArtwork();
                      if (picked != null) {
                        setSheetState(() => artworkPath = picked);
                      }
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 84,
                            height: 84,
                            child: artworkPath != null
                                ? Image.file(
                                    File(artworkPath!),
                                    fit: BoxFit.cover,
                                  )
                                : DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: NocturneColors.bg,
                                    ),
                                    child: Icon(
                                      Icons.photo_outlined,
                                      color: NocturneColors.iconMuted,
                                    ),
                                  ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: NocturneColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) {
                    final trimmed = v.trim();
                    if (trimmed.isNotEmpty) {
                      Navigator.pop(
                        sheetContext,
                        _NewPlaylistResult(trimmed, artworkPath),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: l10n.newPlaylistNameHint,
                    filled: true,
                    fillColor: NocturneColors.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: NocturneColors.accent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: NocturneColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  artworkPath != null
                      ? l10n.newPlaylistArtworkHintChange
                      : l10n.newPlaylistArtworkHintAdd,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: NocturneColors.textMuted(0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  if (result == null || !context.mounted) return;
  final id = await library.createPlaylist(
    result.name,
    artworkPath: result.artworkPath,
  );
  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: id)),
  );
}
