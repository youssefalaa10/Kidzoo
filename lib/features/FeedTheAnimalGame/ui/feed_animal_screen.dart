import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/database/daos/game_scores_dao.dart';
import '../../../core/database/daos/profile_dao.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/background_resolver.dart';
import '../../../core/shared/widgets/fluid_container.dart';
import '../bloc/feed_animal_cubit.dart';
import '../bloc/feed_animal_state.dart';
import 'widgets/animal_target.dart';
import 'widgets/fruit_draggable.dart';

class FeedAnimalScreen extends StatelessWidget {
  const FeedAnimalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameScoresDao = context.read<GameScoresDao>();
    final profileDao = context.read<ProfileDao>();
    final flutterTts = context.read<FlutterTts>();
    final audioPlayer = context.read<AudioPlayer>();
    final l10n = AppLocalizations.of(context);

    return BlocProvider(
      create: (context) => FeedAnimalCubit(
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).education),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => context.read<FeedAnimalCubit>().replayPrompt(),
          ),
        ],
      ),
      body: BlocBuilder<FeedAnimalCubit, FeedAnimalState>(
        builder: (context, state) {
          if (state is FeedAnimalLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final roundData = state is FeedAnimalPlaying
              ? state.roundData
              : state is FeedAnimalSuccess
                  ? state.roundData
                  : state is FeedAnimalWrong
                      ? state.roundData
                      : null;

          final backgroundType =
              roundData?.animal.backgroundType ?? BackgroundType.education;

          return Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xfffaf5f1),
            child: Builder(builder: (context) {
              if (state is FeedAnimalComplete) {
                return FluidContainer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 100),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context).levelComplete,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.replay),
                        label: Text(AppLocalizations.of(context).playAgain),
                        onPressed: () =>
                            context.read<FeedAnimalCubit>().restartGame(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          textStyle: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final isSuccess = state is FeedAnimalSuccess;
              final isError = state is FeedAnimalWrong;
              final showHint =
                  state is FeedAnimalPlaying ? state.showHint : false;

              final roundData = state is FeedAnimalPlaying
                  ? state.roundData
                  : state is FeedAnimalSuccess
                      ? state.roundData
                      : state is FeedAnimalWrong
                          ? state.roundData
                          : null;

              final currentRound = state is FeedAnimalPlaying
                  ? state.currentRound
                  : state is FeedAnimalSuccess
                      ? state.currentRound
                      : state is FeedAnimalWrong
                          ? state.currentRound
                          : 1;

              final totalRounds = state is FeedAnimalPlaying
                  ? state.totalRounds
                  : state is FeedAnimalSuccess
                      ? state.totalRounds
                      : state is FeedAnimalWrong
                          ? state.totalRounds
                          : 10;

              final droppedFood =
                  state is FeedAnimalSuccess ? state.droppedFood : null;

              if (roundData == null) return const SizedBox.shrink();

              final flutterTts = context.read<FlutterTts>();

              return FluidContainer(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Round $currentRound/$totalRounds',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isLandscape =
                              constraints.maxWidth > constraints.maxHeight;

                          // Available space for the animal (flex 3) and the
                          // food tray (flex 2), matching the 3:2 split used
                          // below, so sizes are derived from real space
                          // instead of fixed pixels that could overflow and
                          // force a scroll on small screens.
                          final animalAreaHeight = isLandscape
                              ? constraints.maxHeight - 40
                              : (constraints.maxHeight * 3 / 5) - 40;
                          final animalMaxHeight =
                              animalAreaHeight.clamp(120.0, 350.0);

                          final trayAreaWidth = isLandscape
                              ? (constraints.maxWidth * 2 / 5) - 40
                              : constraints.maxWidth - 40;
                          final trayAreaHeight = isLandscape
                              ? constraints.maxHeight - 40
                              : (constraints.maxHeight * 2 / 5) - 40;

                          final choiceCount = roundData.choices.length;
                          final widthPerCard = (trayAreaWidth -
                                  20 * (choiceCount + 1)) /
                              choiceCount;
                          var cardWidth = widthPerCard.clamp(60.0, 140.0);
                          final approxCardHeight = cardWidth * 1.25;
                          if (approxCardHeight > trayAreaHeight) {
                            cardWidth =
                                (trayAreaHeight / 1.25).clamp(60.0, cardWidth);
                          }
                          final cardScale = cardWidth / 140.0;

                          final animalContent = Center(
                            child: AnimalTarget(
                              animal: roundData.animal,
                              isSuccess: isSuccess,
                              isError: isError,
                              eatenFood: droppedFood,
                              maxHeight: animalMaxHeight,
                              onFoodDropped: (food) {
                                context
                                    .read<FeedAnimalCubit>()
                                    .onFoodDropped(food);
                              },
                            ),
                          );

                          final trayContent = Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 20,
                                runSpacing: 20,
                                children: roundData.choices.map((food) {
                                  final isDropped = isSuccess &&
                                      food.id == roundData.targetFood.id;
                                  final isTarget =
                                      food.id == roundData.targetFood.id;
                                  return FruitDraggable(
                                    food: food,
                                    isDropped: isDropped,
                                    showHint: showHint && isTarget,
                                    flutterTts: flutterTts,
                                    scale: cardScale,
                                  );
                                }).toList(),
                              ),
                            ),
                          );

                          if (isLandscape) {
                            return Row(
                              children: [
                                Expanded(flex: 3, child: animalContent),
                                Expanded(flex: 2, child: trayContent),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                const SizedBox(height: 12),
                                Expanded(flex: 3, child: animalContent),
                                const SizedBox(height: 12),
                                Expanded(flex: 2, child: trayContent),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
