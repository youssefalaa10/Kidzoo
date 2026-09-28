import 'package:flutter/material.dart';
import 'package:kidzo/core/catalog/game_descriptor.dart';
import 'package:kidzo/core/catalog/game_surface.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Difficulty/ui/difficulty_select_screen.dart';

/// Builds a catalog entry whose grid card opens the difficulty picker.
///
/// The six tiered games would otherwise each repeat the same picker wiring in
/// their descriptor. Because `OptionCard` simply calls `screenBuilder()`, the
/// grid itself needs no change: it pushes whatever this returns, which happens
/// to be a picker rather than a game.
GameDescriptor buildTieredDescriptor({
  required String activityId,
  required String titleLocalizationKey,
  required String descriptionKeyPrefix,
  required String iconAsset,
  required String flipImageAsset,
  required GameSurface surface,
  required Widget Function(KidDifficulty difficulty) gameBuilder,
  IconData? backIcon,
  IconData? frontIcon,
  Widget Function(BuildContext context, KidMetrics metrics)? bonusCardBuilder,
}) {
  return GameDescriptor(
    activityId: activityId,
    titleLocalizationKey: titleLocalizationKey,
    iconAsset: iconAsset,
    flipImageAsset: flipImageAsset,
    surface: surface,
    backIcon: backIcon,
    frontIcon: frontIcon,
    tieredScreenBuilder: gameBuilder,
    screenBuilder: () => DifficultySelectScreen(
      activityId: activityId,
      titleLocalizationKey: titleLocalizationKey,
      descriptionKeyPrefix: descriptionKeyPrefix,
      gameBuilder: gameBuilder,
      bonusCardBuilder: bonusCardBuilder,
    ),
  );
}
