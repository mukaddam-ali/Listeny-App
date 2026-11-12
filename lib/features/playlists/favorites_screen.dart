import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/diagnostics/perf_log.dart';
import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/library_repository.dart';
import '../../playback/playback_service.dart';
import '../../shared/song_bulk_actions.dart';
import '../../shared/widgets/song_row.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Set<String> _selectedIds = {};
  late final _favorites = context.read<LibraryRepository>().watchFavorites();

  bool get _selectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String trackId) {
    setState(() {
      _selectedIds.contains(trackId)
          ? _selectedIds.remove(trackId)
          : _selectedIds.add(trackId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryRepository>();
    final playback = context.read<PlaybackService>();
    final l10n = AppLocalizations.of(context);

    return PerfOpenScope(
      name: 'favorites',
      child: StreamBuilder<List<Track>>(
        stream: _favorites,
        initialData: _favorites.value,
        builder: (context, snapshot) {
          PerfOpenScope.onBuild('favorites');
          final favorites = snapshot.data ?? const [];

          return Scaffold(
            backgroundColor: NocturneColors.bg,
            appBar: AppBar(
              leading: _selectionMode
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_selectedIds.clear),
                    )
                  : null,
              title: Text(
                _selectionMode
                    ? l10n.commonSelectedCount(_selectedIds.length)
                    : l10n.libraryFilterFavorites,
              ),
              actions: _selectionMode
                  ? [
                      IconButton(
                        icon: const Icon(Icons.playlist_add),
                        tooltip: l10n.commonAddToPlaylistTooltip,
                        onPressed: () => _bulkAddToPlaylist(library, favorites),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.commonDelete,
                        onPressed: () => _bulkDelete(library, favorites),
                      ),
                    ]
                  : null,
            ),
            body: favorites.isEmpty
                ? Center(child: Text(l10n.commonNoFavoritesYet))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => playback.loadQueue(
                                  favorites,
                                  contextName: l10n.libraryFilterFavorites,
                                ),
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: Text(l10n.commonPlay),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final shuffled = [...favorites]..shuffle();
                                  // Enable shuffle first so the toggle
                                  // reflects immediately, instead of waiting
                                  // on loadQueue's own internal play() to
                                  // resolve.
                                  await playback.setShuffleEnabled(true);
                                  await playback.loadQueue(
                                    shuffled,
                                    contextName: l10n.libraryFilterFavorites,
                                  );
                                },
                                icon: const Icon(Icons.shuffle, size: 16),
                                label: Text(l10n.commonShuffle),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final track in favorites)
                        StreamBuilder<Track?>(
                          stream: playback.currentTrack,
                          initialData: playback.currentTrack.value,
                          builder: (context, current) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: SongRow(
                              track: track,
                              isCurrent: current.data?.id == track.id,
                              playContext: favorites,
                              selectionMode: _selectionMode,
                              selected: _selectedIds.contains(track.id),
                              onLongPress: () => _toggleSelection(track.id),
                              onTap: _selectionMode
                                  ? () => _toggleSelection(track.id)
                                  : () => playback.loadQueue(
                                      favorites,
                                      startIndex: favorites.indexOf(track),
                                      contextName: l10n.libraryFilterFavorites,
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Future<void> _bulkDelete(
    LibraryRepository library,
    List<Track> favorites,
  ) async {
    final selected = favorites
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
    List<Track> favorites,
  ) async {
    final selected = favorites
        .where((t) => _selectedIds.contains(t.id))
        .toList();
    await showAddToPlaylistSheet(context, library: library, tracks: selected);
    if (mounted) setState(() => _selectedIds.clear());
  }
}
