# Quickstart Validation: Splash & Home Polish

## Overview
This guide provides scenarios to validate that the Splash and Home screens are entirely dynamic and free of hardcoded strings or raw asset paths.

## Prerequisites
- Flutter SDK configured.
- Existing device or simulator running.

## Validation Scenarios

### Scenario 1: Localization Completeness
1. Start the application.
2. Observe the **Splash Screen**. Verify no fallback hardcoded text appears.
3. Open the App Settings and switch the primary language.
4. Navigate to the **Home Screen**.
5. **Expected Outcome**: All category names ("Vehicles", "Fruits", "Tic Tac Toe", etc.) and titles instantly switch to the new language without requiring an app restart.

### Scenario 2: Layout Robustness
1. Launch the app on a small-screen device profile (e.g., iPhone SE equivalent).
2. Navigate to the **Home Screen** and open the `AppCategoryOptions` grid.
3. **Expected Outcome**: The category cards scale proportionally. No yellow/black overflow caution tape appears on the screen boundaries.

### Scenario 3: Asset Integrity
1. Temporarily rename an asset referenced by `ImageManager` to simulate a missing file (or rely on edge case handling if explicitly implemented).
2. Load the app.
3. **Expected Outcome**: The system does not crash and handles the missing asset gracefully (e.g., rendering an empty space or a default icon).
