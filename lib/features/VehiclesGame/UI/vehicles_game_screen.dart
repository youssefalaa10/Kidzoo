import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/database/daos/game_scores_dao.dart';
import '../../../core/database/daos/profile_dao.dart';
import '../../../core/localization/app_localizations.dart';
import '../../QuizEngine/bloc/quiz_cubit.dart';
import '../../QuizEngine/ui/quiz_engine_screen.dart';
import '../data/environment_vehicle_question.dart';

class VehiclesGameScreen extends StatelessWidget {
  const VehiclesGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rawQuestions = generateVehicleQuestions();
    
    // Convert to QuizQuestions
    final questions = rawQuestions.asMap().entries.map((entry) {
      return entry.value.toQuizQuestion(l10n, 'vehicle_q_${entry.key}');
    }).toList();

    return BlocProvider(
      create: (context) => QuizCubit(
        gameScoresDao: context.read<GameScoresDao>(),
        profileDao: context.read<ProfileDao>(),
        flutterTts: context.read<FlutterTts>(),
        audioPlayer: context.read<AudioPlayer>(),
        questions: questions,
        gameKey: 'vehicles_game',
      ),
      child: const QuizEngineScreen(),
    );
  }
}
