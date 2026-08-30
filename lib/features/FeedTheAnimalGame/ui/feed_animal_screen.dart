import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/database/daos/game_scores_dao.dart';
import '../../../core/database/daos/profile_dao.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/background_resolver.dart';
import '../../../core/shared/style/kid_ui.dart';
import '../../../core/shared/widgets/kid_game_shell.dart';
import '../../../core/shared/widgets/kid_pick_card.dart';
import '../../../core/shared/widgets/kid_result_view.dart';
import '../bloc/feed_animal_cubit.dart';
import '../bloc/feed_animal_state.dart';
import '../data/feed_animal_models.dart';
import 'widgets/animal_target.dart';

class FeedAnimalScreen extends StatelessWidget {
  const FeedAnimalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Resolved in build, not in `create`: taking an InheritedWidget dependency
    // inside the create callback throws, because that callback runs once and
    // can never be rebuilt to see an update.
    final l10n = AppLocalizations.of(context);
    final gameScoresDao = context.read<GameScoresDao>();
    final profileDao = context.read<ProfileDao>();
    final flutterTts = context.read<FlutterTts>();
    final audioPlayer = context.read<AudioPlayer>();

    return BlocProvider(
      create: (_) => FeedAnimalCubit(
        gameScoresDao: gameScoresDao,
        profileDao: profileDao,
        flutterTts: flutterTts,
        audioPlayer: audioPlayer,
        l10n: l10n,
      ),
      child: const _FeedAnimalView(),
    );
  }
}

class _FeedAnimalView extends StatelessWidget {
  const _FeedAnimalView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedAnimalCubit, FeedAnimalState>(
      builder: (context, state) {
        final cubit = context.read<FeedAnimalCubit>();

        // Each animal brings its own habitat. The old screen computed this and
        // then threw it away, leaving every round on the same flat cream panel.
        final backgroundType =
            state.roundData?.animal.backgroundType ?? BackgroundType.education;
        final background =
            BackgroundResolver(context, backgroundType).resolveBackground();

        return KidGameShell(
          backgroundAsset: background,
          builder: (context, metrics) {
            if (state.phase == FeedPhase.complete) {
              return KidResultView(
                metrics: metrics,
                score: state.score,
                maxScore: cubit.maxScore,
                onPlayAgain: cubit.restartGame,
              );
            }

            final round = state.roundData;
            if (round == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return _FeedBoard(metrics: metrics, state: state, round: round);
          },
        );
      },
    );
  }
}

class _FeedBoard extends StatelessWidget {
  const _FeedBoard({
    required this.metrics,
    required this.state,
    required this.round,
  });

  final KidMetrics metrics;
  final FeedAnimalState state;
  final GameRoundData round;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<FeedAnimalCubit>();
    final m = metrics;
    final hasSelection = state.selectedFoodId != null;

    final animal = AnimalTarget(
      key: ValueKey(round.animal.id),
      animal: round.animal,
      isSuccess: state.phase == FeedPhase.correct,
      isError: state.phase == FeedPhase.wrong,
      isArmed: hasSelection,
      eatenFood: state.eatenFood,
      onTap: cubit.tapAnimal,
      onFoodDropped: cubit.onFoodDropped,
    );

    final tray = _FoodTray(metrics: m, state: state, round: round);

    return Padding(
      padding: EdgeInsets.all(m.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KidTopBar(
            metrics: m,
            current: state.currentRound,
            total: state.totalRounds,
            score: state.score,
            accent: KidUi.correct,
            onReplayPrompt: cubit.replayPrompt,
          ),
          SizedBox(height: m.gap * 0.75),
          KidPromptBanner(
            metrics: m,
            // The question was previously spoken only. A child who looked away
            // had no way to recover it.
            text: round.getPromptText(l10n),
            hint: hasSelection ? l10n.keepGoing : l10n.tapOrDragHint,
            accent: KidUi.correct,
            onSpeak: cubit.replayPrompt,
          ),
          SizedBox(height: m.gap * 0.75),
          Expanded(
            child: m.isLandscape
                ? Row(
                    children: [
                      Expanded(flex: 5, child: animal),
                      SizedBox(width: m.gap),
                      Expanded(flex: 5, child: tray),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 5, child: animal),
                      SizedBox(height: m.gap),
                      Expanded(flex: 4, child: tray),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FoodTray extends StatelessWidget {
  const _FoodTray({
    required this.metrics,
    required this.state,
    required this.round,
  });

  final KidMetrics metrics;
  final FeedAnimalState state;
  final GameRoundData round;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<FeedAnimalCubit>();
    final spacing = metrics.gap * 0.8;

    return Container(
      padding: EdgeInsets.all(metrics.gap * 0.6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(KidUi.radiusCard),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = kidFitCardSize(
            count: round.choices.length,
            box: Size(constraints.maxWidth, constraints.maxHeight),
            spacing: spacing,
            maxSize: 148,
          );

          return Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: spacing,
              children: round.choices.map((food) {
                return KidPickCard<FeedItem>(
                  key: ValueKey('${state.currentRound}_${food.id}'),
                  imageAsset: food.imageAsset,
                  label: food.getLocalizedName(l10n),
                  size: size,
                  dragData: food,
                  state: _cardState(food),
                  accent: KidUi.correct,
                  onTap: () => cubit.selectFood(food),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  KidCardState _cardState(FeedItem food) {
    final isTarget = food.id == round.targetFood.id;
    // The eaten food leaves its slot empty rather than collapsing the tray, so
    // the remaining cards do not jump under the child's finger.
    if (state.phase == FeedPhase.correct && isTarget) return KidCardState.done;
    if (state.wrongFoodId == food.id) return KidCardState.wrong;
    if (state.selectedFoodId == food.id) return KidCardState.selected;
    if (state.showHint && isTarget) return KidCardState.hint;
    return KidCardState.idle;
  }
}
