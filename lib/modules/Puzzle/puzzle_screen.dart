import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/models/puzzle_model.dart';
import 'package:kidzoo/modules/Puzzle/bloc/cubit.dart';
import 'package:kidzoo/modules/Puzzle/bloc/state.dart';
import 'package:kidzoo/shared/style/image_manager.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  //late final PuzzleCubit puzzleCubit;

  @override
  void initState() {
    super.initState();
    //puzzleCubit = PuzzleCubit();
  }

  @override
  void dispose() {
    //puzzleCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<PuzzleCubit, PuzzleState>(
          listener: (context, state) {},
          builder: (context, state) {
            return const Center(
              child: SizedBox(
                height: 500,
                width: 250,
                child: ImageSelectionPage(gridSize: 4),
              ),
            );
          }),
    );
  }
}

class ImageSelectionPage extends StatelessWidget {
  final int gridSize;

  const ImageSelectionPage({super.key, required this.gridSize});

  @override
  Widget build(BuildContext context) {
    // In a real app, you would fetch images from assets or network
    // For this example, we'll use placeholder URLs

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select an Image'),
      ),
      body: GridView.builder(
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
              // In a real app, pass the actual image data
              // For this example, we'll just use the URL
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return BlocProvider(
                  create: (context) => PuzzleCubit(),
                  child: PuzzleFrame(
                    index: index,
                  ),
                );
              }));
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
    );
  }
}

class PuzzleFrame extends StatefulWidget {
  final int index;
  const PuzzleFrame({super.key, required this.index});

  @override
  State<PuzzleFrame> createState() => _PuzzleFrameState();
}

class _PuzzleFrameState extends State<PuzzleFrame> {
  @override
  void initState() {
    super.initState();
    context.read<PuzzleCubit>().selectImage(widget.index);
    context.read<PuzzleCubit>().initGame();
  }

  @override
  Widget build(BuildContext context) {
    // Check if the game is over
    var cubit = context.read<PuzzleCubit>();
    if (!cubit.gameOver &&
        cubit.puzzle.isEmpty &&
        cubit.choosePiece.isEmpty &&
        cubit.score == 100) {
      setState(() {
        cubit.gameOver = true;
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle Frame'),
      ),
      body: BlocBuilder<PuzzleCubit, PuzzleState>(
        builder: (context, state) {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: [
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          opacity: .5,
                          image: AssetImage(sampleImages[widget.index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: GridView(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                        ),
                        children: [
                          DraggableItem(
                              puzzle: cubit.puzzle,
                              choosePiece: cubit.choosePiece,
                              index: 0,
                              score: cubit.score),
                          DraggableItem(
                              puzzle: cubit.puzzle,
                              choosePiece: cubit.choosePiece,
                              index: 1,
                              score: cubit.score),
                          DraggableItem(
                              puzzle: cubit.puzzle,
                              choosePiece: cubit.choosePiece,
                              index: 2,
                              score: cubit.score),
                          DraggableItem(
                              puzzle: cubit.puzzle,
                              choosePiece: cubit.choosePiece,
                              index: 3,
                              score: cubit.score),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      width: 400,
                      child: Row(
                        children: cubit.choosePiece.map((puzzleItem) {
                          return Draggable<PuzzleModel>(
                            data: puzzleItem,
                            childWhenDragging: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  opacity: .5,
                                  image: AssetImage(puzzleItem.image),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            feedback: SizedBox(
                                height: 100,
                                width: 100,
                                child: Image.asset(puzzleItem.image)),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                  height: 50,
                                  width: 50,
                                  child: Image.asset(puzzleItem.image)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Text('Your Score: ${cubit.score}',
                        style: const TextStyle(fontSize: 20)),
                  ])));
        },
      ),
    );
  }
}

class DraggableItem extends StatefulWidget {
  final List<PuzzleModel> puzzle;
  final List<PuzzleModel> choosePiece;
  final int index;
  final int score;
  const DraggableItem(
      {super.key,
      required this.puzzle,
      required this.choosePiece,
      required this.index,
      required this.score});

  @override
  State<DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<DraggableItem> {
  @override
  Widget build(BuildContext context) {
    var puzzleItem = widget.puzzle[widget.index];
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

final List<String> sampleImages = [ImageManager.gazelle, ImageManager.ghost];
