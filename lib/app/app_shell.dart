import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/diagnostics/perf_frames.dart';
import '../core/diagnostics/perf_log.dart';
import '../l10n/generated/app_localizations.dart';
import '../features/download/download_screen.dart';
import '../features/library/library_screen.dart';
import '../features/playlists/playlists_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../shared/widgets/mini_player_bar.dart';

/// Lets a screen inside one tab switch the whole shell to a different tab
/// (e.g. Library's search icon jumping to the Search tab instead of pushing
/// a second, separate search screen).
typedef SwitchTab = void Function(int index);

/// The app's real navigation shell: independent tab stacks (so pushing into
/// an Album from Library, say, doesn't affect the Playlists tab), with the
/// persistent mini-player pinned above the tab bar across all of them.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _navKeys = List.generate(
    _tabs.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  // Tabs are built the first time they're selected, then kept alive by the
  // IndexedStack so their Navigator stacks/state survive tab switches.
  final _opened = <bool>[true, false, false, false, false];

  static const _tabNames = [
    'library',
    'playlists',
    'search',
    'download',
    'settings',
  ];

  static const _tabs = [
    LibraryScreen(),
    PlaylistsScreen(),
    SearchScreen(),
    DownloadScreen(),
    SettingsScreen(),
  ];

  void _onDestinationSelected(int i) {
    if (i == _index) {
      _navKeys[i].currentState?.popUntil((route) => route.isFirst);
    } else {
      if (PerfLog.enabled) {
        PerfLog.begin(
          'tab-switch',
          'to=${_tabNames[i]} ${_opened[i] ? 'already-opened' : 'first-open'}',
        );
        PerfLog.endAfterFrame('tab-switch', 'first frame for destination tab');
      }
      setState(() {
        _index = i;
        _opened[i] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Provider<SwitchTab>.value(
      value: _onDestinationSelected,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    if (_opened[i])
                      Navigator(
                        key: _navKeys[i],
                        observers: PerfLog.enabled
                            ? [PerfNavObserver(_tabNames[i])]
                            : const [],
                        onGenerateRoute: (settings) =>
                            MaterialPageRoute(builder: (_) => _tabs[i]),
                      )
                    else
                      const SizedBox.shrink(),
                ],
              ),
            ),
            const MiniPlayerBar(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onDestinationSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.album_outlined),
              selectedIcon: const Icon(Icons.album),
              label: l10n.navLibrary,
            ),
            NavigationDestination(
              icon: const Icon(Icons.queue_music_outlined),
              selectedIcon: const Icon(Icons.queue_music),
              label: l10n.navPlaylists,
            ),
            NavigationDestination(
              icon: const Icon(Icons.search),
              label: l10n.navSearch,
            ),
            NavigationDestination(
              icon: const Icon(Icons.download_outlined),
              selectedIcon: const Icon(Icons.download),
              label: l10n.navDownload,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
