---
description: "Task list template for feature implementation"
---

# Tasks: Game Enhancements & Exit Buttons

**Input**: Design documents from `/specs/003-game-enhancements-exit-buttons/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create core manager directory `lib/core/managers/`
- [x] T002 Create shared widgets directory `lib/shared/widgets/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Create `GameAssetManager` service in `lib/core/managers/game_asset_manager.dart` for centralized images and audio paths
- [x] T004 Inject `GameAssetManager` using `RepositoryProvider` in `lib/main.dart`
- [x] T005 Implement `GameExitButton` class widget in `lib/shared/widgets/game_exit_button.dart` that consumes `Theme`, `AppLocalizations`, and `GameAssetManager`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Consistent and Managed Exit Button (Priority: P1) 🎯 MVP

**Goal**: Children playing the game should be able to exit seamlessly. The exit button should be visually consistent across all games and rely entirely on centralized assets.

**Independent Test**: Can be fully tested by playing any game session, tapping the exit button, and verifying the user is returned to the main menu.

### Implementation for User Story 1

Update all Phase 4 and 5 games to use the `GameExitButton` widget in their layout stack:

- [x] T006 [P] [US1] Update Flappy Bird game in `lib/features/FlappyBirdGame/flappy_bird_screen.dart`
- [x] T007 [P] [US1] Update Tic Tac Toe game in `lib/features/TicTacToe/tic_tac_toe_game.dart`
- [x] T008 [P] [US1] Update Missing Letter game in `lib/features/MissingLetterGame/Ui/missing_letter_screen.dart`
- [x] T009 [P] [US1] Update Paddle Bounce game in `lib/features/PaddleBounceGame/paddle_bounce_game_screen.dart`
- [x] T010 [P] [US1] Update Dots & Boxes game in `lib/features/DotsAndBoxes/dots_and_boxes_screen.dart`
- [x] T011 [P] [US1] Update Maze Game in `lib/features/MazeGame/`
- [x] T012 [P] [US1] Update Puzzle Game in `lib/features/Puzzle/`
- [x] T013 [P] [US1] Update Color Memory Game in `lib/features/ColorMemory/color_memory_screen.dart`
- [x] T014 [P] [US1] Update Color Switch Game in `lib/features/ColorSwitchGame/color_switch_screen.dart`
- [x] T015 [P] [US1] Update Flag Game in `lib/features/FlagGame/flag_game_menu_screen.dart`
- [x] T016 [P] [US1] Update Memory Game in `lib/features/MemoryGame/`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently.

---

## Phase 4: User Story 2 - Centralized Asset Management (Priority: P1)

**Goal**: Ensure no static data, strings, or colors are used within the phase 4 and 5 enhancements, and all game views retrieve their resources from centralized injected managers.

**Independent Test**: Code analysis confirms no `static const` UI properties inside game screens.

### Implementation for User Story 2

- [x] T017 [P] [US2] Refactor string and color usage in `lib/features/FlappyBirdGame/` to use `AppLocalizations` and `Theme`
- [x] T018 [P] [US2] Refactor string and color usage in `lib/features/TicTacToe/` to use `AppLocalizations` and `Theme`
- [x] T019 [P] [US2] Refactor string and color usage in `lib/features/MissingLetterGame/` to use `AppLocalizations` and `Theme`
- [x] T020 [P] [US2] Refactor string and color usage in `lib/features/PaddleBounceGame/` to use `AppLocalizations` and `Theme`
- [x] T021 [P] [US2] Refactor string and color usage in `lib/features/DotsAndBoxes/` to use `AppLocalizations` and `Theme`
- [x] T022 [P] [US2] Refactor string and color usage in `lib/features/MazeGame/` to use `AppLocalizations` and `Theme`
- [x] T023 [P] [US2] Refactor string and color usage in `lib/features/Puzzle/` to use `AppLocalizations` and `Theme`
- [x] T024 [P] [US2] Refactor string and color usage in `lib/features/ColorMemory/` to use `AppLocalizations` and `Theme`
- [x] T025 [P] [US2] Refactor string and color usage in `lib/features/ColorSwitchGame/` to use `AppLocalizations` and `Theme`
- [x] T026 [P] [US2] Refactor string and color usage in `lib/features/FlagGame/` to use `AppLocalizations` and `Theme`
- [x] T027 [P] [US2] Refactor string and color usage in `lib/features/MemoryGame/` to use `AppLocalizations` and `Theme`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently and adhere to the Zero Static State Constitution.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T028 Run quickstart.md validation to ensure zero static state and functioning exit navigation.
- [x] T029 Clean up unused static constants (e.g., hardcoded app colors/strings) from the refactored features.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Can start immediately.
- **Foundational (Phase 2)**: Depends on Phase 1 completion.
- **User Stories (Phase 3 & 4)**: Depend on Phase 2 completion. Can run in parallel since US1 affects layout and US2 affects internal widget string/color refs.
- **Polish (Final Phase)**: Depends on all user stories.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2).
- **User Story 2 (P1)**: Can start after Foundational (Phase 2). Can be performed on the same files concurrently or sequentially after US1.

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- Updating individual games in Phase 3 (T006-T016) can run in parallel
- Refactoring individual games in Phase 4 (T017-T027) can run in parallel

---

## Parallel Example: User Story 1

```bash
# Developers can work on different games simultaneously to add the exit button:
Task: Update Flappy Bird game in lib/features/FlappyBirdGame/flappy_bird_screen.dart
Task: Update Tic Tac Toe game in lib/features/TicTacToe/tic_tac_toe_game.dart
Task: Update Missing Letter game in lib/features/MissingLetterGame/Ui/missing_letter_screen.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Integrate the exit button across all games)
4. **STOP and VALIDATE**: Test User Story 1 independently

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (Exit Buttons) → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 (Centralized Assets) → Test independently → Deploy/Demo
4. Each story adds value without breaking previous stories
