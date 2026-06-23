# Tasks: kidzoo-v2-refactor

**Input**: Design documents from `/specs/001-kidzoo-v2-refactor/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Update `pubspec.yaml` to include new asset folders (`assets/gen/images/scenes/`) and ensure `drift`, `flutter_bloc`, `flutter_tts`, `audioplayers` are configured properly.
- [x] T002 [P] Create base directories in `lib/features/QuizEngine`, `lib/features/Profile`, `lib/features/Splash` per the plan structure.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Update Drift Database schema (`lib/core/database/config.dart`, `lib/core/database/tables/profile_table.dart`, `lib/core/database/tables/game_scores_table.dart`) with new entities and migrations.
- [x] T004 Run `dart run build_runner build` to generate DAOs and drift database code.
- [x] T005 [P] Implement `ProfileDao` and `GameScoresDao` in `lib/core/database/daos/`.
- [x] T006 [P] Setup dependency injection (e.g., Service Locator or MultiRepositoryProvider) for `FlutterTts`, `AudioPlayer`, and database DAOs in `lib/main.dart` or related setup file.

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Mandatory Profile Onboarding (Priority: P1) 🎯 MVP

**Goal**: Force new users to create a profile after launching the app to enable progress saving.

**Independent Test**: Can be tested by launching the app with an empty DB, proceeding past Splash, seeing ProfileSetupScreen, creating a profile, and landing on Home.

### Implementation for User Story 1

- [x] T007 [P] [US1] Implement `ProfileCubit` in `lib/features/Profile/profile_cubit.dart` handling state for fetching/creating profiles.
- [x] T008 [P] [US1] Create `ProfileSetupScreen` UI in `lib/features/Profile/profile_setup_screen.dart` (strictly using class widgets).
- [x] T009 [US1] Update `SplashScreen` in `lib/features/Splash/splash_screen.dart` to check `ProfileCubit` state and route to `ProfileSetupScreen` instead of directly to Home if no profile exists.
- [x] T010 [US1] Connect `ProfileSetupScreen` save action to `ProfileCubit.createProfile()` and route to `HomeScreen` upon success.

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Unified Quiz-Based Learning Engine (Priority: P1)

**Goal**: Unify Vehicles, Fruits, and Vegetables games into a single quiz interface with visual/audio feedback.

**Independent Test**: Can be verified by opening the Vehicles, Fruits, or Vegetables category, completing a quiz round, and seeing "Correct!" feedback, TTS pronunciation, and score increase.

### Implementation for User Story 2

- [x] T011 [P] [US2] Create data models `QuizQuestion` and `QuizOption` in `lib/features/QuizEngine/data/quiz_models.dart`.
- [x] T012 [P] [US2] Implement `QuizCubit` in `lib/features/QuizEngine/bloc/quiz_cubit.dart` managing states (loading, active question, correct/incorrect feedback, score updating via `GameScoresDao`).
- [x] T013 [P] [US2] Create shared UI components `QuizSceneCard`, `QuizImageCard`, and `QuizOptionsRow` as class widgets in `lib/features/QuizEngine/ui/widgets/`.
- [x] T014 [US2] Implement `QuizEngineScreen` in `lib/features/QuizEngine/ui/quiz_engine_screen.dart` combining Cubit and shared UI.
- [x] T015 [US2] Update `AppCategoryOptions` to route Vehicles, Fruits, and Vegetables clicks to the unified `QuizEngineScreen` with the respective question sets.
- [x] T016 [US2] Implement `FlutterTts` and `AudioPlayer` invocation in `QuizCubit` for correct answer feedback.
- [x] T017 [US2] Implement `ScoreCubit` or direct `GameScoresDao` updates when completing a quiz round.

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Cleanup of Deprecated Games (Priority: P2)

**Goal**: Remove Snake, Basketball, and Goal games to simplify the codebase.

**Independent Test**: Verify these games are no longer accessible from the Home Screen and their corresponding assets/files are removed.

### Implementation for User Story 3

- [x] T018 [P] [US3] Delete feature folders `lib/features/GoalScoreGame/`, `lib/features/BasketballGame/`, and `lib/features/SnakeGame/` if they exist.
- [x] T019 [US3] Remove Snake, Basketball, and Goal game categories from the `HomeScreen` UI and category definitions (`app_category_options.dart`).
- [x] T020 [US3] Delete corresponding assets from `assets/gen/images/games/` and `assets/audio/` (goal_score.mp3, basket_score.mp3, eat_sound.mp3) and remove them from `pubspec.yaml`.

**Checkpoint**: All user stories should now be independently functional

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T021 Code cleanup and formatting using `dart format .`.
- [x] T022 Run quickstart.md validation manually to ensure end-to-end integration works smoothly.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - No dependencies on US1, but needs DB for score saving.
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - No dependencies on other stories

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories
