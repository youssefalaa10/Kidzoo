@Tags(<String>['screenshot'])
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/engines/patterns/patterns_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/sorting/sorting_engine.dart';
import 'package:kidzo/features/Adventure/engine/host/background_resolver.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';

import 'support/disk_content_source.dart';

/// Renders the Ocean boards to PNG so they can be looked at.
///
/// Not an assertion about pixels — a golden file for a hand-drawn board would
/// fail on every font tweak and teach nobody anything. This exists so the
/// question "does it actually look like a reef ledge with holes in it?" has an
/// answer that does not require a device.
///
/// It runs with the rest of the suite (which is also what keeps it working) and
/// writes into `build/adventure_shots/`. The tag is there so it can be singled
/// out: `flutter test --tags screenshot`.
void main() {
  late AdventureContentBundle bundle;
  late ActivityEngineRegistry registry;

  setUpAll(() async {
    registry = buildDefaultEngineRegistry();
    bundle =
        await const AdventureContentLoader(DiskAdventureContentSource()).load();
  });

  Future<void> shoot(
    WidgetTester tester,
    String activityId, {
    required String name,
    required Size size,
    int advance = 0,
  }) async {
    final ActivitySpec spec = bundle.requireActivity(activityId);
    final ActivityEngine<ActivityContent> engine =
        registry.require(spec.engineId);
    final ActivityCubit<ActivityContent, dynamic> cubit =
        engine.createCubit(engine.createSession(
      spec: spec,
      services: ActivityServices.forTest(seed: 11),
      packs: bundle.packResolver,
      storyNodeId: 'shot',
      seed: 11,
    ));
    await cubit.start();
    // Answering rather than hinting, so a shot can show a board part-way
    // through — which is the only way to see the thing the child is building.
    //
    // On the real clock: advancing a step ends in a 350ms settle inside the
    // base cubit, and under the fake clock that timer never fires unless the
    // tester pumps — so awaiting it here deadlocks rather than fails.
    await tester.runAsync(() async {
      for (int i = 0; i < advance; i++) {
        final Object? step = cubit.state.engineStep;
        if (step is SortingStep) {
          await cubit.submit(PlacementAttempt(
            tokenId: step.item.id,
            targetId: step.correctBinId,
          ));
        } else if (step is PatternStep) {
          await cubit.submit(ChoiceAttempt(step.correctItemId));
        } else {
          break;
        }
      }
    });

    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final GlobalKey shotKey = GlobalKey();
    final String? background = const BackgroundResolver()
        .resolve(spec.presentation.backgroundType, width: size.width);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: shotKey,
        child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              image: background == null
                  ? null
                  : DecorationImage(
                      image: AssetImage(background), fit: BoxFit.cover),
            ),
            // The host spends the top of the screen on its bar and the prompt
            // banner, so a board handed the whole window is not the board the
            // child sees. Reserving that space is what makes these shots worth
            // looking at.
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, size.height * 0.30, 16, 16),
              child: Builder(
                builder: (BuildContext context) => engine.createBoard()(
                  context,
                  cubit.state,
                  (ActivityAttempt _) {},
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    // Asset images decode off the main isolate, which the automated binding
    // only allows inside runAsync. Without this the first shot of a run comes
    // out with every picture blank, and later ones only look right because the
    // image cache happens to be warm by then.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    final RenderRepaintBoundary boundary = shotKey.currentContext!
        .findRenderObject()! as RenderRepaintBoundary;
    // toImage needs the engine to actually rasterize, which the automated test
    // binding only lets happen inside runAsync. Without it the future never
    // completes and the run hangs rather than failing.
    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage();
      final ByteData bytes =
          (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final Directory out = Directory('build/adventure_shots')
        ..createSync(recursive: true);
      File('${out.path}/$name.png')
          .writeAsBytesSync(bytes.buffer.asUint8List());
      image.dispose();
    });
    await cubit.close();
  }

  testWidgets('the current, on a phone', (WidgetTester tester) async {
    await shoot(tester, 'ocean_read_the_current',
        name: 'patterns_phone', size: const Size(360, 640));
  });

  testWidgets('the current, on a tablet', (WidgetTester tester) async {
    await shoot(tester, 'ocean_read_the_current',
        name: 'patterns_tablet', size: const Size(800, 1200));
  });

  testWidgets('the current, phone landscape', (WidgetTester tester) async {
    await shoot(tester, 'ocean_read_the_current',
        name: 'patterns_landscape', size: const Size(780, 390));
  });

  testWidgets('float or sink', (WidgetTester tester) async {
    await shoot(tester, 'ocean_float_or_sink',
        name: 'sorting_phone', size: const Size(360, 640));
  });

  testWidgets('float or sink, part way through', (WidgetTester tester) async {
    await shoot(tester, 'ocean_float_or_sink',
        name: 'sorting_phone_midway', size: const Size(360, 640), advance: 5);
  });

  testWidgets('the silt', (WidgetTester tester) async {
    await shoot(tester, 'ocean_find_marker',
        name: 'hidden_clue_phone', size: const Size(360, 640));
  });

  testWidgets('the trench wall', (WidgetTester tester) async {
    await shoot(tester, 'ocean_light_the_wall',
        name: 'trace_phone', size: const Size(360, 640));
  });
}
