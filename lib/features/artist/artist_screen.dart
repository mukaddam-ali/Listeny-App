import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/library_repository.dart';
import '../../playback/playback_service.dart';
import '../../shared/widgets/artwork_view.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/song_row.dart';
import '../album/album_screen.dart';

class ArtistScreen extends StatelessWidget {
  final String artist;
  const ArtistScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryRepository>();
    final playback = context.read<PlaybackService>();
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<List<Track>>(
      stream: library.watchSongsForArtist(artist),
      initialData: library.watchSongsForArtist(artist).value,
      builder: (context, snapshot) {
        final tracks = snapshot.data ?? const <Track>[];
        final albums = <String>{for (final t in tracks) t.album}.toList();
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
                height: 340,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.7, -1),
                      radius: 1.1,
                      colors: [
                        NocturneColors.accent.withValues(alpha: 0.26),
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
                    title: Text(artist),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.artistEyebrow,
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.09,
                              color: NocturneColors.textMuted(0.45),
                            ),
                          ),
                          Text(
                            artist,
                            style: const TextStyle(
                              fontSize: 42,
                              height: 1.02,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.035,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${l10n.artistAlbumCount(albums.length)} · ${l10n.commonTrackCount(tracks.length)} · '
                            '${_formatHms(totalDuration)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: NocturneColors.textMuted(0.48),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: tracks.isEmpty
                                    ? null
                                    : () => playback.loadQueue(
                                        tracks,
                                        contextName: artist,
                                      ),
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: Text(l10n.commonPlay),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: tracks.isEmpty
                                    ? null
                                    : () async {
                                        final shuffled = [...tracks]..shuffle();
                                        // Enable shuffle first so the toggle
                                        // reflects immediately, instead of
                                        // waiting on loadQueue's own internal
                                        // play() to resolve.
                                        await playback.setShuffleEnabled(true);
                                        await playback.loadQueue(
                                          shuffled,
                                          contextName: artist,
                                        );
                                      },
                                icon: const Icon(Icons.shuffle, size: 16),
                                label: Text(l10n.commonShuffle),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: StreamBuilder<List<Track>>(
                        stream: library.watchMostPlayedForArtist(artist),
                        initialData: library
                            .watchMostPlayedForArtist(artist)
                            .value,
                        builder: (context, mostPlayedSnapshot) {
                          final mostPlayed =
                              mostPlayedSnapshot.data ?? const [];
                          if (mostPlayed.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(title: l10n.artistMostPlayed),
                              for (final track in mostPlayed)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: SongRow(
                                    track: track,
                                    playContext: mostPlayed,
                                    onTap: () => playback.loadQueue(
                                      mostPlayed,
                                      startIndex: mostPlayed.indexOf(track),
                                      contextName: artist,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(title: l10n.artistAlbumsHeader),
                          SizedBox(
                            height: 178,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: albums.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, i) {
                                final album = albums[i];
                                final albumTracks = tracks
                                    .where((t) => t.album == album)
                                    .toList();
                                return SizedBox(
                                  width: 126,
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AlbumScreen(
                                          album: album,
                                          albumArtist: artist,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ArtworkView(
                                          artworkPath: albumTracks
                                              .firstOrNull
                                              ?.artworkPath,
                                          seed: '$album|$artist',
                                          size: 126,
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                        const SizedBox(height: 9),
                                        Text(
                                          album,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          l10n.commonTrackCount(
                                            albumTracks.length,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: NocturneColors.text
                                                .withValues(alpha: 0.48),
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
                      ),
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
  }

  String _formatHms(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
