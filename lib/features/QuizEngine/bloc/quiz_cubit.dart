import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';

import '../data/quiz_models.dart';
import 'quiz_state.dart';

class QuizCubit extends Cubit<QuizState> {

  final bool allowRetries;
  final String? tryAgainText;
  final Duration transitionDuration;
  final Duration wrongFeedbackDuration;

  QuizCubit({
    required this.gameScoresDao,
    required this.profileDao,
    required this.flutterTts,
    required this.audioPlayer,
    required List<QuizQuestion> questions,
    required String gameKey,
    this.allowRetries = false,
    this.tryAgainText,
    this.transitionDuration = const Duration(seconds: 2),
    this.wrongFeedbackDuration = const Duration(seconds: 2),
  })  : _questions = questions,
        _gameKey = gameKey,
        super(QuizLoading()) {
    _startQuiz();
  }
  final GameScoresDao gameScoresDao;
  final ProfileDao profileDao;
  final FlutterTts flutterTts;
  final AudioPlayer audioPlayer;

  final List<QuizQuestion> _questions;
  final String _gameKey;

  int _currentIndex = 0;
  int _score = 0;

  void _startQuiz() {
    if (_questions.isEmpty) {
      emit(const QuizCompleted(0));
      return;
    }
    emit(QuizActive(_questions[_currentIndex], _score, _currentIndex));
    _speakPrompt(_questions[_currentIndex].prompt);
  }

  Future<void> _speakPrompt(String text) async {
    try {
      await flutterTts.speak(text);
    } catch (_) {}
  }

  Future<void> submitAnswer(QuizOption option) async {
    final isCorrect = option.isCorrect;
    if (isCorrect) {
      _score += 10;
      try {
        await flutterTts.speak(option.text);
      } catch (_) {}
    } else if (allowRetries) {
      try {
        await flutterTts.speak(tryAgainText ?? "Try again");
      } catch (_) {}
    }

    emit(QuizFeedback(
        _questions[_currentIndex], isCorrect, _score, _currentIndex));

    final delay = isCorrect ? transitionDuration : wrongFeedbackDuration;
    await Future.delayed(delay);

    if (isClosed) return;

    if (isCorrect || !allowRetries) {
      _currentIndex++;
    }
    
    if (_currentIndex < _questions.length) {
      emit(QuizActive(_questions[_currentIndex], _score, _currentIndex));
      if (isCorrect || !allowRetries) {
        _speakPrompt(_questions[_currentIndex].prompt);
      }
    } else {
      await _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final profiles = await profileDao.getAllProfiles();
    if (profiles.isNotEmpty) {
      final profileId = profiles.first.id;
      await gameScoresDao.insertScore(GameScoresCompanion.insert(
        profileId: profileId,
        gameKey: _gameKey,
        score: _score,
      ));
    }
    emit(QuizCompleted(_score));
  }
}
