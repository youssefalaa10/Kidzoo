import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_cubit.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_states.dart';
import 'package:kidzoo/modules/Shapes/widgets/complete_screen.dart';
import 'package:kidzoo/modules/Shapes/widgets/shape_app_bar.dart';
import 'package:kidzoo/modules/Shapes/widgets/shape_display.dart';
import 'package:kidzoo/modules/Shapes/widgets/shape_selection.dart';
import '../../models/shape_model.dart';
import '../../shared/tts_helper.dart';

class ShapeScreen extends StatelessWidget {
  const ShapeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TtsHelper ttsHelper = TtsHelper();

    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = screenWidth < 600
        ? 2
        : screenWidth < 900
            ? 2
            : 3;
    double childAspectRatio = screenWidth < 600 ? .7 : 1.5;

    return Scaffold(
      backgroundColor: const Color(0xfffff8f2),
      body: BlocConsumer<ShapeCubit, ShapeStates>(
        listener: (context, state) {},
        builder: (context, state) {
          var cubit = context.watch<ShapeCubit>();
          if (cubit.score == 80) ttsHelper.speak("Excellent!.");
          final matchedShapes = cubit.matchedShapes;
          cubit.init();
          return cubit.score == 80
              ? CompleteScreen(
                  onPressedGameOVer: () {
                    cubit.gameOver();
                  },
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ShapeAppBar(
                          onTapGameOVer: () {
                            cubit.gameOver();
                          },
                          score: cubit.score.toString(),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              // Left side: Shape display area
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          mainAxisSpacing: 1,
                                          childAspectRatio: childAspectRatio,
                                        ),
                                        itemCount: cubit.temps.length,
                                        itemBuilder: (context, index) {
                                          final temp = cubit.temps[index];
                                          final isMatched =
                                              matchedShapes.contains(temp);
                                          return DragTarget<ShapeModel>(
                                            onWillAcceptWithDetails: (details) {
                                              final data = details.data;
                                              return !isMatched &&
                                                  data.temp == temp;
                                            },
                                            onAcceptWithDetails: (details) {
                                              final data = details.data;
                                              if (data.temp == temp) {
                                                cubit.shapes.remove(data);
                                                cubit.score += 10;
                                                context
                                                    .read<ShapeCubit>()
                                                    .addMatch(temp);
                                                ttsHelper.speak("Great!.");
                                                if (cubit.shapes.isEmpty) {
                                                  cubit.init();
                                                }
                                              }
                                            },
                                            builder: (context, candidateData,
                                                rejectedData) {
                                              return ShapeSelection(
                                                isMatched: isMatched,
                                                temp: temp,
                                                index: index,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Right side: Draggable shapes area
                              ShapeDisplay(
                                shapes: cubit.shapes,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
}
