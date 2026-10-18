import 'package:flutter/material.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';

/// The tier a game is currently being played at, and how to start another one.
///
/// This exists instead of an `onNextLevel` callback on six game constructors
/// for one reason: Adventure Mode hosts several of these same games and must
/// never show a difficulty affordance. [maybeOf] returns null there, so the
/// button structurally cannot render — rather than every future caller having
/// to remember not to pass a flag.
class DifficultyRunScope extends InheritedWidget {
  const DifficultyRunScope({
    required this.difficulty,
    required this.gameBuilder,
    required super.child,
    super.key,
  });

  final KidDifficulty difficulty;
  final Widget Function(KidDifficulty difficulty) gameBuilder;

  static DifficultyRunScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DifficultyRunScope>();

  bool get hasNextDifficulty => difficulty.next != null;

  /// Starts the next tier up.
  ///
  /// [Navigator.pushReplacement], not push: the picker stays the parent route,
  /// so Back from any tier lands on refreshed stars rather than unwinding a
  /// stack of every game the child has played this sitting.
  void playNext(BuildContext context) {
    final KidDifficulty? next = difficulty.next;
    if (next == null) {
      return;
    }
    _replaceWith(context, next);
  }

  /// Restarts the tier being played. Games route their own "play again"
  /// through this so the scope survives the replacement.
  void playAgain(BuildContext context) => _replaceWith(context, difficulty);

  void _replaceWith(BuildContext context, KidDifficulty tier) {
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (BuildContext _) => DifficultyRunScope(
        difficulty: tier,
        gameBuilder: gameBuilder,
        child: gameBuilder(tier),
      ),
    ));
  }

  @override
  bool updateShouldNotify(DifficultyRunScope oldWidget) =>
      oldWidget.difficulty != difficulty;
}
