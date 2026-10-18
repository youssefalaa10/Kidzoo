# Quickstart Validation Guide

## Setup
1. Ensure the device/emulator supports audio output.
2. Run `dart run build_runner build` to generate the Drift database code.
3. Run `flutter run`.

## Validation Scenarios

### 1. Mandatory Onboarding
- **Prerequisite**: Clear app data or uninstall to ensure an empty database.
- **Action**: Launch the app.
- **Expected Outcome**: `SplashScreen` completes and directly navigates to `ProfileSetupScreen`. The user cannot bypass this screen.
- **Action**: Enter a name, select an avatar, and tap save.
- **Expected Outcome**: The profile is saved, and the app navigates to the Home Screen.

### 2. Unified Quiz Engine
- **Action**: Navigate to the Vehicles category.
- **Expected Outcome**: The screen presents a scene (e.g., Sky) and asks a related question with 3 options.
- **Action**: Tap an incorrect option.
- **Expected Outcome**: The option shakes and "Try again" is displayed. The score is not reduced.
- **Action**: Tap the correct option.
- **Expected Outcome**: The app plays "Correct!" TTS, shows a confetti animation, and increases the current score.

### 3. Legacy Games Removed
- **Action**: Review the available games on the Home Screen or App Categories.
- **Expected Outcome**: The Snake Game, Goal Game, and Basketball Game are no longer visible or accessible.
