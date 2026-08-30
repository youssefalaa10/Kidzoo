# Feature Specification: Project-Wide Adaptive Architecture

**Feature Branch**: `[004-project-wide-adaptive]`

**Created**: 2026-06-23

**Status**: Draft

**Input**: User description: "Objective: This is NOT a Unified Quiz only task. Apply responsive and adaptive design to the ENTIRE Kidzoo application. The scope is the whole project. Every screen, every game and every page must support: Mobile portrait, Mobile landscape, Tablet portrait, Tablet landscape, Desktop, Desktop window resizing."

## Clarifications
### Session 2026-06-23
- Q: How to handle layout adaptation for physics-based or strictly dimension-bound games (e.g., Flappy Bird, Maze Game, Paddle Bounce)? → A: Use a centered game canvas with a fixed aspect ratio. Fill the remaining space with decorative backgrounds and supporting UI. Never show black bars. Do not dynamically modify gameplay physics.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fluid Responsive Design (Priority: P1)

Users interacting with any screen or game in the Kidzoo application must experience a native-feeling UI tailored specifically to their device's category. The application will utilize Fluid Responsive Design, keeping the same visual hierarchy and widget order across all devices, but intelligently adjusting spacing, max widths, image sizes, and padding.

**Why this priority**: A consistent visual hierarchy prevents user confusion across devices while utilizing fluid constraints (spacing, max-widths) prevents the "blown-up mobile UI" effect on large screens.

**Independent Test**: Can be tested by running any core screen on mobile, tablet, and desktop viewports. The structural layout (widget order) must remain identical, but spacing, constraints, and image proportions must adjust to prevent stretching.

**Acceptance Scenarios**:

1. **Given** the user is on a Mobile device, **When** they load any screen, **Then** the UI renders with tight padding and full-width components where appropriate.
2. **Given** the user is on a Tablet or Desktop, **When** they load any screen, **Then** the UI renders with identical visual hierarchy, but utilizes increased padding, max-width constraints on central content, and adjusted image sizes to effectively use whitespace.

---

### User Story 2 - Global Device-Specific Backgrounds (Priority: P1)

Users must see crisp background assets specifically designed for their device form factor across all screens to prevent stretching. A centralized `BackgroundResolver` provides the correct background based on device class.

**Why this priority**: Stretching a portrait background across a landscape desktop screen causes severe distortion, reducing the visual quality of the app.

**Independent Test**: Test by navigating through multiple distinct areas of the app (Splash, Home, Quiz) on different screen sizes and verifying that the correct image file (mobile, tablet, or desktop specific) is loaded without stretching.

**Acceptance Scenarios**:

1. **Given** the app runs on a mobile device, **When** loading backgrounds, **Then** the `BackgroundResolver` provides mobile-specific assets.
2. **Given** the app runs on a tablet, **When** loading backgrounds, **Then** the `BackgroundResolver` provides tablet-specific assets.
3. **Given** the app runs on a desktop, **When** loading backgrounds, **Then** the `BackgroundResolver` provides desktop-specific assets.

### Edge Cases

- What happens if the window size fluctuates exactly on a breakpoint boundary repeatedly? The system must switch layouts cleanly without performance drops or infinite loops.
- What happens if a specific game has mechanics strictly tied to an aspect ratio (e.g., Flappy Bird physics)? The game canvas must be centered and maintain its fixed aspect ratio. The remaining space must be filled with decorative backgrounds and supporting UI. Black bars are strictly prohibited, and gameplay physics must not be dynamically modified.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST use Fluid Responsive Design for normal screens, keeping the same order of widgets across devices while adjusting spacing, max widths, image sizes, and padding.
- **FR-002**: The system MUST NOT increase text sizes proportionally with screen width. Text sizes must remain within reasonable readable limits across all devices.
- **FR-003**: The system MUST enforce a centered, fixed-aspect-ratio game canvas for physics-based games, filling excess space with decorative UI and backgrounds without using black bars.
- **FR-004**: The system MUST dynamically switch background assets according to device type using a dedicated `BackgroundResolver` service.
- **FR-005**: Responsive calculations and constraints MUST come directly from `BuildContext` (e.g. via `MediaQuery` or `LayoutBuilder`). There MUST be no static breakpoint classes or global responsive state.
- **FR-006**: The system MUST support orientation changes (portrait to landscape) on all supported devices and immediately recalculate constraints.
- **FR-007**: The system MUST smoothly handle desktop window resizing, transitioning seamlessly.
- **FR-008**: Existing visual hierarchy and educational flow MUST be preserved. The system should not reposition widgets unnecessarily across devices unless a screen becomes unusable due to space constraints.
- **FR-009**: The implementation MUST audit every screen and game in the codebase and apply responsive updates incrementally until all screens comply with the responsive architecture.
### Non-Functional Requirements

- **NFR-001**: BLoC/Cubit logic MUST remain entirely independent from UI responsiveness. It should not know or care which layout is active.
- **NFR-002**: All widgets related to responsiveness MUST be implemented as class-based widgets. Functional widgets are not permitted.

---

## Success Criteria *(mandatory)*

1. **Project-Wide Coverage**: Every single screen and game in the application applies Fluid Responsive Design.
2. **Asset Resolution**: Background assets switch automatically per device category without image stretching occurring.
3. **Visual Consistency**: The widget hierarchy remains identical across devices, with whitespace managed via constraints and padding.
4. **Layout Integrity**: No UI clipping or overflow errors occur across any supported dimensions.
5. **Responsiveness**: Orientation changes and window resizes recalculate layouts immediately.
6. **Zero Static State**: No static variables or singleton managers are introduced to handle layouts.
7. **Clean Architecture**: BLoC logic remains strictly UI-agnostic.

---

## Dependencies & Assumptions *(optional)*

### Assumptions
- The application environment allows dynamic window resizing (Desktop/Web) or orientation changes (Tablet).
- Device-specific background assets are present for the various screen types, or fallback mechanisms are defined.
