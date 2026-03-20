import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

/// A service to manage navigation protection for game screens
class NavigationService {
  factory NavigationService() => _instance;
  NavigationService._internal();
  // Singleton instance
  static final NavigationService _instance = NavigationService._internal();

  // Flag to track if navigation is coming from the level map
  bool _isNavigatingFromLevelMap = false;

  // The current stage number being played
  int _currentStageNumber = 0;

  // Getters
  bool get isNavigatingFromLevelMap => _isNavigatingFromLevelMap;
  int get currentStageNumber => _currentStageNumber;

  /// Set navigation as coming from level map
  void setNavigationFromLevelMap(bool value, {int stageNumber = 0}) {
    _isNavigatingFromLevelMap = value;
    if (stageNumber > 0) {
      _currentStageNumber = stageNumber;
    }
  }

  /// Reset navigation state when returning to map
  void resetNavigationState() {
    _isNavigatingFromLevelMap = false;
    _currentStageNumber = 0;
  }

  /// Navigate to a game screen with protection
  Future<T?> navigateToGameScreen<T>(BuildContext context, Widget gameScreen,
      {int stageNumber = 0}) async {
    // Set navigation state
    setNavigationFromLevelMap(true, stageNumber: stageNumber);

    // Navigate to the game screen
    final result = await Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
    );

    // Reset navigation state when returning
    resetNavigationState();

    return result;
  }

  /// Check if navigation is allowed and show warning if not
  bool checkNavigationAllowed(BuildContext context) {
    if (!_isNavigatingFromLevelMap) {
      final l10n = AppLocalizations.of(context);
      // Show warning dialog
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.navigationNotAllowed),
          content: Text(l10n.gamesOnlyThroughLevelMap),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              child: Text(l10n.goBack),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }
}
