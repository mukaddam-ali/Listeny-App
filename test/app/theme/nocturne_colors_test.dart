import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listeny/app/theme/nocturne_colors.dart';

void main() {
  tearDown(() => NocturneColors.setThemeMode(ThemeMode.dark));

  group('shared readability tokens', () {
    test('are derived from text, not the neutral fill ramp, in both modes', () {
      NocturneColors.setThemeMode(ThemeMode.dark);
      expect(
        NocturneColors.textSecondary,
        NocturneColors.text.withValues(alpha: 0.64),
      );
      expect(
        NocturneColors.textTertiary,
        NocturneColors.text.withValues(alpha: 0.52),
      );
      expect(
        NocturneColors.iconMuted,
        NocturneColors.text.withValues(alpha: 0.58),
      );

      // Light mode strengthens foreground alphas (same hue, more opaque) so
      // secondary text keeps its contrast over the pale ground.
      NocturneColors.setThemeMode(ThemeMode.light);
      expect(NocturneColors.textSecondary, NocturneColors.textMuted(0.64));
      expect(NocturneColors.textTertiary, NocturneColors.textMuted(0.52));
      expect(NocturneColors.iconMuted, NocturneColors.textMuted(0.58));
      expect(
        NocturneColors.textTertiary.a,
        greaterThan(NocturneColors.text.withValues(alpha: 0.52).a),
      );
      // Fills/borders (low alpha) are not boosted.
      expect(
        NocturneColors.textMuted(0.10),
        NocturneColors.text.withValues(alpha: 0.10),
      );
    });

    test('switch to a genuinely different color when the mode switches', () {
      NocturneColors.setThemeMode(ThemeMode.dark);
      final darkSecondary = NocturneColors.textSecondary;
      final darkIcon = NocturneColors.iconMuted;

      NocturneColors.setThemeMode(ThemeMode.light);
      final lightSecondary = NocturneColors.textSecondary;
      final lightIcon = NocturneColors.iconMuted;

      expect(lightSecondary, isNot(darkSecondary));
      expect(lightIcon, isNot(darkIcon));
    });

    test('error token is theme-aware and distinct per mode', () {
      NocturneColors.setThemeMode(ThemeMode.dark);
      final darkError = NocturneColors.error;
      NocturneColors.setThemeMode(ThemeMode.light);
      final lightError = NocturneColors.error;
      expect(lightError, isNot(darkError));
    });
  });
}
