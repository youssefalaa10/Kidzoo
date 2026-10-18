import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';
import 'package:kidzo/core/difficulty/difficulty_run_scope.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_game_shell.dart';
import 'package:kidzo/features/Difficulty/logic/difficulty_load_status.dart';
import 'package:kidzo/features/Difficulty/logic/difficulty_select_cubit.dart';
import 'package:kidzo/features/Difficulty/logic/difficulty_select_state.dart';

/// The one screen standing between the grid and every tiered game.
///
/// Easy is always open and each tier opens the next, so a child meets the
/// gentlest version of a game first and the harder ones read as somewhere to
/// get to rather than a wall they hit by accident.
class DifficultySelectScreen extends StatelessWidget {
  const DifficultySelectScreen({
    required this.activityId,
    required this.titleLocalizationKey,
    required this.descriptionKeyPrefix,
    required this.gameBuilder,
    super.key,
    this.bonusCardBuilder,
  });

  /// Doubles as the `GameScores.gameKey` the tier history is read from.
  final String activityId;
  final String titleLocalizationKey;

  /// Prefix for the three `<prefix>EasyDescription` keys.
  final String descriptionKeyPrefix;
  final Widget Function(KidDifficulty difficulty) gameBuilder;

  /// An extra, always-open card below the three tiers. Only Puzzle passes
  /// one. A builder rather than a widget because it needs the [KidMetrics]
  /// that only exist inside the shell.
  final Widget Function(BuildContext context, KidMetrics metrics)?
      bonusCardBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DifficultySelectCubit>(
      create: (BuildContext _) => DifficultySelectCubit(
        gameScoresDao: context.read<GameScoresDao>(),
        profileDao: context.read<ProfileDao>(),
        gameKey: activityId,
      )..loadProgress(),
      child: _DifficultySelectView(
        titleLocalizationKey: titleLocalizationKey,
        descriptionKeyPrefix: descriptionKeyPrefix,
        gameBuilder: gameBuilder,
        bonusCardBuilder: bonusCardBuilder,
      ),
    );
  }
}

class _DifficultySelectView extends StatefulWidget {
  const _DifficultySelectView({
    required this.titleLocalizationKey,
    required this.descriptionKeyPrefix,
    required this.gameBuilder,
    required this.bonusCardBuilder,
  });

  final String titleLocalizationKey;
  final String descriptionKeyPrefix;
  final Widget Function(KidDifficulty difficulty) gameBuilder;
  final Widget Function(BuildContext context, KidMetrics metrics)?
      bonusCardBuilder;

  @override
  State<_DifficultySelectView> createState() => _DifficultySelectViewState();
}

class _DifficultySelectViewState extends State<_DifficultySelectView> {
  static const List<Color> _accents = <Color>[
    KidUi.correct,
    KidUi.hint,
    KidUi.wrong,
  ];

