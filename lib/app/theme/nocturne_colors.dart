import 'package:flutter/material.dart';

/// Color tokens ported from the Nocturne design system
/// (`design/_ds/nocturne-*/styles.css`). The source design is dark-only, but the
/// user asked for a real light mode, so this derives one systematically
/// from the same tonal ramps rather than inventing new colors: light mode
/// swaps which *end* of each 100–900 ramp plays the "near background" role
/// vs the "near text" role, keeping every call site (`NocturneColors.neutral900`
/// for a subtle fill, `NocturneColors.accent300` for readable accent text,
/// etc.) automatically correct in both modes without being theme-aware
/// itself — only [NocturneColors] resolves the active [ThemeMode].
class NocturneColors {
  NocturneColors._();

  static ThemeMode _mode = ThemeMode.dark;

  static void setThemeMode(ThemeMode mode) => _mode = mode;
  static ThemeMode get themeMode => _mode;

  static Brightness get _brightness {
    if (_mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
    return _mode == ThemeMode.light ? Brightness.light : Brightness.dark;
  }

  static _Palette get _p => _brightness == Brightness.light ? _light : _dark;

  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get text => _p.text;
  static Color get accent => _p.accent;
  static Color get divider => _p.divider;

  static Color get neutral100 => _p.neutral100;
  static Color get neutral200 => _p.neutral200;
  static Color get neutral300 => _p.neutral300;
  static Color get neutral400 => _p.neutral400;
  static Color get neutral500 => _p.neutral500;
  static Color get neutral600 => _p.neutral600;
  static Color get neutral700 => _p.neutral700;
  static Color get neutral800 => _p.neutral800;
  static Color get neutral900 => _p.neutral900;

  static Color get accent100 => _p.accent100;
  static Color get accent200 => _p.accent200;
  static Color get accent300 => _p.accent300;
  static Color get accent400 => _p.accent400;
  static Color get accent500 => _p.accent500;
  static Color get accent600 => _p.accent600;
  static Color get accent700 => _p.accent700;
  static Color get accent800 => _p.accent800;
  static Color get accent900 => _p.accent900;

  /// [text] at [opacity]. Foreground use (>= 0.35) is strengthened in light
  /// mode, where the same alpha over a pale ground has far less contrast than
  /// over the dark ground it was tuned for; low alphas (fills, borders) are
  /// left alone.
  static Color textMuted(double opacity) {
    final boosted = (_brightness == Brightness.light && opacity >= 0.35)
        ? opacity + (1 - opacity) * 0.32
        : opacity;
    return text.withValues(alpha: boosted);
  }

  // Shared readability tokens for secondary/muted foreground content.
  // Deliberately derived from [text] (not the neutral ramp): the neutral
  // ramp's ends are chosen for fill/background roles and swap per theme
  // accordingly, which is wrong for anything that has to stay legible as a
  // foreground element — text or icon — against [bg]/[surface] in *both*
  // themes (e.g. a SongRow's subtitle/duration, or an unselected nav icon).
  static Color get textSecondary => textMuted(0.64);
  static Color get textTertiary => textMuted(0.52);
  static Color get iconMuted => textMuted(0.58);

  // Error/destructive text and icons — one token instead of a raw red
  // literal, tuned per theme so it stays readable against [bg] in both.
  static Color get error => _brightness == Brightness.light
      ? const Color(0xFFC1391D)
      : const Color(0xFFFF7A6B);
}

class _Palette {
  final Color bg, surface, text, accent, divider;
  final Color neutral100,
      neutral200,
      neutral300,
      neutral400,
      neutral500,
      neutral600,
      neutral700,
      neutral800,
      neutral900;
  final Color accent100,
      accent200,
      accent300,
      accent400,
      accent500,
      accent600,
      accent700,
      accent800,
      accent900;

