# Implementation Plan: Project-Wide Adaptive Architecture

**Branch**: `[004-project-wide-adaptive]` | **Date**: 2026-06-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/004-unified-quiz-responsive/spec.md`

## Summary

The entire Kidzoo application will be refactored to use a Fluid Responsive Design. Instead of building completely different structural layout classes for Mobile, Tablet, and Desktop, every screen and game will retain the identical widget order and visual hierarchy across all devices. Whitespace will be managed by intelligently adjusting spacing, constraints (max-widths), image sizes, and padding. Physics-based games will enforce a centered, fixed-aspect-ratio canvas without black bars to preserve gameplay integrity. The `BackgroundResolver` service will dynamically inject device-specific backgrounds globally.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: `LayoutBuilder`, `MediaQuery`, `ConstrainedBox`, `AspectRatio`

**Storage**: N/A

**Testing**: `flutter_test` (unit testing Layout wrappers and BackgroundResolver)

**Target Platform**: Mobile (Android/iOS), Tablet, Desktop

**Project Type**: Flutter Educational App

**Performance Goals**: 60 FPS during resizing and orientation changes

**Constraints**: "Zero Static State" strictly enforced. Avoid creating separate implementations for every device.

Prefer a single Fluid Responsive layout that preserves the existing UI hierarchy.

Only introduce landscape-specific adjustments when necessary to prevent overflow or improve usability. No black bars on physics games.

**Scale/Scope**: Refactoring every screen (Splash, Home, Profile, etc.) and every educational/challenging game (25+ modules).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Zero Static State**: ✅ The plan utilizes `BuildContext`-derived calculations (`LayoutBuilder`, `MediaQuery`) and constraints.
- **State Management via BLoC / Cubit**: ✅ BLoC remains UI-agnostic.
- **Class-Based Widgets Only**: ✅ All widgets remain class-based.
- **Injected Services**: ✅ `BackgroundResolver` will be injected or passed down.

## Project Structure

### Documentation (this feature)

```text
specs/004-unified-quiz-responsive/
├── plan.md              
├── research.md          
├── data-model.md        
├── quickstart.md        
└── contracts/           
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── services/
│   │   └── background_resolver.dart
│   └── shared/
│       └── widgets/
│           ├── fluid_container.dart (NEW: Standardized max-width wrapper)
│           └── physics_game_canvas.dart (NEW: Fixed-aspect-ratio centered wrapper)
├── features/
│   ├── Splash/
│   ├── home/
│   ├── Profile/
│   ├── QuizEngine/
│   └── [All other 25+ Game/Screen modules]
```

**Structure Decision**: A new `fluid_container.dart` will be introduced in `core/shared/widgets/` to easily apply standardized max-width constraints to normal screens. A `physics_game_canvas.dart` will be introduced for games like Flappy Bird to handle the letterboxing without black bars. The `BackgroundResolver` service handles global backgrounds.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*(No violations)*
