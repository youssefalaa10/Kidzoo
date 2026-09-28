import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/badges/badge_definition.dart';
import 'package:kidzo/core/badges/badge_pillar.dart';
import 'package:kidzo/core/badges/default_badge_catalog.dart';

/// Every key the badge catalog names must exist in both locales.
///
/// Badge titles are read with AppLocalizations.resolve rather than through a
/// getter, because they are catalog data. resolve does not throw, so a missing
/// key degrades to the raw key string on a child's badge wall instead of
/// failing the build. This is the guard that takes the getter's place.
void main() {
  Map<String, dynamic> loadLocale(String code) =>
      json.decode(File('assets/lang/$code.json').readAsStringSync())
          as Map<String, dynamic>;

  final Map<String, dynamic> english = loadLocale('en');
  final Map<String, dynamic> arabic = loadLocale('ar');
  final List<BadgeDefinition> badges = buildDefaultBadgeCatalog().all;

  test('every badge title and description resolves in both locales', () {
    for (final BadgeDefinition badge in badges) {
      for (final String key in <String>[
        badge.titleLocalizationKey,
        badge.descriptionLocalizationKey,
      ]) {
        expect(english.containsKey(key), isTrue,
            reason: '${badge.badgeId}: no en.json entry for "$key"');
        expect(arabic.containsKey(key), isTrue,
            reason: '${badge.badgeId}: no ar.json entry for "$key"');
      }
    }
  });

  test('no badge text is blank in either locale', () {
    for (final BadgeDefinition badge in badges) {
      for (final String key in <String>[
        badge.titleLocalizationKey,
        badge.descriptionLocalizationKey,
      ]) {
        expect((english[key] as String?)?.trim(), isNotEmpty, reason: key);
        expect((arabic[key] as String?)?.trim(), isNotEmpty, reason: key);
      }
    }
  });

  test('every pillar heading resolves in both locales', () {
    for (final BadgePillar pillar in BadgePillar.values) {
      expect(english.containsKey(pillar.localizationKey), isTrue,
          reason: pillar.localizationKey);
      expect(arabic.containsKey(pillar.localizationKey), isTrue,
          reason: pillar.localizationKey);
    }
  });
}
