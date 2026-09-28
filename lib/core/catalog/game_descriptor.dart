import 'package:flutter/material.dart';
import 'package:kidzo/core/catalog/game_surface.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';

/// One entry in the activity catalog.
///
/// Two properties matter more than the rest:
///
/// * [titleLocalizationKey] is a **key**, not a resolved string, so a
///   descriptor can be created without a `BuildContext`. That is what lets the
///   catalog be a plain injected value rather than something assembled inside
///   `build`.
/// * [screenBuilder] is **lazy**. The previous registry stored a constructed
///   `Widget`, so every grid rebuild constructed all 18 screens — including
///   their `BlocProvider`s — to display 18 cards. The screen is now built when
///   the child navigates to it.
@immutable
class GameDescriptor {
  const GameDescriptor({
    required this.activityId,
    required this.titleLocalizationKey,
    required this.iconAsset,
    required this.flipImageAsset,
    required this.surface,
    required this.screenBuilder,
    this.backIcon,
    this.frontIcon,
    this.tieredScreenBuilder,
  });

  /// Stable identity for this activity.
  ///
  /// Where the activity records results, this is exactly its
  /// `GameScores.gameKey`, so score history stays joinable across the catalog
  /// migration. The five historical keys are preserved verbatim:
  /// `feed_animal_game`, `fruit_veg_sorter`, `vehicles_game`, `fruits`,
  /// `vegetables`.
  final String activityId;

  /// A key into `AppLocalizations`, resolved by the caller that has a context.
  final String titleLocalizationKey;

  final String iconAsset;
  final String flipImageAsset;
  final GameSurface surface;

  /// Builds the screen on demand. Never call this to populate a list.
  final Widget Function() screenBuilder;

  final IconData? backIcon;
  final IconData? frontIcon;

  /// Builds the game itself at a chosen tier, for the activities that offer
  /// Easy/Medium/Hard.
  ///
  /// When this is set, [screenBuilder] returns the shared difficulty picker
  /// rather than the game, so the grid needs no knowledge of tiers at all.
  /// Adventure never reads it: story beats configure real gameplay
  /// parameters, never a tier.
  final Widget Function(KidDifficulty difficulty)? tieredScreenBuilder;

  bool get hasDifficultyTiers => tieredScreenBuilder != null;
}
