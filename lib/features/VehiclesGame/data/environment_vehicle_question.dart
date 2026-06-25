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
    return 'assets/gen/images/vehicles/${name}.png';
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

class EnvironmentVehicleQuestion {
  final String environmentAsset;
  final String Function(AppLocalizations) getQuestionText;
  final VehicleType correctVehicle;
  final List<VehicleType> options;

  EnvironmentVehicleQuestion({
    required this.environmentAsset,
    required this.getQuestionText,
    required this.correctVehicle,
    required this.options,
  }) {
    assert(options.length == 3, "Options must be exactly 3");
    assert(options.contains(correctVehicle), "Options must contain correct answer");
    assert(options.toSet().length == 3, "Options must be unique");
  }

  QuizQuestion toQuizQuestion(AppLocalizations l10n, String id) {
    return QuizQuestion(
      id: id,
      prompt: getQuestionText(l10n),
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

List<EnvironmentVehicleQuestion> generateVehicleQuestions() {
  return [
    EnvironmentVehicleQuestion(
      environmentAsset: 'assets/gen/images/vehicles/sky.png',
      getQuestionText: (l10n) => l10n.whichVehicleFliesInSky,
      correctVehicle: VehicleType.airplane,
      options: [VehicleType.airplane, VehicleType.car, VehicleType.train],
    ),
    EnvironmentVehicleQuestion(
      environmentAsset: 'assets/gen/images/vehicles/railway.png',
      getQuestionText: (l10n) => l10n.whichVehicleTravelsOnRailway,
      correctVehicle: VehicleType.train,
      options: [VehicleType.train, VehicleType.airplane, VehicleType.boat],
    ),
    EnvironmentVehicleQuestion(
      environmentAsset: 'assets/gen/images/vehicles/road.png',
      getQuestionText: (l10n) => l10n.whichVehicleDrivesOnRoad,
      correctVehicle: VehicleType.car,
      options: [VehicleType.car, VehicleType.airplane, VehicleType.boat],
    ),
    EnvironmentVehicleQuestion(
      environmentAsset: 'assets/gen/images/vehicles/sea.png',
      getQuestionText: (l10n) => l10n.whichVehicleTravelsOnWater,
      correctVehicle: VehicleType.boat,
      options: [VehicleType.boat, VehicleType.car, VehicleType.airplane],
    ),
  ];
}
