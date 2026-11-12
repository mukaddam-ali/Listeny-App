import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// The color behind the design's signature per-track atmosphere (Now
/// Playing bloom, mini-player wash, album header tint). Real artwork gets a
/// real extracted color; a track with no embedded artwork falls back to the
/// same seeded hue its [GeneratedArtwork] placeholder uses, so the bloom
/// still matches what's on screen instead of defaulting to a generic tint.
Future<Color> extractArtworkColor(String? artworkPath, String seed) async {
  if (artworkPath != null && await File(artworkPath).exists()) {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        FileImage(File(artworkPath)),
        maximumColorCount: 16,
      );
      final color =
          palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.mutedColor?.color;
      if (color != null) return color;
    } catch (_) {
      // Fall through to the seeded color below.
    }
  }
  final hash = seed.codeUnits.fold<int>(
    0,
    (acc, c) => (acc * 31 + c) & 0x7fffffff,
  );
  final hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, 0.55, 0.5).toColor();
}

/// Runs [extractArtworkColor] only when the (artwork path, seed) key changes,
/// ignoring results that arrive after a newer request or [dispose], and only
/// notifying when the effective colour actually changed. Lets a screen call
/// [request] from `build` safely: repeated builds with the same key are free,
/// so a result's own rebuild can't start another extraction.
class KeyedColorLoader {
  KeyedColorLoader({
    required this.onColor,
    required Color initial,
    this.extractor = extractArtworkColor,
  }) : _color = initial;

  final void Function(Color color) onColor;
  final Future<Color> Function(String? artworkPath, String seed) extractor;

  Color _color;
  String? _key;
  int _generation = 0;
  bool _disposed = false;

  Color get color => _color;

  void request(String? artworkPath, String seed) {
    if (_disposed) return;
    final key = '${artworkPath ?? ''}|$seed';
    if (key == _key) return;
    _key = key;
    final generation = ++_generation;
    extractor(artworkPath, seed).then(
      (c) {
        if (_disposed || generation != _generation || c == _color) return;
        _color = c;
        onColor(c);
      },
      onError: (Object _) {
        // Keep the current colour, as the extractor's own fallback would.
      },
    );
  }

  void dispose() => _disposed = true;
}
