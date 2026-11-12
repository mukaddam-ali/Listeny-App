import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/nocturne_colors.dart';
import '../core/models/track.dart';
import '../features/album/album_screen.dart';
import '../features/artist/artist_screen.dart';
import '../features/trim/trim_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../library/library_repository.dart';
import '../playback/playback_service.dart';
import 'song_bulk_actions.dart';
import 'widgets/artwork_view.dart';

/// The action sheet every song row opens — matches the design's 1j screen:
/// Play Now, Play Next, Add to Queue, Add to Playlist, Favorite, View Album,
/// View Artist, Remove from Library. Every action here is real: it calls
/// straight into [PlaybackService]/[LibraryRepository], nothing is a no-op.
Future<void> showSongContextMenu(
  BuildContext context, {
  required Track track,
  required List<Track> playContext,
}) {
  final playback = context.read<PlaybackService>();
  final library = context.read<LibraryRepository>();
  final l10n = AppLocalizations.of(context);

  return showModalBottomSheet(
    context: context,
    // The per-tab Navigator this would otherwise attach to only has the
    // screen space above the mini-player/bottom nav bar (they're siblings in
    // AppShell, not part of any tab's Navigator) — so the sheet's actual
    // content (artwork header + up to 8 action rows) doesn't fit and both
    // overflows AND ends up hidden behind the mini-player. useRootNavigator
    // puts it above the entire screen, mini-player included, with full
    // height to lay out in.
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: NocturneColors.surface.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ArtworkView(
                          artworkPath: track.artworkPath,
                          seed: track.artworkSeed,
                          size: 48,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15.5,
                                ),
                              ),
                              Text(
                                '${track.artist} · ${track.album}',
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
                      ],
                    ),
                  ),
                  Divider(height: 1, color: NocturneColors.neutral800),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionTile(
                            label: l10n.contextMenuPlayNow,
                            icon: Icons.play_arrow,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              final index = playContext.indexOf(track);
                              playback.loadQueue(
                                playContext,
                                startIndex: index < 0 ? 0 : index,
                              );
                            },
                          ),
                          _ActionTile(
                            label: l10n.contextMenuPlayNext,
                            icon: Icons.skip_next,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              playback.playNext(track);
                            },
                          ),
                          _ActionTile(
                            label: l10n.contextMenuAddToQueue,
                            icon: Icons.queue_music,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              playback.addToQueue(track);
                            },
                          ),
                          _ActionTile(
                            label: l10n.contextMenuAddToPlaylistEllipsis,
                            icon: Icons.playlist_add,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              showAddToPlaylistSheet(
                                context,
                                library: library,
                                tracks: [track],
                              );
                            },
                          ),
                          StreamBuilder<List<Track>>(
                            stream: library.watchFavorites(),
                            initialData: library.watchFavorites().value,
                            builder: (context, snapshot) {
                              final isFavorite = (snapshot.data ?? const [])
                                  .any((t) => t.id == track.id);
                              return _ActionTile(
                                label: isFavorite
                                    ? l10n.contextMenuRemoveFavorite
                                    : l10n.contextMenuFavorite,
                                icon: isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  library.setFavorite(track.id, !isFavorite);
                                },
                              );
                            },
                          ),
                          _ActionTile(
                            label: l10n.contextMenuViewAlbum,
                            icon: Icons.album,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AlbumScreen(
                                    album: track.album,
                                    albumArtist: track.albumArtist,
                                  ),
                                ),
                              );
                            },
                          ),
                          _ActionTile(
                            label: l10n.contextMenuViewArtist,
                            icon: Icons.person,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ArtistScreen(artist: track.artist),
                                ),
                              );
                            },
                          ),
                          _ActionTile(
                            label: l10n.playlistMenuRename,
                            icon: Icons.edit_outlined,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _showRenameDialog(
                                context,
                                track: track,
                                library: library,
                              );
                            },
                          ),
                          _ActionTile(
                            label: l10n.trimMenuLabel,
                            icon: Icons.content_cut,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => TrimScreen(track: track),
                                ),
                              );
                            },
                          ),
                          _ActionTile(
                            label: l10n.commonRemoveFromLibrary,
                            icon: Icons.playlist_remove,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              library.removeTrackFromLibraryOnly(track);
                            },
                          ),
                          _ActionTile(
                            label: l10n.commonDeleteFromDevice,
                            icon: Icons.delete_outline,
                            isDestructive: true,
                            isLast: true,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _confirmAndDeleteFromDevice(
                                context,
                                track: track,
                                library: library,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: NocturneColors.surface.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pop(sheetContext),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text(
                      l10n.commonCancel,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                        color: NocturneColors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showRenameDialog(
  BuildContext context, {
  required Track track,
  required LibraryRepository library,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: track.title);
  final newTitle = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.renameTrackDialogTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.renameTrackHint),
        onSubmitted: (v) => Navigator.pop(dialogContext, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
          child: Text(l10n.commonSave),
        ),
      ],
    ),
  );
  if (newTitle != null && newTitle.isNotEmpty && newTitle != track.title) {
    await library.renameTrack(track.id, newTitle);
  }
}

/// Deleting the on-disk copy is irreversible — the file is gone, not just
/// hidden from the library — so this confirms before [LibraryRepository.
/// deleteTrackFromDevice] actually removes it, unlike Remove from Library
/// (which only needs the confirmation of the tap itself, since the file
/// survives that one).
Future<void> _confirmAndDeleteFromDevice(
  BuildContext context, {
  required Track track,
  required LibraryRepository library,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.deleteFromDeviceDialogTitle),
      content: Text(l10n.deleteFromDeviceDialogBody(track.title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            l10n.commonDelete,
            style: TextStyle(color: NocturneColors.error),
          ),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await library.deleteTrackFromDevice(track);
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isLast;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? NocturneColors.accent300
        : NocturneColors.text;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: NocturneColors.neutral800)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 16.5, color: color)),
            Icon(
              icon,
              size: 19,
              color: isDestructive ? color : NocturneColors.neutral300,
            ),
          ],
        ),
      ),
    );
  }
}
