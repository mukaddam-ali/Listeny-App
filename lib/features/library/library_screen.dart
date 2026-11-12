import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/diagnostics/startup_log.dart';
import '../../app/app_shell.dart';
import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/library_repository.dart';
import '../../playback/playback_service.dart';
import '../../shared/song_bulk_actions.dart';
import '../../shared/widgets/artwork_view.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/song_row.dart';
import '../album/album_screen.dart';
import '../import/import_flow.dart';
import '../import/video_import_flow.dart';

enum _Filter { songs, albums, recentlyPlayed, favorites }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  _Filter _filter = _Filter.songs;
  final Set<String> _selectedIds = {};

  // Streams are created once per State (lazily, on first use) so the
  // `stream:` and `initialData:` of each StreamBuilder share ONE subscription
  // source instead of each call building an independent stream.
  late final _allTracks = context.read<LibraryRepository>().watchAllTracks();
  late final _recentlyAdded = context
      .read<LibraryRepository>()
      .watchRecentlyAdded();
  late final _favorites = context.read<LibraryRepository>().watchFavorites();
  late final _recentlyPlayed = context
      .read<LibraryRepository>()
      .watchRecentlyPlayed(limit: 100);
  late final _albums = context.read<LibraryRepository>().watchAlbums();

  bool get _selectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String trackId) {
    setState(() {
      _selectedIds.contains(trackId)
          ? _selectedIds.remove(trackId)
          : _selectedIds.add(trackId);
    });
  }

  // allTracks is always the full library list, a superset of whatever's
  // visible in the current filter tab, so it's safe as the lookup list
  // regardless of which tab _selectedIds was built from.
  Future<void> _bulkDelete(
    LibraryRepository library,
    List<Track> allTracks,
  ) async {
    final selected = allTracks
        .where((t) => _selectedIds.contains(t.id))
        .toList();
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
    List<Track> allTracks,
  ) async {
    final selected = allTracks
        .where((t) => _selectedIds.contains(t.id))
        .toList();
    await showAddToPlaylistSheet(context, library: library, tracks: selected);
    if (mounted) setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    StartupLog.markOnce('tab-Library', 'tab Library first build');
    final library = context.watch<LibraryRepository>();
    final playback = context.read<PlaybackService>();
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<List<Track>>(
      stream: _allTracks,
      initialData: _allTracks.value,
      builder: (context, snapshot) {
        final allTracks = snapshot.data ?? const <Track>[];
        if (allTracks.isEmpty) {
          return _EmptyLibrary(onImport: () => runImportFlow(context));
        }

        return Scaffold(
          backgroundColor: NocturneColors.bg,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: NocturneColors.bg,
                pinned: false,
                floating: true,
                leading: _selectionMode
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: l10n.libraryExitSelectionTooltip,
                        onPressed: () => setState(_selectedIds.clear),
                      )
                    : null,
                title: Text(
                  _selectionMode
                      ? l10n.commonSelectedCount(_selectedIds.length)
                      : l10n.libraryTitle,
                ),
                actions: _selectionMode
                    ? [
                        IconButton(
                          icon: const Icon(Icons.playlist_add),
                          tooltip: l10n.commonAddToPlaylistTooltip,
                          onPressed: () =>
                              _bulkAddToPlaylist(library, allTracks),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.commonDelete,
                          onPressed: () => _bulkDelete(library, allTracks),
                        ),
                      ]
                    : [
                        IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: l10n.commonSearchTooltip,
                          // Same search the Search tab has — jumps there
                          // instead of opening a second, separate screen.
                          onPressed: () => context.read<SwitchTab>()(2),
                        ),
                        IconButton(
                          icon: const Icon(Icons.video_file_outlined),
                          tooltip: l10n.importVideoButton,
                          onPressed: () => runVideoImportFlow(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.file_download_outlined),
                          tooltip: l10n.commonImportTooltip,
                          onPressed: () => runImportFlow(context),
                        ),
                      ],
              ),
              SliverToBoxAdapter(
                child: StreamBuilder<List<Track>>(
                  stream: _recentlyAdded,
                  initialData: _recentlyAdded.value,
                  builder: (context, recentSnapshot) {
                    final recent = recentSnapshot.data ?? const [];
                    if (recent.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: l10n.libraryRecentlyAdded),
                        SizedBox(
                          height: 190,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: recent.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, i) {
                              final track = recent[i];
                              return SizedBox(
                                width: 134,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AlbumScreen(
                                        album: track.album,
                                        albumArtist: track.albumArtist,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ArtworkView(
                                        artworkPath: track.artworkPath,
                                        seed:
                                            '${track.album}|${track.albumArtist}',
                                        size: 134,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      const SizedBox(height: 9),
                                      Text(
                                        track.album,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        track.albumArtist,
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
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: SizedBox(
                    height: 33,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in _Filter.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterPill(
                                label: switch (f) {
                                  _Filter.songs => l10n.libraryFilterTracks,
                                  _Filter.albums => l10n.libraryFilterAlbums,
                                  _Filter.recentlyPlayed =>
                                    l10n.libraryFilterRecentlyPlayed,
                                  _Filter.favorites =>
                                    l10n.libraryFilterFavorites,
                                },
                                selected: _filter == f,
                                onTap: () => setState(() {
                                  _filter = f;
                                  _selectedIds.clear();
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              _buildFilterContent(context, library, playback, allTracks),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterContent(
    BuildContext context,
    LibraryRepository library,
    PlaybackService playback,
    List<Track> allTracks,
  ) {
    final l10n = AppLocalizations.of(context);
    switch (_filter) {
      case _Filter.songs:
        return SliverList.builder(
          itemCount: allTracks.length,
          itemBuilder: (context, i) {
            final track = allTracks[i];
            return StreamBuilder<Track?>(
              stream: playback.currentTrack,
              initialData: playback.currentTrack.value,
              builder: (context, current) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SongRow(
                  track: track,
                  isCurrent: current.data?.id == track.id,
                  playContext: allTracks,
                  selectionMode: _selectionMode,
                  selected: _selectedIds.contains(track.id),
                  showDivider: true,
                  onLongPress: () => _toggleSelection(track.id),
                  onTap: _selectionMode
                      ? () => _toggleSelection(track.id)
                      : () => playback.loadQueue(
                          allTracks,
                          startIndex: i,
                          contextName: l10n.libraryTitle,
                        ),
                ),
              ),
            );
          },
        );
      case _Filter.favorites:
        return SliverToBoxAdapter(
          child: StreamBuilder<List<Track>>(
            stream: _favorites,
            initialData: _favorites.value,
            builder: (context, snapshot) {
              final favorites = snapshot.data ?? const [];
              if (favorites.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                  child: Text(l10n.commonNoFavoritesYet),
                );
              }
              return _selectableColumn(
                favorites,
                playback: playback,
                contextName: l10n.libraryFilterFavorites,
              );
            },
          ),
        );
      case _Filter.recentlyPlayed:
        return SliverToBoxAdapter(
          child: StreamBuilder<List<Track>>(
            stream: _recentlyPlayed,
            initialData: _recentlyPlayed.value,
            builder: (context, snapshot) {
              final played = snapshot.data ?? const [];
              if (played.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                  child: Text(l10n.libraryRecentlyPlayedEmpty),
                );
              }
              return _selectableColumn(
                played,
                playback: playback,
                contextName: l10n.libraryFilterRecentlyPlayed,
              );
            },
          ),
        );
      case _Filter.albums:
        return SliverToBoxAdapter(
          child: StreamBuilder<List<Album>>(
            stream: _albums,
            initialData: _albums.value,
            builder: (context, snapshot) {
              final albums = snapshot.data ?? const [];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: albums.length,
                itemBuilder: (context, i) {
                  final album = albums[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AlbumScreen(
                          album: album.name,
                          albumArtist: album.artist,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ArtworkView(
                            artworkPath: album.artworkPath,
                            seed: '${album.name}|${album.artist}',
                            size: double.infinity,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          album.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          l10n.commonTrackCount(album.songCount),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: NocturneColors.textMuted(0.5),
                          ),
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
  }

  /// Shared row rendering for every "flat list of tracks" filter tab
  /// (Favorites, Recently Played) — the Tracks tab stays its own
  /// [SliverList.builder] above since it needs per-item [StreamBuilder]s for
  /// the currently-playing highlight over the *entire* library, not just
  /// this shorter list.
  Widget _selectableColumn(
    List<Track> tracks, {
    required PlaybackService playback,
    required String contextName,
  }) {
    return Column(
      children: [
        for (final track in tracks)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SongRow(
              track: track,
              playContext: tracks,
              selectionMode: _selectionMode,
              selected: _selectedIds.contains(track.id),
              onLongPress: () => _toggleSelection(track.id),
              onTap: _selectionMode
                  ? () => _toggleSelection(track.id)
                  : () => playback.loadQueue(
                      tracks,
                      startIndex: tracks.indexOf(track),
                      contextName: contextName,
                    ),
            ),
          ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? NocturneColors.accent900 : NocturneColors.neutral900,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            alignment: Alignment.center,
            decoration: selected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: NocturneColors.accent700),
                  )
                : null,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                color: selected
                    ? NocturneColors.accent200
                    : NocturneColors.textMuted(0.62),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onImport;
  const _EmptyLibrary({required this.onImport});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(title: Text(l10n.libraryTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      NocturneColors.neutral900,
                      NocturneColors.neutral900.withValues(alpha: 0),
                    ],
                  ),
                  border: Border.all(color: NocturneColors.neutral800),
                ),
                child: Icon(
                  Icons.album_outlined,
                  size: 46,
                  color: NocturneColors.iconMuted,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                l10n.libraryEmptyTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.02,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.libraryEmptyBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: NocturneColors.textMuted(0.52),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.file_download_outlined),
                label: Text(l10n.libraryImportAudioButton),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: NocturneColors.textMuted(0.42),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.libraryPrivacyNote,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: NocturneColors.textMuted(0.42),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
