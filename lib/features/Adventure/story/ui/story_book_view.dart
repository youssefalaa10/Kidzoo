import 'package:flutter/material.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';
import 'package:kidzo/features/Adventure/engine/support/number_words.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/rewards/adventure_reward.dart';

/// The book: hub, progress meter and reason to continue in one object.
///
/// It shows one slot per stop on the journey, filled when that page has been
/// recovered. A pre-reader cannot read "3 of 8", but they can see that three
/// slots are full and five are empty — which is the whole point of making
/// progress spatial rather than numeric.
///
/// A filled slot shows **the page itself**, the same art that flew into the
/// book at the end of that Adventure. It used to show a generic document icon,
/// which quietly undid the reward: a child who watched a green page fly in and
/// then found a grey glyph waiting for them has not been shown their page, they
/// have been shown a receipt for it.
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
        final AdventureRewardBook book = AdventureRewardBook.fromBundle(
          bundle: bundle,
          arc: arc,
          earnedIds: earned,
        );
        final double slot = metrics.size(60, min: 48, max: 80);

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
                      maxLines: 1,
                    ),
                  ),
                  // Digits in the child's own script. A Western "1 / 4" inside
                  // an otherwise fully Arabic screen is the kind of detail that
                  // makes an app feel translated rather than written.
                  ActivityGlyphText(
                    '${NumberWords.digits(book.earnedCount, languageCode)}'
                    ' / '
                    '${NumberWords.digits(arc.stopCount, languageCode)}',
                    languageCode: languageCode,
                    fontSize: metrics.size(18, min: 14, max: 22),
                    color: KidUi.primary,
                  ),
                ],
              ),
              SizedBox(height: metrics.gap * 0.6),
              Wrap(
                spacing: metrics.gap * 0.5,
                runSpacing: metrics.gap * 0.5,
                children: <Widget>[
                  for (final AdventureReward reward in book.rewards)
                    _PageSlot(
                      reward: reward,
                      isEarned: book.isEarned(reward),
                      languageCode: languageCode,
                      size: slot,
                    ),
                  // One empty slot per place still to come, so the book shows
                  // the size of the journey rather than only the part already
                  // written. It is the same promise the map makes, kept in the
                  // one object the child returns to.
                  for (final UpcomingDestination destination in arc.upcoming)
                    _PageSlot(
                      reward: null,
                      isEarned: false,
                      languageCode: languageCode,
                      size: slot,
                      semanticLabel:
                          destination.title.resolve(languageCode),
                    ),
                ],
              ),
              if (book.earnedCount == 0) ...<Widget>[
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
    required this.reward,
    required this.isEarned,
    required this.languageCode,
    required this.size,
    this.semanticLabel,
  });

  /// Null for a slot whose Adventure has not been written yet.
  final AdventureReward? reward;

  final bool isEarned;
  final String languageCode;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final int? accentValue = reward?.accentValue;
    final Color accent =
        accentValue == null ? KidUi.primary : Color(accentValue);
    final String label = semanticLabel ??
        reward?.title.resolve(languageCode) ??
        '';

    return Semantics(
      label: label,
      child: AnimatedContainer(
        duration: KidUi.medium,
        width: size,
        height: size * 1.25,
        decoration: BoxDecoration(
          // An empty slot is a dashed outline, a filled one holds the page.
          // Shape, fill and content all change, so the difference does not
          // depend on colour vision.
          color: isEarned
              ? accent.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(size * 0.16),
          border: Border.all(
            color: isEarned ? accent : Colors.black26,
            width: isEarned ? 3 : 2,
          ),
        ),
        alignment: Alignment.center,
        child: isEarned && reward?.art != null
            ? Padding(
                padding: EdgeInsets.all(size * 0.06),
                child: Image.asset(reward!.art!, fit: BoxFit.contain),
              )
            : Icon(
                isEarned
                    ? Icons.description_rounded
                    : Icons.help_outline_rounded,
                color: isEarned ? accent : Colors.black26,
                size: size * 0.45,
              ),
      ),
    );
  }
}
