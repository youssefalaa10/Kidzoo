import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_result_view.dart';
import 'package:kidzo/features/FeedTheAnimalGame/data/feed_animal_data.dart';
import 'package:kidzo/features/FruitVegSorterGame/data/sorter_data.dart';
import 'package:kidzo/features/FruitVegSorterGame/data/sorter_models.dart';
import 'package:kidzo/features/VehiclesGame/data/environment_vehicle_question.dart';

void main() {
  group('Fruit & vegetable sorter rounds', () {
    test('every round offers both categories, so the baskets stay meaningful',
        () {
      final random = Random(7);
      for (var seed = 0; seed < 200; seed++) {
        for (var round = 1; round <= 10; round++) {
          final data = SorterGameData.buildRound(
            round: round,
            totalRounds: 10,
            random: random,
          );
          expect(
            data.choices.any((f) => f.type == FoodType.fruit),
            isTrue,
            reason: 'round $round had no fruit',
          );
          expect(
            data.choices.any((f) => f.type == FoodType.vegetable),
            isTrue,
            reason: 'round $round had no vegetable',
          );
        }
      }
    });

    test('choices are unique and always contain the requested food', () {
      final random = Random(11);
      for (var round = 1; round <= 10; round++) {
        final data = SorterGameData.buildRound(
          round: round,
          totalRounds: 10,
          random: random,
        );
        expect(data.choices.map((f) => f.id).toSet().length,
            data.choices.length);
        expect(data.choices.contains(data.targetFood), isTrue);
        expect(data.targetBasket, data.targetFood.type);
      }
    });

    test('the tray grows as the game progresses', () {
      final random = Random(3);
      int size(int round) => SorterGameData.buildRound(
            round: round,
            totalRounds: 10,
            random: random,
          ).choices.length;

      expect(size(1), 2);
      expect(size(5), 3);
      expect(size(8), 4);
      expect(size(10), 5);
    });

    test('a recently requested food is not asked for again', () {
      final random = Random(5);
      final data = SorterGameData.buildRound(
        round: 10,
        totalRounds: 10,
        random: random,
      );
      final avoid = {data.choices.first.id};
      for (var i = 0; i < 50; i++) {
        final next = SorterGameData.buildRound(
          round: 10,
          totalRounds: 10,
          random: random,
          avoidTargets: avoid,
        );
        // Only enforceable when at least one other choice is available, which
        // is always true from three cards up.
        if (next.choices.any((f) => !avoid.contains(f.id))) {
          expect(avoid.contains(next.targetFood.id), isFalse);
        }
      }
    });
  });

  group('Feed the animal distractors', () {
    test('never offer a food the animal would actually eat', () {
      final random = Random(13);
      for (final animal in FeedAnimalData.allAnimals) {
        final target = FeedAnimalData.allFoods
            .firstWhere((f) => f.id == animal.targetFoodId);
        for (final progress in <double>[0.1, 0.5, 0.9, 1.0]) {
          final distractors = FeedAnimalData.buildDistractors(
            animal: animal,
            targetFood: target,
            count: 4,
            progress: progress,
            random: random,
          );
          for (final food in distractors) {
            expect(
              animal.wouldEat(food.id),
              isFalse,
              reason: '${animal.id} was offered ${food.id} as a wrong answer',
            );
          }
        }
      }
    });

    test('every animal can fill the largest tray without repeats', () {
      final random = Random(17);
      final maxChoices = FeedAnimalData.choiceCountFor(1);
      for (final animal in FeedAnimalData.allAnimals) {
        final target = FeedAnimalData.allFoods
            .firstWhere((f) => f.id == animal.targetFoodId);
        final distractors = FeedAnimalData.buildDistractors(
          animal: animal,
          targetFood: target,
          count: maxChoices - 1,
          progress: 1,
          random: random,
        );
        expect(distractors.length, maxChoices - 1,
            reason: '${animal.id} ran out of distractors');
        final ids = {target.id, ...distractors.map((f) => f.id)};
        expect(ids.length, maxChoices);
      }
    });

    test('easy rounds contrast the food families, later rounds do not', () {
      final random = Random(23);
      final lion =
          FeedAnimalData.allAnimals.firstWhere((a) => a.id == 'lion');
      final meat =
          FeedAnimalData.allFoods.firstWhere((f) => f.id == 'meat');

      final easy = FeedAnimalData.buildDistractors(
        animal: lion,
        targetFood: meat,
        count: 2,
        progress: 0.2,
        random: random,
      );
      expect(easy.every((f) => f.kind != meat.kind), isTrue);

      final hard = FeedAnimalData.buildDistractors(
        animal: lion,
        targetFood: meat,
        count: 4,
        progress: 0.9,
        random: random,
      );
      // The lion's only same-family alternative is excluded as edible, so the
      // hard set simply stops privileging contrast; it must still be valid.
      expect(hard.length, 4);
    });

    test('tray size ramps with progress', () {
      expect(FeedAnimalData.choiceCountFor(0.1), 3);
      expect(FeedAnimalData.choiceCountFor(0.5), 4);
      expect(FeedAnimalData.choiceCountFor(1), 5);
    });
  });

  group('Vehicle questions', () {
    test('distractors never belong to the scene being asked about', () {
      for (var i = 0; i < 100; i++) {
        for (final question in generateVehicleQuestions()) {
          final valid = environmentVehicles[question.environmentType]!;
          final wrong = question.options
              .where((v) => v != question.correctVehicle)
              .toList();
          for (final vehicle in wrong) {
            expect(
              valid.contains(vehicle),
              isFalse,
              reason: '$vehicle also belongs in ${question.environmentType}',
            );
          }
        }
      }
    });

    test('options are unique, contain the answer, and ramp 3 then 4', () {
      final questions = generateVehicleQuestions();
      expect(questions.length, 10);
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        expect(q.options.toSet().length, q.options.length);
        expect(q.options.contains(q.correctVehicle), isTrue);
        expect(q.options.length, i < 4 ? 3 : 4);
      }
    });

    test('the correct vehicle really lives in the shown environment', () {
      for (var i = 0; i < 50; i++) {
        for (final q in generateVehicleQuestions()) {
          expect(
            environmentVehicles[q.environmentType]!.contains(q.correctVehicle),
            isTrue,
          );
          expect(q.environmentAsset, q.environmentType.assetPath);
        }
      }
    });
  });

  group('Shared kid UI', () {
    test('stars scale with how well the child did', () {
      expect(KidResultView.starsFor(100, 100), 3);
      expect(KidResultView.starsFor(90, 100), 3);
      expect(KidResultView.starsFor(70, 100), 2);
      expect(KidResultView.starsFor(40, 100), 1);
      expect(KidResultView.starsFor(0, 100), 1);
      // Never zero stars, and never a divide-by-zero.
      expect(KidResultView.starsFor(0, 0), 1);
    });

    test('cards shrink to fit rather than overflowing the tray', () {
      // A five-card tray in a short, narrow box still produces a size that
      // tiles inside it.
      const box = Size(300, 160);
      const spacing = 12.0;
      final size = kidFitCardSize(count: 5, box: box, spacing: spacing);

      var fits = false;
      for (var columns = 1; columns <= 5; columns++) {
        final rows = (5 / columns).ceil();
        final w = columns * size + spacing * (columns - 1);
        final h = rows * size + spacing * (rows - 1);
        if (w <= box.width + 0.01 && h <= box.height + 0.01) fits = true;
      }
      expect(fits, isTrue, reason: 'no arrangement of $size fits in $box');
    });

    test('metrics stay inside sane bounds on tiny and huge screens', () {
      final tiny = KidMetrics.of(const BoxConstraints(
        maxWidth: 240,
        maxHeight: 400,
      ));
      final huge = KidMetrics.of(const BoxConstraints(
        maxWidth: 1400,
        maxHeight: 1000,
      ));

      expect(tiny.scale, greaterThanOrEqualTo(0.72));
      expect(huge.scale, lessThanOrEqualTo(1.35));
      expect(tiny.size(24, min: 17, max: 30), greaterThanOrEqualTo(17));
      expect(huge.size(24, min: 17, max: 30), lessThanOrEqualTo(30));
      expect(huge.isTablet, isTrue);
      expect(huge.isLandscape, isTrue);
    });
  });
}
