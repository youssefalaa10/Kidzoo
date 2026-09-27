import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/host/background_resolver.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';

import 'support/disk_content_source.dart';

/// The highest-value test in this feature, and the reason `payload` being
/// untyped is survivable.
///
/// Content is data, so the compiler cannot help. Without this suite an
/// activity file is strictly worse than hardcoded Dart, which at least fails to
/// build. With it, an authoring mistake fails the suite naming the JSON path.
///
/// It reads from **disk**, not the asset bundle, so it needs no widget binding
/// and an author can run it in a second.
void main() {
  const String contentRoot = 'assets/adventures';

  late AdventureContentBundle bundle;
  late ActivityEngineRegistry registry;
  late Map<String, dynamic> manifest;

  setUpAll(() async {
    registry = buildDefaultEngineRegistry();
    bundle = await const AdventureContentLoader(DiskAdventureContentSource())
        .load();
    manifest = json.decode(
      File('$contentRoot/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  /// Every locale any content file claims to support.
  Set<String> declaredLocales() {
    final Set<String> locales = <String>{};
    for (final ActivitySpec spec in bundle.activities.values) {
      locales.addAll(spec.locales);
    }
    return locales;
  }

  group('Manifest agrees with disk, both directions', () {
    void expectDirectoryMatchesManifest(String directory, String manifestKey) {
      final Directory dir = Directory('$contentRoot/$directory');
      expect(dir.existsSync(), isTrue, reason: 'missing $directory/');

      final Set<String> onDisk = dir
          .listSync()
          .whereType<File>()
          .where((File file) => file.path.endsWith('.json'))
          .map((File file) => file.uri.pathSegments.last.replaceAll('.json', ''))
          .toSet();

      final Set<String> inManifest =
          (manifest[manifestKey] as List<dynamic>).map((e) => '$e').toSet();

      expect(onDisk.difference(inManifest), isEmpty,
          reason: 'files in $directory/ missing from manifest.$manifestKey — '
              'they would silently never ship');
      expect(inManifest.difference(onDisk), isEmpty,
          reason: 'manifest.$manifestKey names files that do not exist');
    }

    test('arcs', () => expectDirectoryMatchesManifest('arcs', 'arcs'));
    test('adventures',
        () => expectDirectoryMatchesManifest('adventures', 'adventures'));
    test('activities',
        () => expectDirectoryMatchesManifest('activities', 'activities'));
    test('packs', () => expectDirectoryMatchesManifest('packs', 'packs'));

    test('no subdirectories exist below the five fixed directories', () {
      // pubspec asset entries are NOT recursive, so a nested directory would
      // parse in this test and then ship nothing at all to a real device.
      for (final String directory in <String>[
        'arcs',
        'adventures',
        'activities',
        'packs',
      ]) {
        final List<Directory> nested = Directory('$contentRoot/$directory')
            .listSync()
            .whereType<Directory>()
            .toList();
        expect(nested, isEmpty,
            reason: '$directory/ has subdirectories ${nested.map((d) => d.path)} '
                'which pubspec will not bundle');
      }
    });

    test('the five directories are declared in pubspec', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      for (final String path in <String>[
        'assets/adventures/',
        'assets/adventures/arcs/',
        'assets/adventures/adventures/',
        'assets/adventures/activities/',
        'assets/adventures/packs/',
      ]) {
        expect(pubspec, contains('- $path'),
            reason: '$path is not in pubspec assets, so it will not ship');
      }
    });
  });

  group('Activities parse against their own engine', () {
    test('every engineId is registered', () {
      for (final ActivitySpec spec in bundle.activities.values) {
        expect(registry.contains(spec.engineId), isTrue,
            reason: '${spec.sourcePath} names unknown engine '
                '"${spec.engineId}"; registered: '
                '${(registry.engineIds.toList()..sort())}');
      }
    });

    test("each engine's own parseContent runs over every file that uses it", () {
      // This is what makes the untyped payload safe: not a schema check, but
      // the real parser the runtime will use.
      for (final ActivitySpec spec in bundle.activities.values) {
        final ActivityEngine<ActivityContent> engine =
            registry.require(spec.engineId);
        expect(
          () => engine.parseContent(spec, bundle.packResolver),
          returnsNormally,
          reason: '${spec.sourcePath} does not parse',
        );
      }
    });

    test('every asset an activity references exists on disk', () {
      for (final ActivitySpec spec in bundle.activities.values) {
        final ActivityEngine<ActivityContent> engine =
            registry.require(spec.engineId);
        final ActivityContent content =
            engine.parseContent(spec, bundle.packResolver);
        for (final String asset in engine.assetsFor(content)) {
          expect(File(asset).existsSync(), isTrue,
              reason: '${spec.sourcePath} references missing asset $asset');
        }
      }
    });

    test('every declared backgroundType resolves to an asset', () {
      const BackgroundResolver resolver = BackgroundResolver();
      for (final ActivitySpec spec in bundle.activities.values) {
        final String? type = spec.presentation.backgroundType;
        if (type == null) {
          continue;
        }
        final String? asset = resolver.resolve(type, width: 400);
        expect(asset, isNotNull,
            reason: '${spec.sourcePath} uses backgroundType "$type", which is '
                'not one of ${BackgroundResolver.knownTypes.toList()}');
        expect(File(asset!).existsSync(), isTrue);
      }
      for (final String asset in BackgroundResolver.allAssets) {
        expect(File(asset).existsSync(), isTrue,
            reason: 'BackgroundResolver points at missing $asset');
      }
    });
  });

  group('Difficulty tiers cannot come back as the authoring API', () {
    // Adventure content configures real gameplay parameters by name -
    // targetCount, pairCount, gridSize, clueCount. A 1-5 tier or an
    // easy/medium/hard label is a lossy encoding of what the author actually
    // means, and it cannot express orderings that matter (counting cares about
    // arrangement as much as about quantity). Easy/Medium/Hard survives only
    // inside the legacy adapter, never in content.
    const List<String> forbiddenKeys = <String>[
      'level',
      'difficulty',
      'difficultyLevel',
      'easy',
      'medium',
      'hard',
    ];

    void expectNoForbiddenKeys(Object? node, String path, List<String> failures) {
      if (node is Map) {
        node.forEach((Object? key, Object? value) {
          final String keyName = '$key';
          if (forbiddenKeys.contains(keyName)) {
            failures.add('$path.$keyName');
          }
          expectNoForbiddenKeys(value, '$path.$keyName', failures);
        });
      } else if (node is List) {
        for (int index = 0; index < node.length; index++) {
          expectNoForbiddenKeys(node[index], '$path[$index]', failures);
        }
      }
    }

    test('no activity file uses a difficulty tier key', () {
      final List<String> failures = <String>[];
      for (final File file in Directory('$contentRoot/activities')
          .listSync()
          .whereType<File>()) {
        final Object? decoded = json.decode(file.readAsStringSync());
        expectNoForbiddenKeys(
            decoded, file.uri.pathSegments.last, failures);
      }
      expect(failures, isEmpty,
          reason: 'difficulty tiers found in content: $failures — configure the '
              'real gameplay parameter instead');
    });
  });

  group('Content parameters are declared and in range', () {
    test('no activity sets a parameter its engine does not declare', () {
      // Without this, "make this harder" can silently do nothing: an author
      // adds a knob, the engine never reads it, and the file still loads.
      // Any key starting with `_` is an authoring note, not a parameter. One
      // `_comment` per file was not enough once files grew sections worth
      // explaining separately, and the alternative — one giant comment at the
      // top describing four unrelated decisions — is the kind of comment
      // nobody updates.
      bool isAuthoringNote(String key) => key.startsWith('_');

      for (final ActivitySpec spec in bundle.activities.values) {
        final ActivityEngineDescriptor descriptor =
            registry.require(spec.engineId).descriptor;
        final Set<String> declared = descriptor.contentParameters
            .map((ContentParameter parameter) => parameter.name)
            .toSet();

        for (final String key in spec.payload.keys) {
          if (isAuthoringNote(key)) {
            continue;
          }
          expect(declared, contains(key),
              reason: '${spec.sourcePath} sets payload."$key", which engine '
                  '"${spec.engineId}" does not declare. Declared: '
                  '${(declared.toList()..sort())}');
        }
      }
    });

    test('integer parameters sit inside their declared range', () {
      for (final ActivitySpec spec in bundle.activities.values) {
        final ActivityEngineDescriptor descriptor =
            registry.require(spec.engineId).descriptor;
        for (final ContentParameter parameter in descriptor.contentParameters) {
          if (parameter.type != ContentParameterType.integer) {
            continue;
          }
          final Object? raw = spec.payload[parameter.name];
          if (raw is! num) {
            continue;
          }
          if (parameter.minValue != null) {
            expect(raw.toInt(), greaterThanOrEqualTo(parameter.minValue!),
                reason: '${spec.sourcePath}: ${parameter.name} below minimum');
          }
          if (parameter.maxValue != null) {
            expect(raw.toInt(), lessThanOrEqualTo(parameter.maxValue!),
                reason: '${spec.sourcePath}: ${parameter.name} above maximum');
          }
        }
      }
    });

    test('enumeration parameters use an allowed value', () {
      for (final ActivitySpec spec in bundle.activities.values) {
        final ActivityEngineDescriptor descriptor =
            registry.require(spec.engineId).descriptor;
        for (final ContentParameter parameter in descriptor.contentParameters) {
          final List<String>? allowed = parameter.allowedValues;
          if (allowed == null) {
            continue;
          }
          final Object? raw = spec.payload[parameter.name];
          if (raw == null) {
            continue;
          }
          expect(allowed, contains('$raw'),
              reason: '${spec.sourcePath}: ${parameter.name}="$raw" is not one '
                  'of $allowed');
        }
      }
    });

    test('required parameters are present', () {
      for (final ActivitySpec spec in bundle.activities.values) {
        final ActivityEngineDescriptor descriptor =
            registry.require(spec.engineId).descriptor;
        for (final ContentParameter parameter in descriptor.contentParameters) {
          if (!parameter.isRequired) {
            continue;
          }
          expect(spec.payload.containsKey(parameter.name), isTrue,
              reason: '${spec.sourcePath} is missing required payload.'
                  '${parameter.name}');
        }
      }
    });

    test("every engine's adaptationAxis is a parameter it declares", () {
      for (final ActivityEngine<ActivityContent> engine in registry.engines) {
        final String? axis = engine.descriptor.adaptationAxis;
        if (axis == null) {
          continue;
        }
        expect(engine.descriptor.parameterNamed(axis), isNotNull,
            reason: '${engine.engineId} adapts along "$axis" but does not '
                'declare it as a content parameter');
      }
    });
  });

  group('Localization is complete and honest', () {
    test('an activity never claims a locale its engine cannot be authored in',
        () {
      // "The UI supports Arabic" does not make an activity bilingual. A
      // literacy engine needs real letterforms, connected contextual shapes and
      // Arabic-specific pedagogy; until those exist it declares {'en'} and this
      // assertion keeps Arabic children out of English content.
      for (final ActivitySpec spec in bundle.activities.values) {
        final Set<String> supported =
            registry.require(spec.engineId).descriptor.supportedLocales;
        for (final String locale in spec.locales) {
          expect(supported, contains(locale),
              reason: '${spec.sourcePath} declares locale "$locale" but engine '
                  '"${spec.engineId}" supports only $supported');
        }
      }
    });

    test('every narration line covers every locale the activity declares', () {
      for (final ActivitySpec spec in bundle.activities.values) {
        spec.narration.all.forEach((String name, LocalizedText text) {
          for (final String locale in spec.locales) {
            expect(text.hasLanguage(locale), isTrue,
                reason: '${spec.sourcePath}: narration.$name has no "$locale" '
                    'text, so an $locale child would hear English');
          }
        });
      }
    });

    test('every pack item label covers every declared locale', () {
      for (final ItemPack pack in bundle.packs.values) {
        for (final PackItem item in pack.items) {
          for (final String locale in declaredLocales()) {
            expect(item.label.hasLanguage(locale), isTrue,
                reason: 'pack "${pack.packId}" item "${item.id}" has no '
                    '"$locale" label');
          }
        }
      }
    });

    test('every story line covers every declared locale', () {
      for (final Adventure adventure in bundle.adventures.values) {
        for (final StoryNode node in adventure.nodes) {
          for (int index = 0; index < node.lines.length; index++) {
            for (final String locale in declaredLocales()) {
              expect(node.lines[index].hasLanguage(locale), isTrue,
                  reason: '${adventure.adventureId}.${node.nodeId} line $index '
                      'has no "$locale" text');
            }
          }
        }
      }
    });

    test('no Arabic string interpolates a count without a plural block', () {
      // Arabic number-noun agreement is irregular: 3-10 take a broken plural,
      // 11+ a singular accusative. A template with {count} substituted in
      // produces wrong Arabic, so counts are authored whole.
      final RegExp placeholder = RegExp(r'\{[a-zA-Z_]+\}');
      for (final ActivitySpec spec in bundle.activities.values) {
        spec.narration.all.forEach((String name, LocalizedText text) {
          final String arabic = text.resolve('ar');
          if (!text.hasLanguage('ar')) {
            return;
          }
          expect(placeholder.hasMatch(arabic), isFalse,
              reason: '${spec.sourcePath}: narration.$name Arabic text contains '
                  'a placeholder ("$arabic"). Author the sentence whole.');
        });
      }
    });

    test('Arabic content carries harakat', () {
      // Vowelisation is settled for ages 3-8: diglossia and orthographic
      // complexity interact multiplicatively, and the benefit of harakat is
      // strongest in exactly this age band. Unvowelised Arabic here is a bug.
      final RegExp harakat = RegExp('[ً-ْٰ]');
      for (final ActivitySpec spec in bundle.activities.values) {
        if (!spec.locales.contains('ar')) {
          continue;
        }
        spec.narration.all.forEach((String name, LocalizedText text) {
          final String arabic = text.resolve('ar');
          if (arabic.isEmpty) {
            return;
          }
          expect(harakat.hasMatch(arabic), isTrue,
              reason: '${spec.sourcePath}: narration.$name Arabic has no '
                  'diacritics — early readers need them');
        });
      }
    });
  });

  group('Every chapter declares the full dramatic shape', () {
    test('each adventure declares every required beat, in order', () {
      // A story contract, not a guideline. Requiring the beats forces an author
      // to answer "why is this activity here?" before the activity exists,
      // which is the difference between a story and a themed list of drills.
      for (final Adventure adventure in bundle.adventures.values) {
        final List<StoryBeat> declared = adventure.declaredBeats;
        expect(declared, StoryBeat.requiredSequence,
            reason: '${adventure.adventureId} declares $declared but the '
                'required shape is ${StoryBeat.requiredSequence}');
      }
    });

    test('every activity node sits inside a beat and names a real activity', () {
      for (final Adventure adventure in bundle.adventures.values) {
        for (final StoryNode node in adventure.nodes) {
          if (!node.isActivity) {
            continue;
          }
          expect(node.activityRef, isNotNull);
          expect(() => bundle.requireActivity(node.activityRef!),
              returnsNormally,
              reason: '${adventure.adventureId}.${node.nodeId} points at '
                  'missing activity "${node.activityRef}"');
        }
      }
    });

    test('each adventure contains at least one activity', () {
      for (final Adventure adventure in bundle.adventures.values) {
        expect(adventure.activityCount, greaterThan(0),
            reason: '${adventure.adventureId} is all narration and no doing');
      }
    });

    test('node ids are unique within an adventure', () {
      for (final Adventure adventure in bundle.adventures.values) {
        final List<String> ids = adventure.nodes
            .map((StoryNode node) => node.nodeId)
            .toList(growable: false);
        expect(ids.toSet().length, ids.length,
            reason: '${adventure.adventureId} has duplicate node ids');
      }
    });

    test('exactly one node grants the adventure reward', () {
      for (final Adventure adventure in bundle.adventures.values) {
        final List<StoryNode> granting = adventure.nodes
            .where((StoryNode node) => node.rewardId != null)
            .toList();
        expect(granting.length, 1,
            reason: '${adventure.adventureId} must hand over its page exactly '
                'once; found ${granting.length} nodes with a rewardId');
        expect(granting.single.rewardId, adventure.rewardId);
      }
    });

    test('a declared accent is a usable colour', () {
      // A typo degrades to the default rather than throwing, but the author
      // should still be told they got nothing.
      for (final Adventure adventure in bundle.adventures.values) {
        if (adventure.accent == null) {
          continue;
        }
        expect(adventure.accentColorValue, isNotNull,
            reason: '${adventure.adventureId} accent "${adventure.accent}" is '
                'not #RRGGBB, so it would be silently ignored');
      }
    });

    test('speaker and scene art exists on disk', () {
      for (final Adventure adventure in bundle.adventures.values) {
        for (final StoryNode node in adventure.nodes) {
          for (final String? asset in <String?>[
            node.speakerArt,
            node.sceneArt,
          ]) {
            if (asset == null) {
              continue;
            }
            expect(File(asset).existsSync(), isTrue,
                reason: '${adventure.adventureId}.${node.nodeId} references '
                    'missing art $asset');
          }
        }
      }
    });

    test('narration stays within the attention budget', () {
      // A child who has to listen for a minute before touching anything stops
      // listening. Two lines per beat, and short ones.
      for (final Adventure adventure in bundle.adventures.values) {
        for (final StoryNode node in adventure.nodes) {
          expect(node.lines.length, lessThanOrEqualTo(2),
              reason: '${adventure.adventureId}.${node.nodeId} has '
                  '${node.lines.length} lines; the budget is 2 per beat');
          for (final LocalizedText line in node.lines) {
            for (final String locale in declaredLocales()) {
              expect(line.resolve(locale).length, lessThanOrEqualTo(160),
                  reason: '${adventure.adventureId}.${node.nodeId} has a long '
                      '"$locale" line; keep beats speakable in about 8 seconds');
            }
          }
        }
      }
    });
  });

  group('Arc wiring', () {
    test('every adventure the arc names exists', () {
      for (final StoryArc arc in bundle.arcs.values) {
        for (final String adventureId in arc.adventureIds) {
          expect(bundle.adventures.containsKey(adventureId), isTrue,
              reason: 'arc "${arc.arcId}" names missing adventure '
                  '"$adventureId"');
        }
      }
    });

    test('every adventure belongs to an arc', () {
      final Set<String> claimed = bundle.arcs.values
          .expand((StoryArc arc) => arc.adventureIds)
          .toSet();
      for (final String adventureId in bundle.adventures.keys) {
        expect(claimed, contains(adventureId),
            reason: 'adventure "$adventureId" is unreachable: no arc lists it');
      }
    });

    test('the companion and book are named in content, not in code', () {
      for (final StoryArc arc in bundle.arcs.values) {
        for (final String locale in declaredLocales()) {
          expect(arc.companionName.resolve(locale), isNotEmpty);
          expect(arc.bookName.resolve(locale), isNotEmpty);
        }
      }
    });
  });

  group('Packs', () {
    test('every item image exists on disk', () {
      for (final ItemPack pack in bundle.packs.values) {
        for (final PackItem item in pack.items) {
          expect(File(item.imageAsset).existsSync(), isTrue,
              reason: 'pack "${pack.packId}" item "${item.id}" references '
                  'missing ${item.imageAsset}');
        }
      }
    });

    test('item ids are unique within a pack', () {
      for (final ItemPack pack in bundle.packs.values) {
        final List<String> ids =
            pack.items.map((PackItem item) => item.id).toList(growable: false);
        expect(ids.toSet().length, ids.length,
            reason: 'pack "${pack.packId}" has duplicate item ids');
      }
    });

    test('a sorting activity has a bin for every value its items carry', () {
      // Otherwise a token appears that has nowhere legal to go, and the child
      // is asked to do something impossible.
      for (final ActivitySpec spec in bundle.activities.values) {
        if (spec.engineId != 'sorting') {
          continue;
        }
        final String attribute = '${spec.payload['activeAttribute']}';
        final List<String> itemIds =
            (spec.payload['itemIds'] as List<dynamic>? ?? <dynamic>[])
                .map((e) => '$e')
                .toList();
        final ItemPack pack = bundle.packResolver.require(
          '${spec.payload['itemsRef']}',
          debugPath: spec.sourcePath,
        );
        final List<PackItem> items =
            pack.select(itemIds, debugPath: spec.sourcePath);
        final Set<String> binValues =
            (spec.payload['bins'] as List<dynamic>? ?? <dynamic>[])
                .map((e) => '${(e as Map<dynamic, dynamic>)['value']}')
                .toSet();

        for (final PackItem item in items) {
          final String? value = item.attribute(attribute);
          expect(value, isNotNull,
              reason: '${spec.sourcePath}: item "${item.id}" has no '
                  '"$attribute" attribute');
          expect(binValues, contains(value),
              reason: '${spec.sourcePath}: item "${item.id}" is '
                  '"$attribute=$value" but no bin accepts it');
        }
      }
    });
  });

  group('The words and the pictures agree', () {
    // The class of bug this group exists for: the story called the recovered
    // object "the Green Page" in both locales, a hint said "it is green, and
    // flat like paper", and the art the child actually tapped was
    // `shapes/square.png`, which is orange. Nothing caught it, because every
    // individual file was internally valid.

    test('every adventure names reward art, and it exists', () {
      for (final Adventure adventure in bundle.adventures.values) {
        expect(adventure.rewardArt, isNotNull,
            reason: '${adventure.adventureId} hands over a page with no '
                'picture, so the child cannot be shown what they earned');
        expect(File(adventure.rewardArt!).existsSync(), isTrue,
            reason: '${adventure.adventureId} reward art '
                '"${adventure.rewardArt}" is missing');
      }
    });

    test('the object searched for is the object awarded', () {
      // A hidden_clue whose clue id matches the adventure reward IS that
      // reward. The two must be one picture, or the child searches for one
      // thing and is handed another.
      for (final Adventure adventure in bundle.adventures.values) {
        for (final StoryNode node in adventure.nodes) {
          if (!node.isActivity) {
            continue;
          }
          final ActivitySpec spec =
              bundle.requireActivity(node.activityRef!);
          if (spec.engineId != 'hidden_clue') {
            continue;
          }
          final List<dynamic> clues =
              spec.payload['clues'] as List<dynamic>? ?? <dynamic>[];
          for (final dynamic raw in clues) {
            final Map<dynamic, dynamic> clue = raw as Map<dynamic, dynamic>;
            if ('${clue['id']}' != adventure.rewardId) {
              continue;
            }
            expect('${clue['image']}', adventure.rewardArt,
                reason: '${spec.sourcePath}: the child searches for '
                    '"${clue['image']}" but ${adventure.adventureId} awards '
                    '"${adventure.rewardArt}". One object, one picture.');
          }
        }
      }
    });

    test('art referenced anywhere in an adventure exists on disk', () {
      for (final Adventure adventure in bundle.adventures.values) {
        for (final String? asset in <String?>[adventure.rewardArt]) {
          if (asset == null) {
            continue;
          }
          expect(File(asset).existsSync(), isTrue);
        }
      }
    });

    test('every asset path inside an activity payload exists on disk', () {
      // Only `rewardArt` used to be checked, so a mistyped path anywhere in a
      // payload - a clue image, a scene prop, a cover - shipped as a grey box
      // in a child's game and nothing failed. Walking the payload catches all
      // of them, including the fields no engine has invented yet.
      final List<String> missing = <String>[];

      void walk(Object? node, String where) {
        if (node is String) {
          if (node.startsWith('assets/') && !File(node).existsSync()) {
            missing.add('$where -> $node');
          }
          return;
        }
        if (node is List<dynamic>) {
          for (int index = 0; index < node.length; index++) {
            walk(node[index], '$where[$index]');
          }
          return;
        }
        if (node is Map<String, dynamic>) {
          node.forEach((String key, Object? value) {
            // `_comment` fields are prose and may mention a path in passing.
            if (!key.startsWith('_')) {
              walk(value, '$where.$key');
            }
          });
        }
      }

      for (final ActivitySpec spec in bundle.activities.values) {
        walk(spec.payload, spec.sourcePath);
      }
      expect(missing, isEmpty, reason: 'missing art: $missing');
    });
  });

  group('A sorting activity holds constant what it says it holds constant', () {
    test('every heldConstant attribute really is constant across its items', () {
      // `heldConstant` is a pedagogical claim: young children attend to the
      // most salient attribute even when it is irrelevant, so an activity
      // teaching "sort by habitat" while the sizes also vary risks teaching
      // size. The claim was documented in a comment and contradicted by the
      // content directly beneath it - three small animals and a lion.
      for (final ActivitySpec spec in bundle.activities.values) {
        if (spec.engineId != 'sorting') {
          continue;
        }
        final List<String> held =
            (spec.payload['heldConstant'] as List<dynamic>? ?? <dynamic>[])
                .map((e) => '$e')
                .toList();
        if (held.isEmpty) {
          continue;
        }
        final ItemPack pack = bundle.packResolver.require(
          '${spec.payload['itemsRef']}',
          debugPath: spec.sourcePath,
        );
        final List<PackItem> items = pack.select(
          (spec.payload['itemIds'] as List<dynamic>? ?? <dynamic>[])
              .map((e) => '$e')
              .toList(),
          debugPath: spec.sourcePath,
        );

        for (final String attribute in held) {
          final Set<String?> values = items
              .map((PackItem item) => item.attribute(attribute))
              .toSet();
          expect(values.length, 1,
              reason: '${spec.sourcePath} claims "$attribute" is held '
                  'constant, but its items span $values. Either the claim is '
                  'wrong or the cast is.');
        }
      }
    });
  });

  group('Counting rounds are authored, distinct and bilingual', () {
    List<Map<String, dynamic>> roundsOf(ActivitySpec spec) =>
        (spec.payload['rounds'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<String, dynamic>>();

    test('no two rounds ask the same question', () {
      // A repeat inside one activity reads to a child as the app being stuck,
      // not as a coincidence.
      for (final ActivitySpec spec in bundle.activities.values) {
        if (spec.engineId != 'counting') {
          continue;
        }
        final List<String> signatures = roundsOf(spec)
            .map((Map<String, dynamic> round) =>
                '${round['itemId']}:${round['targetCount']}')
            .toList();
        expect(signatures.toSet().length, signatures.length,
            reason: '${spec.sourcePath} repeats a round: $signatures');
      }
    });

    test('each round carries its own wording in every declared locale', () {
      for (final ActivitySpec spec in bundle.activities.values) {
        if (spec.engineId != 'counting') {
          continue;
        }
        for (final Map<String, dynamic> round in roundsOf(spec)) {
          for (final String field in <String>['prompt', 'revealLine']) {
            final LocalizedText text = LocalizedText.fromJson(round[field],
                debugPath: '${spec.sourcePath}.rounds.$field');
            for (final String locale in spec.locales) {
              expect(text.hasLanguage(locale), isTrue,
                  reason: '${spec.sourcePath}: a round has no "$locale" '
                      '$field, so that child would hear the generic prompt '
                      'three times running');
            }
          }
        }
      }
    });

    test('a round never interpolates a count into Arabic', () {
      // Arabic number-noun agreement is irregular - dual for 2, a broken plural
      // for 3-10, a singular accusative for 11+ - so a count substituted into a
      // template produces wrong Arabic. The same rule the narration block
      // already obeys, now applied where the counts actually live.
      final RegExp placeholder = RegExp(r'\{[a-zA-Z_]+\}');
      for (final ActivitySpec spec in bundle.activities.values) {
        if (spec.engineId != 'counting') {
          continue;
        }
        for (final Map<String, dynamic> round in roundsOf(spec)) {
          for (final String field in <String>['prompt', 'revealLine']) {
            final LocalizedText text = LocalizedText.fromJson(round[field],
                debugPath: '${spec.sourcePath}.rounds.$field');
            if (!text.hasLanguage('ar')) {
              continue;
            }
            expect(placeholder.hasMatch(text.resolve('ar')), isFalse,
                reason: '${spec.sourcePath}: a round Arabic $field is a '
                    'template. Author the sentence whole.');
          }
        }
      }
    });
  });

  group('Pattern rounds ask something that has to be read', () {
    List<Map<String, dynamic>> roundsOf(ActivitySpec spec) =>
        (spec.payload['rounds'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<String, dynamic>>();

    Iterable<ActivitySpec> patternActivities() => bundle.activities.values
        .where((ActivitySpec spec) => spec.engineId == 'patterns');

    test('every gap sits inside the strip it belongs to', () {
      for (final ActivitySpec spec in patternActivities()) {
        for (final Map<String, dynamic> round in roundsOf(spec)) {
          final int unit = (round['unit'] as List<dynamic>).length;
          final int repeats = (round['repeats'] as num?)?.toInt() ?? 3;
          final int length = unit * repeats;
          for (final dynamic gap in round['gaps'] as List<dynamic>) {
            expect(gap as int, lessThan(length),
                reason: '${spec.sourcePath}: round "${round['id']}" opens a '
                    'hole at $gap in a strip of $length');
          }
        }
      }
    });

    test('no round can be answered by copying one repeat back', () {
      // Holes that all land on the same position within the unit are one
      // question asked repeatedly: a child copies the tile a fixed distance
      // back and never works out what the unit is.
      for (final ActivitySpec spec in patternActivities()) {
        for (final Map<String, dynamic> round in roundsOf(spec)) {
          final int unit = (round['unit'] as List<dynamic>).length;
          final List<int> gaps =
              (round['gaps'] as List<dynamic>).cast<int>();
          if (gaps.length < 2) {
            continue;
          }
          expect(gaps.map((int gap) => gap % unit).toSet().length,
              greaterThan(1),
              reason: '${spec.sourcePath}: round "${round['id']}" asks the '
                  'same question in every hole');
        }
      }
    });

    test('no two rounds ask the same question', () {
      for (final ActivitySpec spec in patternActivities()) {
        final List<String> signatures = roundsOf(spec)
            .map((Map<String, dynamic> round) =>
                '${(round['unit'] as List<dynamic>).join('-')}'
                '|${(round['gaps'] as List<dynamic>).toList()..sort()}')
            .toList();
        expect(signatures.toSet().length, signatures.length,
            reason: '${spec.sourcePath} repeats a round: $signatures');
      }
    });

    test('a unit is never all one item', () {
      for (final ActivitySpec spec in patternActivities()) {
        for (final Map<String, dynamic> round in roundsOf(spec)) {
          final List<dynamic> unit = round['unit'] as List<dynamic>;
          expect(unit.toSet().length, greaterThan(1),
              reason: '${spec.sourcePath}: round "${round['id']}" repeats one '
                  'item, so there is no rule to find');
        }
      }
    });

    test('the tray always keeps a tile that belongs in no hole', () {
      // Without a spare, the last hole of a round is answerable by
      // elimination rather than by reading the pattern.
      for (final ActivitySpec spec in patternActivities()) {
        final int extras =
            (spec.payload['trayExtraCount'] as num?)?.toInt() ?? 1;
        expect(extras, greaterThanOrEqualTo(1),
            reason: '${spec.sourcePath} offers no decoy tile');
      }
    });

    test('each round carries its own wording in every declared locale', () {
      for (final ActivitySpec spec in patternActivities()) {
        for (final Map<String, dynamic> round in roundsOf(spec)) {
          for (final String field in <String>['prompt', 'revealLine']) {
            final LocalizedText text = LocalizedText.fromJson(round[field],
                debugPath: '${spec.sourcePath}.rounds.$field');
            for (final String locale in spec.locales) {
              expect(text.hasLanguage(locale), isTrue,
                  reason: '${spec.sourcePath}: a round has no "$locale" '
                      '$field');
            }
          }
        }
      }
    });
  });

  group('The thing being built is on screen', () {
    Iterable<ActivitySpec> staged() => bundle.activities.values.where(
        (ActivitySpec spec) => spec.presentation.stage != null);

    test('every stage names art that exists on disk', () {
      for (final ActivitySpec spec in staged()) {
        final String art = spec.presentation.stage!.art;
        expect(File(art).existsSync(), isTrue,
            reason: '${spec.sourcePath} stages "$art", which is not on disk');
      }
    });

    test('a stage is used where the board does not already show the work', () {
      // The stage exists so an activity's progress is a picture of the thing
      // being made rather than a counter. It is deliberately NOT on every
      // activity: a scene being uncovered, a line being drawn and a gate being
      // opened are already the world changing, and a stage on top of those
      // would say the same thing twice.
      final Set<String> staffed =
          staged().map((ActivitySpec spec) => spec.instanceId).toSet();
      expect(staffed, isNotEmpty,
          reason: 'nothing uses the stage, so the knob is dead');
      for (final ActivitySpec spec in staged()) {
        expect(
          const <String>{'hidden_clue', 'trace_path', 'patterns'},
          isNot(contains(spec.engineId)),
          reason: '${spec.sourcePath} stages progress its own board already '
              'shows',
        );
      }
    });
  });

  group('A locked destination promises without spoiling', () {
    test('an upcoming id is never a real adventure id', () {
      // They are separate lists for a reason: `adventures` is validated to name
      // playable content, `upcoming` names places that do not exist yet.
      for (final StoryArc arc in bundle.arcs.values) {
        for (final UpcomingDestination destination in arc.upcoming) {
          expect(bundle.adventures.containsKey(destination.id), isFalse,
              reason: 'arc "${arc.arcId}" lists "${destination.id}" as '
                  'upcoming, but it is a real adventure - move it into '
                  '`adventures` so it can be played');
          expect(arc.adventureIds, isNot(contains(destination.id)));
        }
      }
    });

    test('an upcoming destination is named in every locale', () {
      for (final StoryArc arc in bundle.arcs.values) {
        for (final UpcomingDestination destination in arc.upcoming) {
          for (final String locale in declaredLocales()) {
            expect(destination.title.resolve(locale), isNotEmpty,
                reason: 'a stop with no name in "$locale" is a blank on the '
                    'map, which promises nothing');
          }
        }
      }
    });

    test('a teaser stays short enough to be a tease', () {
      for (final StoryArc arc in bundle.arcs.values) {
        for (final UpcomingDestination destination in arc.upcoming) {
          for (final String locale in declaredLocales()) {
            expect(destination.peek.resolve(locale).length,
                lessThanOrEqualTo(90),
                reason: '"${destination.id}" gives away too much of a chapter '
                    'the child has not reached');
          }
        }
      }
    });
  });

  group('Registry architecture', () {
    test('no two reusable engines claim the same capability', () {
      // The teeth of the reuse ladder: the likeliest way this design fails is
      // one developer building ten engines that are really four.
      expect(buildDefaultEngineRegistry, returnsNormally);
    });

    test('a bespoke engine must justify itself', () {
      for (final ActivityEngine<ActivityContent> engine in registry.engines) {
        if (engine.descriptor.kind != EngineKind.bespoke) {
          continue;
        }
        expect(engine.descriptor.justification, isNotEmpty,
            reason: '${engine.engineId} is bespoke with no justification');
      }
    });

    test('the bespoke folder is empty', () {
      final Directory bespoke =
          Directory('lib/features/Adventure/engine/bespoke');
      if (!bespoke.existsSync()) {
        return;
      }
      final List<File> files = bespoke
          .listSync()
          .whereType<File>()
          .where((File file) => file.path.endsWith('.dart'))
          .toList();
      expect(files, isEmpty,
          reason: 'bespoke engines exist: ${files.map((f) => f.path)}. That is '
              'allowed, but it should be a deliberate, visible decision.');
    });
  });
}
