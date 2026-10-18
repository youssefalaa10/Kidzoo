# Project-Wide Adaptive Audit Report

**Date**: 2026-06-23

This audit classifies all screens and games in the Kidzoo application and determines their current adaptive capabilities and required refactoring paths.

## Core Screens

| Module | Portrait Only? | Landscape? | Overflow Issues? | Stretched BGs? | Physics-Based? | Needs Fluid Updates? |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Splash** | No | Yes | Solved | Solved | No | **Completed** |
| **Profile** | No | Yes (Unoptimized) | High Risk | Yes | No | Yes (`FluidContainer`) |
| **Character Selection** | No | Yes (Unoptimized) | High Risk | Yes | No | Yes (`FluidContainer`) |
| **Home** | No | Yes (Unoptimized) | Yes (Grid) | Yes | No | Yes (`FluidContainer`) |
| **Settings** | No | Yes (Unoptimized) | High Risk | Yes | No | Yes (`FluidContainer`) |
| **Language** | No | Yes (Unoptimized) | High Risk | Yes | No | Yes (`FluidContainer`) |
| **Level Map** | No | Yes (Unoptimized) | Yes | Yes | No | Yes (`FluidContainer`) |

## Educational Modules

| Module | Portrait Only? | Landscape? | Overflow Issues? | Stretched BGs? | Physics-Based? | Needs Fluid Updates? |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Vehicles** | No | Yes (Unoptimized) | Yes (Images) | Yes | No | Yes (`FluidContainer`) |
| **Fruits** | No | Yes (Unoptimized) | Yes (Images) | Yes | No | Yes (`FluidContainer`) |
| **Vegetables** | No | Yes (Unoptimized) | Yes (Images) | Yes | No | Yes (`FluidContainer`) |
| **Animal Name** | No | Yes (Unoptimized) | Yes (Keyboard) | Yes | No | Yes (`FluidContainer`) |

## Game Modules

| Module | Portrait Only? | Landscape? | Overflow Issues? | Stretched BGs? | Physics-Based? | Needs Fluid Updates? |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Flappy Bird** | Assumed | Unoptimized | Collision Risks | Yes | **Yes** | Yes (`PhysicsGameCanvas`) |
| **Color Switch** | Assumed | Unoptimized | Collision Risks | Yes | **Yes** | Yes (`PhysicsGameCanvas`) |
| **Color Memory** | No | Yes (Unoptimized) | Yes (Grid) | Yes | No | Yes (`FluidContainer`) |
| **Paddle Bounce** | Assumed | Unoptimized | Collision Risks | Yes | **Yes** | Yes (`PhysicsGameCanvas`) |
| **Dots & Boxes** | No | Yes (Unoptimized) | Yes (Grid) | Yes | **Yes** (Geometry)| Yes (`PhysicsGameCanvas`) |
| **Memory Game** | No | Yes (Unoptimized) | Yes (Grid) | Yes | No | Yes (`FluidContainer`) |
| **Maze Game** | Assumed | Unoptimized | Collision Risks | Yes | **Yes** | Yes (`PhysicsGameCanvas`) |
| **Puzzle Game** | No | Yes (Unoptimized) | Yes (Drag/Drop) | Yes | No | Yes (`FluidContainer`) |
| **Missing Letter** | No | Yes (Unoptimized) | Yes (Keyboard) | Yes | No | Yes (`FluidContainer`) |
| **Flag Game** | No | Yes (Unoptimized) | High Risk | Yes | No | Yes (`FluidContainer`) |
| **Tic Tac Toe** | No | Yes (Unoptimized) | High Risk | Yes | No | Yes (`FluidContainer`) |

## Audit Summary

1. **Orientation**: The application natively allows rotation (no `setPreferredOrientations` lock detected), but the UI is heavily optimized for mobile portrait. Forcing landscape on tablets creates massive widgets and potential overflows.
2. **Overflows**: Because components aren't constrained by a `FluidContainer`, `GridViews` and `Columns` risk overflowing bounds or ballooning to comical sizes on desktop monitors.
3. **Backgrounds**: Almost all screens currently suffer from stretched backgrounds on ultra-wide desktop monitors or tablets in landscape due to relying on singular, hard-coded image assets with `BoxFit.cover`.
4. **Physics Engines**: Games like Flappy Bird, Color Switch, Paddle Bounce, Maze Game, and Dots & Boxes rely heavily on fixed mathematical coordinates for collision bounds.

### Recommended Task Strategy
1. **Infrastructure**: Implement the `FluidContainer` and `PhysicsGameCanvas` core widgets to standardize the bounds.
2. **Core Screens Refactor**: Apply `FluidContainer` and `BackgroundResolver` to Profile, Home, Settings, and Level Map.
3. **Physics Games Refactor**: Wrap Flappy Bird, Paddle Bounce, Maze Game, and Color Switch in the `PhysicsGameCanvas` to preserve their logic.
4. **Grid/Educational Refactor**: Apply `FluidContainer` to grid-heavy games (Tic Tac Toe, Memory Game, Educational Modules).
