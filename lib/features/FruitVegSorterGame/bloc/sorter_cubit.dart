import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/database/daos/game_scores_dao.dart';
import '../../../core/database/daos/profile_dao.dart';
import '../../../core/helpers/speech.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/scoring/game_score_recorder.dart';
import '../data/sorter_data.dart';
import '../data/sorter_models.dart';
import 'sorter_state.dart';

/// Points for a round solved first try. Mistakes cost a little but never zero,
/// so a struggling child still sees the score move.
const int kSorterMaxRoundScore = 10;
const int kSorterMinRoundScore = 4;
const String kSorterGameKey = 'fruit_veg_sorter';

class SorterGameCubit extends Cubit<SorterGameState> {
  SorterGameCubit({
    required this.flutterTts,
    required this.audioPlayer,
    required this.l10n,
    this.gameScoresDao,
    this.profileDao,
    this.scoreRecorder,
    this.totalRounds = 10,
  }) : super(const SorterGameState.loading()) {
    _startGame();
  }

  final FlutterTts flutterTts;
  final AudioPlayer audioPlayer;
  final AppLocalizations l10n;

  /// Optional so the cubit stays testable without a database.
  final GameScoresDao? gameScoresDao;
  final ProfileDao? profileDao;

  /// The shared recorder. Optional for the same reason as the DAOs above.
  final GameScoreRecorder? scoreRecorder;
  final int totalRounds;

  final Random _random = Random();

  /// Recently used targets, so the same food is not requested twice in a row.
  final List<String> _recentTargets = [];

  int get maxScore => totalRounds * kSorterMaxRoundScore;

  void _startGame() {
    _recentTargets.clear();
    _startRound(round: 1, score: 0);
  }

  void restartGame() => _startGame();

  void _startRound({required int round, required int score}) {
    final roundData = _generateRoundData(round);
    emit(SorterGameState(
      phase: SorterPhase.playing,
      roundData: roundData,
      currentRound: round,
      totalRounds: totalRounds,
      score: score,
    ));
    _playRoundPrompt(roundData);
  }

  SorterGameRoundData _generateRoundData(int round) {
    final data = SorterGameData.buildRound(
      round: round,
      totalRounds: totalRounds,
      random: _random,
      avoidTargets: _recentTargets.toSet(),
    );
    _recentTargets.add(data.targetFood.id);
    if (_recentTargets.length > 4) _recentTargets.removeAt(0);
    return data;
  }

  Future<void> _playRoundPrompt(SorterGameRoundData data) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (isClosed) return;
    await _speak(data.getPromptText(l10n));
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

  /// Tap-to-pick, the alternative to dragging.
  ///
  /// Precise dragging is beyond most children under nine, so a tap selects the
  /// food and a second tap on a basket completes the move.
  Future<void> selectFood(FoodItem food) async {
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

  /// Tapping a basket resolves whatever food is currently held.
  Future<void> tapBasket(FoodType basketType) async {
    if (!state.isInteractive) return;
    final data = state.roundData;
    final selectedId = state.selectedFoodId;
    if (data == null) return;

    if (selectedId == null) {
      // Nothing in hand: re-state the goal rather than doing nothing, which a
      // child reads as "the app is broken".
      await _speak(data.getPromptText(l10n));
      return;
    }

    final food = data.choices.firstWhere((f) => f.id == selectedId);
    await _resolve(food, basketType);
  }

  /// Drag-and-drop entry point.
  Future<void> dropFood(FoodItem food, FoodType basketType) async {
    if (!state.isInteractive) return;
    await _resolve(food, basketType);
  }

  Future<void> _resolve(FoodItem food, FoodType basketType) async {
    final data = state.roundData;
    final isRightFood = food.id == data!.targetFood.id;
    final isRightBasket = basketType == food.type;

    if (isRightFood && isRightBasket) {
      await _handleCorrect(food);
    } else {
      await _handleWrong(food, basketType);
    }
  }

  Future<void> _handleCorrect(FoodItem food) async {
    final earned = max(
      kSorterMinRoundScore,
      kSorterMaxRoundScore - state.incorrectAttempts * 3,
    );
    final newScore = state.score + earned;

    emit(state.copyWith(
      phase: SorterPhase.correct,
      score: newScore,
      clearSelection: true,
      clearWrong: true,
    ));

    await _playSound('audio/success.mp3');
    final phrases = [
      l10n.sorterGreatJob,
      l10n.sorterExcellent,
      l10n.sorterFantastic
    ];
    await _speak(phrases[_random.nextInt(phrases.length)]);

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (isClosed) return;

    if (state.currentRound < totalRounds) {
      _startRound(round: state.currentRound + 1, score: newScore);
    } else {
      await _finish(newScore);
    }
  }

  Future<void> _handleWrong(FoodItem food, FoodType basketType) async {
    final attempts = state.incorrectAttempts + 1;

    emit(state.copyWith(
      phase: SorterPhase.wrong,
      incorrectAttempts: attempts,
      wrongFoodId: food.id,
      wrongBasket: basketType,
      clearSelection: true,
    ));

    await _playSound('audio/wrong.mp3');
    await _speak(l10n.sorterTryAgain);

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (isClosed) return;

    // The baskets only light up once the child has actually struggled. They
    // used to glow from the first frame, which gave the answer away.
    emit(state.copyWith(
      phase: SorterPhase.playing,
      showHint: attempts >= 2,
      clearWrong: true,
    ));
  }

  Future<void> _finish(int finalScore) async {
    await _saveScore(finalScore);
    if (isClosed) return;
    emit(state.copyWith(phase: SorterPhase.complete, score: finalScore));
  }

  /// The sorter was the only one of the three games that never persisted a
  /// score, so it was invisible in the child's profile.
  ///
  /// It still was: the DAO above is optional and the screen never passed one,
  /// so this method returned early every single time. Routing through the
  /// shared recorder fixes that, and picks up badge evaluation with it.
  Future<void> _saveScore(int finalScore) async {
    await scoreRecorder?.recordPlay(
      gameKey: kSorterGameKey,
      score: finalScore,
      maxScore: maxScore,
    );
  }
}
