import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/base/kid_game_screen.dart';
import 'package:kidzo/core/difficulty/difficulty_run_scope.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/scoring/game_score_recorder.dart';
import 'package:kidzo/core/shared/style/image_manager.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/fluid_container.dart';
import 'package:kidzo/features/Puzzle/bloc/cubit.dart';
import 'package:kidzo/features/Puzzle/bloc/state.dart';
import 'package:kidzo/features/Puzzle/data/model/puzzle_model.dart';
import 'package:kidzo/features/Puzzle/data/puzzle_star_rule.dart';

class PuzzleScreen extends KidGameScreen {
  const PuzzleScreen({required super.level, super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends KidGameScreenState<PuzzleScreen> {
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
          ? PuzzleFrame(index: 0, level: widget.level)
          : widget.level == 2
              // Level 2: auto-select ghost image (index 1)
              ? PuzzleFrame(index: 1, level: widget.level)
              : widget.level == 3
                  // Level 3: auto-select party image (index 2)
                  ? PuzzleFrame(index: 2, level: widget.level)
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
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
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
                onTap: () {
                  // Free play: no level, so the solve is celebrated but not
                  // recorded. The result used to be bubbled up to
                  // LevelMapScreen, which no longer exists.
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(builder: (BuildContext _) {
                      return BlocProvider<PuzzleCubit>(
                        create: (BuildContext _) => PuzzleCubit(),
                        child: PuzzleFrame(index: index),
                      );
                    }),
                  );
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
  const PuzzleFrame({required this.index, super.key, this.level});

  final int index;

  /// The tier this puzzle is being played at, or null for free play.
  ///
  /// Free play deliberately records nothing: it lets a child pick any
  /// picture, so treating it as tier evidence would unlock the harder
  /// puzzles without them ever being solved.
  final int? level;

  @override
  State<PuzzleFrame> createState() => _PuzzleFrameState();
}

class _PuzzleFrameState extends State<PuzzleFrame> {
  bool _completionReturned = false;
  final Stopwatch _solveTime = Stopwatch();
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
    _solveTime.start();
  }


  /// Records the solve and shows the result.
  ///
  /// This used to `pop(true)` so the level map would open the next stage. The
  /// level map is gone and the value was being discarded, so the child now
  /// gets a proper ending with somewhere to go next.
  void _handleCompletion(PuzzleCubit cubit) {
    _solveTime.stop();
    final int pieceCount = cubit.puzzle.length;
    final int elapsed = _solveTime.elapsed.inSeconds;
    final int? level = widget.level;
    if (level != null) {
      unawaited(context.read<GameScoreRecorder>().recordWin(
            gameKey: 'puzzle',
            difficulty: KidDifficulty.fromLevel(level),
            score: cubit.score,
            stars: PuzzleStarRule.rate(
              pieceCount: pieceCount,
              elapsedSeconds: elapsed,
            ),
            maxScore: PuzzleStarRule.maxScoreFor(pieceCount),
            durationSeconds: elapsed,
          ));
    }
    _showResultDialog(elapsed: elapsed, pieceCount: pieceCount);
  }

  void _showResultDialog({required int elapsed, required int pieceCount}) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DifficultyRunScope? scope = DifficultyRunScope.maybeOf(context);
    final int stars = PuzzleStarRule.rate(
      pieceCount: pieceCount,
      elapsedSeconds: elapsed,
    );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KidUi.radiusCard),
        ),
        title: Text(l10n.levelComplete, textAlign: TextAlign.center),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int index = 0; index < 3; index++)
              Icon(
                index < stars
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: KidUi.hint,
                size: 40,
              ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).maybePop();
            },
            child: Text(l10n.exit),
          ),
          if (scope != null && scope.hasNextDifficulty)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                scope.playNext(context);
              },
              child: Text(l10n.nextLevel),
            ),
        ],
      ),
    );
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
          _handleCompletion(cubitPre);
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
          _handleCompletion(cubit);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.puzzleFrame),
        ),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
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
                                            child:
                                                Image.asset(puzzleItem.image)),
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
