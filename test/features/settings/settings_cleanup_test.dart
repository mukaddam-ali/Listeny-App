import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/features/settings/settings_screen.dart')
      .readAsStringSync();

  test('Settings has no Crossfade placeholder', () {
    expect(source.contains('settingsCrossfade'), isFalse);
    expect(source.contains('settingsComingSoon'), isFalse);
  });

  test('Settings shows only the marketing version (no build number)', () {
    expect(source.contains('buildNumber'), isFalse);
    expect(source.contains('_packageInfo!.version'), isTrue);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('version: 1.3.1+4007'),
      reason: 'internal build number unchanged',
    );
  });

  test('Settings has exactly one library sync action and no Rescan row', () {
    expect(
      RegExp(r'l10n\.settingsSyncLibrary\b(?!Running)')
          .allMatches(source)
          .length,
      1,
    );
    expect(source.contains('settingsRescan'), isFalse);
    expect(source.contains('rescanForMissingFiles'), isFalse);
  });

  test(
    'removed strings are gone from every locale and the rest stay valid JSON',
    () {
      for (final f in Directory(
        'lib/l10n',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.arb'))) {
        final map = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final k in [
          'settingsCrossfade',
          'settingsComingSoon',
          'settingsRescanLibrary',
          'settingsRescanUpToDate',
          'settingsRescanRemoved',
        ]) {
          expect(map.containsKey(k), isFalse, reason: '$k in ${f.path}');
        }
      }
      final en = jsonDecode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(en['settingsSyncLibrary'], 'Sync Library');
    },
  );
}
