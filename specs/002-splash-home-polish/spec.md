# Feature Specification: Splash and Home Polish

**Feature Branch**: `002-splash-home-polish`

**Created**: 2026-06-23

**Status**: Draft

**Input**: User description: "phase 2 and 3 Splash & Home Polish- Bug Fixes and make sure no static values or strings or image"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Splash Screen Dynamic Loading (Priority: P1)

Users opening the application should experience a splash screen that correctly reflects localized content and dynamically loaded images, without relying on static placeholders.

**Why this priority**: Splash screen is the first impression; removing static hardcoded values ensures the app is easily localizable and maintainable.

**Independent Test**: Can be fully tested by launching the app and verifying that all text and images on the splash screen are loaded from the localization engine and configuration providers.

**Acceptance Scenarios**:

1. **Given** the app is launched in English, **When** the splash screen appears, **Then** the title and subtext correctly display the English localized strings.
2. **Given** the app configuration defines a specific splash image, **When** the splash screen renders, **Then** it uses the dynamically provided image path rather than a hardcoded string.

---

### User Story 2 - Home Screen Dynamic Content (Priority: P1)

Users navigating the home screen should see fully dynamic UI elements (category names, descriptions, icons) loaded via state management rather than hardcoded string or image values.

**Why this priority**: Eliminating static values is a core requirement of the requested polish and aligns with architectural standards for maintainability.

**Independent Test**: Can be fully tested by switching the app language and observing the home screen update entirely without requiring code changes for static values.

**Acceptance Scenarios**:

1. **Given** the user is on the home screen, **When** viewing the categories, **Then** all category titles, descriptions, and button labels are fetched from localization strings.
2. **Given** the user is viewing a game category, **When** the category image renders, **Then** the image path is provided by the state configuration, not hardcoded into the widget.

---

### User Story 3 - UI Bug Fixes and Layout Polish (Priority: P2)

Users should experience a smooth, bug-free layout across the Splash and Home screens with no layout overflows or visual glitches.

**Why this priority**: Resolving lingering bugs from Phase 2 and 3 refactoring is crucial for a polished user experience.

**Independent Test**: Can be fully tested by navigating through the Splash and Home flows on various screen sizes and verifying no visual issues occur.

**Acceptance Scenarios**:

1. **Given** a device with a smaller screen size, **When** navigating the Home screen, **Then** all elements fit cleanly without layout overflow errors.

### Edge Cases

- **Missing Localization Key**: If the localization configuration is missing a required string, the system gracefully falls back to the default language string or a safe placeholder without crashing.
- **Missing Asset Path**: If a dynamically requested image path fails to load or does not exist, the system gracefully renders a default fallback image or a safe empty space to preserve layout structure.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST replace all hardcoded text strings on the Splash and Home screens with localized string references.
- **FR-002**: The system MUST ensure all image and asset paths in the Splash and Home screens are supplied dynamically (e.g., via state variables or a dedicated configuration manager) rather than hardcoded string literals.
- **FR-003**: The system MUST resolve any layout overflow or rendering bugs present on the Splash and Home screens from previous development phases.
- **FR-004**: All UI components updated MUST strictly utilize encapsulated, object-oriented structures, avoiding standalone functional components completely.
- **FR-005**: The system MUST ensure state variables for UI content are instance-owned and managed centrally, adhering to the Zero Static State principle.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Static code analysis reveals zero instances of hardcoded string literals used for display text within the Splash and Home screen widget trees.
- **SC-002**: Static code analysis reveals zero instances of hardcoded asset paths within the Splash and Home screen widget trees.
- **SC-003**: Visual testing on target screen dimensions results in zero layout overflow errors.
- **SC-004**: Switching the application language updates 100% of the visible text on the Splash and Home screens instantaneously.

## Assumptions

- The project's existing localization infrastructure (e.g., `AppLocalizations`) is fully functional and supports adding new keys.
- The state management infrastructure (BLoC/Cubit) is already correctly set up in the application root to provide configurations.
