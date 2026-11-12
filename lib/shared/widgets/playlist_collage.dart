import 'package:flutter/material.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import 'artwork_view.dart';

/// A playlist's artwork: the user's custom image if they chose one,
/// otherwise a 2×2 collage generated from up to four member tracks (real
/// artwork or each track's own generated-gradient stand-in), per the design.
class PlaylistCollage extends StatelessWidget {
  final String? customArtworkPath;
  final List<Track> memberTracks;
  final String seed;
  final double size;
  final BorderRadius borderRadius;

  const PlaylistCollage({
    super.key,
    required this.customArtworkPath,
    required this.memberTracks,
    required this.seed,
    required this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    if (customArtworkPath != null) {
      return ArtworkView(
        artworkPath: customArtworkPath,
        seed: seed,
        size: size,
        borderRadius: borderRadius,
      );
    }
    if (memberTracks.isEmpty) {
      return ArtworkView(
        artworkPath: null,
        seed: seed,
        size: size,
        borderRadius: borderRadius,
      );
    }
    final cells = List.generate(
      4,
      (i) => i < memberTracks.length ? memberTracks[i] : null,
    );
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: size,
        height: size,
        child: GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final track in cells)
              track == null
                  ? ColoredBox(color: NocturneColors.neutral900)
                  : ArtworkView(
                      artworkPath: track.artworkPath,
                      seed: track.artworkSeed,
                      size: size / 2,
                      borderRadius: BorderRadius.zero,
                    ),
          ],
        ),
      ),
    );
  }
}