  const _Palette({
    required this.bg,
    required this.surface,
    required this.text,
    required this.accent,
    required this.divider,
    required this.neutral100,
    required this.neutral200,
    required this.neutral300,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral700,
    required this.neutral800,
    required this.neutral900,
    required this.accent100,
    required this.accent200,
    required this.accent300,
    required this.accent400,
    required this.accent500,
    required this.accent600,
    required this.accent700,
    required this.accent800,
    required this.accent900,
  });
}

// The raw 100–900 ramps themselves (objective lightness steps, independent
// of which mode uses which end) — generated on one shared perceptual scale
// per the design system's own methodology.
const _n100 = Color(0xFFF3F5FE);
const _n200 = Color(0xFFE4E7F5);
const _n300 = Color(0xFFCFD3E5);
const _n400 = Color(0xFFB2B6CA);
const _n500 = Color(0xFF9397AB);
const _n600 = Color(0xFF75798C);
const _n700 = Color(0xFF595D6C);
const _n800 = Color(0xFF3F424D);
const _n900 = Color(0xFF292B31);

const _a100 = Color(0xFFF5F4FF);
const _a200 = Color(0xFFE7E5FE);
const _a300 = Color(0xFFD2CEFD);
const _a400 = Color(0xFFB5ABFC);
const _a500 = Color(0xFF968AE0);
const _a600 = Color(0xFF796CBF);
const _a700 = Color(0xFF5D5294);
const _a800 = Color(0xFF423A6A);
const _a900 = Color(0xFF2B2741);

const _dark = _Palette(
  bg: Color(0xFF161826),
  surface: Color(0xFF232532),
  text: Color(0xFFE9E9ED),
  accent: Color(0xFF9184D9),
  divider: Color(0x29E9E9ED), // ~16% white
  neutral100: _n100,
  neutral200: _n200,
  neutral300: _n300,
  neutral400: _n400,
  neutral500: _n500,
  neutral600: _n600,
  neutral700: _n700,
  neutral800: _n800,
  neutral900: _n900,
  accent100: _a100,
  accent200: _a200,
  accent300: _a300,
  accent400: _a400,
  accent500: _a500,
  accent600: _a600,
  accent700: _a700,
  accent800: _a800,
  accent900: _a900,
);

// Light mode: same ramps, ends swapped (neutral900/accent900 — used
// throughout as "subtle fill near the ground" — resolve to the *light* end
// of the ramp here, since the ground itself is now light; neutral100/accent100
// — used as "readable text/icon on a tinted fill" — resolve to the dark end).
// bg/surface/text/accent/divider are their own near-white/near-black/deepened-accent
// values rather than literal ramp endpoints, matching how the dark palette's
// bg/surface/text/accent aren't literal ramp endpoints either.
// Neutral grey ramp for light mode: the Nocturne neutrals carry a blue tint
// that reads fine on the dark ground but makes a light UI look bluish, so
// light mode uses the same 100-900 lightness steps with no hue.
const _g100 = Color(0xFFF5F5F5);
const _g200 = Color(0xFFE9E9E9);
const _g300 = Color(0xFFD6D6D6);
const _g400 = Color(0xFFB9B9B9);
const _g500 = Color(0xFF9B9B9B);
const _g600 = Color(0xFF7D7D7D);
const _g700 = Color(0xFF5F5F5F);
const _g800 = Color(0xFF454545);
const _g900 = Color(0xFF2D2D2D);

const _light = _Palette(
  bg: Color(0xFFFFFFFF),
  surface: Color(0xFFF6F6F6),
  text: Color(0xFF1A1A1A),
  accent: Color(0xFF6A5CD0),
  divider: Color(0x1F1A1A1A), // ~12% ink
  neutral100: _g900,
  neutral200: _g800,
  neutral300: _g700,
  neutral400: _g600,
  neutral500: _g500,
  neutral600: _g400,
  neutral700: _g300,
  neutral800: _g200,
  neutral900: _g100,
  accent100: _a900,
  accent200: _a800,
  accent300: _a700,
  accent400: _a600,
  accent500: _a500,
  accent600: _a400,
  accent700: _a300,
  accent800: _a200,
  accent900: _a100,
);
