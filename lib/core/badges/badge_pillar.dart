/// The four things a child can be recognised for.
///
/// Games and Education deliberately mirror the two `GameSurface` values, so a
/// badge sits in the same half of the app as the activity that earns it. Story
/// covers Adventure Mode, and Habit covers coming back at all — which is the
/// one achievement that has nothing to do with skill.
enum BadgePillar {
  story,
  games,
  education,
  habit;

  /// Key into AppLocalizations for the section heading on the badge wall.
  String get localizationKey {
    switch (this) {
      case BadgePillar.story:
        return 'badgePillarStory';
      case BadgePillar.games:
        return 'badgePillarGames';
      case BadgePillar.education:
        return 'badgePillarEducation';
      case BadgePillar.habit:
        return 'badgePillarHabit';
    }
  }
}
