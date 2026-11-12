import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/diagnostics/perf_log.dart';
import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import '../../core/utilities/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/artwork_picker.dart';
import '../../library/library_repository.dart';
import '../../playback/playback_service.dart';
import '../../shared/widgets/artwork_view.dart';
import '../../shared/widgets/playlist_collage.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryRepository>();
    final playback = context.read<PlaybackService>();
    final l10n = AppLocalizations.of(context);

    return PerfOpenScope(
      name: 'playlist',
      child: StreamBuilder<List<Playlist>>(
        stream: library.watchPlaylists(),
        initialData: library.watchPlaylists().value,
        builder: (context, playlistsSnapshot) {
          final playlist = (playlistsSnapshot.data ?? const [])
              .cast<Playlist?>()
              .firstWhere((p) => p?.id == playlistId, orElse: () => null);
          if (playlist == null) {
            return Scaffold(body: Center(child: Text(l10n.playlistDeleted)));
          }

          return StreamBuilder<List<Track>>(
            stream: library.watchPlaylistSongs(playlistId),
            initialData: library.watchPlaylistSongs(playlistId).value,
            builder: (context, songsSnapshot) {
              PerfOpenScope.onBuild('playlist');
              final songs = songsSnapshot.data ?? const [];
              final totalDuration = songs.fold<Duration>(
                Duration.zero,
                (sum, t) => sum + t.duration,
              );

              return Scaffold(
                backgroundColor: NocturneColors.bg,
                body: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 380,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              NocturneColors.accent.withValues(alpha: 0.22),
                              NocturneColors.accent.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          backgroundColor: Colors.transparent,
                          title: Text(playlist.name),
                          actions: [
                            PopupMenuButton<String>(
                              onSelected: (value) =>
                                  _handleMenu(context, value, playlist),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text(l10n.playlistMenuRename),
                                ),
                                PopupMenuItem(
                                  value: 'artwork',
                                  child: Text(l10n.playlistMenuChangeArtwork),
                                ),
                                if (playlist.artworkPath != null)
                                  PopupMenuItem(
                                    value: 'remove_artwork',
                                    child: Text(l10n.playlistMenuRemoveArtwork),
                                  ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(l10n.playlistMenuDeletePlaylist),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                PlaylistCollage(
                                  customArtworkPath: playlist.artworkPath,
                                  memberTracks: songs.take(4).toList(),
                                  seed: playlist.id,
                                  size: 132,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playlist.name,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.03,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${l10n.commonTrackCount(songs.length)} · ${formatDurationLong(l10n, totalDuration)}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: NocturneColors.text
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                        Text(
                                          l10n.playlistCreatedOn(
                                            _formatDate(
                                              context,
                                              playlist.createdAt,
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: NocturneColors.text
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: songs.isEmpty
                                        ? null
                                        : () => playback.loadQueue(
                                            songs,
                                            contextName: playlist.name,
                                          ),
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      size: 16,
                                    ),
                                    label: Text(l10n.commonPlay),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: songs.isEmpty
                                        ? null
                                        : () async {
                                            final shuffled = [...songs]
                                              ..shuffle();
                                            // Enable shuffle first so the
                                            // toggle reflects immediately,
                                            // instead of waiting on loadQueue's
                                            // own internal play() to resolve.
                                            await playback.setShuffleEnabled(
                                              true,
                                            );
                                            await playback.loadQueue(
                                              shuffled,
                                              contextName: playlist.name,
                                            );
                                          },
                                    icon: const Icon(Icons.shuffle, size: 16),
                                    label: Text(l10n.commonShuffle),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: OutlinedButton.icon(
                              onPressed: () => _showAddSongsSheet(
                                context,
                                library: library,
                                playlist: playlist,
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(l10n.playlistAddTracksButton),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 8)),
                        if (songs.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 30,
                              ),
                              child: Text(l10n.playlistEmptyTracks),
                            ),
                          )
                        else
                          SliverToBoxAdapter(
                            child: ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              itemCount: songs.length,
                              onReorderItem: (oldIndex, newIndex) {
                                final reordered = [...songs];
                                final moved = reordered.removeAt(oldIndex);
                                reordered.insert(newIndex, moved);
                                library.reorderPlaylistSongs(
                                  playlistId,
                                  reordered.map((t) => t.id).toList(),
                                );
                              },
                              itemBuilder: (context, i) {
                                final track = songs[i];
                                return Dismissible(
                                  key: ValueKey('${track.id}-$i'),
                                  background: Container(
                                    color: Colors.redAccent,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onDismissed: (_) =>
                                      library.removeSongFromPlaylist(
                                        playlistId,
                                        track.id,
                                      ),
                                  child: ListTile(
                                    leading: ArtworkView(
                                      artworkPath: track.artworkPath,
                                      seed: track.artworkSeed,
                                      size: 44,
                                    ),
                                    title: Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(track.artist),
                                    trailing: Icon(
                                      Icons.drag_handle,
                                      color: NocturneColors.neutral700,
                                    ),
                                    onTap: () => playback.loadQueue(
                                      songs,
                                      startIndex: i,
                                      contextName: playlist.name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleMenu(BuildContext context, String action, Playlist playlist) {
    final library = context.read<LibraryRepository>();
    final l10n = AppLocalizations.of(context);
    if (action == 'rename') {
      final controller = TextEditingController(text: playlist.name);
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: NocturneColors.surface,
          title: Text(l10n.playlistRenameDialogTitle),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) library.renamePlaylist(playlist.id, name);
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      );
    } else if (action == 'artwork') {
      _changeArtwork(context, library: library, playlist: playlist);
    } else if (action == 'remove_artwork') {
      _removeArtwork(library: library, playlist: playlist);
    } else if (action == 'delete') {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: NocturneColors.surface,
          title: Text(l10n.playlistDeleteDialogTitle),
          content: Text(l10n.playlistDeleteDialogBody(playlist.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () {
                library.deletePlaylist(playlist.id);
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: Text(
                l10n.commonDelete,
                style: TextStyle(color: NocturneColors.error),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _changeArtwork(
    BuildContext context, {
    required LibraryRepository library,
    required Playlist playlist,
  }) async {
    final newPath = await pickAndSaveArtwork();
    if (newPath == null) return;
    final oldPath = playlist.artworkPath;
    final stored = await library.updatePlaylistArtwork(playlist.id, newPath);
    // Only after the database points at the new file, and only if nothing
    // else still references the old one.
    if (stored && oldPath != null) {
      await library.deleteArtworkIfUnreferenced(oldPath);
    }
  }

  Future<void> _removeArtwork({
    required LibraryRepository library,
    required Playlist playlist,
  }) async {
    final oldPath = playlist.artworkPath;
    await library.updatePlaylistArtwork(playlist.id, null);
    if (oldPath != null) await library.deleteArtworkIfUnreferenced(oldPath);
  }

  void _showAddSongsSheet(
    BuildContext context, {
    required LibraryRepository library,
    required Playlist playlist,
  }) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NocturneColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        expand: false,
        builder: (context, scrollController) => StreamBuilder<List<Track>>(
          stream: library.watchAllTracks(),
          initialData: library.watchAllTracks().value,
          builder: (context, allSnapshot) {
            return StreamBuilder<List<Track>>(
              stream: library.watchPlaylistSongs(playlist.id),
              initialData: library.watchPlaylistSongs(playlist.id).value,
              builder: (context, memberSnapshot) {
                final memberIds = (memberSnapshot.data ?? const [])
                    .map((t) => t.id)
                    .toSet();
                final all = allSnapshot.data ?? const [];
                return ListView(
                  controller: scrollController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text(
                        l10n.playlistAddTracksButton,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    for (final track in all)
                      ListTile(
                        leading: ArtworkView(
                          artworkPath: track.artworkPath,
                          seed: track.artworkSeed,
                          size: 42,
                        ),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(track.artist),
                        trailing: Icon(
                          memberIds.contains(track.id)
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color: memberIds.contains(track.id)
                              ? NocturneColors.accent400
                              : NocturneColors.iconMuted,
                        ),
                        onTap: () {
                          if (memberIds.contains(track.id)) {
                            library.removeSongFromPlaylist(
                              playlist.id,
                              track.id,
                            );
                          } else {
                            library.addSongToPlaylist(playlist.id, track.id);
                          }
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(date);
  }
}
