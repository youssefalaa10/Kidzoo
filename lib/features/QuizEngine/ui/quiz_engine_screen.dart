import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/shared/widgets/fluid_container.dart';
import '../bloc/quiz_cubit.dart';
import '../bloc/quiz_state.dart';
import 'widgets/quiz_options_row.dart';
import 'widgets/quiz_scene_card.dart';

class QuizEngineScreen extends StatelessWidget {
  const QuizEngineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xfffaf5f1),
        child: BlocBuilder<QuizCubit, QuizState>(
        builder: (context, state) {
          if (state is QuizLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is QuizCompleted) {
            return FluidContainer(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Quiz Completed!',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 20),
                  Text('Score: ${state.finalScore}',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Menu'),
                  ),
                ],
              ),
            );
          }

          if (state is QuizActive || state is QuizFeedback) {
            final question = state is QuizActive
                ? state.question
                : (state as QuizFeedback).question;
            final score = state is QuizActive
                ? state.score
                : (state as QuizFeedback).score;
            final isFeedback = state is QuizFeedback;

            return FluidContainer(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text('Score: $score',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Text(question.prompt,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    QuizSceneCard(imagePath: question.imageOrScenePath),
                    const SizedBox(height: 20), // Replace Spacer with SizedBox
                    QuizOptionsRow(
                      options: question.options,
                      showFeedback: isFeedback,
                      onOptionSelected: (option) {
                        if (!isFeedback) {
                          context.read<QuizCubit>().submitAnswer(option);
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      ),
    );
  }
}
