import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_narrator.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/ui/story_beat_view.dart';

import 'support/disk_content_source.dart';

/// Layout, at the sizes that actually broke things before.
///
/// This codebase already has `kidFitCardSize` precisely because trays
/// overflowed when a round added one more choice on a small phone. So every
/// board is pumped at a narrow phone, a short landscape window and a tablet,
/// and `takeException()` must come back null each time.
void main() {
  late AdventureContentBundle bundle;
  late ActivityEngineRegistry registry;

  setUpAll(() async {
    registry = buildDefaultEngineRegistry();
    bundle = await const AdventureContentLoader(DiskAdventureContentSource())
        .load();
  });

  /// The sizes that matter, not a comfortable default.
  const List<Size> testSizes = <Size>[
    Size(360, 640), // small phone, portrait
    Size(780, 390), // phone, landscape
    Size(800, 1200), // tablet
  ];

  Future<ActivityCubit<ActivityContent, dynamic>> startedCubit(
    String activityId, {
    String languageCode = 'en',
  }) async {
    final ActivitySpec spec = bundle.requireActivity(activityId);
    final ActivityEngine<ActivityContent> engine =
        registry.require(spec.engineId);
    final ActivityCubit<ActivityContent, dynamic> cubit =
        engine.createCubit(engine.createSession(
      spec: spec,
      services: ActivityServices.forTest(languageCode: languageCode),
      packs: bundle.packResolver,
    ));
    await cubit.start();
    return cubit;
  }

  Future<void> pumpBoard(
    WidgetTester tester, {
    required String activityId,
    required Size size,
    String languageCode = 'en',
    List<ActivityAttempt> submitted = const <ActivityAttempt>[],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ActivitySpec spec = bundle.requireActivity(activityId);
    final ActivityEngine<ActivityContent> engine =
        registry.require(spec.engineId);
    final ActivityCubit<ActivityContent, dynamic> cubit =
        await startedCubit(activityId, languageCode: languageCode);
    addTearDown(cubit.close);

    final ActivityBoardBuilder board = engine.createBoard();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => board(
            context,
            cubit.state,
            submitted.add,
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  group('Every board lays out without overflow', () {
    for (final Size size in testSizes) {
      testWidgets('at ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
        for (final String activityId in bundle.activities.keys) {
          await pumpBoard(
            tester,
            activityId: activityId,
            size: size,
          );
          expect(tester.takeException(), isNull,
              reason: '$activityId overflowed at $size');
        }
      });
    }

    testWidgets('and in Arabic, where text is longer and taller',
        (WidgetTester tester) async {
      for (final Size size in testSizes) {
        for (final String activityId in bundle.activities.keys) {
          await pumpBoard(
            tester,
            activityId: activityId,
            size: size,
            languageCode: 'ar',
          );
          expect(tester.takeException(), isNull,
              reason: '$activityId overflowed in Arabic at $size');
        }
      }
    });
  });

  group('Boards are completable by tap alone', () {
    // Drag succeeds as little as 30% of the time for some school-age children,
    // and WCAG 2.2 SC 2.5.7 requires a single-pointer alternative to every
    // drag. So every interactive element must be reachable without dragging.
    testWidgets('every board exposes tappable targets',
        (WidgetTester tester) async {
      for (final String activityId in bundle.activities.keys) {
        final List<ActivityAttempt> submitted = <ActivityAttempt>[];
        await pumpBoard(
          tester,
          activityId: activityId,
          size: const Size(360, 640),
          submitted: submitted,
        );
        final Finder tappable = find.byType(GestureDetector);
        expect(tappable, findsWidgets,
            reason: '$activityId has nothing a child can tap');
      }
    });
  });

  group('ActivityGlyphText', () {
    testWidgets('Arabic renders right-to-left', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ActivityGlyphText('مَرْحَبًا', languageCode: 'ar'),
        ),
      ));
      final Directionality directionality = tester.widget<Directionality>(
        find
            .descendant(
              of: find.byType(ActivityGlyphText),
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('English renders left-to-right even inside an RTL app',
        (WidgetTester tester) async {
      // Direction follows the *text*, not the surrounding layout, so a Latin
      // label inside an Arabic screen still reads correctly.
      await tester.pumpWidget(const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: ActivityGlyphText('Hello', languageCode: 'en'),
          ),
        ),
      ));
      final Directionality directionality = tester.widget<Directionality>(
        find
            .descendant(
              of: find.byType(ActivityGlyphText),
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(directionality.textDirection, TextDirection.ltr);
    });

    test('Arabic gets the optical size bump', () {
      // Harakat sit above and below the baseline, so Arabic set at the Latin
      // size reads smaller and the marks blur together.
      expect(ActivityGlyphText.opticalSizeFor('ar', 20),
          greaterThan(ActivityGlyphText.opticalSizeFor('en', 20)));
    });
  });

  group('StoryBeatView', () {
    testWidgets('reveals one line at a time, then continues',
        (WidgetTester tester) async {
      final Adventure adventure = bundle.requireAdventure('jungle');
      final StoryNode node = adventure.nodes
          .firstWhere((StoryNode n) => !n.isActivity && n.lines.length > 1);

      int continued = 0;
      final RecordingActivityNarrator narrator = RecordingActivityNarrator();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StoryBeatView(
            node: node,
            languageCode: 'en',
            onSpeak: narrator.speak,
            onContinue: () => continued++,
            continueLabel: 'Next',
          ),
        ),
      ));
      await tester.pump();

      expect(find.text(node.lines.first.resolve('en')), findsOneWidget);
      expect(find.text(node.lines[1].resolve('en')), findsNothing,
          reason: 'a wall of text a pre-reader cannot read is not a story');

      await tester.tap(find.byType(StoryBeatView));
      await tester.pump();
      expect(find.text(node.lines[1].resolve('en')), findsOneWidget);
      expect(continued, 0);

      await tester.tap(find.byType(StoryBeatView));
      await tester.pump();
      expect(continued, 1);
    });

    testWidgets('speaks each line as it appears', (WidgetTester tester) async {
      final Adventure adventure = bundle.requireAdventure('jungle');
      final StoryNode node = adventure.nodes
          .firstWhere((StoryNode n) => !n.isActivity && n.lines.length > 1);
      final RecordingActivityNarrator narrator = RecordingActivityNarrator();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StoryBeatView(
            node: node,
            languageCode: 'en',
            onSpeak: narrator.speak,
            onContinue: () {},
            continueLabel: 'Next',
          ),
        ),
      ));
      await tester.pump();
      expect(narrator.spoken.length, 1,
          reason: 'audio is primary for a pre-reader; text is decoration');

      await tester.tap(find.byType(StoryBeatView));
      await tester.pump();
      expect(narrator.spoken.length, 2);
    });

    testWidgets('works in Arabic without overflow at phone size',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final Adventure adventure = bundle.requireAdventure('jungle');
      for (final StoryNode node in adventure.nodes) {
        if (node.isActivity) {
          continue;
        }
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StoryBeatView(
              node: node,
              languageCode: 'ar',
              onSpeak: (String _) async {},
              onContinue: () {},
              continueLabel: 'التَّالِي',
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: '${node.nodeId} overflowed in Arabic');
      }
    });
  });

  group('Touch targets', () {
    test('primary engine targets use the young-child minimum', () {
      // NN/g's guidance for young children is about 2cm, roughly 96-120dp -
      // four times the adult minimum. 76dp chrome is not good enough for
      // something a child aims at to answer.
      expect(KidUi.minTouchYoung, greaterThanOrEqualTo(96));
      expect(KidUi.minTouchYoung, greaterThan(KidUi.minTouch));
    });
  });
}
