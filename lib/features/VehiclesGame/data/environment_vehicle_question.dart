import 'dart:math';

import '../../../core/localization/app_localizations.dart';
import '../../QuizEngine/data/quiz_models.dart';

enum VehicleType {
  airplane,
  car,
  train,
  boat,
  helicopter,
  motorcycle,
  truck,
  bus,
  bicycle,
  submarine,
}

extension VehicleTypeExtension on VehicleType {
  String get assetPath {
    if (this == VehicleType.boat) return 'assets/gen/images/vehicles/ship.png';
    return 'assets/gen/images/vehicles/$name.png';
  }

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case VehicleType.airplane:
        return l10n.airplane;
      case VehicleType.car:
        return l10n.car;
      case VehicleType.train:
        return l10n.train;
      case VehicleType.boat:
        return l10n.boat;
      case VehicleType.helicopter:
        return l10n.helicopter;
      case VehicleType.motorcycle:
        return l10n.motorcycle;
      case VehicleType.truck:
        return l10n.truck;
      case VehicleType.bus:
        return l10n.bus;
      case VehicleType.bicycle:
        return l10n.bicycle;
      case VehicleType.submarine:
        return l10n.submarine;
    }
  }
}

enum EnvironmentType {
  sky,
  sea,
  road,
  railway,
}

extension EnvironmentTypeExtension on EnvironmentType {
  String get assetPath {
    switch (this) {
      case EnvironmentType.sky:
        return 'assets/gen/images/vehicles/sky.png';
      case EnvironmentType.sea:
        return 'assets/gen/images/vehicles/sea.png';
      case EnvironmentType.road:
        return 'assets/gen/images/vehicles/road.png';
      case EnvironmentType.railway:
        return 'assets/gen/images/vehicles/railway.png';
    }
  }


}

const Map<EnvironmentType, List<VehicleType>> environmentVehicles = {
  EnvironmentType.sky: [VehicleType.airplane, VehicleType.helicopter],
  EnvironmentType.sea: [VehicleType.boat, VehicleType.submarine],
  EnvironmentType.road: [
    VehicleType.car,
    VehicleType.motorcycle,
    VehicleType.truck,
    VehicleType.bus,
    VehicleType.bicycle
  ],
  EnvironmentType.railway: [VehicleType.train],
};

class EnvironmentVehicleQuestion {

  EnvironmentVehicleQuestion({
    required this.environmentAsset,
    required this.environmentType,
    required this.correctVehicle,
    required this.options,
  }) {
    assert(options.length == 3, "Options must be exactly 3");
    assert(options.contains(correctVehicle),
        "Options must contain correct answer");
    assert(options.toSet().length == 3, "Options must be unique");
  }
  final String environmentAsset;
  final EnvironmentType environmentType;
  final VehicleType correctVehicle;
  final List<VehicleType> options;

  QuizQuestion toQuizQuestion(AppLocalizations l10n, String id) {
    final templates = l10n.getVehicleEnvironmentPrompts(environmentType.name);
    templates.shuffle(Random());
    final prompt = templates.first;

    return QuizQuestion(
      id: id,
      prompt: prompt,
      imageOrScenePath: environmentAsset,
      options: options.map((v) {
        return QuizOption(
          id: v.name,
          text: v.localizedName(l10n),
          imagePath: v.assetPath,
          isCorrect: v == correctVehicle,
        );
      }).toList(),
    );
  }
}

List<EnvironmentVehicleQuestion> generateVehicleQuestions({int count = 10}) {
  final random = Random();
  final List<EnvironmentVehicleQuestion> questions = [];

  EnvironmentType? lastEnvironment;
  VehicleType? lastCorrectAnswer;
  List<EnvironmentType> environmentCycle = [];

  final List<VehicleType> usedAnswers = [];

  for (int i = 0; i < count; i++) {
    // 1. Select Environment (Cycle through all before repeating)
    if (environmentCycle.isEmpty) {
      environmentCycle = EnvironmentType.values.toList();
      environmentCycle.shuffle(random);
      // Ensure the new cycle doesn't start with the last environment of the previous cycle
      if (lastEnvironment != null &&
          environmentCycle.first == lastEnvironment &&
          environmentCycle.length > 1) {
        final temp = environmentCycle[0];
        environmentCycle[0] = environmentCycle.last;
        environmentCycle.last = temp;
      }
    }
    final EnvironmentType env = environmentCycle.removeAt(0);

    // 2. Select Correct Vehicle (Avoid repeating recently used vehicles)
    final List<VehicleType> validVehicles = List.from(environmentVehicles[env]!);
    final List<VehicleType> unusedValid = validVehicles.where((v) => !usedAnswers.contains(v)).toList();
    
    VehicleType correctVehicle;
    if (unusedValid.isNotEmpty) {
      unusedValid.shuffle(random);
      correctVehicle = unusedValid.first;
    } else {
      if (lastCorrectAnswer != null && validVehicles.length > 1) {
        validVehicles.remove(lastCorrectAnswer);
      }
      validVehicles.shuffle(random);
      correctVehicle = validVehicles.first;
    }
    usedAnswers.add(correctVehicle);

    // 3. Select 2 Invalid Vehicles from DIFFERENT environments
    // To ensure distractors are very distinct, we pick from 2 distinct incorrect environments
    final List<EnvironmentType> otherEnvs = EnvironmentType.values.where((e) => e != env).toList();
    otherEnvs.shuffle(random);
    
    final List<VehicleType> invalidVehicles = [];
    for (int j = 0; j < 2; j++) {
      final List<VehicleType> pool = List.from(environmentVehicles[otherEnvs[j]]!);
      pool.shuffle(random);
      invalidVehicles.add(pool.first);
    }

    // 4. Combine and Shuffle Options
    final List<VehicleType> options = [correctVehicle, ...invalidVehicles];
    options.shuffle(random);

    questions.add(EnvironmentVehicleQuestion(
      environmentAsset: env.assetPath,
      environmentType: env,
      correctVehicle: correctVehicle,
      options: options,
    ));

    lastEnvironment = env;
    lastCorrectAnswer = correctVehicle;
  }

  return questions;
}
