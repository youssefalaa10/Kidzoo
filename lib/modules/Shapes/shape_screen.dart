import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_cubit.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_states.dart';
import 'package:kidzoo/modules/Shapes/widgets/shape_app_bar.dart';

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
    double childAspectRatio = screenWidth < 600 ? .9 : 1.5;
    int selectionCrossAxisCount = screenWidth < 600
        ? 1
        : screenWidth < 900
            ? 2
            : 3;
    double selectionChildAspectRatio = screenWidth < 600 ? 1.6 : 1.5;

    return Scaffold(
      backgroundColor: const Color(0xffecf3f0),
      body: BlocConsumer<ShapeCubit, ShapeStates>(
        listener: (context, state) {},
        builder: (context, state) {
          var cubit = context.watch<ShapeCubit>();
          final matchedShapes = cubit.matchedShapes;
          cubit.init();
          return cubit.score == 80
              ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            "Game Over",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            cubit.result(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.width / 10,
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        cubit.gameOver();
                      },
                      child: Text(
                        'Play Again',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
              : Row(
                  children: [
                    // Left side: Shape display area
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 50, horizontal: 10),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Icon(
                                          Icons.arrow_back,
                                          size: 30,
                                        )),
                                    const Text(
                                      'Shapes',
                                      style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Score: ',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                        TextSpan(
                                          text: cubit.score.toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(color: Colors.teal),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              shrinkWrap: true,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 10,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: cubit.temps.length,
                              itemBuilder: (context, index) {
                                final temp = cubit.temps[index];
                                final isMatched = matchedShapes.contains(temp);

                                return DragTarget<ShapeModel>(
                                  onWillAccept: (data) =>
                                      !isMatched && data?.temp == temp,
                                  onAccept: (data) {
                                    if (data != null && data.temp == temp) {
                                      cubit.shapes.remove(data);
                                      cubit.score += 10;
                                      context.read<ShapeCubit>().addMatch(temp);
                                      ttsHelper.speak("Great!.");
                                      if (cubit.shapes.isEmpty) cubit.init();
                                    }
                                  },
                                  builder:
                                      (context, candidateData, rejectedData) {
                                    return Container(
                                      margin: const EdgeInsets.all(10),
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: isMatched
                                            ? Colors.green[100]
                                            : Colors.white,
                                        border: Border.all(
                                          color: isMatched
                                              ? Colors.green
                                              : Colors.grey,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: isMatched
                                            ? Icon(Icons.check,
                                                color: Colors.green, size: 30)
                                            : SvgPicture.asset(temp),
                                      ),
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
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: Colors.white,
                        child: GridView.builder(
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: selectionCrossAxisCount,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: selectionChildAspectRatio,
                          ),
                          itemCount: cubit.shapes.length,
                          itemBuilder: (context, index) {
                            final shape = cubit.shapes[index];

                            return GestureDetector(
                              onTap: () => ttsHelper.speak(shape.shape),
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Draggable<ShapeModel>(
                                  data: shape,
                                  feedback: Container(
                                    width: 80,
                                    height: 80,
                                    child: Image.asset(shape.imagePath),
                                  ),
                                  child: Image.asset(shape.imagePath),
                                  childWhenDragging: Image.asset(
                                    shape.imagePath,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }
}
