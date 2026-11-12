import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import '../../core/utilities/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/library_repository.dart';
import '../../playback/playback_service.dart';
import '../../playback/playback_state.dart';
import '../../shared/artwork_color.dart';
import '../../shared/widgets/artwork_view.dart';
import '../queue/queue_screen.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  Color _bloom = NocturneColors.accent;
  String? _bloomForTrackId;
  double _dragDistance = 0;

  Future<void> _updateBloom(Track track) async {
    final color = await extractArtworkColor(
      track.artworkPath,
      track.artworkSeed,
    );
    if (mounted && _bloomForTrackId == track.id) {
      setState(() => _bloom = color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackService>();
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<Track?>(
      stream: playback.currentTrack,
      initialData: playback.currentTrack.value,
      builder: (context, snapshot) {
        final track = snapshot.data;
        if (track == null) {
          return Scaffold(
            backgroundColor: NocturneColors.bg,
            body: Center(child: Text(l10n.nowPlayingNothingPlaying)),
          );
        }
        if (_bloomForTrackId != track.id) {
          _bloomForTrackId = track.id;
          _updateBloom(track);
        }

        return Scaffold(
          backgroundColor: NocturneColors.bg,
          // Clamp rather than disable text scaling: this screen's transport
          // controls and album/artist rows are fixed-height, so an
          // unclamped accessibility text size can overflow them — capping
          // it keeps larger text safe without redesigning the layout.
          body: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.5),
                        radius: 0.9,
                        colors: [
                          _bloom.withValues(alpha: 0.40),
                          _bloom.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragUpdate: (details) =>
                        _dragDistance += details.delta.dy,
                    onVerticalDragEnd: (details) {
                      // Either signal dismisses: a fast flick (velocity) or a
                      // slower deliberate drag that still moved far enough
                      // (distance) — velocity alone missed ordinary unhurried
                      // swipes, which is why this felt broken before.
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity > 200 || _dragDistance > 80) {
                        Navigator.of(context).maybePop();
                      }
                      _dragDistance = 0;
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 0, 26, 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          Container(
                            width: 38,
                            height: 5,
                            decoration: BoxDecoration(
                              color: NocturneColors.textMuted(0.28),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: StreamBuilder<String?>(
                              stream: playback.contextName,
                              initialData: playback.contextName.value,
                              builder: (context, ctxSnapshot) {
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l10n.nowPlayingFrom(
                                          (ctxSnapshot.data ??
                                                  l10n.libraryTitle)
                                              .toUpperCase(),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          letterSpacing: 0.09,
                                          color: NocturneColors.textMuted(0.48),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.more_horiz,
                                        color: NocturneColors.text,
                                      ),
                                      tooltip:
                                          l10n.nowPlayingMoreOptionsTooltip,
                                      onPressed: () {},
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Hero(
                                tag: 'now-playing-artwork-${track.id}',
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha:
                                                Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? 0.22
                                                : 0.6,
                                          ),
                                          blurRadius: 70,
                                          offset: const Offset(0, 30),
                                        ),
                                      ],
                                    ),
                                    child: ArtworkView(
                                      artworkPath: track.artworkPath,
                                      seed: track.artworkSeed,
                                      size: double.infinity,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.03,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      track.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: NocturneColors.textMuted(0.72),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        track.album,
                                        if (track.year != null) '${track.year}',
                                        track.format.toUpperCase() +
                                            (track.sampleRateHz != null
                                                ? ' ${(track.sampleRateHz! / 1000).toStringAsFixed(0)}kHz'
                                                : ''),
                                      ].join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: NocturneColors.textMuted(0.42),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _FavoriteButton(track: track),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: _ScrubberRow(),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: _TransportRow(),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 22),
                            child: _UtilityRow(),
                          ),
                        ],
                      ),
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

class _FavoriteButton extends StatelessWidget {
  final Track track;
  const _FavoriteButton({required this.track});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryRepository>();
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<Track>>(
      stream: library.watchFavorites(),
      initialData: library.watchFavorites().value,
      builder: (context, snapshot) {
        final isFavorite = (snapshot.data ?? const []).any(
          (t) => t.id == track.id,
        );
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: NocturneColors.accent400,
              size: 25,
            ),
            tooltip: isFavorite
                ? l10n.nowPlayingRemoveFavoriteTooltip
                : l10n.nowPlayingAddFavoriteTooltip,
            onPressed: () => library.setFavorite(track.id, !isFavorite),
          ),
        );
      },
    );
  }
}

class _ScrubberRow extends StatefulWidget {
  const _ScrubberRow();
  @override
  State<_ScrubberRow> createState() => _ScrubberRowState();
}

