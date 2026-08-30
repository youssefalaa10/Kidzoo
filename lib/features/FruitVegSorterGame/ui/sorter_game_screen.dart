import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/shared/widgets/fluid_container.dart';
import '../bloc/sorter_cubit.dart';
import '../bloc/sorter_state.dart';
import '../data/sorter_models.dart';
import 'widgets/basket_target.dart';
import 'widgets/food_draggable.dart';

class SorterGameScreen extends StatelessWidget {
  const SorterGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flutterTts = context.read<FlutterTts>();
    final audioPlayer = context.read<AudioPlayer>();
    final l10n = AppLocalizations.of(context);

    return BlocProvider(
      create: (context) => SorterGameCubit(
        flutterTts: flutterTts,
        audioPlayer: audioPlayer,
        l10n: l10n,
      ),
      child: const _SorterGameView(),
    );
  }
}

class _SorterGameView extends StatelessWidget {
  const _SorterGameView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fruitVegSorterTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => context.read<SorterGameCubit>().replayPrompt(),
          ),
        ],
      ),
      body: BlocBuilder<SorterGameCubit, SorterGameState>(
        builder: (context, state) {
          if (state is SorterGameLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xfffaf5f1),
            child: Builder(builder: (context) {
              if (state is SorterGameComplete) {
                return FluidContainer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 100),
                      const SizedBox(height: 20),
                      Text(
                        l10n.levelComplete,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.replay),
                        label: Text(l10n.playAgain),
                        onPressed: () =>
                            context.read<SorterGameCubit>().restartGame(),
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

              final isSuccess = state is SorterGameSuccess;
              final isError = state is SorterGameWrong;
              final showHint =
                  state is SorterGamePlaying ? state.showHint : false;

              final roundData = state is SorterGamePlaying
                  ? state.roundData
                  : state is SorterGameSuccess
                      ? state.roundData
                      : state is SorterGameWrong
                          ? state.roundData
                          : null;

              final currentRound = state is SorterGamePlaying
                  ? state.currentRound
                  : state is SorterGameSuccess
                      ? state.currentRound
                      : state is SorterGameWrong
                          ? state.currentRound
                          : 1;

              final totalRounds = state is SorterGamePlaying
                  ? state.totalRounds
                  : state is SorterGameSuccess
                      ? state.totalRounds
                      : state is SorterGameWrong
                          ? state.totalRounds
                          : 10;

              final droppedFood =
                  state is SorterGameSuccess ? state.droppedFood : null;

              if (roundData == null) return const SizedBox.shrink();

              final flutterTts = context.read<FlutterTts>();

              return FluidContainer(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${l10n.roundText} $currentRound/$totalRounds',
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

                          final basketsWidget = Expanded(
                            flex: isLandscape ? 1 : 0,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: isLandscape
                                  ? SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: _buildBaskets(
                                            context, roundData.targetFood.type),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: _buildBaskets(context,
                                              roundData.targetFood.type)
                                          .map((w) => Expanded(child: w))
                                          .toList(),
                                    ),
                            ),
                          );

                          final trayWidget = Expanded(
                            flex: isLandscape ? 1 : 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: SingleChildScrollView(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 20,
                                    runSpacing: 20,
                                    children: roundData.choices.map((food) {
                                      final isDropped = isSuccess &&
                                          food.id == roundData.targetFood.id;
                                      final isTarget =
                                          food.id == roundData.targetFood.id;
                                      return FoodDraggable(
                                        food: food,
                                        isDropped: isDropped,
                                        showHint: showHint && isTarget,
                                        flutterTts: flutterTts,
                                        isError: isError &&
                                            isTarget, // Simple way to just pass state down
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          );

                          if (isLandscape) {
                            return Row(
                              children: [
                                basketsWidget,
                                trayWidget,
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                const SizedBox(height: 10),
                                basketsWidget,
                                const Spacer(),
                                trayWidget,
                                const SizedBox(height: 20),
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

  List<Widget> _buildBaskets(BuildContext context, FoodType? targetBasketType) {
    final l10n = AppLocalizations.of(context);
    return [
      BasketTarget(
        basketType: FoodType.fruit,
        label: l10n.fruitsBasket,
        icon: Icons.shopping_basket_rounded,
        color: Colors.orange,
        isTargetBasket: targetBasketType == FoodType.fruit,
        onFoodDropped: (food) {
          context.read<SorterGameCubit>().onFoodDropped(food, FoodType.fruit);
        },
      ),
      BasketTarget(
        basketType: FoodType.vegetable,
        label: l10n.vegetablesBasket,
        icon: Icons.shopping_cart_rounded,
        color: Colors.green,
        isTargetBasket: targetBasketType == FoodType.vegetable,
        onFoodDropped: (food) {
          context
              .read<SorterGameCubit>()
              .onFoodDropped(food, FoodType.vegetable);
        },
      ),
    ];
  }
}
