import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/multiple_choice/multiple_choice_engine.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_narrator.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';
import 'package:kidzo/features/Adventure/engine/support/number_words.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/rewards/adventure_reward.dart';
import 'package:kidzo/features/Adventure/story/rewards/adventure_reward_overlay.dart';
import 'package:kidzo/features/Adventure/story/ui/journey_trail.dart';

import 'support/disk_content_source.dart';

/// The polish pass, pinned.
///
/// Everything here is a thing that was wrong when Adventure 1 was played end to
/// end, expressed as the behaviour that replaced it. They are grouped by the
/// symptom a child would have hit, not by the file that changed, because that
/// is what a future reader needs to know before "simplifying" one of them away.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdventureContentBundle bundle;
  late ActivityEngineRegistry registry;

  late AppLocalizations englishL10n;

  setUpAll(() async {
    registry = buildDefaultEngineRegistry();
    bundle = await const AdventureContentLoader(DiskAdventureContentSource())
        .load();
    englishL10n = AppLocalizations(
      const Locale('en', ''),
      (json.decode(File('assets/lang/en.json').readAsStringSync())
              as Map<String, dynamic>)
          .map((String key, dynamic value) =>
              MapEntry<String, String>(key, '$value')),
    );
  });

  RecordingActivityNarrator narrator = RecordingActivityNarrator();

  ActivityCubit<ActivityContent, dynamic> cubitFor(
    String activityId, {
    String languageCode = 'en',
    int seed = 11,
  }) {
    narrator = RecordingActivityNarrator();
    final ActivitySpec spec = bundle.requireActivity(activityId);
    final ActivityEngine<ActivityContent> engine =
        registry.require(spec.engineId);
    return engine.createCubit(engine.createSession(
      spec: spec,
      services: ActivityServices(
        narrator: narrator,
        soundboard: RecordingActivitySoundboard(),
        random: Random(seed),
        languageCode: languageCode,
      ),
      packs: bundle.packResolver,
      storyNodeId: 'test.node',
    ));
  }

  group('The story is spoken, not just stored', () {
    test('a correct answer speaks the clue the next beat depends on', () async {
      // Regression, and the worst one found. Every multiple_choice question
      // carries an authored `revealLine` - "the monkey says: something green
      // flew past the tall trees" - and nothing ever spoke it. The child picked
      // the monkey, heard a chime, and was told nothing; the beat afterwards
      // then talked as though they had been told.
      final MultipleChoiceCubit cubit =
          cubitFor('jungle_ask_animals') as MultipleChoiceCubit;
      await cubit.start();

      final MultipleChoiceStep step = cubit.currentStep;
      final String reveal = step.question.revealLine.resolve('en');
      expect(reveal, isNotEmpty, reason: 'fixture has nothing to reveal');

      await cubit.submit(ChoiceAttempt(step.question.correctItem.id));

      expect(narrator.spoken, contains(reveal));
      await cubit.close();
    });

    test('the clue is still spoken for a child who needed every hint',
        () async {
      // Withholding the story from the one child who used the whole ladder
      // would be exactly backwards.
      final MultipleChoiceCubit cubit =
          cubitFor('jungle_ask_animals') as MultipleChoiceCubit;
      await cubit.start();
      final String reveal = cubit.currentStep.question.revealLine.resolve('en');

      for (int attempt = 0; attempt < 4; attempt++) {
        await cubit.submit(const ChoiceAttempt('__definitely_wrong__'));
      }

      expect(narrator.spoken, contains(reveal));
      await cubit.close();
    });

    test('the closing line is spoken once, at the end', () async {
      // `narration.success` was authored for every activity and spoken by
      // none. It is the payoff line - "nine watchers in all" - so it belongs at
      // the end and nowhere else: after every step it would be wallpaper.
      final CountingCubit cubit =
          cubitFor('jungle_count_watchers') as CountingCubit;
      await cubit.start();
      final String success =
          cubit.spec.narration.success.resolve('en');

      while (cubit.state.status == ActivityStatus.running) {
        await cubit.submit(QuantityAttempt(cubit.currentStep.targetCount));
      }

      expect(
        narrator.spoken.where((String line) => line == success).length,
        1,
        reason: 'the closing line must land exactly once',
      );
      expect(narrator.spoken.last, success);
      await cubit.close();
    });

    test('backing out says nothing and celebrates nothing', () async {
      final CountingCubit cubit =
          cubitFor('jungle_count_watchers') as CountingCubit;
      await cubit.start();
      final String success = cubit.spec.narration.success.resolve('en');

      await cubit.abandon();

      expect(narrator.spoken, isNot(contains(success)));
      expect(narrator.cancelCount, greaterThan(0),
          reason: 'leaving must silence whatever was mid-sentence');
      await cubit.close();
    });
  });

  group('Counting out loud', () {
    test('a tally speaks the number and is not an attempt', () async {
      final CountingCubit cubit =
          cubitFor('jungle_count_watchers') as CountingCubit;
      await cubit.start();
      final int before = cubit.state.stepIndex;

      await cubit.submit(const TallyAttempt(1));
      await cubit.submit(const TallyAttempt(2));
      await cubit.submit(const TallyAttempt(3));

      expect(narrator.spoken.sublist(narrator.spoken.length - 3),
          <String>['one', 'two', 'three']);
      expect(cubit.state.stepIndex, before,
          reason: 'counting is not answering');
      expect(cubit.state.scaffoldLevel, ScaffoldLevel.initial,
          reason: 'a tally must never burn a rung of the ladder');
      await cubit.close();
    });

    test('the numbers are spoken in Arabic, not read out as digits', () async {
      final CountingCubit cubit =
          cubitFor('jungle_count_watchers', languageCode: 'ar')
              as CountingCubit;
      await cubit.start();

      await cubit.submit(const TallyAttempt(3));

      expect(narrator.spoken.last, 'ثَلَاثَة');
      await cubit.close();
    });

    test('digits are shown in the script the child is reading', () {
      expect(NumberWords.digits(3, 'en'), '3');
      expect(NumberWords.digits(3, 'ar'), '٣');
      expect(NumberWords.digits(10, 'ar'), '١٠');
    });
  });

  group('The counting board', () {
    Future<CountingCubit> pumpBoard(
      WidgetTester tester, {
      String languageCode = 'en',
      Size size = const Size(390, 780),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final CountingCubit cubit =
          cubitFor('jungle_count_watchers', languageCode: languageCode)
              as CountingCubit;
      await cubit.start();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CountingBoard(
            step: cubit.currentStep,
            state: cubit.state,
            submit: cubit.submit,
            languageCode: languageCode,
          ),
        ),
      ));
      await tester.pump();
      return cubit;
    }

    /// The number on the tally strip, as the child sees it.
    String tally(WidgetTester tester) {
      final Finder text = find.descendant(
        of: find.byKey(countTotalKey),
        matching: find.byType(Text),
      );
      return tester.widget<Text>(text.first).data!;
    }

    testWidgets('tapping an item counts it, and the total is on screen',
        (WidgetTester tester) async {
      // A count the child cannot see is a count they have to hold in their
      // head while also tracking which animals they already touched.
      final CountingCubit cubit = await pumpBoard(tester);
      addTearDown(cubit.close);

      expect(tally(tester), '0');

      await tester.tap(find.byKey(countableKey(0)));
      await tester.pumpAndSettle();
      expect(tally(tester), '1');

      await tester.tap(find.byKey(countableKey(1)));
      await tester.pumpAndSettle();
      expect(tally(tester), '2');
    });

    testWidgets('the same object cannot be counted twice',
        (WidgetTester tester) async {
      // Regression, and the one that actively misled. Tapping an item used to
      // *toggle* it, so a child who double-tapped silently lost a count and had
      // no way to see why. Now the second tap does nothing at all.
      final CountingCubit cubit = await pumpBoard(tester);
      addTearDown(cubit.close);

      for (int tap = 0; tap < 3; tap++) {
        await tester.tap(find.byKey(countableKey(0)));
        await tester.pumpAndSettle();
      }

      expect(tally(tester), '1',
          reason: 'a re-tap must neither add to the count nor take it back');
    });

    testWidgets('counting every item marks the total as complete',
        (WidgetTester tester) async {
      final CountingCubit cubit = await pumpBoard(tester);
      addTearDown(cubit.close);
      final int target = cubit.currentStep.targetCount;

      for (int index = 0; index < target; index++) {
        await tester.tap(find.byKey(countableKey(index)));
        await tester.pumpAndSettle();
      }

      expect(tally(tester), '$target');
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget,
          reason: 'the final total has to be obvious, not inferred');
    });

    testWidgets('a miscounted scene can be started over',
        (WidgetTester tester) async {
      final CountingCubit cubit = await pumpBoard(tester);
      addTearDown(cubit.close);

      await tester.tap(find.byKey(countableKey(0)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      await tester.tap(find.byKey(countResetKey));
      await tester.pumpAndSettle();
      expect(tally(tester), '0');
    });

    testWidgets('countable items are big enough for a young child to hit',
        (WidgetTester tester) async {
      // The old board clamped item size to a *maximum* of KidUi.minTouchYoung -
      // the young-child floor used as a ceiling - and produced 56dp animals on
      // a phone. A counting target is a primary target.
      for (final Size size in <Size>[
        const Size(360, 640),
        const Size(780, 390),
        const Size(800, 1200),
      ]) {
        final CountingCubit cubit = await pumpBoard(tester, size: size);
        final Size item =
            tester.getSize(find.byKey(countableKey(0)).first);
        expect(item.width, greaterThanOrEqualTo(72),
            reason: 'countable items too small at $size');
        expect(tester.takeException(), isNull);
        await cubit.close();
      }
    });

    testWidgets('lays out in Arabic at every size without overflow',
        (WidgetTester tester) async {
      for (final Size size in <Size>[
        const Size(360, 640),
        const Size(780, 390),
        const Size(800, 1200),
      ]) {
        final CountingCubit cubit =
            await pumpBoard(tester, languageCode: 'ar', size: size);
        expect(tester.takeException(), isNull, reason: 'overflowed at $size');
        // Eastern Arabic-Indic zero, not "0".
        expect(tally(tester), '٠');
        await cubit.close();
      }
    });
  });

  group('The Green Page is actually green', () {
    test('the reward art the story calls green reads as green', () async {
      // The literal bug this pass started from: the page the child searched for
      // was `shapes/square.png`, which is orange, while both locales called it
      // the Green Page and a hint said "it is green, and flat like paper".
      // Asserting the words match the picture is not something a schema can do,
      // so the test looks at the pixels.
      final Adventure jungle = bundle.requireAdventure('jungle');
      expect(jungle.rewardArt, isNotNull);

      final ByteData data = await rootBundle.load(jungle.rewardArt!);
      final ui.Codec codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ByteData? pixels =
          await frame.image.toByteData();
      expect(pixels, isNotNull);

      int green = 0;
      int opaque = 0;
      final Uint8List bytes = pixels!.buffer.asUint8List();
      for (int offset = 0; offset + 3 < bytes.length; offset += 4) {
        if (bytes[offset + 3] < 200) {
          continue;
        }
        opaque++;
        final int r = bytes[offset];
        final int g = bytes[offset + 1];
        final int b = bytes[offset + 2];
        if (g > r + 12 && g > b + 12) {
          green++;
        }
      }

      expect(opaque, greaterThan(0), reason: 'the art is empty');
      expect(green / opaque, greaterThan(0.8),
          reason: 'the Green Page is not green; ${jungle.rewardArt} is what '
              'the child is told to look for');
    });
  });

  group('Recovering the page is a moment', () {
    /// The reward the jungle actually hands over, built the way the runner
    /// builds it.
    AdventureReward jungleReward() {
      final Adventure jungle = bundle.requireAdventure('jungle');
      return AdventureReward(
        rewardId: jungle.rewardId,
        adventureId: jungle.adventureId,
        title: jungle.rewardTitle,
        art: jungle.rewardArt,
        accentValue: jungle.accentColorValue,
      );
    }

    Future<int> pumpCelebration(
      WidgetTester tester, {
      String languageCode = 'en',
      Offset? destination,
      Duration runFor = AdventureRewardOverlay.duration,
    }) async {
      int done = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdventureRewardOverlay(
            // A fresh key per pump. The overlay is built to be created once and
            // then removed, so without this the second pump reuses the state of
            // an animation that has already finished.
            key: UniqueKey(),
            reward: jungleReward(),
            languageCode: languageCode,
            destination: destination,
            caption: languageCode == 'ar' ? 'عَادَتْ صَفْحَة!' : 'A page came home!',
            onDone: () => done++,
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(runFor);
      await tester.pump(const Duration(milliseconds: 32));
      return done;
    }

    testWidgets('shows the page the child recovered, then hands it over',
        (WidgetTester tester) async {
      // The page has to be the page: the same picture they searched for and the
      // same one that will be sitting in the book afterwards. A generic
      // "achievement" glyph here would quietly make the reward abstract.
      final Adventure jungle = bundle.requireAdventure('jungle');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdventureRewardOverlay(
            reward: jungleReward(),
            languageCode: 'en',
            onDone: () {},
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final Image page = tester.widget<Image>(find.byType(Image).first);
      expect((page.image as AssetImage).assetName, jungle.rewardArt);
      expect(find.text(jungle.rewardTitle.resolve('en')), findsOneWidget);
    });

    testWidgets('finishes on its own, exactly once',
        (WidgetTester tester) async {
      // The story is blocked behind this callback. If it never fires, the child
      // is stuck looking at a page forever; if it fires twice, the beat behind
      // it advances twice.
      final int done = await pumpCelebration(tester);
      expect(done, 1);
    });

    testWidgets('can be skipped by a child who has seen it before',
        (WidgetTester tester) async {
      int done = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdventureRewardOverlay(
            reward: jungleReward(),
            languageCode: 'en',
            onDone: () => done++,
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(AdventureRewardOverlay));
      await tester.pump();
      expect(done, 1, reason: 'a tap must end it immediately');

      // And the timer that would have fired later must not fire again.
      await tester.pump(AdventureRewardOverlay.duration);
      await tester.pump(const Duration(milliseconds: 32));
      expect(done, 1);
    });

    testWidgets('lands on the book wherever the book happens to be',
        (WidgetTester tester) async {
      // The destination is passed in from the real widget position rather than
      // assumed, because a page that flies to a corner with nothing in it has
      // not been put anywhere.
      final int done = await pumpCelebration(
        tester,
        destination: const Offset(320, 40),
      );
      expect(done, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('runs in Arabic at phone and tablet sizes',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final Size size in <Size>[
        const Size(360, 640),
        const Size(780, 390),
        const Size(800, 1200),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        final int done = await pumpCelebration(tester, languageCode: 'ar');
        expect(done, 1);
        expect(tester.takeException(), isNull, reason: 'broke at $size');
      }
    });

    test('the reward book is built from content, not from a hardcoded list',
        () {
      // What makes the celebration reusable: Adventure 2 gets the same moment
      // by authoring a reward, not by anyone editing this feature.
      final AdventureRewardBook book = AdventureRewardBook.fromBundle(
        bundle: bundle,
        arc: bundle.primaryArc,
        earnedIds: const <String>{'green_page'},
      );
      expect(book.total, bundle.primaryArc.adventureIds.length);
      expect(book.earnedCount, 1);
      expect(book.byRewardId('green_page'), isNotNull);
      expect(book.forAdventure('jungle')?.art, isNotNull);
      expect(book.isEarned(book.forAdventure('jungle')!), isTrue);
    });
  });

  group('The map reads as a journey, not as a list', () {
    /// Renders a whole trail with the localizations a real screen would have.
    Future<void> pumpTrail(
      WidgetTester tester,
      List<MapStop> stops, {
      void Function(MapStop stop)? onOpen,
    }) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en', ''),
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          _SynchronousLocalizations(englishL10n),
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                JourneyTrail(
              stops: stops,
              languageCode: 'en',
              metrics: KidMetrics.of(constraints),
              controller: controller,
              topInset: 0,
              statusLabelFor: _statusLabel,
              onOpen: onOpen,
            ),
          ),
        ),
      ));
      // Not pumpAndSettle: the bead the child should play next breathes on a
      // repeating controller, so nothing on this screen is ever "settled". A
      // handful of frames instead, which is also what the asynchronous
      // localization delegate needs before any label exists to assert on.
      for (int frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    const MapStop market = MapStop(
      id: 'market',
      title: LocalizedText(<String, String>{'en': 'The Market'}),
      teaser: LocalizedText.empty(),
      state: MapStopState.comingSoon,
      icon: 'market',
    );

    const MapStop current = MapStop(
      id: 'jungle',
      title: LocalizedText(<String, String>{'en': 'The Green Page'}),
      teaser: LocalizedText.empty(),
      state: MapStopState.open,
    );

    testWidgets('names do not take permanent space beside every bead',
        (WidgetTester tester) async {
      // The redesign, as an assertion. A name printed next to every stop is
      // what made the old map read as a stepper; only the bead the child is on
      // wears its name, and the rest answer when asked.
      await pumpTrail(tester, <MapStop>[current, market]);

      expect(find.text('The Green Page'), findsOneWidget,
          reason: 'the current bead says where the child is');
      expect(find.text('The Market'), findsNothing,
          reason: 'a name beside every bead is the stepper being rebuilt');
    });

    testWidgets('a place that is not written yet is shown, and names itself '
        'on demand, but cannot be played', (WidgetTester tester) async {
      // All three at once is the point. Hiding it entirely makes the map a
      // single button; showing it as playable lies; showing its story spends
      // the surprise before the child gets there.
      int opened = 0;
      await pumpTrail(
        tester,
        <MapStop>[market],
        onOpen: (MapStop _) => opened++,
      );

      // The motif the content authored, rather than one padlock for every
      // unwritten place.
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      expect(find.text('The Market'), findsNothing);

      await tester.tap(find.byIcon(Icons.storefront_rounded));
      await tester.pump();

      expect(find.text('The Market'), findsOneWidget);
      expect(opened, 0, reason: 'it is not a place the child can go');
    });

    testWidgets('an unwritten place with no motif still reads as shut',
        (WidgetTester tester) async {
      await pumpTrail(tester, const <MapStop>[
        MapStop(
          id: 'somewhere',
          title: LocalizedText(<String, String>{'en': 'Somewhere'}),
          teaser: LocalizedText.empty(),
          state: MapStopState.comingSoon,
        ),
      ]);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('a locked stop gives nothing away until it is earned',
        (WidgetTester tester) async {
      await pumpTrail(tester, <MapStop>[market]);
      await tester.tap(find.byIcon(Icons.storefront_rounded));
      await tester.pump();
      expect(find.textContaining('busy market'), findsNothing);

      await pumpTrail(tester, const <MapStop>[
        MapStop(
          id: 'market',
          title: LocalizedText(<String, String>{'en': 'The Market'}),
          teaser: LocalizedText(<String, String>{
            'en': 'A page blew into a busy market.',
          }),
          state: MapStopState.comingSoon,
          icon: 'market',
        ),
      ]);
      await tester.tap(find.byIcon(Icons.storefront_rounded));
      await tester.pump();
      expect(find.textContaining('busy market'), findsOneWidget,
          reason: 'the one earned teaser line belongs on the bead it teases');
    });

    testWidgets('the current bead invites a tap and opens its story',
        (WidgetTester tester) async {
      int opened = 0;
      await pumpTrail(
        tester,
        <MapStop>[current],
        onOpen: (MapStop _) => opened++,
      );

      expect(find.text('Start'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('a finished story wears its page and offers a replay',
        (WidgetTester tester) async {
      int opened = 0;
      await pumpTrail(
        tester,
        const <MapStop>[
          MapStop(
            id: 'jungle',
            title: LocalizedText(<String, String>{'en': 'The Green Page'}),
            teaser: LocalizedText.empty(),
            state: MapStopState.completed,
            art: 'assets/gen/images/story/page_green.png',
          ),
        ],
        onOpen: (MapStop _) => opened++,
      );

      // The page it gave up, not a tick: the clearest statement of what
      // playing it was for. The replay wording stays reachable for a screen
      // reader without printing a word next to every bead.
      expect(find.byType(Image), findsOneWidget);
      expect(find.bySemanticsLabel('The Green Page, Again'), findsOneWidget);

      await tester.tap(find.byType(Image));
      await tester.pump();
      expect(opened, 1);
    });

    test('bead positions come from the index, so the trail has no end', () {
      // The extendability requirement, as an assertion: there is no table of
      // authored coordinates to run out of, so story 400 is placed by the same
      // rule as story 1 and adding one costs nothing.
      for (final int index in <int>[0, 1, 5, 6, 99, 400]) {
        expect(TrailGeometry.xFor(index), inInclusiveRange(0.0, 1.0));
      }
      expect(
        TrailGeometry.xFor(0),
        TrailGeometry.xFor(TrailGeometry.lanes.length),
        reason: 'the lane cycle is what makes the rule total',
      );
      expect(
        <double>{for (int i = 0; i < 4; i++) TrailGeometry.xFor(i)}.length,
        4,
        reason: 'four beads running must not stack in the same lane',
      );
    });
  });
}

/// The status wording the map screen hands the trail.
String _statusLabel(MapStop stop) {
  switch (stop.state) {
    case MapStopState.completed:
      return 'Again';
    case MapStopState.open:
      return 'Start';
    case MapStopState.locked:
      return 'Not yet';
    case MapStopState.comingSoon:
      return 'Coming soon';
  }
}

/// Hands a widget test its localizations without going through the bundle.
///
/// The shipped delegate reads `assets/lang/*.json` asynchronously, and a widget
/// test that pumps a fixed number of frames sometimes rendered before it landed
/// — producing an empty tree and a finder failure that looked like a layout bug
/// and was not. The strings themselves are still the real ones, read off disk;
/// only the *timing* is taken out of the test.
class _SynchronousLocalizations
    extends LocalizationsDelegate<AppLocalizations> {
  const _SynchronousLocalizations(this.value);

  final AppLocalizations value;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(value);

  @override
  bool shouldReload(_SynchronousLocalizations old) => false;
}
