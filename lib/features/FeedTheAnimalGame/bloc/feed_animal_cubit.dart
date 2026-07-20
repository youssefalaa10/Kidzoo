import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/database/config.dart';
import '../../../core/database/daos/game_scores_dao.dart';
import '../../../core/database/daos/profile_dao.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/feed_animal_data.dart';
import '../data/feed_animal_models.dart';
import 'feed_animal_state.dart';

class FeedAnimalCubit extends Cubit<FeedAnimalState> {

  FeedAnimalCubit({
    required this.gameScoresDao,
    required this.profileDao,
    required this.flutterTts,
    required this.audioPlayer,
    required this.l10n,
  }) : super(FeedAnimalLoading()) {
    _startNextRound();
  }
  final GameScoresDao gameScoresDao;
  final ProfileDao profileDao;
  final FlutterTts flutterTts;
  final AudioPlayer audioPlayer;
  final AppLocalizations l10n;

  int _score = 0;
  int _currentRound = 1;
  final int _totalRounds = 10;
  int _wrongAttempts = 0;
  final Random _random = Random();

  void restartGame() {
    _score = 0;
    _currentRound = 1;
    _startNextRound();
  }

  Future<void> _startNextRound() async {
    if (_currentRound > _totalRounds) {
      // Save score
      final profiles = await profileDao.getAllProfiles();
      if (profiles.isNotEmpty) {
        final profileId = profiles.first.id;
        await gameScoresDao.insertScore(GameScoresCompanion.insert(
          profileId: profileId,
          gameKey: 'feed_animal_game',
          score: _score,
        ));
      }
      emit(FeedAnimalComplete(score: _score, totalRounds: _totalRounds));
      return;
    }
    final animal = FeedAnimalData.allAnimals[_random.nextInt(FeedAnimalData.allAnimals.length)];
    
    // Difficulty scaling: Easy (1-3) -> 3 choices, Medium (4-7) -> 4 choices, Hard (8-10) -> 5 choices
    int numChoices = 3;
    if (_currentRound > 3) numChoices = 4;
    if (_currentRound > 7) numChoices = 5;

    final targetFood = FeedAnimalData.allFoods.firstWhere((f) => f.id == animal.targetFoodId);
    
    // Distractor foods must NOT contain the target food, and must NOT contain duplicates
    final distractorFoods = FeedAnimalData.allFoods.where((f) => f.id != targetFood.id).toList()..shuffle(_random);
    
    final choices = [targetFood, ...distractorFoods.take(numChoices - 1)]..shuffle(_random);

    final promptTypes = [PromptType.feedAnimal, PromptType.whatDoesAnimalEat];
    final promptType = promptTypes[_random.nextInt(promptTypes.length)];

    _wrongAttempts = 0;

    final roundData = GameRoundData(
      animal: animal,
      targetFood: targetFood,
      choices: choices,
      promptType: promptType,
    );

    emit(FeedAnimalPlaying(
      roundData: roundData, 
      score: _score, 
      currentRound: _currentRound, 
      totalRounds: _totalRounds,
    ));

    // Wait 500ms before speaking
    await Future.delayed(const Duration(milliseconds: 500));
    if (state is FeedAnimalPlaying) {
      _speakPrompt(roundData);
    }
  }

  void _speakPrompt(GameRoundData roundData) async {
    try {
      await flutterTts.speak(roundData.getPromptText(l10n));
    } catch (_) {}
  }

  void replayPrompt() {
    final currentState = state;
    if (currentState is FeedAnimalPlaying) {
      _speakPrompt(currentState.roundData);
    }
  }

  void onFoodDropped(FeedItem food) async {
    final currentState = state;
    if (currentState is! FeedAnimalPlaying) return;

    final roundData = currentState.roundData;

    if (food.id == roundData.targetFood.id) {
      _score += 10;
      emit(FeedAnimalSuccess(
        roundData: roundData, 
        score: _score, 
        currentRound: _currentRound, 
        totalRounds: _totalRounds,
        droppedFood: food,
      ));
      
      // Play Animal Sound
      audioPlayer.play(AssetSource(roundData.animal.audioAsset.replaceFirst('assets/', '')));

      // Play random positive TTS
      try {
        final phraseIndex = _random.nextInt(4);
        String phrase;
        if (phraseIndex == 0) {
          phrase = l10n.greatJob;
        } else if (phraseIndex == 1) {
          phrase = l10n.excellent;
        } else if (phraseIndex == 2) {
          phrase = l10n.fantastic;
        } else {
          phrase = l10n.wellDone;
        }
        await flutterTts.speak(phrase);
      } catch (_) {}

      // Wait for success animation
      await Future.delayed(const Duration(seconds: 2));
      _currentRound++;
      _startNextRound();
    } else {
      _wrongAttempts++;
      emit(FeedAnimalWrong(
        roundData: roundData, 
        score: _score, 
        wrongFoodId: food.id,
        currentRound: _currentRound,
        totalRounds: _totalRounds,
      ));
      
      try {
        await flutterTts.speak(l10n.tryAgainPrompt);
      } catch (_) {}

      await Future.delayed(const Duration(seconds: 1));
      
      // Return to playing state, applying hint if _wrongAttempts >= 2
      if (state is FeedAnimalWrong) {
        emit(FeedAnimalPlaying(
          roundData: roundData, 
          score: _score,
          currentRound: _currentRound,
          totalRounds: _totalRounds,
          showHint: _wrongAttempts >= 2,
        ));
      }
    }
  }
}
