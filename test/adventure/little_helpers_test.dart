import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/shared/widgets/kid_pick_card.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/sorting/sorting_engine.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';

void main() {
  for (final theme in ['teeth', 'weather', 'laundry']) {
    testWidgets('$theme accepts tap-to-place and a desktop drag',
        (tester) async {
      Map<String, dynamic> load(String path) =>
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final spec = ActivitySpec.fromJson(
          load('assets/adventures/activities/helpers_$theme.json'));
      final pack = ItemPack.fromJson(
          load('assets/adventures/packs/helpers_$theme.json'));
      const engine = SortingEngine();
      final cubit = engine.createCubit(engine.createSession(
          spec: spec,
          services: ActivityServices.forTest(),
          packs: MapItemPackResolver({pack.packId: pack})));
      await cubit.start();
      final submitted = <ActivityAttempt>[];
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
        builder: (context) =>
            engine.createBoard()(context, cubit.state, submitted.add),
      ))));
      await tester.pump();
      final step = cubit.state.engineStep as SortingStep;
      final target = find
          .byType(DragTarget<String>)
          .at(step.bins.indexWhere((bin) => bin.id == step.correctBinId));
      final token = find.byType(KidPickCard<String>);
      await tester.tap(token);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(target);
      expect(
          (submitted.single as PlacementAttempt).targetId, step.correctBinId);
      submitted.clear();
      await tester.drag(
          token, tester.getCenter(target) - tester.getCenter(token));
      await tester.pump();
      expect(
          (submitted.single as PlacementAttempt).targetId, step.correctBinId);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    });
    for (final locale in ['en', 'ar']) {
      test('$theme in $locale rejects wrong bins and completes all items',
          () async {
        Map<String, dynamic> load(String path) =>
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        final spec = ActivitySpec.fromJson(
            load('assets/adventures/activities/helpers_$theme.json'));
        final pack = ItemPack.fromJson(
            load('assets/adventures/packs/helpers_$theme.json'));
        const engine = SortingEngine();
        final services = ActivityServices.forTest(languageCode: locale);
        final session = engine.createSession(
            spec: spec,
            services: services,
            packs: MapItemPackResolver({pack.packId: pack}));
        for (final path in engine.assetsFor(session.content)) {
          expect(File(path).existsSync(), isTrue, reason: path);
        }
        final cubit = engine.createCubit(session);
        await cubit.start();
        final count = pack.items.length;
        for (var i = 0; i < count; i++) {
          final step = cubit.state.engineStep as SortingStep;
          expect(step.alreadySorted.length, i);
          final wrong = step.bins.firstWhere((b) => b.id != step.correctBinId);
          expect(cubit.judge(step, ChoiceAttempt(wrong.id)).isCorrect, isFalse);
          // Exercise the real retry path once, without triggering automatic help.
          if (i == 0) {
            await cubit.submit(ChoiceAttempt(wrong.id));
            expect(cubit.state.stepIndex, 0);
          }
          await cubit.submit(PlacementAttempt(
              tokenId: step.item.id, targetId: step.correctBinId));
        }
        expect(cubit.state.status, ActivityStatus.finished);
        expect((services.soundboard as RecordingActivitySoundboard).played,
            contains(ActivitySound.celebrate));
        await cubit.close();
        final wav = File('assets/audio/helpers_$theme.wav').readAsBytesSync();
        expect(ascii.decode(wav.sublist(0, 4)), 'RIFF');
        expect(wav.length, greaterThan(10000));
      });
    }
  }
}
