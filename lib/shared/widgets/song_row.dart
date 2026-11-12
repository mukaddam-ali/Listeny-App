import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import '../../core/utilities/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/library_repository.dart';
import '../song_context_menu.dart';
import 'artwork_view.dart';

class SongRow extends StatelessWidget {
  final Track track;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final List<Track> playContext;
  final bool showAlbum;

  /// When true, this row is a member of a multi-select session started by a
  /// long-press elsewhere in the list — it shows a checkbox instead of
  /// artwork/trailing actions, and [onTap] toggles selection rather than
  /// playing. Swipe-to-delete is disabled in this mode so it doesn't fight
  /// with the checkbox tap.
  final bool selectionMode;
  final bool selected;

  /// A hairline separator along the row's bottom edge — off by default since
  /// most screens space rows with their own padding, on for the Library
  /// lists where rows sit flush against each other.
  final bool showDivider;

  const SongRow({
    super.key,
    required this.track,
    required this.onTap,
    required this.playContext,
    this.onLongPress,
    this.isCurrent = false,
    this.showAlbum = true,
    this.selectionMode = false,
    this.selected = false,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final row = ListTile(
      selected: isCurrent,
      selectedTileColor: Colors.transparent,
      // Material's default ListTile content padding gives trailing more
      // breathing room than leading (part of the M3 spec, not this app's
      // design), which is what read as excess empty space to the right of
      // the duration/"..." button — pinning both sides to the same explicit
      // value keeps trailing exactly as tight to the edge as leading is.
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: selectionMode
          ? Checkbox(value: selected, onChanged: (_) => onTap())
          : (isCurrent
                ? SizedBox(
                    width: 46,
                    height: 46,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: NocturneColors.accent900,
                      ),
                      child: Icon(
                        Icons.graphic_eq,
                        color: NocturneColors.accent300,
                        size: 20,
                      ),
                    ),
                  )
                : ArtworkView(
                    artworkPath: track.artworkPath,
                    seed: track.artworkSeed,
                    size: 46,
                  )),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.01,
          color: isCurrent ? NocturneColors.accent300 : NocturneColors.text,
        ),
      ),
      subtitle: Text(
        showAlbum ? '${track.artist} · ${track.album}' : track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5, color: NocturneColors.textSecondary),
      ),
      trailing: selectionMode
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (track.favorite)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.favorite,
                      size: 14,
                      color: NocturneColors.accent400,
                    ),
                  ),
                Text(
                  formatDuration(track.duration),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: NocturneColors.textTertiary,
                  ),
                ),
                // Default IconButton padding (8px) plus its 48x48 minimum tap
                // target pads the glyph well past its visual bounds, so the
                // row reads as having more empty space on the right than the
                // artwork's flush-left edge — zeroing both here lets it sit
                // at the true edge, matching the left side.
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color: NocturneColors.iconMuted,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: l10n.songRowOptionsTooltip,
                  onPressed: () => showSongContextMenu(
                    context,
                    track: track,
                    playContext: playContext,
                  ),
                ),
              ],
            ),
      onTap: onTap,
      onLongPress: selectionMode ? null : onLongPress,
    );

    final decorated = showDivider
        ? DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: NocturneColors.divider)),
            ),
            child: row,
          )
        : row;

    if (selectionMode) return decorated;

    return Dismissible(
      key: ValueKey('song-row-${track.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmSwipeDelete(context),
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        color: Colors.redAccent.withValues(alpha: 0.85),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      // The actual delete already happened inside confirmDismiss (it needs
      // to know which kind before Dismissible commits to the animation) —
      // the row's own removal from the list comes from the track stream
      // re-emitting without it, not from this callback.
      onDismissed: (_) {},
      child: decorated,
    );
  }

  Future<bool> _confirmSwipeDelete(BuildContext context) async {
    final library = context.read<LibraryRepository>();
    final l10n = AppLocalizations.of(context);
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l10n.songRowDeleteDialogTitle(track.title),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
    switch (choice) {
      case 'library':
        await library.removeTrackFromLibraryOnly(track);
        return true;
      case 'device':
        await library.deleteTrackFromDevice(track);
        return true;
      default:
        return false;
    }
  }
}
