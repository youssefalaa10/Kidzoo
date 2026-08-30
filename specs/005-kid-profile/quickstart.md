# Quickstart: Kid Profile Validation

## Overview

This guide provides steps to validate the UI and functionality of the new Kid Profile feature without requiring a fully populated database initially.

## Setup

1. Build and run the app on an emulator (Phone or Tablet):
   ```bash
   flutter run -d emulator
   ```

## Validation Scenarios

### Scenario 1: UI Responsiveness and Animations
1. Navigate to the Profile screen from the Main Menu.
2. Verify the Hero Section displays the Avatar, Name, Level, and XP Bar.
3. Tap the Avatar. Verify the Avatar Selection Dialog appears.
4. Select a new Avatar. Verify the dialog closes and the avatar on the profile updates with a smooth transition.
5. Rotate the device to Landscape mode. Verify no RenderFlex overflow occurs and the UI adapts cleanly.
6. Scroll down to view the Badges, Statistics, and Weekly Progress. Ensure all cards animate into view.

### Scenario 2: Badge and Stats Rendering
1. Observe the Achievement Badges section. Verify locked badges are greyed out and unlocked badges have a sparkle visual.
2. Observe the Statistics section. Verify cards like "Games Played" and "Stars Collected" render with correct numerical data.
3. Observe the Weekly Progress chart. Verify it displays kid-friendly icons (stars/smileys).

## Success

If the profile screen loads without errors, avatar changes animate smoothly, and there are no UI overflows in any orientation, the UI layer is successfully implemented.
