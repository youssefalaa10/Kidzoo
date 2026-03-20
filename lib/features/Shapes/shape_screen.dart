import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/core/localization/app_localizations.dart';
import 'package:kidzoo/core/mixins/background_music_mixin.dart';
import 'package:kidzoo/core/services/cubit/music_cubit.dart';
import 'package:kidzoo/features/Shapes/bloc/shape_cubit.dart';
import 'package:kidzoo/features/Shapes/bloc/shape_states.dart';
import 'package:kidzoo/features/Shapes/widgets/complete_screen.dart';
import 'package:kidzoo/features/Shapes/widgets/shape_app_bar.dart';
import 'package:kidzoo/features/Shapes/widgets/shape_display.dart';
import 'package:kidzoo/features/Shapes/widgets/shape_selection.dart';

import '../../core/helpers/tts_helper.dart';
import 'data/model/shape_model.dart';

class ShapeScreen extends StatefulWidget {
  const ShapeScreen({super.key});

  @override
  State<ShapeScreen> createState() => _ShapeScreenState();
}

class _ShapeScreenState extends State<ShapeScreen> with TTSMusicMixin {
  TtsHelper? _ttsHelper;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ttsHelper == null) {
      final musicCubit = context.read<MusicCubit>();
      final languageCode = Localizations.localeOf(context).languageCode;
      _ttsHelper = TtsHelper(
        musicCubit: musicCubit,
        languageCode: languageCode,
      );
    }
  }

  @override
  void dispose() {
    _ttsHelper?.stop();
    super.dispose();
  }
  String _localizedShapeName(BuildContext context, String shape) {
    final l10n = AppLocalizations.of(context);
    final map = {
      'Square': l10n.square,
      'Triangle': l10n.triangle,
      'Circle': l10n.circle,
      'Cylinder': l10n.cylinder,
      'Diamond': l10n.diamond,
      'Pentagon': l10n.pentagon,
      'Hexagon': l10n.hexagon,
      'Star': l10n.star,
    };
    return map[shape] ?? shape;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final int crossAxisCount = screenWidth < 600
        ? 2
        : screenWidth < 900
            ? 2
            : 3;
    final double childAspectRatio = screenWidth < 600 ? .7 : 1.5;

    return Scaffold(
      backgroundColor: const Color(0xfffff8f2),
      body: BlocConsumer<ShapeCubit, ShapeStates>(
        listener: (context, state) {},
        builder: (context, state) {
          final cubit = context.watch<ShapeCubit>();
          final l10n = AppLocalizations.of(context);
          if (cubit.score == 80) _ttsHelper?.speak(l10n.excellent);
          final matchedShapes = cubit.matchedShapes;
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
                                                _ttsHelper?.speak(_localizedShapeName(context, data.shape));
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
