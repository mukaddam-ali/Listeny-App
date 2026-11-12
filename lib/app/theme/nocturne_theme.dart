import 'package:flutter/material.dart';

import 'nocturne_colors.dart';
import 'nocturne_spacing.dart';

/// Builds the ThemeData for one brightness. Called for both `theme:` and
/// `darkTheme:` on every MaterialApp rebuild — see app.dart for why it
/// temporarily forces [NocturneColors] to match [brightness] while
/// constructing (colors below are plain getters, not brightness-parametrized
/// themselves, so this ordering is what keeps them correct here).
ThemeData buildNocturneTheme(Brightness brightness) {
  NocturneColors.setThemeMode(
    brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
  );

  final colorScheme = brightness == Brightness.light
      ? ColorScheme.light(
          surface: NocturneColors.bg,
          surfaceContainer: NocturneColors.surface,
          primary: NocturneColors.accent,
          onPrimary: NocturneColors.surface,
          onSurface: NocturneColors.text,
          secondary: NocturneColors.accent,
        )
      : ColorScheme.dark(
          surface: NocturneColors.bg,
          surfaceContainer: NocturneColors.surface,
          primary: NocturneColors.accent,
          onPrimary: NocturneColors.bg,
          onSurface: NocturneColors.text,
          secondary: NocturneColors.accent,
        );

  final headingStyle = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    letterSpacing: -0.02,
    color: NocturneColors.text,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: NocturneColors.bg,
    colorScheme: colorScheme,
    fontFamily: 'Inter',
    splashFactory: NoSplash.splashFactory,
    textTheme: TextTheme(
      displaySmall: headingStyle.copyWith(fontSize: 34, letterSpacing: -0.03),
      headlineMedium: headingStyle.copyWith(
        fontSize: 25,
        letterSpacing: -0.025,
      ),
      headlineSmall: headingStyle.copyWith(fontSize: 22),
      titleLarge: headingStyle.copyWith(fontSize: 20),
      titleMedium: headingStyle.copyWith(fontSize: 17),
      titleSmall: headingStyle.copyWith(fontSize: 15, letterSpacing: -0.01),
      bodyLarge: TextStyle(fontSize: 16, color: NocturneColors.text),
      bodyMedium: TextStyle(fontSize: 15, color: NocturneColors.text),
      bodySmall: TextStyle(fontSize: 13, color: NocturneColors.textMuted(0.6)),
      labelSmall: TextStyle(
        fontSize: 11,
        letterSpacing: 0.09,
        color: NocturneColors.textMuted(0.45),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: NocturneColors.bg,
      foregroundColor: NocturneColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 20,
        color: NocturneColors.text,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: NocturneColors.bg.withValues(alpha: 0.9),
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 10,
          color: states.contains(WidgetState.selected)
              ? NocturneColors.accent300
              : NocturneColors.iconMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? NocturneColors.accent300
              : NocturneColors.iconMuted,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: NocturneColors.divider,
      thickness: 1,
      space: 1,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: NocturneColors.accent200,
      thumbColor: NocturneColors.accent100,
      inactiveTrackColor: NocturneColors.neutral900,
      trackHeight: 4,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NocturneColors.accent300,
        side: BorderSide(color: NocturneColors.accent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NocturneRadius.lg),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 15.5,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: NocturneColors.accent300,
        side: BorderSide(color: NocturneColors.accent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NocturneRadius.lg),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 15.5,
        ),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: NocturneColors.text,
      iconColor: NocturneColors.neutral400,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? NocturneColors.accent700
            : NocturneColors.neutral800,
      ),
      thumbColor: WidgetStateProperty.all(NocturneColors.accent100),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: NocturneColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: NocturneColors.surface,
      contentTextStyle: TextStyle(color: NocturneColors.text),
    ),
  );
}
