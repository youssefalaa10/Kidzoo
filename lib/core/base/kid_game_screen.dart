import 'package:flutter/material.dart';

/// Base class for a game screen that is parameterised by difficulty.
///
/// Replaces `ProtectedGameScreen`, which additionally refused to run unless a
/// mutable singleton said the child had arrived from the level map. That gate
/// is gone: games are reachable from the grids, from the level map, and (once
/// Adventure Mode lands) from a story node, so "which screen did you come
/// from" is no longer a meaningful question to ask.
abstract class KidGameScreen extends StatefulWidget {
  const KidGameScreen({required this.level, super.key});

  final int level;
}

/// Base state providing a single, one-shot [onGameInit] callback.
///
/// [onGameInit] is deliberately invoked from [didChangeDependencies] rather
/// than `initState`, and that is not an accident to be tidied up later:
/// subclasses read inherited widgets in it — `animal_quiz_screen.dart` calls
/// `AppLocalizations.of(context)` and `Localizations.localeOf(context)` — and
/// those are unavailable during `initState`. The latch keeps it to one call
/// even though `didChangeDependencies` can fire repeatedly.
abstract class KidGameScreenState<T extends KidGameScreen> extends State<T> {
  bool _hasInitialisedGame = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialisedGame) {
      return;
    }
    _hasInitialisedGame = true;
    onGameInit();
  }

  /// Called exactly once, after inherited widgets are available.
  void onGameInit() {}
}
