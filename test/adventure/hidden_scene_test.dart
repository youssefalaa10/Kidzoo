import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/engines/hidden_clue/hidden_clue_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/hidden_clue/scene_props.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';

import 'support/disk_content_source.dart';

/// The last stage of Adventure 1: finding the page that was lost.
///
/// The scene has one job and one constraint that pull against each other. It
/// must feel like a discovery — the page part-hidden under things the child can
/// move — and it must stay **very easy**, because this is the climax of a story
/// for a four-year-old and a child who cannot finish it never learns how the
/// story ends.
///
/// The way both hold at once is that moving things is optional. A corner of the
/// page is always exposed and always tappable, so the level is winnable without
/// touching a single leaf; moving one is a thing the child may do, not a thing
/// they must solve.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdventureContentBundle bundle;
  late ActivitySpec spec;
  late HiddenClueContent content;

  const HiddenClueEngine engine = HiddenClueEngine();

  setUpAll(() async {
    bundle =
        await const AdventureContentLoader(DiskAdventureContentSource()).load();
    spec = bundle.requireActivity('jungle_find_page');
    content = engine.parseContent(spec, bundle.packResolver);
  });

  HiddenClueCubit cubitFor({int seed = 5}) {
    return HiddenClueCubit(engine.createSession(
      spec: spec,
      services: ActivityServices.forTest(seed: seed),
      packs: bundle.packResolver,
      storyNodeId: 'jungle.n6',
    ));
  }

  group('The scene is a place, not a backdrop', () {
    test('the page lies among scenery rather than alone on a photograph', () {
      expect(content.props, isNotEmpty,
          reason: 'the page used to float on an empty jungle plate, which is '
              'what made it the only thing on screen worth looking at');
      expect(content.ground, isNotNull);
    });

    test('every prop and cover can actually be drawn', () {
      for (final SceneProp prop in <SceneProp>[
        ...content.props,
        ...content.covers,
        content.ground!,
      ]) {
        expect(prop.shape != null || prop.image != null, isTrue,
            reason: 'a prop with neither a shape nor art draws nothing');
        expect(prop.position.dx, inInclusiveRange(0.0, 1.0));
        expect(prop.position.dy, inInclusiveRange(0.0, 1.0));
      }
    });

    test('scenery never claims to be movable, and covers always are', () {
      expect(content.props.every((SceneProp p) => !p.isMovable), isTrue,
          reason: 'a prop that moves is a cover; keeping them separate is what '
              'lets the board decide what to hint at');
      expect(content.covers.every((SceneProp p) => p.isMovable), isTrue);
      expect(content.covers.every((SceneProp p) => p.id != null), isTrue);
    });

    test('art referenced by any prop is precached with everything else', () {
      final Iterable<String> assets = engine.assetsFor(content);
      for (final SceneProp prop in <SceneProp>[
        ...content.props,
        ...content.covers,
      ]) {
        if (prop.image != null) {
          expect(assets, contains(prop.image),
              reason: 'a leaf that pops in after the prompt has told the child '
                  'to look under it is worse than no leaf at all');
        }
      }
    });
  });

  group('It stays very easy', () {
    test('the covers leave part of the page showing at every screen size', () {
      // The rule the whole design rests on. The board asserts this too, but
      // only in debug and only for sizes a widget test happens to pump; here
      // it is checked as arithmetic across a spread of real aspect ratios.
      const List<Size> boards = <Size>[
        Size(360, 420),
        Size(780, 300),
        Size(800, 900),
        Size(320, 380),
      ];

      for (final Size box in boards) {
        final double clueSize =
            (box.shortestSide * 0.24).clamp(72.0, 190.0) *
                content.clues.first.scale;
        final double coverBase =
            (box.shortestSide * 0.30).clamp(84.0, 240.0);

        final Rect clue = Rect.fromCenter(
          center: Offset(
            content.clues.first.position.dx * box.width,
            content.clues.first.position.dy * box.height,
          ),
          width: clueSize,
          height: clueSize,
        );
        final List<Rect> covers = <Rect>[
          for (final SceneProp cover in content.covers)
            Rect.fromCenter(
              center: clue.center +
                  Offset(
                    cover.offsetFromClue!.dx * clueSize,
                    cover.offsetFromClue!.dy * clueSize,
                  ),
              width: coverBase * cover.scale,
              height: coverBase * cover.scale,
            ),
        ];

        int visible = 0;
        const int steps = 5;
        for (int row = 0; row < steps; row++) {
          for (int column = 0; column < steps; column++) {
            final Offset point = Offset(
              clue.left + clue.width * (column + 0.5) / steps,
              clue.top + clue.height * (row + 0.5) / steps,
            );
            if (!covers.any((Rect cover) => cover.contains(point))) {
              visible++;
            }
          }
        }
        expect(visible / (steps * steps), greaterThanOrEqualTo(0.25),
            reason: 'at $box the covers bury the page, and a page that cannot '
                'be seen cannot be found');
      }
    });

    test('tapping the page wins immediately, with nothing moved first',
        () async {
      final HiddenClueCubit cubit = cubitFor();
      await cubit.start();
      final HiddenClueStep step = cubit.state.engineStep! as HiddenClueStep;

      await cubit.submit(ChoiceAttempt(step.clue.id));

      expect(cubit.state.status, ActivityStatus.finished);
      expect(cubit.state.result.completion, ActivityCompletion.completed);
      expect(cubit.state.result.stepsIndependent, 1,
          reason: 'the child found it unaided; moving a cover was never '
              'required and no hint was spent');
      await cubit.close();
    });

    test('a near miss on the exposed corner still counts', () async {
      // The tolerance is generous on purpose: a child who found the page and
      // missed it by a few millimetres has a motor problem, not a search one.
      final HiddenClueCubit cubit = cubitFor();
      await cubit.start();
      final HiddenClueStep step = cubit.state.engineStep! as HiddenClueStep;

      await cubit.submit(
        TapPointAttempt(step.clue.position + const Offset(0.05, 0.05)),
      );
      expect(cubit.state.status, ActivityStatus.finished);
      await cubit.close();
    });

    test('there is no way to lose, however many wrong taps', () async {
      final HiddenClueCubit cubit = cubitFor();
      await cubit.start();

      for (int attempt = 0; attempt < 6; attempt++) {
        if (cubit.state.status != ActivityStatus.running) {
          break;
        }
        await cubit.submit(const TapPointAttempt(Offset(0.02, 0.02)));
      }

      expect(cubit.state.status, ActivityStatus.finished,
          reason: 'the errorless ladder credits the step rather than stranding '
              'a child on the last stage of the story');
      expect(cubit.state.result.completion, ActivityCompletion.completed);
      expect(cubit.state.result.score, greaterThan(0),
          reason: 'scored at the floor, never at zero');
      await cubit.close();
    });

    test('help arrives on its own, and quickly', () {
      // Eight seconds, down from fifteen. The nudge has to land while the
      // child is still looking, not after they have given up and gone quiet.
      expect(content.revealOnIdleSeconds, lessThanOrEqualTo(8));
      expect(content.revealOnIdleSeconds, greaterThan(0),
          reason: 'zero would disarm the idle nudge entirely');
    });

    test('every cover is anchored to the page, not to the scene', () {
      // Scene percentages drift in landscape, because positions are per-axis
      // and sizes come from the short side. A cover that drifts is a cover
      // that stops covering, and the overlap is the entire mechanic.
      for (final SceneProp cover in content.covers) {
        expect(cover.offsetFromClue, isNotNull);
      }
    });

    test('the covers over the page are the ones the hints act on', () {
      // The board wiggles, and later clears, only covers within one clue-size
      // of the page. A scene whose covers all sat far away would hint at
      // nothing, and the automatic help would silently do nothing at all.
      expect(
        content.covers.any((SceneProp c) => c.offsetFromClue!.distance < 1.0),
        isTrue,
        reason: 'at least one cover must be close enough to be hinted at',
      );
    });
  });

  group('The search is still a search', () {
    test('decoys never land on the page', () async {
      // Unchanged by the redesign, and worth re-checking because the scene
      // gained a lot of other things that sit near the clue.
      for (int seed = 0; seed < 60; seed++) {
        final HiddenClueCubit cubit = cubitFor(seed: seed);
        await cubit.start();
        final HiddenClueStep step = cubit.state.engineStep! as HiddenClueStep;
        for (final MapEntry<dynamic, Offset> decoy in step.noisePositions) {
          expect((decoy.value - step.clue.position).distance,
              greaterThanOrEqualTo(0.1),
              reason: 'a decoy on top of the clue makes it luck, not search');
        }
        await cubit.close();
      }
    });

    test('the scene carries the environment now, not a crowd of decoys', () {
      expect(content.visualNoise.length, lessThanOrEqualTo(5),
          reason: 'seven random animals plus a furnished floor is clutter; '
              'what makes an object hard to find is how much it looks like its '
              'neighbours, not how many neighbours there are');
    });

    test('the same seed always builds the same scene', () async {
      final HiddenClueCubit a = cubitFor(seed: 42);
      final HiddenClueCubit b = cubitFor(seed: 42);
      await a.start();
      await b.start();

      final HiddenClueStep first = a.state.engineStep! as HiddenClueStep;
      final HiddenClueStep second = b.state.engineStep! as HiddenClueStep;
      for (int i = 0; i < first.noisePositions.length; i++) {
        expect(first.noisePositions[i].value, second.noisePositions[i].value);
      }
      expect(first.covers.length, second.covers.length);
      await a.close();
      await b.close();
    });
  });

  group('Authoring mistakes fail loudly', () {
    ActivitySpec specWith(Map<String, dynamic> payload) {
      return ActivitySpec.fromJson(<String, dynamic>{
        'instanceId': 'test.scene',
        'engineId': 'hidden_clue',
        'schemaVersion': 1,
        'locales': const <String>['en'],
        'narration': const <String, dynamic>{
          'prompt': <String, String>{'en': 'Find it'},
          'hint1': <String, String>{'en': 'Look low'},
          'hint2': <String, String>{'en': 'It is green'},
          'model': <String, String>{'en': 'There'},
          'success': <String, String>{'en': 'Found'},
        },
        'payload': <String, dynamic>{
          'clues': const <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'page',
              'positionPercent': <int>[50, 50],
              'image': 'assets/gen/images/story/page_green.png',
              'label': <String, String>{'en': 'the page'},
            },
          ],
          'visualNoiseCount': 0,
          ...payload,
        },
      });
    }

    test('a prop with neither art nor a shape is rejected', () {
      expect(
        () => engine.parseContent(
          specWith(<String, dynamic>{
            'props': const <Map<String, dynamic>>[
              <String, dynamic>{'positionPercent': <int>[10, 10]},
            ],
          }),
          bundle.packResolver,
        ),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('a cover with no way to move is rejected as scenery', () {
      expect(
        () => engine.parseContent(
          specWith(<String, dynamic>{
            'covers': const <Map<String, dynamic>>[
              <String, dynamic>{
                'shape': 'leaf',
                'positionPercent': <int>[50, 50],
              },
            ],
          }),
          bundle.packResolver,
        ),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('an unknown shape names the ones that exist', () {
      expect(
        () => engine.parseContent(
          specWith(<String, dynamic>{
            'props': const <Map<String, dynamic>>[
              <String, dynamic>{
                'shape': 'palmtree',
                'positionPercent': <int>[10, 10],
              },
            ],
          }),
          bundle.packResolver,
        ),
        throwsA(
          isA<ActivityContentException>().having(
            (ActivityContentException e) => '$e',
            'message',
            allOf(contains('palmtree'), contains('frond')),
          ),
        ),
      );
    });

    test('turn is authored in degrees and stored in turns', () {
      final HiddenClueContent parsed = engine.parseContent(
        specWith(<String, dynamic>{
          'props': const <Map<String, dynamic>>[
            <String, dynamic>{
              'shape': 'leaf',
              'positionPercent': <int>[10, 10],
              'turn': 90,
            },
          ],
        }),
        bundle.packResolver,
      );
      expect(parsed.props.single.turns, closeTo(0.25, 1e-9));
    });
  });

  group('The board', () {
    Widget boardUnderTest(ActivityState state, void Function(ActivityAttempt) submit) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 420,
            child: Builder(
              builder: (BuildContext context) =>
                  engine.createBoard()(context, state, submit),
            ),
          ),
        ),
      );
    }

    testWidgets('a cover can be moved, and moving it is not an attempt',
        (WidgetTester tester) async {
      final HiddenClueCubit cubit = cubitFor();
      await cubit.start();

      final List<ActivityAttempt> submitted = <ActivityAttempt>[];
      await tester.pumpWidget(
        boardUnderTest(cubit.state, submitted.add),
      );
      await tester.pump();

      final Finder cover = find.bySemanticsLabel('Move');
      expect(cover, findsNWidgets(cubit.state.engineStep is HiddenClueStep
          ? (cubit.state.engineStep! as HiddenClueStep).covers.length
          : 0));

      await tester.tap(cover.first, warnIfMissed: false);
      for (int frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 80));
      }

      expect(submitted, isEmpty,
          reason: 'sweeping a leaf aside is not a guess and must never be '
              'scored, hinted at, or recorded as one');
      await cubit.close();
    });

    testWidgets('the page is still reachable with the covers in place',
        (WidgetTester tester) async {
      final HiddenClueCubit cubit = cubitFor();
      await cubit.start();

      final List<ActivityAttempt> submitted = <ActivityAttempt>[];
      await tester.pumpWidget(boardUnderTest(cubit.state, submitted.add));
      await tester.pump();

      final HiddenClueStep step = cubit.state.engineStep! as HiddenClueStep;
      final Rect page =
          tester.getRect(find.bySemanticsLabel(step.clue.label.resolve('en')));

      // Deliberately not the centre. A cover lies over the middle of the page —
      // that is the point of it — so the centre belongs to the leaf and tapping
      // it moves the leaf. The corner is what the child is meant to see, and it
      // has to be the page.
      await tester.tapAt(page.topRight + const Offset(-10, 10));
      await tester.pump();

      expect(submitted.whereType<ChoiceAttempt>().length, 1,
          reason: 'the exposed corner is the whole reason this stays easy: the '
              'level is winnable without moving anything');
      await cubit.close();
    });
  });
}
