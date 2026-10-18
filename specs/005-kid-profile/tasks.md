# Tasks: Kid Profile

**Input**: Design documents from `/specs/005-kid-profile/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create `Profile` feature module directories in `lib/features/Profile/`
- [ ] T002 Create UI, widgets, dialogs, bloc, models, repository folders

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Update Drift database tables to include Profile, Badge, and DailyActivity schemas
- [ ] T004 Create `ProfileData` model classes in `lib/features/Profile/models/profile_data.dart`
- [ ] T005 Implement `ProfileRepository` in `lib/features/Profile/repository/profile_repository.dart`
- [ ] T006 Implement `ProfileState` and `ProfileCubit` in `lib/features/Profile/bloc/`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Viewing Kid Profile Overview (Priority: P1) 🎯 MVP

**Goal**: Children or parents open the profile page and immediately see the child's basic progress, including a large avatar, name, current level, and a colorful XP progress bar.

**Independent Test**: Can be tested by navigating to the Profile page from Home. The interface should load the correct name, avatar, and XP without crashing and display a friendly, playful layout.

### Implementation for User Story 1

- [ ] T007 [P] [US1] Create `ProfileScreen` in `lib/features/Profile/UI/profile_screen.dart` linking to Cubit
- [ ] T008 [US1] Implement `HeroSection` widget in `lib/features/Profile/UI/widgets/hero_section.dart` (Bouncing Avatar, Name, Level, XP Bar)
- [ ] T009 [US1] Add basic Profile navigation button to the main Home Screen

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Changing the Avatar (Priority: P1)

**Goal**: Children can tap their avatar to choose a new animal avatar from a pre-defined list.

**Independent Test**: Tested by opening the avatar selection dialog and selecting a new avatar; the profile should update instantly.

### Implementation for User Story 2

- [ ] T010 [P] [US2] Create `AvatarSelectionDialog` in `lib/features/Profile/UI/dialogs/avatar_selection_dialog.dart`
- [ ] T011 [US2] Update `HeroSection` to detect taps on Avatar and launch the dialog
- [ ] T012 [US2] Add updateAvatar method to `ProfileCubit` and `ProfileRepository`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Achievement Badges & Personality Summary (Priority: P2)

**Goal**: Children can see unlocked and locked achievement badges with sparkling animations for unlocked ones, followed by a personalized friendly message.

**Independent Test**: Verify that badges reflect the state and unlock animations play.

### Implementation for User Story 3

- [ ] T013 [P] [US3] Create `BadgeData` model and drift table extensions if needed
- [ ] T014 [US3] Implement `AnimatedBadge` widget in `lib/core/shared/widgets/animated_badge.dart`
- [ ] T015 [US3] Implement `BadgesSection` widget in `lib/features/Profile/UI/widgets/badges_section.dart`
- [ ] T016 [US3] Implement Personality Summary text generation in `ProfileCubit` based on stats

**Checkpoint**: All user stories 1, 2, 3 should now be independently functional

---

## Phase 6: User Story 4 - Fun Statistics & Weekly Progress (Priority: P2)

**Goal**: Children and parents can view animated statistical cards and a weekly chart.

**Independent Test**: Verify the statistics cards and weekly chart update accordingly.

### Implementation for User Story 4

- [ ] T017 [P] [US4] Create `StatsSection` widget in `lib/features/Profile/UI/widgets/stats_section.dart` (Games Played, Stars Collected, Best Score)
- [ ] T018 [P] [US4] Create `WeeklyProgress` widget in `lib/features/Profile/UI/widgets/weekly_progress.dart` (stars/smileys per day)
- [ ] T019 [US4] Add stats retrieval logic to `ProfileCubit`

---

## Phase 7: User Story 5 - Daily Challenges & Rewards (Priority: P3)

**Goal**: Children receive one daily challenge and earn rewards upon completion.

**Independent Test**: Check the current daily challenge, complete it, and claim reward.

### Implementation for User Story 5

- [ ] T020 [P] [US5] Create `DailyChallenge` model
- [ ] T021 [US5] Implement `ChallengeCard` widget in `lib/features/Profile/UI/widgets/challenge_card.dart`
- [ ] T022 [US5] Add daily challenge generation and validation logic to `ProfileCubit`

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T023 Code cleanup and refactoring in Profile widgets
- [ ] T024 Ensure responsive fluid layout for Landscape and Tablet using `LayoutBuilder` across Profile Screen
- [ ] T025 Run `quickstart.md` validation on Emulator

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
- **Polish (Final Phase)**: Depends on all desired user stories being complete
