import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/modules/Puzzle/bloc/cubit.dart';
import 'package:kidzoo/modules/Puzzle/bloc/state.dart';
import 'package:easy_puzzle_game/easy_puzzle_game.dart';
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
                child: EasyPuzzleGameApp(
                  title: 'Puzzle',
                  puzzleFullImg: ImageManager.puzzleImage4,
                  puzzleBlockFolderPath: ImageManager.puzzleBlocks4,
                  puzzleRowColumn: 3,
                ),
              ),
            );
          }),
    );
  }
}
