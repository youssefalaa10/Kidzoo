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
import '../../../core/helpers/speech.dart';

const int kFeedMaxRoundScore = 10;
const int kFeedMinRoundScore = 4;
const String kFeedGameKey = 'feed_animal_game';

class FeedAnimalCubit extends Cubit<FeedAnimalState> {
  FeedAnimalCubit({
    required this.gameScoresDao,
    required this.profileDao,
    required this.flutterTts,
    required this.audioPlayer,
    required this.l10n,
    this.totalRounds = 10,
  }) : super(const FeedAnimalState.loading()) {
    _startGame();
  }

  final GameScoresDao gameScoresDao;
  final ProfileDao profileDao;
  final FlutterTts flutterTts;
  final AudioPlayer audioPlayer;
  final AppLocalizations l10n;
  final int totalRounds;

  final Random _random = Random();

  int _wrongAttempts = 0;
  String? _lastAnimalId;
  List<AnimalItem> _animalCycle = [];
  PromptType? _lastPromptType;

  /// Guards the delayed prompt: a round that has already been answered must not
  /// speak its question over the next round's.
  int _promptToken = 0;

  int get maxScore => totalRounds * kFeedMaxRoundScore;

  void _startGame() {
    _lastAnimalId = null;
    _animalCycle = [];
    _lastPromptType = null;
    _startRound(round: 1, score: 0);
  }

  void restartGame() => _startGame();

  AnimalItem _pickNextAnimal() {
    if (_animalCycle.isEmpty) {
      _animalCycle = List.of(FeedAnimalData.allAnimals)..shuffle(_random);
      // Avoid the new cycle starting with the animal that just ended the
      // previous one, which would read as a back-to-back repeat.
      if (_lastAnimalId != null &&
          _animalCycle.length > 1 &&
          _animalCycle.first.id == _lastAnimalId) {
        final temp = _animalCycle[0];
        _animalCycle[0] = _animalCycle.last;
        _animalCycle.last = temp;
      }
    }
    final animal = _animalCycle.removeAt(0);
    _lastAnimalId = animal.id;
    return animal;
  }

  void _startRound({required int round, required int score}) {
    final animal = _pickNextAnimal();
    final targetFood =
        FeedAnimalData.allFoods.firstWhere((f) => f.id == animal.targetFoodId);

    final progress = totalRounds <= 0 ? 1.0 : round / totalRounds;
    final numChoices = FeedAnimalData.choiceCountFor(progress);

    final choices = <FeedItem>[
      targetFood,
      ...FeedAnimalData.buildDistractors(
        animal: animal,
        targetFood: targetFood,
        count: numChoices - 1,
        progress: progress,
        random: _random,
      ),
    ]..shuffle(_random);

    // Alternate the phrasing so the same sentence is not repeated ten times.
    final promptCandidates = PromptType.values
        .where((p) => p != _lastPromptType)
        .toList();
    final promptType = promptCandidates[_random.nextInt(promptCandidates.length)];
    _lastPromptType = promptType;

    _wrongAttempts = 0;

    final roundData = GameRoundData(
      animal: animal,
      targetFood: targetFood,
      choices: choices,
      promptType: promptType,
    );

    emit(FeedAnimalState(
      phase: FeedPhase.playing,
      roundData: roundData,
      currentRound: round,
      totalRounds: totalRounds,
      score: score,
    ));

    _schedulePrompt(roundData);
  }

  Future<void> _schedulePrompt(GameRoundData roundData) async {
    final token = ++_promptToken;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (isClosed || token != _promptToken) return;
    await _speak(roundData.getPromptText(l10n));
  }

  Future<void> _speak(String text) async {
    try {
      await Speech.speak(text);
    } catch (_) {}
  }

  Future<void> _playSound(String asset) async {
    try {
      await audioPlayer.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> replayPrompt() async {
    final data = state.roundData;
    if (data == null) return;
    await _speak(data.getPromptText(l10n));
  }

  /// Tap-to-pick: a tap selects the food and speaks its name, a second tap on
  /// the animal feeds it. Dragging remains available but is no longer required.
  Future<void> selectFood(FeedItem food) async {
    if (!state.isInteractive) return;
    final alreadySelected = state.selectedFoodId == food.id;
    emit(state.copyWith(
      selectedFoodId: alreadySelected ? null : food.id,
      clearSelection: alreadySelected,
      clearWrong: true,
    ));
    if (!alreadySelected) {
      await _speak(food.getLocalizedName(l10n));
    }
  }

  /// Tapping the animal feeds it whatever is currently held.
  Future<void> tapAnimal() async {
    if (!state.isInteractive) return;
    final data = state.roundData;
    if (data == null) return;

    final selectedId = state.selectedFoodId;
    if (selectedId == null) {
      await _speak(data.getPromptText(l10n));
      return;
    }
    await onFoodDropped(data.choices.firstWhere((f) => f.id == selectedId));
  }

  Future<void> onFoodDropped(FeedItem food) async {
    if (!state.isInteractive) return;
    final data = state.roundData!;

    if (food.id == data.targetFood.id) {
      await _handleCorrect(food);
    } else {
      await _handleWrong(food);
    }
  }

  Future<void> _handleCorrect(FeedItem food) async {
    _promptToken++; // cancel any pending prompt for this round
    final earned =
        max(kFeedMinRoundScore, kFeedMaxRoundScore - _wrongAttempts * 3);
    final newScore = state.score + earned;

    emit(state.copyWith(
      phase: FeedPhase.correct,
      score: newScore,
      eatenFood: food,
      clearSelection: true,
      clearWrong: true,
    ));

    final animal = state.roundData!.animal;
    await _playSound(animal.audioAsset.replaceFirst('assets/', ''));

    final phrases = [
      l10n.greatJob,
      l10n.excellent,
      l10n.fantastic,
      l10n.wellDone,
    ];
    await _speak(phrases[_random.nextInt(phrases.length)]);

    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (isClosed) return;

    if (state.currentRound < totalRounds) {
      _startRound(round: state.currentRound + 1, score: newScore);
    } else {
      await _finish(newScore);
    }
  }

  Future<void> _handleWrong(FeedItem food) async {
    _wrongAttempts++;

    emit(state.copyWith(
      phase: FeedPhase.wrong,
      wrongFoodId: food.id,
      clearSelection: true,
    ));

    await _playSound('audio/wrong.mp3');
    await _speak(l10n.tryAgainPrompt);

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (isClosed) return;

    emit(state.copyWith(
      phase: FeedPhase.playing,
      showHint: _wrongAttempts >= 2,
      clearWrong: true,
    ));
  }

  Future<void> _finish(int finalScore) async {
    await _saveScore(finalScore);
    if (isClosed) return;
    emit(state.copyWith(phase: FeedPhase.complete, score: finalScore));
  }

  Future<void> _saveScore(int finalScore) async {
    try {
      final profiles = await profileDao.getAllProfiles();
      if (profiles.isEmpty) return;
      await gameScoresDao.insertScore(GameScoresCompanion.insert(
        profileId: profiles.first.id,
        gameKey: kFeedGameKey,
        score: finalScore,
      ));
    } catch (_) {}
  }
}
