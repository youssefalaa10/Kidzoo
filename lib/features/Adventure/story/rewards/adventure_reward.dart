import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';

/// Something the child earned and keeps.
///
/// One type for every milestone an Adventure can hand over, not one type per
/// milestone. Today the only kind is a recovered page, and the temptation was
/// to leave "the page" hardcoded in the three places that draw it — which is
/// precisely how the previous feature ended up with a book view, a completion
/// screen and a search scene that each had their own idea of what the reward
/// looked like, and disagreed.
@immutable
class AdventureReward {
  const AdventureReward({
    required this.rewardId,
    required this.adventureId,
    required this.title,
    required this.art,
    required this.accentValue,
  });

  final String rewardId;

  /// The Adventure that hands it over. One per Adventure, enforced in content:
  /// a chapter must grant its page exactly once.
  final String adventureId;

  final LocalizedText title;

  /// Art for the reward, or null when the Adventure never authored any. Callers
  /// fall back to a generic page glyph rather than failing — a missing picture
  /// must never cost a child the thing they earned.
  final String? art;

  /// The Adventure's accent as ARGB, or null.
  final int? accentValue;
}

/// Every reward in an arc, and who has earned which.
///
/// Built from content rather than from a hardcoded list, so a new Adventure
/// arrives with its reward already wired into the book, the celebration and the
/// map without any of them being edited.
@immutable
class AdventureRewardBook {
  const AdventureRewardBook({required this.rewards, required this.earnedIds});

  /// Builds the book for [arc] out of [bundle], in playing order.
  factory AdventureRewardBook.fromBundle({
    required AdventureContentBundle bundle,
    required StoryArc arc,
    required Set<String> earnedIds,
  }) {
    final List<AdventureReward> rewards = <AdventureReward>[];
    for (final String adventureId in arc.adventureIds) {
      final Adventure? adventure = bundle.adventures[adventureId];
      if (adventure == null) {
        continue;
      }
      rewards.add(AdventureReward(
        rewardId: adventure.rewardId,
        adventureId: adventure.adventureId,
        title: adventure.rewardTitle,
        art: adventure.rewardArt,
        accentValue: adventure.accentColorValue,
      ));
    }
    return AdventureRewardBook(rewards: rewards, earnedIds: earnedIds);
  }

  final List<AdventureReward> rewards;
  final Set<String> earnedIds;

  bool isEarned(AdventureReward reward) => earnedIds.contains(reward.rewardId);

  int get earnedCount =>
      rewards.where((AdventureReward reward) => isEarned(reward)).length;

  int get total => rewards.length;

  AdventureReward? byRewardId(String rewardId) {
    for (final AdventureReward reward in rewards) {
      if (reward.rewardId == rewardId) {
        return reward;
      }
    }
    return null;
  }

  AdventureReward? forAdventure(String adventureId) {
    for (final AdventureReward reward in rewards) {
      if (reward.adventureId == adventureId) {
        return reward;
      }
    }
    return null;
  }
}
