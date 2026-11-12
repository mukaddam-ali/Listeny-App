import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/diagnostics/perf_log.dart';
import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import '../../core/utilities/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/library_repository.dart';
import '../../playback/playback_service.dart';
import '../../shared/artwork_color.dart';
import '../../shared/song_bulk_actions.dart';
import '../../shared/widgets/artwork_view.dart';
import '../../shared/widgets/song_row.dart';

class AlbumScreen extends StatefulWidget {
  final String album;
  final String albumArtist;
  const AlbumScreen({
    super.key,
    required this.album,
    required this.albumArtist,
  });

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  Color _wash = NocturneColors.accent;
  final Set<String> _selectedIds = {};

  // Starts a colour extraction only when (artwork path, album, artist)
  // changes — never on ordinary rebuilds, StreamBuilder re-emissions or the
  // rebuild its own result triggers.
  late final KeyedColorLoader _washLoader = KeyedColorLoader(
    initial: _wash,
    onColor: (c) {
      if (mounted) setState(() => _wash = c);
    },
  );

  @override
  void dispose() {
    _washLoader.dispose();
    super.dispose();
  }

  bool get _selectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String trackId) {
    setState(() {
      _selectedIds.contains(trackId)
          ? _selectedIds.remove(trackId)
          : _selectedIds.add(trackId);
    });
  }

  Future<void> _bulkDelete(
    LibraryRepository library,
    List<Track> tracks,
  ) async {
    final selected = tracks.where((t) => _selectedIds.contains(t.id)).toList();
    await confirmAndBulkDelete(
      context,
      library: library,
      tracks: selected,
      onDeleted: () {
        if (mounted) setState(() => _selectedIds.clear());
      },
    );
  }

  Future<void> _bulkAddToPlaylist(
    LibraryRepository library,
    List<Track> tracks,
  ) async {
    final selected = tracks.where((t) => _selectedIds.contains(t.id)).toList();
    await showAddToPlaylistSheet(context, library: library, tracks: selected);
    if (mounted) setState(() => _selectedIds.clear());
  }

  Future<void> _renameAlbum(
    LibraryRepository library,
    PlaybackService playback,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: widget.album);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.renameAlbumDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.renameAlbumHint),
          onSubmitted: (v) => Navigator.pop(dialogContext, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == widget.album) return;
    if (!mounted) return;

    try {
      await library.renameAlbum(
        album: widget.album,
        albumArtist: widget.albumArtist,
        newAlbum: newName,
      );
    } on AlbumRenameCollisionException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.renameAlbumCollisionMessage(newName, widget.albumArtist),
            ),
          ),
        );
      }
      return;
    }

    // Reflects the rename in an already-loaded playback queue immediately
    // (without reloading audio/resetting position) rather than waiting for
    // the next unrelated playback event to happen to refresh it.
    //
    // A one-shot read, not `.first` on watchSongsForAlbum(newName, ...):
    // that stream is `shareValueSeeded(const [])`, so a fresh subscription's
    // very first event can be the empty seed rather than the real
    // just-renamed rows — which would make refreshTrackMetadata a no-op and
    // leave the queue/current track showing the OLD album name.
    final renamedTracks = await library.getSongsForAlbumOnce(
      newName,
      widget.albumArtist,
    );
    await playback.refreshTrackMetadata(renamedTracks);

    // widget.album/widget.albumArtist are immutable route params identifying
    // a (album, albumArtist) group that no longer exists after the rename —
    // staying here would show an empty list, so return to the Albums list,
    // where the renamed album now appears under its new name.
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryRepository>();
    final playback = context.read<PlaybackService>();
    final l10n = AppLocalizations.of(context);

    return PerfOpenScope(
      name: 'album',
      child: StreamBuilder<List<Track>>(
        stream: library.watchSongsForAlbum(widget.album, widget.albumArtist),
        initialData: library
            .watchSongsForAlbum(widget.album, widget.albumArtist)
            .value,
        builder: (context, snapshot) {
          PerfOpenScope.onBuild('album');
          final tracks = snapshot.data ?? const <Track>[];
          final artworkPath = tracks
              .firstWhere(
                (t) => t.artworkPath != null,
                orElse: () => tracks.isNotEmpty ? tracks.first : _emptyTrack,
              )
              .artworkPath;
          if (tracks.isNotEmpty) {
            _washLoader.request(
              artworkPath,
              '${widget.album}|${widget.albumArtist}',
            );
          }
          final totalDuration = tracks.fold<Duration>(
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
                  height: 420,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _wash.withValues(alpha: 0.30),
                          _wash.withValues(alpha: 0.05),
                          _wash.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      leading: _selectionMode
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(_selectedIds.clear),
                            )
                          : null,
                      title: Text(
                        _selectionMode
                            ? l10n.commonSelectedCount(_selectedIds.length)
                            : widget.album,
                      ),
                      actions: _selectionMode
                          ? [
                              IconButton(
                                icon: const Icon(Icons.playlist_add),
                                tooltip: l10n.commonAddToPlaylistTooltip,
                                onPressed: () =>
                                    _bulkAddToPlaylist(library, tracks),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: l10n.commonDelete,
                                onPressed: () => _bulkDelete(library, tracks),
                              ),
                            ]
                          : [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: l10n.playlistMenuRename,
                                onPressed: () =>
                                    _renameAlbum(library, playback),
                              ),
                            ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                        child: Column(
                          children: [
                            ArtworkView(
                              artworkPath: artworkPath,
                              seed: '${widget.album}|${widget.albumArtist}',
                              size: 216,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.album,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.025,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.albumArtist,
                              style: TextStyle(
                                fontSize: 16,
                                color: NocturneColors.accent300,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${tracks.isNotEmpty ? tracks.first.year ?? '' : ''} · ${l10n.commonTrackCount(tracks.length)} · '
                              '${formatDurationLong(l10n, totalDuration)}'
                              '${tracks.isNotEmpty ? ' · ${tracks.first.format.toUpperCase()}' : ''}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: NocturneColors.textMuted(0.45),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: tracks.isEmpty
                                        ? null
                                        : () => playback.loadQueue(
                                            tracks,
                                            contextName: widget.album,
                                          ),
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      size: 18,
                                    ),
                                    label: Text(l10n.commonPlay),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: tracks.isEmpty
                                        ? null
                                        : () async {
                                            final shuffled = [...tracks]
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
                                              contextName: widget.album,
                                            );
                                          },
                                    icon: const Icon(Icons.shuffle, size: 18),
                                    label: Text(l10n.commonShuffle),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverList.builder(
                      itemCount: tracks.length,
                      itemBuilder: (context, i) {
                        final track = tracks[i];
                        return StreamBuilder<Track?>(
                          stream: playback.currentTrack,
                          initialData: playback.currentTrack.value,
                          builder: (context, current) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: SongRow(
                              track: track,
                              isCurrent: current.data?.id == track.id,
                              showAlbum: false,
                              playContext: tracks,
                              selectionMode: _selectionMode,
                              selected: _selectedIds.contains(track.id),
                              onLongPress: () => _toggleSelection(track.id),
                              onTap: _selectionMode
                                  ? () => _toggleSelection(track.id)
                                  : () => playback.loadQueue(
                                      tracks,
                                      startIndex: i,
                                      contextName: widget.album,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final _emptyTrack = Track(
  id: '',
  filePath: '',
  title: '',
  artist: '',
  album: '',
  albumArtist: '',
  duration: Duration.zero,
  format: '',
  fileSizeBytes: 0,
  dateAdded: DateTime.fromMillisecondsSinceEpoch(0),
);
