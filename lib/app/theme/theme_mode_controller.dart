import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/diagnostics/startup_log.dart';
import 'nocturne_colors.dart';

const themeModePrefKey = 'theme_mode';

/// The single source of truth for System/Light/Dark, persisted across
/// launches. [NocturneColors] mirrors whatever mode this holds so raw
/// `NocturneColors.xxx` references (used throughout the app outside of
/// `Theme.of(context)`) resolve to the same palette MaterialApp is showing —
/// setting the mode here is what keeps both in sync.
class ThemeModeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await StartupLog.stage(
      'SharedPreferences.getInstance (theme)',
      SharedPreferences.getInstance,
    );
    final saved = prefs.getString(themeModePrefKey);
    // No saved value (first launch) or a corrupted one falls back to dark;
    // an explicitly saved Light or System preference always wins above.
    _mode = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.dark,
    );
    NocturneColors.setThemeMode(_mode);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    NocturneColors.setThemeMode(mode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModePrefKey, mode.name);
  }
}
