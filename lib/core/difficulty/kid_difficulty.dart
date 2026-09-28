/// The three tiers every free-play game offers.
///
/// Games do not take this type: they take the `int level` they have always
/// taken, and [level] is the conversion. That keeps each game's own vocabulary
/// intact — `MazeDifficulty`, `GameLevel`, `LevelConfig.forLevel` — while
/// giving the picker, the unlock rules and the score rows one shared name.
///
/// Deliberately not called `GameDifficulty` or `AIDifficulty`: both already
/// exist in this codebase (DotsAndBoxes, and twice more in PaddleBounce with a
/// fourth `expert` value), and a fifth enum answering to the same name would
/// be a merge conflict waiting to happen.
enum KidDifficulty {
  easy,
  medium,
  hard;

  /// The integer every `KidGameScreen` already accepts.
  int get level => index + 1;

  /// Clamps rather than throwing: a level read back from a score row written
  /// by an older build can be anything, and a child should never see a crash
  /// because of a number in a database.
  static KidDifficulty fromLevel(int level) {
    if (level <= 1) {
      return KidDifficulty.easy;
    }
    if (level == 2) {
      return KidDifficulty.medium;
    }
    return KidDifficulty.hard;
  }

  KidDifficulty? get next =>
      this == KidDifficulty.hard ? null : KidDifficulty.values[index + 1];

  KidDifficulty? get previous =>
      this == KidDifficulty.easy ? null : KidDifficulty.values[index - 1];

  /// The `AppLocalizations` key holding this tier's display name. The three
  /// keys already exist in both locales.
  String get nameKey => const <String>['easy', 'medium', 'hard'][index];
}
