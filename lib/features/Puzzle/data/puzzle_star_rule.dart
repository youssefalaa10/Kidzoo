import 'package:kidzo/core/scoring/star_rating.dart';

/// Stars for a finished puzzle, rated on time.
///
/// A puzzle is only finished when every piece is in its place, so the score is
/// always the maximum and a points ratio would award three stars for any
/// completion at all. How long it took is the real measure.
class PuzzleStarRule {
  const PuzzleStarRule._();

  /// Seconds a comfortable solve of a puzzle of this size should take.
  static int parSecondsFor(int pieceCount) =>
      pieceCount * _secondsPerPiece;

  static int rate({required int pieceCount, required int elapsedSeconds}) =>
      StarRating.fromDuration(
        seconds: elapsedSeconds,
        parSeconds: parSecondsFor(pieceCount),
      );

  /// Points for the score row: 25 a piece, matching what the cubit awards.
  static int maxScoreFor(int pieceCount) => pieceCount * _pointsPerPiece;

  static const int _secondsPerPiece = 6;
  static const int _pointsPerPiece = 25;
}
