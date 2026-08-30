import '../data/feed_animal_models.dart';

abstract class FeedAnimalState {}

class FeedAnimalLoading extends FeedAnimalState {}

class FeedAnimalPlaying extends FeedAnimalState {

  FeedAnimalPlaying({required this.roundData, required this.score, required this.currentRound, required this.totalRounds, this.showHint = false});
  final GameRoundData roundData;
  final int score;
  final int currentRound;
  final int totalRounds;
  final bool showHint;
}

class FeedAnimalSuccess extends FeedAnimalState {

  FeedAnimalSuccess({required this.roundData, required this.score, required this.currentRound, required this.totalRounds, required this.droppedFood});
  final GameRoundData roundData;
  final int score;
  final int currentRound;
  final int totalRounds;
  final FeedItem droppedFood;
}

class FeedAnimalWrong extends FeedAnimalState {

  FeedAnimalWrong({required this.roundData, required this.score, required this.wrongFoodId, required this.currentRound, required this.totalRounds});
  final GameRoundData roundData;
  final int score;
  final String wrongFoodId;
  final int currentRound;
  final int totalRounds;
}

class FeedAnimalComplete extends FeedAnimalState {

  FeedAnimalComplete({required this.score, required this.totalRounds});
  final int score;
  final int totalRounds;
}
