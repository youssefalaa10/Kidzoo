# Quickstart & Validation Guide: Project-Wide Adaptive Architecture

This guide describes how to validate the Fluid Responsive Design and the Physics-Based Game adaptation rules.

## Prerequisites
- Windows Development Environment running the Flutter app.
- An Android Emulator (Phone).

## Scenario 1: Fluid Layout on Standard Screens

**Goal**: Verify that standard screens (e.g., Settings, Profile) do not stretch infinitely on desktop and retain their visual hierarchy.

**Execution**:
1. Run the app on the Windows target:
   ```bash
   flutter run -d windows
   ```
2. Navigate to the Settings Screen.
3. Maximize the window.
4. Verify the `FluidContainer` restricts the maximum width of the content (it should not span edge-to-edge on an ultra-wide monitor).
5. Verify the widget hierarchy (order of buttons/text) is identical to the mobile view.
6. Verify the background asset switches to `colorful_bg_desk.jpg`.

**Expected Outcome**: The UI is centered, readable, and properly constrained. No extreme stretching of buttons or text.

## Scenario 2: Physics-Based Game Boundaries

**Goal**: Verify games like Flappy Bird maintain their gameplay physics boundaries on large screens without black bars.

**Execution**:
1. Run the app on the Windows target:
   ```bash
   flutter run -d windows
   ```
2. Navigate to Flappy Bird (or Maze Game).
3. Maximize the window.
4. Verify the active game canvas maintains a strict aspect ratio in the center of the screen.
5. Verify the area *outside* the game canvas is filled with the dynamically resolved background (e.g., `tech_bg_desk.jpg`).
6. Verify there are **NO** black bars (letterboxing/pillarboxing) anywhere on the screen.

**Expected Outcome**: Physics gameplay is unaffected by window resizing, and the app remains visually immersive.
