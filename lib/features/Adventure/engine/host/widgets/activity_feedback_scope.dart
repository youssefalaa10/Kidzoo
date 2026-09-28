import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';

/// Gives a board the sounds the host already owns.
///
/// Sound normally belongs to the cubit, because the cubit is where the *answer*
/// happens and where the tests can see it. This is for the other kind of sound:
/// the one that belongs to an animation the board is playing, where the timing
/// is the whole point and lives in the widget. A rhythm ticked out by the cubit
/// while the board animated on its own clock would drift apart, and putting the
/// board's clock into the cubit would make every test wait out a wave it cannot
/// see.
///
/// Deliberately not on the engine contract: an engine that needs this reads it
/// from the tree, and one that does not is unaffected. Nothing localized comes
/// through here, so the rule that keeps engines free of `AppLocalizations`
/// still holds.
class ActivityFeedbackScope extends InheritedWidget {
  const ActivityFeedbackScope({
    required this.soundboard,
    required super.child,
    super.key,
  });

  final ActivitySoundboard soundboard;

  /// Null outside a host — a board pumped directly by a widget test is the
  /// usual case, and it must still build.
  static ActivityFeedbackScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActivityFeedbackScope>();

  @override
  bool updateShouldNotify(ActivityFeedbackScope oldWidget) =>
      oldWidget.soundboard != soundboard;
}
