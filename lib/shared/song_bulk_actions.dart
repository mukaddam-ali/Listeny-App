import 'package:flutter/material.dart';

import '../app/theme/nocturne_colors.dart';
import '../core/models/track.dart';
import '../l10n/generated/app_localizations.dart';
import '../library/library_repository.dart';

/// The "Add to Playlist" bottom sheet, for one track or many — the single
/// shared implementation every call site (the song context menu's single-
/// track action, and every screen's bulk multi-select action) goes through,
/// so there's exactly one place that lists playlists and calls
/// [LibraryRepository.addSongToPlaylist].
Future<void> showAddToPlaylistSheet(
  BuildContext context, {
  required LibraryRepository library,
  required List<Track> tracks,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet(
    context: context,
    backgroundColor: NocturneColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) => SafeArea(
      child: StreamBuilder<List<Playlist>>(
        stream: library.watchPlaylists(),
        initialData: library.watchPlaylists().value,
        builder: (context, snapshot) {
          final playlists = snapshot.data ?? const [];
          return ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  l10n.bulkAddToPlaylistTitle(tracks.length),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                  ),
                ),
              ),
              for (final playlist in playlists)
                ListTile(
                  leading: Icon(
                    Icons.queue_music,
                    color: NocturneColors.neutral400,
                  ),
                  title: Text(playlist.name),
                  subtitle: Text(l10n.commonTrackCount(playlist.songCount)),
                  onTap: () async {
                    for (final track in tracks) {
                      await library.addSongToPlaylist(playlist.id, track.id);
                    }
                    if (context.mounted) Navigator.pop(sheetContext);
                  },
                ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    ),
  );
}

/// The "Delete" confirmation for one track or many — same two choices as
/// [SongRow]'s swipe-to-delete dialog (Remove from Library / Delete from
/// Device), generalized to a list and shared by every bulk-select surface.
/// Calls [onDeleted] only if the user actually made a choice, so callers can
/// clear their selection without doing it on a cancelled dialog.
Future<void> confirmAndBulkDelete(
  BuildContext context, {
  required LibraryRepository library,
  required List<Track> tracks,
  required VoidCallback onDeleted,
}) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.bulkDeleteTitle(tracks.length)),
      content: Text(l10n.bulkDeleteChooseHow),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, 'library'),
          child: Text(l10n.commonRemoveFromLibrary),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, 'device'),
          child: Text(
            l10n.commonDeleteFromDevice,
            style: TextStyle(color: NocturneColors.error),
          ),
        ),
      ],
    ),
  );
  if (choice == null) return;
  if (choice == 'library') {
    for (final track in tracks) {
      await library.removeTrackFromLibraryOnly(track);
    }
  } else {
    await library.deleteTracksFromDevice(tracks);
  }
  onDeleted();
}
