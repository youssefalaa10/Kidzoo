# Feature Specification: Kid Profile

**Feature Branch**: `[005-kid-profile]`

**Created**: 2026-06-25

**Status**: Draft

**Input**: User description: "Design and implement a brand-new Kid Profile feature for Kidzoo..."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Viewing Kid Profile Overview (Priority: P1)

Children or parents open the profile page and immediately see the child's basic progress, including a large avatar, name, current level, and a colorful XP progress bar.

**Why this priority**: It is the foundation of the profile and establishes the playful aesthetic required. Without this, there is no profile.

**Independent Test**: Can be tested by navigating to the Profile page from Home. The interface should load the correct name, avatar, and XP without crashing and display a friendly, playful layout.

**Acceptance Scenarios**:

1. **Given** the user is on the main menu, **When** they tap the profile icon, **Then** they see a large colorful profile card with the child's bouncing avatar, name, level, XP bar, and favorite badge.

### User Story 2 - Changing the Avatar (Priority: P1)

Children can tap their avatar to choose a new animal avatar from a pre-defined list (Lion, Monkey, Elephant, Panda, Cat, Dog, Rabbit, Bird) and see the change animate smoothly.

**Why this priority**: Essential for customization, making the app feel personal and engaging for the child.

**Independent Test**: Tested by opening the avatar selection dialog and selecting a new avatar; the profile should update instantly with a smooth transition.

**Acceptance Scenarios**:

1. **Given** the user is viewing the profile, **When** they tap the avatar or edit button, **Then** a friendly dialog appears showing available animal avatars.
2. **Given** the avatar dialog is open, **When** the user taps an avatar, **Then** the dialog closes and the avatar updates with a smooth animation.

### User Story 3 - Achievement Badges & Personality Summary (Priority: P2)

Children can scroll down to see unlocked and locked achievement badges with sparkling animations for unlocked ones, followed by a personalized friendly message summarizing their play style.

**Why this priority**: Badges and personality messages provide strong long-term motivation for children to keep playing.

**Independent Test**: Tested by verifying that playing a specific category of games (e.g., fruit games) unlocks the correct badge (Fruit Master) and influences the personality text ("You are becoming a Fruit Expert!").

**Acceptance Scenarios**:

1. **Given** the child has completed a specific milestone, **When** they view their badges, **Then** the corresponding badge appears unlocked with a sparkle animation.
2. **Given** the child's activity history, **When** the personality section is rendered, **Then** a friendly message matching their history is displayed.

### User Story 4 - Fun Statistics & Weekly Progress (Priority: P2)

Children and parents can view animated statistical cards (Games Played, Stars Collected, Best Score) and a weekly chart using stars or smiley faces.

**Why this priority**: Provides quantitative feedback in a kid-friendly visual way, showing progress to parents while remaining fun for children.

**Independent Test**: Tested by playing a game, scoring points, and verifying the statistics cards and weekly chart update accordingly.

**Acceptance Scenarios**:

1. **Given** the profile page is loaded, **When** the statistics section appears, **Then** the cards animate in and display correct metrics.
2. **Given** daily activity over a week, **When** the weekly chart is rendered, **Then** it shows stars corresponding to the daily activity level.

### User Story 5 - Daily Challenges & Rewards (Priority: P3)

Children receive one daily challenge (e.g., "Feed 5 animals") and earn rewards (XP, stars) upon completion, eventually unlocking treasure chests for new avatars or stickers.

**Why this priority**: Provides daily retention loops, but the core profile can function without it initially.

**Independent Test**: Tested by checking the current daily challenge, completing it in a game, and returning to claim the reward.

**Acceptance Scenarios**:

1. **Given** a new day, **When** the child opens the profile, **Then** a new daily challenge is displayed.
2. **Given** a completed daily challenge, **When** the user returns to the profile, **Then** a reward chest is presented with a celebration animation.

---

### Edge Cases

- What happens when a user earns XP that surpasses multiple levels at once?
- How does the system handle missing asset paths for locked/unlocked badges?
- What happens if there is no activity history for the personality summary?
- How does the UI behave on a small phone in landscape mode where vertical space is extremely limited?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a colorful hero section with bouncing avatar, name, level, XP bar, and favorite badge.
- **FR-002**: System MUST allow changing the avatar from a predefined set (Lion, Monkey, Elephant, Panda, Cat, Dog, Rabbit, Bird) and animate the transition.
- **FR-003**: System MUST provide a friendly dialog to change the child's display name.
- **FR-004**: System MUST calculate XP based on activity completion (e.g., Easy +10, Medium +20, Hard +35) and level progression.
- **FR-005**: System MUST display achievement badges, showing unlocked badges with sparkle animations and locked badges as greyed out.
- **FR-006**: System MUST generate and display a friendly personality summary based on the child's activity history.
- **FR-007**: System MUST display fun statistics (Games Played, Correct Answers, Stars, Current Streak, etc.) using animated cards.
- **FR-008**: System MUST display a weekly progress chart using kid-friendly icons (stars/smileys).
- **FR-009**: System MUST generate one daily challenge and grant rewards (Stars, XP, badges) upon completion.
- **FR-010**: System MUST periodically unlock a Reward Chest granting items like stickers, golden stars, or confetti.
- **FR-011**: System MUST display random motivational messages.
- **FR-012**: System MUST use playful UI elements: rounded containers, floating clouds, stars, confetti, soft gradients, and large touch targets.
- **FR-013**: System MUST be fully responsive across Portrait, Landscape, Tablets, and Small Phones without RenderFlex overflow.
- **FR-014**: System MUST utilize implicit animations (`AnimatedContainer`, `AnimatedSwitcher`, `Hero`) to avoid full page rebuilds and optimize performance.

### Key Entities

- **Profile**: Represents the child's current state, including name, avatar, level, total XP, and current streak.
- **Badge**: Represents an unlockable achievement (e.g., First Steps, Fruit Master) with state (locked/unlocked).
- **DailyChallenge**: Represents a daily task with a description, target count, current count, and associated reward.
- **Statistics**: Contains aggregated data such as Games Played, Stars Collected, Best Score, and Time Spent.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The Profile page renders fully without any RenderFlex overflows on all device orientations and sizes (Phone Portrait/Landscape, Tablet Portrait/Landscape).
- **SC-002**: Avatar changes animate smoothly, taking less than 500ms without dropping frames below 60fps.
- **SC-003**: XP is correctly aggregated and the Level is accurately calculated according to the defined progression curve.
- **SC-004**: Achievement badges correctly reflect the completion state of the user's historical game data.

## Assumptions

- We are using the existing Cubit/Bloc state management pattern.
- The existing games will dispatch their completion events so the Profile feature can update XP, statistics, and badges.
- Local storage (Drift or SharedPreferences) will be used to persist the Profile data.
- The feature does not require immediate cloud sync or multi-device synchronization for v1.
- We have placeholder or generated assets for avatars, badges, and UI elements.
