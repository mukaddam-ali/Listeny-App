import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/diagnostics/perf_frames.dart';
import '../core/diagnostics/perf_log.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_shell.dart';
import 'theme/nocturne_colors.dart';
import 'theme/nocturne_theme.dart';
import 'theme/theme_mode_controller.dart';

class ListenyApp extends StatefulWidget {
  const ListenyApp({super.key});

  @override
  State<ListenyApp> createState() => _ListenyAppState();
}

class _ListenyAppState extends State<ListenyApp> with WidgetsBindingObserver {
  ThemeModeController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = context.read<ThemeModeController>();
    if (!identical(c, _controller)) {
      _controller?.removeListener(_markAllDirty);
      _controller = c..addListener(_markAllDirty);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_markAllDirty);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (_controller?.mode == ThemeMode.system) _markAllDirty();
  }

  // Most screens read NocturneColors.xxx directly (not via Theme.of), so
  // const/cached subtrees and pushed routes would keep the old colors. Mark
  // every mounted element dirty synchronously (we're outside build here) so
  // the whole tree repaints in the SAME frame, not piece by piece.
  void _markAllDirty() {
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeModeController>();

    final lightTheme = buildNocturneTheme(Brightness.light);
    final darkTheme = buildNocturneTheme(Brightness.dark);
    NocturneColors.setThemeMode(themeController.mode);

    return MaterialApp(
      navigatorObservers: PerfLog.enabled
          ? [PerfNavObserver('root')]
          : const [],
      title: 'Listeny',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Follow the device's language (matching by language code only, so
      // e.g. any Arabic/Chinese region variant still matches) when it's one
      // of the 10 supported languages; explicit English fallback otherwise
      // — deliberately not left to supportedLocales list order, since 'ar'
      // sorts before 'en' alphabetically.
      localeListResolutionCallback: (deviceLocales, supportedLocales) {
        if (deviceLocales != null) {
          for (final deviceLocale in deviceLocales) {
            for (final supported in supportedLocales) {
              if (supported.languageCode == deviceLocale.languageCode) {
                return supported;
              }
            }
          }
        }
        return const Locale('en');
      },
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeController.mode,
      themeAnimationDuration: Duration.zero,
      // Not const: ListenyApp only rebuilds when ThemeModeController changes,
      // and a canonicalized const AppShell instance would make Flutter skip
      // rebuilding this whole subtree on that rebuild (identical widget
      // fast-path), leaving every raw NocturneColors.xxx read below here
      // stuck on the old mode until something unrelated forced a rebuild.
      home: AppShell(),
    );
  }
}
