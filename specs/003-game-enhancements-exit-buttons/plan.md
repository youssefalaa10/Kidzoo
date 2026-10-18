# Implementation Plan: [FEATURE]

**Branch**: `[003-game-enhancements-exit-buttons]` | **Date**: 2026-06-23 | **Spec**: [003-game-enhancements-exit-buttons/spec.md](spec.md)

**Input**: Feature specification from `/specs/003-game-enhancements-exit-buttons/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

This feature implements a centralized `GameAssetManager` and a reusable `GameExitButton` to eliminate static assets and standardize the exit experience across Phase 4 and Phase 5 game modules, adhering strictly to the "Zero Static State" Constitution principle.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: `flutter_bloc` (Cubit/BLoC), `drift` (persistence), `flutter_localizations`

**Storage**: N/A for this feature (Drift used globally)

**Testing**: `flutter_test`

**Target Platform**: Mobile (Android/iOS)

**Project Type**: mobile-app

**Performance Goals**: 60 fps rendering, <16ms frame build time for the exit button

**Constraints**: Zero static state, class-based widgets only

**Scale/Scope**: Update all game screens in Phase 4 and 5 to use the centralized Exit Button and Asset Manager

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Zero Static State**: ✅ Pass. Will use injected `GameAssetManager` via `RepositoryProvider`.
- **State Management via BLoC/Cubit**: ✅ Pass. State is instance-owned.
- **Class-Based Widgets Only**: ✅ Pass. The Exit Button will be a `StatelessWidget` class.
- **Drift as Persistence Layer**: ✅ Pass (N/A for UI components).
- **Injected Services**: ✅ Pass. Centralized asset management injected via context.
- **Descriptive Naming**: ✅ Pass. Using `GameExitButton` and `GameAssetManager`.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
lib/
├── core/
│   └── managers/
│       └── game_asset_manager.dart    # New centralized asset manager service
├── shared/
│   └── widgets/
│       └── game_exit_button.dart      # Reusable exit button component
└── features/
    ├── phase4_games/                  # Targets for refactoring
    └── phase5_games/                  # Targets for refactoring
```

**Structure Decision**: The feature introduces shared core services (`lib/core/managers/`) and shared UI components (`lib/shared/widgets/`) that will be consumed by the respective game feature modules.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
