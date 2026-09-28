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
import '../bloc/sorter_cubit.dart';
import '../bloc/sorter_state.dart';
import '../data/sorter_models.dart';
import 'widgets/basket_target.dart';

class SorterGameScreen extends StatelessWidget {
  const SorterGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Everything is resolved here, in build, and captured by the closure.
    //
    // `AppLocalizations.of` reaches for an InheritedWidget, and doing that
    // inside `create` throws: the create callback runs once and can never be
    // rebuilt, so it is not allowed to take a dependency. The cubit was then
    // never constructed, which surfaced later as a null cast on the first
    // `context.read<SorterGameCubit>()`.
    final l10n = AppLocalizations.of(context);
    final flutterTts = context.read<FlutterTts>();
    final audioPlayer = context.read<AudioPlayer>();
    final gameScoresDao = context.read<GameScoresDao>();
    final profileDao = context.read<ProfileDao>();

    return BlocProvider<SorterGameCubit>(
      create: (_) => SorterGameCubit(
        flutterTts: flutterTts,
        audioPlayer: audioPlayer,
        l10n: l10n,
        gameScoresDao: gameScoresDao,
        profileDao: profileDao,
      ),
      child: const _SorterGameView(),
    );
  }
}

class _SorterGameView extends StatelessWidget {
  const _SorterGameView();

  @override
  Widget build(BuildContext context) {
    final background = BackgroundResolver(context, BackgroundType.education)
        .resolveBackground();

    // The bloc is subscribed above the shell, so state changes rebuild through
    // a normal build pass rather than from inside the shell's LayoutBuilder,
    // whose callback runs during layout.
    return BlocBuilder<SorterGameCubit, SorterGameState>(
      builder: (context, state) {
        final cubit = context.read<SorterGameCubit>();

        return KidGameShell(
          backgroundAsset: background,
          builder: (context, metrics) {
            if (state.phase == SorterPhase.complete) {
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

            return _SorterBoard(metrics: metrics, state: state, round: round);
          },
        );
      },
    );
  }
}

class _SorterBoard extends StatelessWidget {
  const _SorterBoard({
    required this.metrics,
    required this.state,
    required this.round,
  });

  final KidMetrics metrics;
  final SorterGameState state;
  final SorterGameRoundData round;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SorterGameCubit>();
    final m = metrics;

    final hasSelection = state.selectedFoodId != null;
    final accent =
        round.targetBasket == FoodType.fruit ? KidUi.fruit : KidUi.vegetable;

    final baskets = _Baskets(metrics: m, state: state, round: round);
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
            accent: accent,
            onReplayPrompt: cubit.replayPrompt,
          ),
          SizedBox(height: m.gap * 0.75),
          KidPromptBanner(
            metrics: m,
            text: round.getPromptText(l10n),
            // The hint line changes with what the child is holding, so the
            // two-step tap flow explains itself without a tutorial.
            hint: hasSelection ? l10n.tapBasketHint : l10n.tapOrDragHint,
            accent: accent,
            onSpeak: cubit.replayPrompt,
          ),
          SizedBox(height: m.gap * 0.75),
          Expanded(
            child: m.isLandscape
                ? Row(
                    children: [
                      Expanded(flex: 4, child: baskets),
                      SizedBox(width: m.gap),
                      Expanded(flex: 6, child: tray),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 4, child: baskets),
                      SizedBox(height: m.gap),
                      Expanded(flex: 5, child: tray),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Baskets extends StatelessWidget {
  const _Baskets({
    required this.metrics,
    required this.state,
    required this.round,
  });

  final KidMetrics metrics;
  final SorterGameState state;
  final SorterGameRoundData round;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SorterGameCubit>();
    final spacing = metrics.gap;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Baskets stack in landscape (tall, narrow column) and sit side by side
        // in portrait, always square and always inside their box.
        final stacked = metrics.isLandscape;
        final size = kidFitCardSize(
          count: 2,
          box: Size(constraints.maxWidth, constraints.maxHeight),
          spacing: spacing,
          minSize: 84,
          maxSize: 210,
        );

        Widget basket(FoodType type) {
          final isTarget = round.targetBasket == type;
          return BasketTarget(
            label: type == FoodType.fruit
                ? l10n.fruitsBasket
                : l10n.vegetablesBasket,
            color: type == FoodType.fruit ? KidUi.fruit : KidUi.vegetable,
            size: size,
            isHinted: state.showHint && isTarget,
            isArmed: state.selectedFoodId != null,
            isWrong: state.wrongBasket == type,
            onTap: () => cubit.tapBasket(type),
            onFoodDropped: (food) => cubit.dropFood(food, type),
          );
        }

        return Flex(
          direction: stacked ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            basket(FoodType.fruit),
            basket(FoodType.vegetable),
          ],
        );
      },
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
  final SorterGameState state;
  final SorterGameRoundData round;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SorterGameCubit>();
    final spacing = metrics.gap * 0.8;
    final padding = metrics.gap * 0.6;

    return Container(
      padding: EdgeInsets.all(padding),
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
                return KidPickCard<FoodItem>(
                  key: ValueKey('${state.currentRound}_${food.id}'),
                  imageAsset: food.imageAsset,
                  label: food.getLocalizedName(l10n),
                  size: size,
                  dragData: food,
                  state: _cardState(food),
                  accent: food.type == FoodType.fruit
                      ? KidUi.fruit
                      : KidUi.vegetable,
                  onTap: () => cubit.selectFood(food),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  KidCardState _cardState(FoodItem food) {
    final isTarget = food.id == round.targetFood.id;
    if (state.phase == SorterPhase.correct && isTarget) {
      return KidCardState.correct;
    }
    if (state.wrongFoodId == food.id) return KidCardState.wrong;
    if (state.selectedFoodId == food.id) return KidCardState.selected;
    if (state.showHint && isTarget) return KidCardState.hint;
    return KidCardState.idle;
  }
}
