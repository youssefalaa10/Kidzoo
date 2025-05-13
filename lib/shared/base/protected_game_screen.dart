import 'package:flutter/material.dart';
import '../services/navigation_service.dart';

/// A base class for all game screens that implements navigation protection
///
/// All game screens should extend this class to ensure they can only be
/// launched from the level map screen.
abstract class ProtectedGameScreen extends StatefulWidget {
  final int level;

  const ProtectedGameScreen({super.key, required this.level});
}

/// Base state class for protected game screens
abstract class ProtectedGameScreenState<T extends ProtectedGameScreen>
    extends State<T> {
  final NavigationService _navigationService = NavigationService();
  bool _navigationChecked = false;

  @override
  void initState() {
    super.initState();
    // Navigation check will be performed in didChangeDependencies
    // because we need access to the BuildContext
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only check navigation once
    if (!_navigationChecked) {
      _navigationChecked = true;

      // Check if navigation is allowed (coming from level map)
      // This will show a warning dialog and navigate back if not allowed
      if (!_navigationService.checkNavigationAllowed(context)) {
        // Navigation not allowed, the dialog will handle going back
        return;
      }

      // Navigation is allowed, continue with game initialization
      onGameInit();
    }
  }

  /// Called when the game is initialized and navigation is allowed
  /// Override this method to initialize your game
  void onGameInit() {
    // To be implemented by subclasses
  }

  /// Get the current stage number from the navigation service
  int get currentStageNumber => _navigationService.currentStageNumber;
}
