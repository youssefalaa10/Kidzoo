import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/localization/app_localizations.dart';
import '../data/sorter_data.dart';
import '../data/sorter_models.dart';
import 'sorter_state.dart';

class SorterGameCubit extends Cubit<SorterGameState> {
  final FlutterTts flutterTts;
  final AudioPlayer audioPlayer;
  final AppLocalizations l10n;
  
  final int totalRounds = 10;
  int currentRound = 1;
  final Random _random = Random();

  SorterGameCubit({
    required this.flutterTts,
    required this.audioPlayer,
    required this.l10n,
  }) : super(SorterGameLoading()) {
    _initGame();
  }

  void _initGame() {
    currentRound = 1;
    _startRound();
  }

  void restartGame() {
    _initGame();
  }

  void _startRound() {
    final roundData = _generateRoundData();
    
    emit(SorterGamePlaying(
      roundData: roundData,
      currentRound: currentRound,
      totalRounds: totalRounds,
      incorrectAttempts: 0,
      showHint: false,
    ));

    _playRoundPrompt(roundData);
  }

  SorterGameRoundData _generateRoundData() {
    // Determine number of choices based on progression
    int numChoices;
    if (currentRound <= 3) {
      numChoices = 2;
    } else if (currentRound <= 6) {
      numChoices = 3;
    } else if (currentRound <= 8) {
      numChoices = 4;
    } else {
      numChoices = 5;
    }

    final allFoods = List<FoodItem>.from(SorterGameData.allFoods);
    allFoods.shuffle(_random);
    
    final choices = allFoods.take(numChoices).toList();
    final targetFood = choices[_random.nextInt(choices.length)];

    return SorterGameRoundData(
      choices: choices,
      targetFood: targetFood,
    );
  }

  Future<void> _playRoundPrompt(SorterGameRoundData data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (isClosed) return;
    
    final prompt = data.getPromptText(l10n);
    await flutterTts.speak(prompt);
  }

  Future<void> replayPrompt() async {
    if (state is SorterGamePlaying) {
      final playingState = state as SorterGamePlaying;
      await _playRoundPrompt(playingState.roundData);
    }
  }

  Future<void> onFoodDropped(FoodItem food, FoodType targetBasketType) async {
    if (state is! SorterGamePlaying) return;
    
    final playingState = state as SorterGamePlaying;
    
    // Check if it is the correct food requested AND the correct basket
    if (food.id == playingState.roundData.targetFood.id && food.type == targetBasketType) {
      _handleCorrectAnswer(playingState, food);
    } else {
      _handleWrongAnswer(playingState);
    }
  }

  Future<void> _handleCorrectAnswer(SorterGamePlaying playingState, FoodItem food) async {
    emit(SorterGameSuccess(
      roundData: playingState.roundData,
      currentRound: currentRound,
      totalRounds: totalRounds,
      droppedFood: food,
    ));

    // Play success sound
    try {
      await audioPlayer.play(AssetSource('audio/success.mp3'));
    } catch (_) {}

    // Speak success phrase
    final phrases = [l10n.sorterGreatJob, l10n.sorterExcellent, l10n.sorterFantastic];
    final selectedPhrase = phrases[_random.nextInt(phrases.length)];
    await flutterTts.speak(selectedPhrase);

    await Future.delayed(const Duration(milliseconds: 2000));
    if (isClosed) return;

    if (currentRound < totalRounds) {
      currentRound++;
      _startRound();
    } else {
      emit(SorterGameComplete());
    }
  }

  Future<void> _handleWrongAnswer(SorterGamePlaying playingState) async {
    final newAttempts = playingState.incorrectAttempts + 1;
    
    emit(SorterGameWrong(
      roundData: playingState.roundData,
      currentRound: playingState.currentRound,
      totalRounds: playingState.totalRounds,
    ));

    // Speak error phrase
    await flutterTts.speak(l10n.sorterTryAgain);

    await Future.delayed(const Duration(milliseconds: 1000));
    if (isClosed) return;

    emit(playingState.copyWith(
      incorrectAttempts: newAttempts,
      showHint: newAttempts >= 2,
    ));
  }
}
