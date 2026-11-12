import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/diagnostics/startup_log.dart';
import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/library_repository.dart';
import '../../shared/widgets/playlist_collage.dart';
import 'favorites_screen.dart';
import 'new_playlist_sheet.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  // One stream per source per State, shared by `stream:` and `initialData:`.
  late final _playlists = context.read<LibraryRepository>().watchPlaylists();
  late final _favorites = context.read<LibraryRepository>().watchFavorites();
  final _playlistSongs = <String, ValueStream<List<Track>>>{};

  ValueStream<List<Track>> _songsFor(LibraryRepository library, String id) =>
      _playlistSongs.putIfAbsent(id, () => library.watchPlaylistSongs(id));

  @override
  Widget build(BuildContext context) {
    StartupLog.markOnce('tab-Playlists', 'tab Playlists first build');
    final library = context.watch<LibraryRepository>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(
        title: Text(l10n.navPlaylists),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showNewPlaylistSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Playlist>>(
        stream: _playlists,
        initialData: _playlists.value,
        builder: (context, snapshot) {
          final playlists = snapshot.data ?? const [];
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemCount: playlists.length + 2,
            itemBuilder: (context, i) {
              if (i == 0) {
                return StreamBuilder<List<Track>>(
                  stream: _favorites,
                  initialData: _favorites.value,
                  builder: (context, favSnapshot) {
                    final count = (favSnapshot.data ?? const []).length;
                    return _Tile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      ),
                      art: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              NocturneColors.neutral900,
                              NocturneColors.neutral800.withValues(alpha: 0.35),
                            ],
                          ),
                          border: Border.all(color: NocturneColors.neutral800),
                        ),
                        child: Icon(
                          Icons.favorite,
                          size: 38,
                          color: NocturneColors.accent400,
                        ),
                      ),
                      title: l10n.libraryFilterFavorites,
                      subtitle: l10n.commonTrackCount(count),
                    );
                  },
                );
              }
              if (i == playlists.length + 1) {
                return _Tile(
                  onTap: () => showNewPlaylistSheet(context),
                  art: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          NocturneColors.accent800.withValues(alpha: 0.35),
                          NocturneColors.accent800.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(color: NocturneColors.accent800),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 28,
                      color: NocturneColors.accent300,
                    ),
                  ),
                  title: l10n.newPlaylistTitle,
                  titleColor: NocturneColors.accent300,
                  subtitle: l10n.playlistsPickTracksLater,
                );
              }
              final playlist = playlists[i - 1];
              return StreamBuilder<List<Track>>(
                stream: _songsFor(library, playlist.id),
                initialData: _songsFor(library, playlist.id).value,
                builder: (context, songsSnapshot) {
                  final songs = songsSnapshot.data ?? const [];
                  return _Tile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PlaylistDetailScreen(playlistId: playlist.id),
                      ),
                    ),
                    art: AspectRatio(
                      aspectRatio: 1,
                      child: PlaylistCollage(
                        customArtworkPath: playlist.artworkPath,
                        memberTracks: songs.take(4).toList(),
                        seed: playlist.id,
                        size: double.infinity,
                      ),
                    ),
                    title: playlist.name,
                    subtitle: l10n.commonTrackCount(songs.length),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Widget art;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _Tile({
    required this.art,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 1, child: art),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: titleColor ?? NocturneColors.text,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: NocturneColors.textMuted(0.48),
            ),
          ),
        ],
      ),
    );
  }
}
