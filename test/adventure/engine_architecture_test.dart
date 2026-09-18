import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';

/// The rules that keep an engine from becoming a screen.
///
/// These exist because of a specific, documented failure in this codebase:
/// `QuizEngineScreen` was written as a shared screen with no extension points,
/// so its one real consumer wrote 280 lines of its own layout and never used
/// it. A grep test is a blunt instrument, but it is the only kind that still
/// works in six months when the reason has been forgotten.
void main() {
  const String engineDir = 'lib/features/Adventure/engine/engines';

  List<File> engineSources() {
    final Directory dir = Directory(engineDir);
    if (!dir.existsSync()) {
      return const <File>[];
    }
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .toList();
  }

  /// Source with `//` comment lines removed, so prose explaining a rule does
  /// not trip the rule.
  String codeOf(File file) => file
      .readAsStringSync()
      .split('\n')
      .where((String line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  setUpAll(() {
    expect(engineSources(), isNotEmpty,
        reason: 'found no engine sources to check — the path is probably wrong, '
            'and these tests would pass vacuously');
  });

  group('Engines own no chrome', () {
    void forbid(String needle, String why) {
      test('no "$needle"', () {
        final List<String> offenders = <String>[];
        for (final File file in engineSources()) {
          if (codeOf(file).contains(needle)) {
            offenders.add(file.path);
          }
        }
        expect(offenders, isEmpty, reason: '$why\nOffenders: $offenders');
      });
    }

    forbid(
      'Scaffold(',
      'The host owns the Scaffold. An engine that builds its own is building a '
      'screen, which is how the previous quiz engine ended up unusable.',
    );
    forbid(
      'AppBar(',
      'The host owns the top bar. An AppBar here also means hardcoded titles, '
      'which is how English literals got into a bilingual app.',
    );
    forbid(
      'MediaQuery.of',
      'Boards size themselves from the LayoutBuilder constraints they are given '
      '(KidMetrics), not from the window. Reading the window is what broke '
      'layout inside the tablet split view.',
    );
    forbid(
      'AppLocalizations',
      'Engines never touch the app localization file. Content carries its own '
      'per-locale text, which is what lets hundreds of story strings ship '
      'without editing a 700-getter class.',
    );
    forbid(
      'Navigator.of',
      'An engine does not decide what happens next. The host reports a result '
      'and the story layer navigates.',
    );
    forbid(
      'showDialog',
      'A dialog is chrome. The host owns it.',
    );
  });

  group('Engines hardcode no colours', () {
    test('no Color(0x literals', () {
      // `Color(0xfffaf5f1)` in the old quiz screen is exactly why every game
      // drifted apart visually. Colours come from KidUi or from content.
      final List<String> offenders = <String>[];
      for (final File file in engineSources()) {
        if (RegExp(r'Color\(0x').hasMatch(codeOf(file))) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty, reason: 'hardcoded colours in: $offenders');
    });
  });

  group('Engines name no domain', () {
    test('no engine source mentions a specific content item', () {
      // The platform's whole claim is that one counting engine counts animals
      // in the Jungle, fruit in the Market and stars in Space. The moment
      // "monkey" appears in the engine, that claim is false.
      const List<String> domainWords = <String>[
        'monkey',
        'elephant',
        'banana',
        'jungle',
        'market',
        'giraffe',
      ];
      final List<String> offenders = <String>[];
      for (final File file in engineSources()) {
        final String lower = codeOf(file).toLowerCase();
        for (final String word in domainWords) {
          if (lower.contains(word)) {
            offenders.add('${file.path} mentions "$word"');
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'engines must stay domain-free: $offenders');
    });
  });

  group('Registry', () {
    late ActivityEngineRegistry registry;

    setUpAll(() => registry = buildDefaultEngineRegistry());

    test('building the default registry does not throw', () {
      // Capability uniqueness is asserted inside the constructor.
      expect(buildDefaultEngineRegistry, returnsNormally);
    });

    test('two reusable engines claiming one capability is rejected', () {
      // Proving the guard actually fires, rather than trusting that it would.
      final ActivityEngine<ActivityContent> first =
          registry.require('counting');
      expect(
        () => ActivityEngineRegistry(<ActivityEngine<ActivityContent>>[
          first,
          _CloneEngine(first.descriptor),
        ]),
        throwsA(isA<EngineRegistryException>()),
      );
    });

    test('a duplicate engineId is rejected', () {
      final ActivityEngine<ActivityContent> first =
          registry.require('counting');
      expect(
        () => ActivityEngineRegistry(<ActivityEngine<ActivityContent>>[
          first,
          first,
        ]),
        throwsA(isA<EngineRegistryException>()),
      );
    });

    test('every registered engine declares at least one parameter', () {
      for (final ActivityEngine<ActivityContent> engine in registry.engines) {
        expect(engine.descriptor.contentParameters, isNotEmpty,
            reason: '${engine.engineId} accepts no content, so it cannot be '
                'reused — it is a one-off wearing an engine costume');
      }
    });

    test('every registered engine declares a locale it can be authored in', () {
      for (final ActivityEngine<ActivityContent> engine in registry.engines) {
        expect(engine.descriptor.supportedLocales, isNotEmpty);
      }
    });

    test('no reusable engine silently claims Arabic it cannot deliver', () {
      // A literacy-shaped engine needs ~110 pre-shaped glyphs and connected
      // contextual forms before it can honestly say 'ar'. None exist yet, so
      // any engine claiming Arabic must be one of the direction-agnostic
      // mechanics.
      const Set<String> literacyDomains = <String>{'literacy'};
      for (final ActivityEngine<ActivityContent> engine in registry.engines) {
        final bool isLiteracy = engine.descriptor.learningDomains
            .map((LearningDomain d) => d.name)
            .any(literacyDomains.contains);
        if (isLiteracy) {
          expect(engine.descriptor.supportedLocales, <String>{'en'},
              reason: '${engine.engineId} is literacy-shaped, so it cannot '
                  'claim Arabic until Arabic letterform content exists');
        }
      }
    });
  });

  group('The bespoke folder', () {
    test('is empty, and that is the point', () {
      final Directory bespoke =
          Directory('lib/features/Adventure/engine/bespoke');
      if (!bespoke.existsSync()) {
        return;
      }
      final List<File> files = bespoke
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => file.path.endsWith('.dart'))
          .toList();
      expect(files, isEmpty,
          reason: 'a bespoke engine is allowed, but it should cost a visible '
              'diff and a conversation: ${files.map((f) => f.path)}');
    });
  });
}

/// An engine that copies another's capability key, to prove the guard fires.
class _CloneEngine extends ActivityEngine<ActivityContent> {
  _CloneEngine(ActivityEngineDescriptor original)
      : descriptor = ActivityEngineDescriptor(
          engineId: '${original.engineId}_clone',
          kind: original.kind,
          learningDomains: original.learningDomains,
          interactionModes: original.interactionModes,
          contentParameters: original.contentParameters,
          adaptationAxis: original.adaptationAxis,
          supportedLocales: original.supportedLocales,
        );

  @override
  final ActivityEngineDescriptor descriptor;

  @override
  ActivityContent parseContent(ActivitySpec spec, Object packs) =>
      throw UnimplementedError();

  @override
  Never createCubit(Object session) => throw UnimplementedError();

  @override
  Never createBoard() => throw UnimplementedError();
}