class _ScrubberRowState extends State<_ScrubberRow> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackService>();
    return StreamBuilder<Duration>(
      stream: playback.position,
      initialData: playback.position.value,
      builder: (context, posSnapshot) {
        final position = posSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: playback.duration,
          initialData: playback.duration.value,
          builder: (context, durSnapshot) {
            final duration = durSnapshot.data ?? Duration.zero;
            final max = duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0;
            final value =
                _dragValue ??
                position.inMilliseconds.clamp(0, max.toInt()).toDouble();
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    min: 0,
                    max: max,
                    value: value.clamp(0, max),
                    onChanged: duration == Duration.zero
                        ? null
                        : (v) => setState(() => _dragValue = v),
                    onChangeEnd: duration == Duration.zero
                        ? null
                        : (v) {
                            playback.seek(Duration(milliseconds: v.round()));
                            setState(() => _dragValue = null);
                          },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(Duration(milliseconds: value.round())),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: NocturneColors.textMuted(0.45),
                        ),
                      ),
                      Text(
                        '−${formatDuration(duration - Duration(milliseconds: value.round()))}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: NocturneColors.textMuted(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TransportRow extends StatelessWidget {
  const _TransportRow();

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackService>();
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, size: 26),
          tooltip: l10n.nowPlayingRewind10Tooltip,
          onPressed: () {
            HapticFeedback.selectionClick();
            playback.seekBackward10();
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 34),
          tooltip: l10n.nowPlayingPreviousTrackTooltip,
          onPressed: () {
            HapticFeedback.lightImpact();
            playback.skipToPrevious();
          },
        ),
        StreamBuilder<bool>(
          stream: playback.isPlaying,
          initialData: playback.isPlaying.value,
          builder: (context, snapshot) {
            final playing = snapshot.data ?? false;
            return Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NocturneColors.textMuted(0.10),
                border: Border.all(color: NocturneColors.textMuted(0.14)),
              ),
              child: IconButton(
                icon: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  size: 34,
                  color: NocturneColors.text,
                ),
                tooltip: playing ? l10n.commonPause : l10n.commonPlay,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  playback.togglePlayPause();
                },
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 34),
          tooltip: l10n.commonNextTrack,
          onPressed: () {
            HapticFeedback.lightImpact();
            playback.skipToNext();
          },
        ),
        IconButton(
          icon: const Icon(Icons.forward_10, size: 26),
          tooltip: l10n.nowPlayingForward10Tooltip,
          onPressed: () {
            HapticFeedback.selectionClick();
            playback.seekForward10();
          },
        ),
      ],
    );
  }
}

class _UtilityRow extends StatelessWidget {
  const _UtilityRow();

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackService>();
    final l10n = AppLocalizations.of(context);
    final mutedColor = NocturneColors.textMuted(0.6);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StreamBuilder<bool>(
          stream: playback.shuffleEnabled,
          initialData: playback.shuffleEnabled.value,
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? false;
            return Semantics(
              selected: enabled,
              child: IconButton(
                icon: Icon(
                  Icons.shuffle,
                  size: 21,
                  color: enabled ? NocturneColors.accent300 : mutedColor,
                ),
                tooltip: enabled
                    ? l10n.nowPlayingShuffleOn
                    : l10n.nowPlayingShuffleOff,
                onPressed: () => playback.setShuffleEnabled(!enabled),
              ),
            );
          },
        ),
        StreamBuilder<PlaybackRepeatMode>(
          stream: playback.repeatMode,
          initialData: playback.repeatMode.value,
          builder: (context, snapshot) {
            final mode = snapshot.data ?? PlaybackRepeatMode.off;
            const cycle = [
              PlaybackRepeatMode.off,
              PlaybackRepeatMode.all,
              PlaybackRepeatMode.one,
            ];
            final isOn = mode != PlaybackRepeatMode.off;
            final label = switch (mode) {
              PlaybackRepeatMode.off => '',
              PlaybackRepeatMode.one => l10n.nowPlayingRepeatTrack,
              PlaybackRepeatMode.all => l10n.nowPlayingRepeatQueue,
            };
            return Semantics(
              key: const Key('repeat-mode-semantics'),
              selected: isOn,
              child: TextButton.icon(
                onPressed: () => playback.setRepeatMode(
                  cycle[(cycle.indexOf(mode) + 1) % cycle.length],
                ),
                icon: Icon(
                  mode == PlaybackRepeatMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                  size: 21,
                  color: isOn ? NocturneColors.accent300 : mutedColor,
                ),
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOn ? NocturneColors.accent300 : mutedColor,
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.speaker_group_outlined, size: 21, color: mutedColor),
          tooltip: l10n.nowPlayingPlaybackDeviceTooltip,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.nowPlayingPlaybackDeviceMessage)),
          ),
        ),
        TextButton.icon(
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const QueueScreen())),
          icon: Icon(Icons.queue_music, size: 21, color: mutedColor),
          label: Text(
            l10n.queueTitle,
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
        ),
      ],
    );
  }
}