  Future<void> _playTier(KidDifficulty difficulty) async {
    KidHaptics.tap();
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (BuildContext _) => DifficultyRunScope(
        difficulty: difficulty,
        gameBuilder: widget.gameBuilder,
        child: widget.gameBuilder(difficulty),
      ),
    ));
    if (!mounted) {
      return;
    }
    // Re-read on the way back, so a tier just cleared is already unlocked and
    // the stars just earned are already on the card.
    await context.read<DifficultySelectCubit>().loadProgress();
  }

  void _refuseTier(KidDifficulty difficulty) {
    KidHaptics.error();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final KidDifficulty previous = difficulty.previous!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.finishPreviousTier(l10n.resolve(previous.nameKey))),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return KidGameShell(
      builder: (BuildContext context, KidMetrics metrics) {
        return BlocBuilder<DifficultySelectCubit, DifficultySelectState>(
          builder: (BuildContext context, DifficultySelectState state) {
            if (state.status == DifficultyLoadStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: EdgeInsets.all(metrics.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Header(
                    metrics: metrics,
                    title: l10n.resolve(widget.titleLocalizationKey),
                    subtitle: l10n.chooseDifficulty,
                  ),
                  SizedBox(height: metrics.gap),
                  for (final KidDifficulty difficulty in KidDifficulty.values)
                    Padding(
                      padding: EdgeInsets.only(bottom: metrics.gap),
                      child: _DifficultyCard(
                        metrics: metrics,
                        difficulty: difficulty,
                        accent: _accents[difficulty.index],
                        isUnlocked: state.isUnlocked(difficulty),
                        stars: state.starsFor(difficulty),
                        bestScore: state.bestScoreFor(difficulty),
                        descriptionKeyPrefix: widget.descriptionKeyPrefix,
                        onPlay: () => _playTier(difficulty),
                        onRefused: () => _refuseTier(difficulty),
                      ),
                    ),
                  if (widget.bonusCardBuilder != null)
                    widget.bonusCardBuilder!(context, metrics),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.metrics,
    required this.title,
    required this.subtitle,
  });

  final KidMetrics metrics;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _PickerBackButton(metrics: metrics),
        SizedBox(width: metrics.gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: metrics.size(28, min: 20, max: 36),
                  fontWeight: FontWeight.w900,
                  color: KidUi.ink,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: metrics.size(17, min: 13, max: 21),
                  fontWeight: FontWeight.w600,
                  color: KidUi.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickerBackButton extends StatelessWidget {
  const _PickerBackButton({required this.metrics});

  final KidMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final double side = metrics.size(52, min: 44, max: 64);
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: Material(
        color: KidUi.surface,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            KidHaptics.tap();
            Navigator.of(context).maybePop();
          },
          child: SizedBox(
            width: side,
            height: side,
            child: Icon(
              Icons.arrow_back_rounded,
              color: KidUi.ink,
              size: side * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.metrics,
    required this.difficulty,
    required this.accent,
    required this.isUnlocked,
    required this.stars,
    required this.bestScore,
    required this.descriptionKeyPrefix,
    required this.onPlay,
    required this.onRefused,
  });

  final KidMetrics metrics;
  final KidDifficulty difficulty;
  final Color accent;
  final bool isUnlocked;
  final int stars;
  final int? bestScore;
  final String descriptionKeyPrefix;
  final VoidCallback onPlay;
  final VoidCallback onRefused;

  String _describeTier(AppLocalizations l10n) {
    final String suffix =
        difficulty.name[0].toUpperCase() + difficulty.name.substring(1);
    return l10n.resolve(
      '$descriptionKeyPrefix${suffix}Description',
      fallback: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String name = l10n.resolve(difficulty.nameKey);
    final String description = _describeTier(l10n);
    final Color surface = isUnlocked ? KidUi.surface : const Color(0xFFEDEAF3);
    return Semantics(
      button: true,
      enabled: isUnlocked,
      label: isUnlocked ? name : '$name, ${l10n.tierLocked}',
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(KidUi.radiusCard),
        elevation: isUnlocked ? 6 : 0,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(KidUi.radiusCard),
          onTap: isUnlocked ? onPlay : onRefused,
          child: Container(
            constraints: BoxConstraints(
              minHeight: metrics.size(104, min: KidUi.minTouch, max: 132),
            ),
            padding: EdgeInsets.all(metrics.size(16, min: 12, max: 22)),
            child: Row(
              children: <Widget>[
                _TierBadge(
                  metrics: metrics,
                  accent: accent,
                  isUnlocked: isUnlocked,
                  tierNumber: difficulty.level,
                ),
                SizedBox(width: metrics.gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: metrics.size(23, min: 18, max: 29),
                          fontWeight: FontWeight.w900,
                          color: isUnlocked ? KidUi.ink : KidUi.inkSoft,
                        ),
                      ),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: metrics.size(14, min: 11, max: 18),
                            fontWeight: FontWeight.w600,
                            color: KidUi.inkSoft,
                          ),
                        ),
                      SizedBox(height: metrics.size(6, min: 4, max: 10)),
                      _CardFooter(
                        metrics: metrics,
                        difficulty: difficulty,
                        isUnlocked: isUnlocked,
                        stars: stars,
                        bestScore: bestScore,
                      ),
                    ],
                  ),
                ),
                Icon(
                  isUnlocked ? Icons.play_arrow_rounded : Icons.lock_rounded,
                  size: metrics.size(34, min: 26, max: 44),
                  color: isUnlocked ? accent : KidUi.inkSoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({
    required this.metrics,
    required this.accent,
    required this.isUnlocked,
    required this.tierNumber,
  });

  final KidMetrics metrics;
  final Color accent;
  final bool isUnlocked;
  final int tierNumber;

  @override
  Widget build(BuildContext context) {
    final double side = metrics.size(56, min: 44, max: 72);
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: isUnlocked ? accent : KidUi.inkSoft.withValues(alpha: 0.35),
        shape: BoxShape.circle,
        boxShadow: isUnlocked ? KidUi.shadow(accent, strength: 0.6) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$tierNumber',
        style: TextStyle(
          fontSize: side * 0.46,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Stars and best score once played, the unlock hint while still locked.
class _CardFooter extends StatelessWidget {
  const _CardFooter({
    required this.metrics,
    required this.difficulty,
    required this.isUnlocked,
    required this.stars,
    required this.bestScore,
  });

  final KidMetrics metrics;
  final KidDifficulty difficulty;
  final bool isUnlocked;
  final int stars;
  final int? bestScore;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double small = metrics.size(13, min: 11, max: 16);
    if (!isUnlocked) {
      final KidDifficulty previous = difficulty.previous!;
      return Text(
        l10n.finishPreviousTier(l10n.resolve(previous.nameKey)),
        style: TextStyle(
          fontSize: small,
          fontWeight: FontWeight.w700,
          color: KidUi.inkSoft,
        ),
      );
    }
    final double starSize = metrics.size(20, min: 16, max: 26);
    return Row(
      children: <Widget>[
        for (int index = 0; index < 3; index++)
          Icon(
            index < stars ? Icons.star_rounded : Icons.star_border_rounded,
            size: starSize,
            color: index < stars ? KidUi.hint : KidUi.inkSoft,
          ),
        SizedBox(width: metrics.size(8, min: 6, max: 12)),
        Flexible(
          child: Text(
            bestScore == null
                ? l10n.notPlayedYet
                : l10n.tierBestScore(bestScore!),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: small,
              fontWeight: FontWeight.w700,
              color: KidUi.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}
