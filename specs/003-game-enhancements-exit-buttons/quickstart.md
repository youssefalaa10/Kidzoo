# Quickstart & Validation Guide: Game Enhancements & Exit Buttons

## Prerequisites
- Flutter SDK 3.x installed.
- Kidzoo application built and running on an emulator or physical device.

## Validation Scenarios

### Scenario 1: Verify Zero Static State in Exit Buttons
1. Launch the application.
2. Navigate to any Phase 4 or Phase 5 game module.
3. Observe the `GameExitButton` rendered on the screen.
4. **Code Verification**: Open the source code for the current game screen. Verify that the exit button is instantiated as `GameExitButton()` without passing any hardcoded static strings or `Color` constants directly from static fields.

### Scenario 2: Centralized Asset and Localization Updates
1. Open the project's localization file (e.g., `lib/l10n/app_en.arb`) and change the value for the `exitGame` key from "Exit" to "Leave Game".
2. Open the central theme configuration (`lib/core/theme/app_theme.dart` or similar) and modify the primary exit button color (e.g., from Red to Orange).
3. Perform a hot reload (`r` in the Flutter console).
4. **Verification**: Observe that the `GameExitButton` in the active game immediately updates to display "Leave Game" and changes its color to Orange, proving that it successfully consumes the injected, centralized state.

### Scenario 3: Functional Exit Navigation
1. While inside a game session, tap the `GameExitButton`.
2. **Verification**: The application should successfully pop the current route (`Navigator.pop()`) and return the user to the game selection menu without triggering any layout overflows or null reference errors related to missing assets.
