# Feature Specification: kidzoo-v2-refactor

**Feature Branch**: `[001-kidzoo-v2-refactor]`

**Created**: 2026-06-23

**Status**: Draft

**Input**: User description: "@[d:\coding\Flutter Projects\StudioProjects\kidzoo\docs\kidzoo_implementation_plan.md]"

## Clarifications

### Session 2026-06-23
- Q: Profile Management Scope → A: Single Profile Only (Option A)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mandatory Profile Onboarding (Priority: P1)

As a new user, I need to create a profile after launching the app so that my scores and progress can be saved.

**Why this priority**: Profile creation is mandatory and gates the rest of the application. It establishes the persistence layer needed for tracking scores.

**Independent Test**: Can be fully tested by launching the app, completing the splash screen, and verifying the profile creation screen appears before the home screen, and that a profile is successfully stored in Drift.

**Acceptance Scenarios**:

1. **Given** a first-time launch or no active profile, **When** the splash screen finishes, **Then** the user is navigated to the Profile Setup Screen.
2. **Given** the Profile Setup Screen, **When** the user inputs a name and selects an avatar and saves, **Then** the profile is persisted in the local database and the user navigates to the Home Screen.

---

### User Story 2 - Unified Quiz-Based Learning Engine (Priority: P1)

As a user playing educational games (Vehicles, Fruits, Vegetables), I want a consistent quiz interface so that I can easily understand how to play and learn new words.

**Why this priority**: Unifies three distinct games into one scalable engine, drastically reducing code duplication and standardizing the learning experience.

**Independent Test**: Can be fully tested by opening the Vehicles, Fruits, or Vegetables category and verifying that the game uses the unified quiz UI, plays correct TTS/audio, and tracks score correctly.

**Acceptance Scenarios**:

1. **Given** a user opens the Vehicles game, **When** a question is presented with a scene (e.g., Sky) and options, **Then** the user can tap an option and receive visual/audio feedback.
2. **Given** a user taps the correct option, **When** the feedback triggers, **Then** the app plays "Correct!" TTS, shows confetti, and increases the score.
3. **Given** a user taps an incorrect option, **When** the feedback triggers, **Then** the app shows "Try again", shakes the option, and does not penalize the score.

---

### User Story 3 - Cleanup of Deprecated Games (Priority: P2)

As a maintainer, I want the Snake, Basketball, and Goal games removed so that the codebase is simplified and focuses purely on educational content.

**Why this priority**: Reduces technical debt and app size, aligning the project with its core educational mission.

**Independent Test**: Can be fully tested by verifying these games are no longer accessible from the Home Screen and their corresponding assets/files are removed.

**Acceptance Scenarios**:

1. **Given** a user navigates the Home Screen categories, **When** looking for games, **Then** Snake, Basketball, and Goal games are not present.

### Edge Cases

- What happens when the user force-closes the app during profile creation?
- How does system handle TTS configuration if the device does not support the required language (e.g., Arabic)?
- What happens if the user rapidly taps multiple answers before the feedback animation finishes?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST force a single, persistent profile creation after the Splash Screen (no multi-profile switching supported).
- **FR-002**: System MUST persist profiles and game scores locally using Drift.
- **FR-003**: System MUST provide a unified Quiz Engine supporting scene-based questions and image-based questions.
- **FR-004**: System MUST play TTS pronunciation and sound effects upon correct answers.
- **FR-005**: System MUST NOT use functional widgets; all UI components must be class-based widgets.
- **FR-006**: System MUST manage all state via BLoC/Cubit without relying on static variables or global state.
- **FR-007**: System MUST completely remove legacy games (Snake, Basketball, Goal) and their assets.

### Key Entities

- **Profile**: Represents a user, containing an ID, name, avatar index, and total points.
- **GameScore**: Represents a score achieved by a Profile in a specific game, including the game key, score, and timestamp.
- **QuizQuestion**: Represents a question in the unified engine, including the prompt, associated image/scene, and a list of QuizOptions.
- **QuizOption**: Represents a possible answer, including its text, image, and whether it is the correct answer.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of new app launches require profile creation before accessing the Home Screen.
- **SC-002**: Codebase size is reduced due to the removal of 3 games and unification of 3 others.
- **SC-003**: Zero instances of `static` variables or functional widgets exist in the refactored features.
- **SC-004**: Users can successfully answer quiz questions with immediate visual and audio feedback without crashing or state desync.

## Assumptions

- Users have devices capable of playing local audio and supporting TTS.
- Drift database schema migrations will be handled cleanly for existing installations.
- All needed assets for the unified quiz engine (scenes, vehicles, fruits, vegetables) are available locally.
