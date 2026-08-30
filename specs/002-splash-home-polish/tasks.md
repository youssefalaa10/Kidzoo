# Tasks: Splash & Home Polish

**Input**: Design documents from `specs/002-splash-home-polish/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Initialize workspace and verify existing `AppLocalizations` setup.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Add required localization keys for Splash and Home screens to `en.json` (and other supported languages, e.g., `ar.json`).
- [x] T003 Ensure `ImageManager` in `lib/core/shared/style/image_manager.dart` contains references for all dynamically loaded images needed.

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Splash Screen Dynamic Loading (Priority: P1) 🎯 MVP

**Goal**: Splash screen correctly reflects localized content and dynamically loaded images without static placeholders.

**Independent Test**: Launch the app and verify that all text and images on the splash screen are loaded dynamically.

### Implementation for User Story 1

- [x] T004 [P] [US1] Refactor `SplashScreen` in `lib/features/Splash/splash_screen.dart` to replace hardcoded strings with `AppLocalizations.of(context)`.
- [x] T005 [P] [US1] Update `SplashScreen` in `lib/features/Splash/splash_screen.dart` to use dynamic image paths via `ImageManager`.
- [x] T006 [US1] Add fallback edge-case handling in `SplashScreen` for missing localization keys or broken asset paths.

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Home Screen Dynamic Content (Priority: P1)

**Goal**: Home screen UI elements (category names, descriptions, icons) loaded via state management rather than hardcoded string or image values.

**Independent Test**: Switch the app language and observe the home screen update entirely without requiring code changes.

### Implementation for User Story 2

- [x] T007 [P] [US2] Update `AppCategoryOptions` in `lib/features/AppCategory/app_category_options.dart` to use `AppLocalizations` keys for all category titles.
- [x] T008 [P] [US2] Refactor `HomeScreen` (`lib/features/home/character.dart`) to replace any hardcoded UI text with localized keys.
- [x] T009 [P] [US2] Ensure all asset paths in `app_category_options.dart` strictly reference `ImageManager` constants and remove raw strings.

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - UI Bug Fixes and Layout Polish (Priority: P2)

**Goal**: A smooth, bug-free layout across the Splash and Home screens with no layout overflows or visual glitches.

**Independent Test**: Navigate through Splash and Home flows on various screen sizes and verify no visual issues occur.

### Implementation for User Story 3

- [x] T010 [P] [US3] Wrap scaling widgets in `lib/features/AppCategory/app_category_options.dart` with `Flexible` or `Expanded` to prevent layout overflow errors on smaller screens.
- [x] T011 [P] [US3] Verify and fix layout overflow warnings in the character selection flow in `lib/features/home/character.dart`.
- [x] T012 [US3] Ensure `CustomMQ` is correctly utilized for responsive text and widget sizing in both updated screens.

**Checkpoint**: All user stories should now be independently functional

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T013 Code cleanup and formatting using `dart format .`
- [x] T014 Run manual UI verification against `quickstart.md` scenarios.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2)
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Independent of US1
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Integrates with US1/US2 UI

### Parallel Opportunities

- **US1 Implementation**: T004 and T005 can be executed simultaneously.
- **US2 Implementation**: T007, T008, and T009 affect distinct components and can be parallelized.
- **US3 Implementation**: T010 and T011 focus on separate screen files and can run in parallel.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 & 2.
2. Complete Phase 3: Splash Screen Polish.
3. Validate and demo dynamic Splash Screen behavior.

### Incremental Delivery

1. Implement US1 for dynamic Splash Screen setup.
2. Follow up with US2 for full Home Screen localization and dynamic assets.
3. Finalize with US3 to squash overflow bugs using responsive wrappers.
