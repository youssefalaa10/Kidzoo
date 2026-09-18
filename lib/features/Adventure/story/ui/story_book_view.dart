import 'package:flutter/material.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';

/// The book: hub, progress meter and reason to continue in one object.
///
/// It shows one slot per Adventure in the arc, filled when that page has been
/// recovered. A pre-reader cannot read "3 of 8", but they can see that three
/// slots are full and five are empty — which is the whole point of making
/// progress spatial rather than numeric.
///
/// Pages are deliberately not scarce: no rarity, no randomness, nothing
/// paywalled. The book answers "how far am I?", it is not a collection to chase.
class StoryBookView extends StatelessWidget {
  const StoryBookView({
    required this.bundle,
    required this.storyDao,
    required this.profileId,
    required this.languageCode,
    required this.metrics,
    required this.l10n,
    super.key,
  });

  final AdventureContentBundle bundle;
  final StoryDao storyDao;
  final int profileId;
  final String languageCode;
  final KidMetrics metrics;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final StoryArc arc = bundle.primaryArc;

    return FutureBuilder<List<StoryReward>>(
      future: storyDao.rewardsFor(profileId),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<StoryReward>> snapshot,
      ) {
        final Set<String> earned = (snapshot.data ?? const <StoryReward>[])
            .map((StoryReward reward) => reward.rewardId)
            .toSet();

        return Container(
          padding: EdgeInsets.all(metrics.size(18, min: 12, max: 26)),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(KidUi.radiusCard),
            boxShadow: KidUi.shadow(KidUi.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.auto_stories_rounded,
                    size: metrics.size(30, min: 24, max: 38),
                    color: KidUi.primary,
                  ),
                  SizedBox(width: metrics.gap * 0.5),
                  Expanded(
                    child: ActivityGlyphText(
                      arc.bookName.resolve(languageCode),
                      languageCode: languageCode,
                      fontSize: metrics.size(20, min: 16, max: 26),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  ActivityGlyphText(
                    '${earned.length} / ${arc.adventureIds.length}',
                    languageCode: 'en',
                    fontSize: metrics.size(18, min: 14, max: 22),
                    color: KidUi.primary,
                  ),
                ],
              ),
              SizedBox(height: metrics.gap * 0.6),
              Row(
                children: <Widget>[
                  for (final String adventureId in arc.adventureIds)
                    if (bundle.adventures.containsKey(adventureId))
                      Padding(
                        padding: EdgeInsets.only(right: metrics.gap * 0.5),
                        child: _PageSlot(
                          adventure: bundle.requireAdventure(adventureId),
                          isEarned: earned.contains(
                              bundle.requireAdventure(adventureId).rewardId),
                          languageCode: languageCode,
                          size: metrics.size(56, min: 44, max: 72),
                        ),
                      ),
                ],
              ),
              if (earned.isEmpty) ...<Widget>[
                SizedBox(height: metrics.gap * 0.5),
                ActivityGlyphText(
                  l10n.resolve('storyBookEmpty'),
                  languageCode: languageCode,
                  fontSize: metrics.size(14, min: 12, max: 17),
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.start,
                  color: Colors.black54,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PageSlot extends StatelessWidget {
  const _PageSlot({
    required this.adventure,
    required this.isEarned,
    required this.languageCode,
    required this.size,
  });

  final Adventure adventure;
  final bool isEarned;
  final String languageCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final int? accentValue = adventure.accentColorValue;
    final Color accent =
        accentValue == null ? KidUi.primary : Color(accentValue);

    return Semantics(
      label: adventure.rewardTitle.resolve(languageCode),
      child: AnimatedContainer(
        duration: KidUi.medium,
        width: size,
        height: size * 1.25,
        decoration: BoxDecoration(
          // An empty slot is an outline, a filled one is solid. Shape and fill
          // both change, so the difference does not depend on colour vision.
          color: isEarned ? accent.withValues(alpha: 0.85) : Colors.transparent,
          borderRadius: BorderRadius.circular(size * 0.16),
          border: Border.all(
            color: isEarned ? accent : Colors.black26,
            width: isEarned ? 0 : 2.5,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          isEarned ? Icons.description_rounded : Icons.help_outline_rounded,
          color: isEarned ? Colors.white : Colors.black26,
          size: size * 0.45,
        ),
      ),
    );
  }
}
