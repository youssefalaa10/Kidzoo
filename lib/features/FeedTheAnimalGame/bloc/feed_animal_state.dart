import '../data/feed_animal_models.dart';

abstract class FeedAnimalState {}

class FeedAnimalLoading extends FeedAnimalState {}

class FeedAnimalPlaying extends FeedAnimalState {
  final GameRoundData roundData;
  final int score;
  final int currentRound;
  final int totalRounds;
  final bool showHint;

  FeedAnimalPlaying({required this.roundData, required this.score, required this.currentRound, required this.totalRounds, this.showHint = false});
}

class FeedAnimalSuccess extends FeedAnimalState {
  final GameRoundData roundData;
  final int score;
  final int currentRound;
  final int totalRounds;
  final FeedItem droppedFood;

  FeedAnimalSuccess({required this.roundData, required this.score, required this.currentRound, required this.totalRounds, required this.droppedFood});
}

class FeedAnimalWrong extends FeedAnimalState {
  final GameRoundData roundData;
  final int score;
  final String wrongFoodId;
  final int currentRound;
  final int totalRounds;

  FeedAnimalWrong({required this.roundData, required this.score, required this.wrongFoodId, required this.currentRound, required this.totalRounds});
}

class FeedAnimalComplete extends FeedAnimalState {
  final int score;
  final int totalRounds;

  FeedAnimalComplete({required this.score, required this.totalRounds});
}
