import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/base/protected_game_screen.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/services/background_resolver.dart';
import 'package:kidzo/core/shared/style/image_manager.dart';
import 'package:kidzo/core/shared/widgets/fluid_container.dart';
import 'package:kidzo/features/Puzzle/bloc/cubit.dart';
import 'package:kidzo/features/Puzzle/bloc/state.dart';
import 'package:kidzo/features/Puzzle/data/model/puzzle_model.dart';

class PuzzleScreen extends ProtectedGameScreen {
  const PuzzleScreen({required super.level, super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ProtectedGameScreenState<PuzzleScreen> {
  @override
  void onGameInit() {}

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Adjust grid size based on level (3x3 for level 1, 4x4 for level 2, 5x5 for level 3+)
    final gridSize = widget.level == 1 ? 3 : (widget.level == 2 ? 4 : 5);

    return BlocProvider(
      create: (context) => PuzzleCubit(),
      child: widget.level == 1
          // Level 1: auto-select default image (index 0) and go straight to the puzzle
          ? const PuzzleFrame(index: 0)
          : widget.level == 2
              // Level 2: auto-select ghost image (index 1)
              ? const PuzzleFrame(index: 1)
              : widget.level == 3
                  // Level 3: auto-select party image (index 2)
                  ? const PuzzleFrame(index: 2)
                  // Other levels: let the user choose the image
                  : ImageSelectionPage(gridSize: gridSize, level: widget.level),
    );
  }
}

class ImageSelectionPage extends StatelessWidget {
  const ImageSelectionPage({required this.gridSize, super.key, this.level = 1});
  final int gridSize;
  final int level;

  @override
  Widget build(BuildContext context) {
    // In a real app, you would fetch images from assets or network
    // For this example, we'll use placeholder URLs

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectAnImage),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(BackgroundResolver(context, BackgroundType.game).resolveBackground()!),
            fit: BoxFit.cover,
          ),
        ),
        child: FluidContainer(
          padding: EdgeInsets.zero,
          child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: sampleImages.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () async {
              // In a real app, pass the actual image data
              // For this example, we'll just use the URL
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) {
                  return BlocProvider(
                    create: (context) => PuzzleCubit(),
                    child: PuzzleFrame(index: index),
                  );
                }),
              );
              if (result == true) {
                // Bubble the completion up to LevelMapScreen
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                sampleImages[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
      ),
      ),
    );
  }
}

class PuzzleFrame extends StatefulWidget {
  const PuzzleFrame({required this.index, super.key});
  final int index;

  @override
  State<PuzzleFrame> createState() => _PuzzleFrameState();
}

class _PuzzleFrameState extends State<PuzzleFrame> {
  bool _completionReturned = false;
  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PuzzleCubit>().selectImage(widget.index);
        context.read<PuzzleCubit>().initGame();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Extra guard: if already completed, return true
    final cubitPre = context.read<PuzzleCubit>();
    if (!_completionReturned &&
        cubitPre.choosePiece.isEmpty &&
        cubitPre.puzzle.isNotEmpty) {
      _completionReturned = true;
      cubitPre.gameOver = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    }

    return BlocListener<PuzzleCubit, PuzzleState>(
      listener: (context, state) {
        final cubit = context.read<PuzzleCubit>();
        if (!_completionReturned &&
            cubit.choosePiece.isEmpty &&
            cubit.puzzle.isNotEmpty) {
          _completionReturned = true;
          cubit.gameOver = true;
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.puzzleFrame),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(BackgroundResolver(context, BackgroundType.game).resolveBackground()!),
              fit: BoxFit.cover,
            ),
          ),
          child: FluidContainer(
            padding: EdgeInsets.zero,
            child: BlocBuilder<PuzzleCubit, PuzzleState>(
          builder: (context, state) {
            final cubit = context.read<PuzzleCubit>();
            // Check if puzzle data is ready
            if (cubit.puzzle.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(children: [
                      Container(
                        height: widget.index == 2 ? 300 : 200,
                        width: widget.index == 2 ? 300 : 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            opacity: .5,
                            image: AssetImage(sampleImages[widget.index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: widget.index == 2 ? 3 : 2,
                            ),
                            itemCount: cubit.puzzle.length,
                            itemBuilder: (context, i) {
                              return DraggableItem(
                                  puzzle: cubit.puzzle,
                                  choosePiece: cubit.choosePiece,
                                  index: i,
                                  score: cubit.score);
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: SingleChildScrollView(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: cubit.choosePiece.map((puzzleItem) {
                                return Draggable<PuzzleModel>(
                                  data: puzzleItem,
                                  childWhenDragging: Container(
                                    height: widget.index == 2 ? 60 : 80,
                                    width: widget.index == 2 ? 60 : 80,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        opacity: .5,
                                        image: AssetImage(puzzleItem.image),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  feedback: SizedBox(
                                      height: widget.index == 2 ? 80 : 100,
                                      width: widget.index == 2 ? 80 : 100,
                                      child: Image.asset(puzzleItem.image)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: SizedBox(
                                        height: widget.index == 2 ? 60 : 80,
                                        width: widget.index == 2 ? 60 : 80,
                                        child: Image.asset(puzzleItem.image)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      Text('${l10n.yourScore} ${cubit.score}',
                          style: const TextStyle(fontSize: 20)),
                    ])));
          },
        ),
        ),
        ),
      ),
    );
  }

  // Completion dialog removed in favor of auto-pop on completion
}

class DraggableItem extends StatefulWidget {
  const DraggableItem(
      {required this.puzzle,
      required this.choosePiece,
      required this.index,
      required this.score,
      super.key});
  final List<PuzzleModel> puzzle;
  final List<PuzzleModel> choosePiece;
  final int index;
  final int score;

  @override
  State<DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<DraggableItem> {
  @override
  Widget build(BuildContext context) {
    // Check if the puzzle array has enough elements
    if (widget.puzzle.isEmpty || widget.index >= widget.puzzle.length) {
      return SizedBox(
        height: 50,
        width: 50,
        child: Container(), // Empty container while loading
      );
    }

    final puzzleItem = widget.puzzle[widget.index];
    return DragTarget<PuzzleModel>(
      builder: (context, candidateData, rejectedData) {
        return SizedBox(
          height: 50,
          width: 50,
          child: puzzleItem.accepting
              ? Image.asset(
                  puzzleItem.image,
                  fit: BoxFit.cover,
                )
              : Container(),
        );
      },
      onAcceptWithDetails: (receivedData) {
        if (receivedData.data.index == widget.index) {
          setState(() {
            widget.choosePiece
                .removeWhere((item) => item.index == receivedData.data.index);

            puzzleItem.accepting = true;
            context.read<PuzzleCubit>().updateScore(25);
          });
        }
      },
      onWillAcceptWithDetails: (
        receivedData,
      ) {
        if (receivedData.data.index == widget.index) {
          setState(() {
            //puzzleItem.accepting = true;
          });
          return true;
        }
        return false;
      },
      onLeave: (_) {
        setState(() {
          if (!puzzleItem.accepting) {
            puzzleItem.accepting = false;
          }
        });
      },
    );
  }
}

final List<String> sampleImages = [
  ImageManager.gazelle,
  ImageManager.ghost,
  ImageManager.party
];
