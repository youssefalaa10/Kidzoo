import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'Data/Logic/Model/level_model.dart';
import 'Data/Logic/cubit/levelmap_cubit.dart';
import 'Widgets/level_button.dart';

class LevelMapScreen extends StatelessWidget {
  // Define the height of the background image (adjust based on actual image height)
  final double backgroundHeight = 2000;

  const LevelMapScreen(
      {super.key}); // Example height in pixels (adjust as needed)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => LevelCubit(),
        child: SingleChildScrollView(
          child: SizedBox(
            height:
                backgroundHeight, // Set the container height to match the image
            child: Stack(
              children: [
                // Background Image
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/home/Fav.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Level Buttons
                BlocBuilder<LevelCubit, List<Level>>(
                  builder: (context, levels) {
                    return Stack(
                      children: levels.map((level) {
                        return Positioned(
                          left: level.positionX,
                          top: level.positionY,
                          child: LevelButton(
                            level: level,
                            onTap: () {
                              if (!level.isLocked) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Playing Level ${level.id}')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Level ${level.id} is locked!')),
                                );
                              }
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

