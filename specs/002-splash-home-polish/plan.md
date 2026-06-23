# Implementation Plan: Splash & Home Polish

**Branch**: `002-splash-home-polish` | **Date**: 2026-06-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-splash-home-polish/spec.md`

## Summary

The objective is to replace hardcoded strings and image paths with dynamic, state-managed configurations and localized texts in the Splash and Home screens, resolving any layout bugs while adhering strictly to the project's zero static state and class-based widget constitution.

## Technical Context

**Language/Version**: Dart / Flutter

**Primary Dependencies**: `flutter_bloc`, `flutter_localizations`

**Storage**: N/A (UI and localization focus)

**Testing**: Flutter test (Widget testing)

**Target Platform**: Android, iOS

**Project Type**: Mobile Application

**Performance Goals**: 60 fps rendering, instantaneous language switching

**Constraints**: Zero static state, Class-based widgets only

**Scale/Scope**: ~10 screens/widgets impacted (Splash, Home, and related categories)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Zero Static State**: Configuration and text provided via `BuildContext` and `flutter_bloc` state.
- [x] **State Management via BLoC / Cubit**: Dynamic configurations managed through BLoC/Cubit.
- [x] **Class-Based Widgets Only**: All refactored components will be strict `StatelessWidget` or `StatefulWidget` classes.
- [x] **Injected Services**: Localization and configurations injected via context.

## Project Structure

### Documentation (this feature)

```text
specs/002-splash-home-polish/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (created in speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── localization/      # AppLocalizations and translation files
│   └── shared/style/      # ImageManager constants
└── features/
    ├── AppCategory/       # Category definitions (app_category_options.dart)
    ├── Splash/            # splash_screen.dart
    └── home/              # character.dart (HomeScreen)
```

**Structure Decision**: Utilizing the existing feature-based structure of the Kidzoo application.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No violations.*
