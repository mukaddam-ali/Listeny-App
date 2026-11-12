import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:listeny/app/theme/theme_mode_controller.dart';

void main() {
  test('first launch (no saved preference) defaults to dark', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeModeController();
    await controller.load();
    expect(controller.mode, ThemeMode.dark);
  });

  test(
    'a corrupted/invalid saved preference also falls back to dark',
    () async {
      SharedPreferences.setMockInitialValues({
        themeModePrefKey: 'not-a-real-mode',
      });
      final controller = ThemeModeController();
      await controller.load();
      expect(controller.mode, ThemeMode.dark);
    },
  );

  test(
    'an explicitly saved Light preference is preserved, not overridden to dark',
    () async {
      SharedPreferences.setMockInitialValues({
        themeModePrefKey: ThemeMode.light.name,
      });
      final controller = ThemeModeController();
      await controller.load();
      expect(controller.mode, ThemeMode.light);
    },
  );

  test('an explicitly saved System preference is preserved, not overridden to dark', () async {
    SharedPreferences.setMockInitialValues({
      themeModePrefKey: ThemeMode.system.name,
    });
    final controller = ThemeModeController();
    await controller.load();
    expect(controller.mode, ThemeMode.system);
  });

  test('an explicitly saved Dark preference round-trips normally', () async {
    SharedPreferences.setMockInitialValues({
      themeModePrefKey: ThemeMode.dark.name,
    });
    final controller = ThemeModeController();
    await controller.load();
    expect(controller.mode, ThemeMode.dark);
  });
}
