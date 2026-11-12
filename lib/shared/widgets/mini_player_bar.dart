import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import '../../features/now_playing/now_playing_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../playback/playback_service.dart';
import 'artwork_view.dart';

/// Persistent bar pinned above the tab bar whenever a track is loaded —
/// matches the design's 64px mini-player with a thin top progress line and a
/// wash of the current track's tint. Tapping it opens Now Playing with a
/// shared-element artwork expansion (Hero, keyed by track id).
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackService>();
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<Track?>(
      stream: playback.currentTrack,
      initialData: playback.currentTrack.value,
      builder: (context, snapshot) {
        final track = snapshot.data;
        if (track == null) return const SizedBox.shrink();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const NowPlayingScreen(),
            ),
          ),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: NocturneColors.divider)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NocturneColors.accent.withValues(alpha: 0.14),
                  NocturneColors.accent.withValues(alpha: 0.06),
                ],
              ),
              color: NocturneColors.surface.withValues(alpha: 0.9),
            ),
            child: Column(
              children: [
                StreamBuilder<Duration>(
                  stream: playback.position,
                  initialData: playback.position.value,
                  builder: (context, posSnapshot) {
                    final position = posSnapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: playback.duration,
                      initialData: playback.duration.value,
                      builder: (context, durSnapshot) {
                        final duration = durSnapshot.data ?? Duration.zero;
                        final fraction = duration.inMilliseconds > 0
                            ? (position.inMilliseconds /
                                      duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                            : 0.0;
                        return SizedBox(
                          height: 2,
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: NocturneColors.neutral900,
                            valueColor: AlwaysStoppedAnimation(
                              NocturneColors.accent400,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'now-playing-artwork-${track.id}',
                          child: ArtworkView(
                            artworkPath: track.artworkPath,
                            seed: track.artworkSeed,
                            size: 42,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.01,
                                ),
                              ),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: NocturneColors.textMuted(0.52),
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<bool>(
                          stream: playback.isPlaying,
                          initialData: playback.isPlaying.value,
                          builder: (context, snapshot) {
                            final playing = snapshot.data ?? false;
                            return IconButton(
                              icon: Icon(
                                playing ? Icons.pause : Icons.play_arrow,
                                size: 26,
                              ),
                              tooltip: playing
                                  ? l10n.commonPause
                                  : l10n.commonPlay,
                              onPressed: playback.togglePlayPause,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.skip_next,
                            size: 22,
                            color: NocturneColors.textMuted(0.7),
                          ),
                          tooltip: l10n.commonNextTrack,
                          onPressed: playback.skipToNext,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: NocturneColors.textMuted(0.5),
                          ),
                          tooltip: l10n.miniPlayerDismissTooltip,
                          onPressed: playback.stop,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
