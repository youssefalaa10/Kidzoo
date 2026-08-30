---

description: "Task list for Project-Wide Adaptive Architecture"
---

# Tasks: Project-Wide Adaptive Architecture

**Input**: Design documents from `specs/004-unified-quiz-responsive/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, audit_report.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- Paths shown below assume Flutter single project structure within `lib/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

*(Project is already initialized. Skipping to foundational tasks.)*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T001 Implement `BackgroundResolver` service in `lib/core/services/background_resolver.dart`
- [x] T002 Implement `FluidContainer` base widget in `lib/core/shared/widgets/fluid_container.dart`
- [x] T003 Implement `PhysicsGameCanvas` base widget in `lib/core/shared/widgets/physics_game_canvas.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel.

---

## Phase 3: User Story 1 - Fluid Responsive Design & Global Backgrounds (Priority: P1) 🎯 MVP

**Goal**: Convert all standard screens and grid games to Fluid Responsive Design to retain visual hierarchy while adjusting constraints. Replace stretched backgrounds globally using the background resolver. Wrap physics games in fixed-aspect-ratio canvases.

**Independent Test**: Resize the window on desktop. Standard screens should constrain content gracefully. Physics games should scale via aspect ratio without modifying physics variables or creating black bars. Backgrounds must intelligently swap.

### Implementation for User Story 1

*Note: These tasks bundle the UI constraints (US1) and Background injection (US2) since they target identical files.*

- [x] T004 [P] [US1] Apply `FluidContainer` and `BackgroundResolver` to `lib/features/Profile/profile_setup_screen.dart` and `lib/features/home/UI/character.dart`
- [x] T005 [P] [US1] Apply `FluidContainer` and `BackgroundResolver` to `lib/features/home/home_screen.dart`
- [x] T006 [P] [US1] Apply `FluidContainer` and `BackgroundResolver` to `lib/features/LevelsMap/levels_map_screen.dart`
- [x] T007 [P] [US1] Apply `FluidContainer` and `BackgroundResolver` to `lib/features/settings/settings_screen.dart` and `lib/features/settings/language_screen.dart`
- [x] T008 [P] [US1] Refactor Educational modules (Vehicles, Fruits, Vegetables, Animal Name) wrapping grids in `FluidContainer`
- [x] T009 [P] [US1] Refactor Grid/Tile Games (Tic Tac Toe, Memory Game, Flag Game, Puzzle Game, Color Memory, Missing Letter) wrapping grids in `FluidContainer`
- [ ] T010 [P] [US1] Isolate Flappy Bird game engine in `lib/features/FlappyBird/` using `PhysicsGameCanvas`
- [ ] T011 [P] [US1] Isolate Paddle Bounce in `lib/features/PaddleBounce/` using `PhysicsGameCanvas`
- [ ] T012 [P] [US1] Isolate Maze Game in `lib/features/MazeGame/` using `PhysicsGameCanvas`
- [ ] T013 [P] [US1] Isolate Color Switch in `lib/features/ColorSwitchGame/` and Dots & Boxes in `lib/features/DotsAndBoxes/` using `PhysicsGameCanvas`

**Checkpoint**: At this point, the entire application has been successfully migrated to the Fluid Adaptive Layout architecture.

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T014 Run validation scenarios defined in `quickstart.md`
- [ ] T015 Verify zero usage of `BoxFit.cover` directly on device orientation edge cases.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: N/A
- **Foundational (Phase 2)**: BLOCKS all user stories. Must implement the UI wrappers and resolver first.
- **User Stories (Phase 3+)**: All depend on Foundational phase completion. All tasks inside Phase 3 can run entirely in parallel as they target highly isolated module directories.
- **Polish (Final Phase)**: Depends on all desired user stories being complete.

### Parallel Opportunities

- All Foundational tasks (T001, T002, T003) can theoretically be built in parallel.
- ALL screen refactors (T004 - T013) marked `[P]` touch completely isolated `lib/features/*` directories and can be implemented safely in parallel.

---

## Implementation Strategy

### Incremental Delivery

1. Complete Foundational layout wrappers (`FluidContainer`, `PhysicsGameCanvas`, `BackgroundResolver`).
2. Knock out Core Navigation Screens (Profile, Home, Settings) to ensure the primary app shell is fluid.
3. Batch update the grid-based games to ensure consistency.
4. Batch update the physics-based games to ensure gameplay integrity is preserved.
