# Implementation Plan: kidzoo-v2-refactor

**Branch**: `[]` | **Date**: 2026-06-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-kidzoo-v2-refactor/spec.md`

## Summary

Refactor the educational games (Vehicles, Fruits, Vegetables) into a unified Quiz-Based Learning Engine. Introduce a mandatory Profile Setup flow immediately following the Splash screen. Remove deprecated games (Snake, Basketball, Goal).

## Technical Context

**Language/Version**: Dart (Flutter)

**Primary Dependencies**: `flutter_bloc`, `drift`, `flutter_tts`, `audioplayers`, `flutter_animate`, `confetti`, `lottie`

**Storage**: Local SQLite via `drift`

**Testing**: `flutter_test`

**Target Platform**: Android, iOS, Web, Desktop

**Project Type**: Mobile Application

**Performance Goals**: 60 FPS animations, immediate TTS playback without lag

**Constraints**: Strict adherence to BLoC/Cubit for all state. No static variables or global singletons.

**Scale/Scope**: Refactoring 3 games into 1 engine, removing 3 games, and adding 1 onboarding flow.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Zero Static State**: Verified. All services will be injected.
- [x] **II. State Management via BLoC / Cubit**: Verified. `QuizCubit` and `ProfileCubit` will manage state.
- [x] **III. Class-Based Widgets Only**: Verified. All UI updates will use `StatelessWidget` or `StatefulWidget`.
- [x] **IV. Drift as Persistence Layer**: Verified. Drift tables (`Profiles`, `GameScores`) defined.
- [x] **V. Injected Services**: Verified. `FlutterTts` and `AudioPlayer` provided via DI.
- [x] **VI. Descriptive Naming**: Verified.

## Project Structure

### Documentation (this feature)

```text
specs/001-kidzoo-v2-refactor/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (future)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── database/        # Drift database and DAOs
│   ├── services/        # Injected TTS and Audio services
│   └── widgets/         # Shared UI (GameExitButton)
├── features/
│   ├── QuizEngine/      # Unified quiz engine (Cubit, UI, Data)
│   ├── Profile/         # Profile creation and state
│   ├── Splash/          # Updated splash routing
│   └── home/            # Updated to remove legacy games
```

**Structure Decision**: Standard feature-first structure under `lib/features/`, utilizing `lib/core/` for shared cross-feature infrastructure like database and DI.

## Complexity Tracking

*(No unjustified violations to track)*
