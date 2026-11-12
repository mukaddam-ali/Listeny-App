import 'dart:io';

import 'package:flutter/material.dart';

/// Shows a track/album/playlist's real embedded artwork when it has any.
/// When it doesn't, renders a deterministic abstract gradient derived from
/// [seed] (e.g. "title|artist") instead of a generic placeholder icon —
/// matching the source design's own artwork stand-in ("Artwork is abstract
/// CSS... Library content is fictional") so every unartworked item still
/// reads as visually distinct rather than a wall of identical placeholders.
/// Artwork files that already failed to decode this session (never retried).
final Set<String> _undecodableArtwork = <String>{};

class ArtworkView extends StatelessWidget {
  final String? artworkPath;
  final String seed;
  final double size;
  final BorderRadius borderRadius;

  const ArtworkView({
    super.key,
    required this.artworkPath,
    required this.seed,
    required this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: size,
        height: size,
        child: artworkPath != null && !_undecodableArtwork.contains(artworkPath)
            ? Image.file(
                File(artworkPath!),
                fit: BoxFit.cover,
                // Remember a failed file so rebuilds fall straight back to the
                // generated artwork instead of re-attempting the decode.
                errorBuilder: (_, _, _) {
                  _undecodableArtwork.add(artworkPath!);
                  return GeneratedArtwork(seed: seed);
                },
              )
            : GeneratedArtwork(seed: seed),
      ),
    );
  }
}

/// The generated-gradient placeholder on its own, for spots that need the
/// same visual identity without going through [ArtworkView] (e.g. playlist
/// collages compositing four of these).
class GeneratedArtwork extends StatelessWidget {
  final String seed;
  const GeneratedArtwork({super.key, required this.seed});

  @override
  Widget build(BuildContext context) {
    final hash = seed.codeUnits.fold<int>(
      0,
      (acc, c) => (acc * 31 + c) & 0x7fffffff,
    );
    final hue = (hash % 360).toDouble();
    final hue2 = (hue + 34) % 360;
    final base = HSLColor.fromAHSL(1, hue, 0.42, 0.16).toColor();
    final glow = HSLColor.fromAHSL(1, hue2, 0.55, 0.46).toColor();
    final dx = -0.6 + ((hash >> 4) % 100) / 100 * 1.2;
    final dy = -0.6 + ((hash >> 9) % 100) / 100 * 1.2;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(dx, dy),
          radius: 1.1,
          colors: [glow, base],
        ),
      ),
    );
  }
}
