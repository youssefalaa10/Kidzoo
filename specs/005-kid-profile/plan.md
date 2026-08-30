# Implementation Plan: Kid Profile

**Branch**: `[005-kid-profile]` | **Date**: 2026-06-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/005-kid-profile/spec.md`

## Summary

Design and implement a brand-new Kid Profile feature that serves as a central "home" for the child's progress. It will include a colorful hero section with bouncing avatars and XP progress, unlockable achievement badges, personalized personality summaries, fun statistics, weekly progress charts, and daily challenges. The design will be fully fluid and responsive, utilizing implicit animations and avoiding static lists.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: `flutter_bloc` (state management), `drift` (local persistence)

**Storage**: Drift (SQLite)

**Testing**: `flutter_test` (unit testing Cubits and widgets)

**Target Platform**: Android, iOS (Mobile, Tablet, Desktop layouts)

**Project Type**: Flutter Educational App

**Performance Goals**: 60 FPS for all animations and transitions.

**Constraints**: "Zero Static State" strictly enforced. All data must be fetched and persisted via BLoC/Cubit + Repository patterns. Must work seamlessly across Portrait and Landscape orientations without overflow.

**Scale/Scope**: 1 main Profile Screen, ~5 custom Widgets (Hero, Badges, Stats, Challenges), 1 Cubit, 1 Drift DAO.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Zero Static State**: ✅ Profile data will be instance-owned by `ProfileCubit`.
- **State Management via BLoC / Cubit**: ✅ `ProfileCubit` will manage states (Loading, Loaded, Error).
- **Class-Based Widgets Only**: ✅ All UI components will be implemented as `StatelessWidget` or `StatefulWidget`.
- **Drift as Persistence Layer**: ✅ Profile, stats, and badges will be stored in Drift.
- **Injected Services**: ✅ Repositories will be injected.
- **Descriptive Naming**: ✅ `ProfileScreen`, `AvatarSelectionDialog`, `AchievementBadgeCard`.

## Project Structure

### Documentation (this feature)

```text
specs/005-kid-profile/
├── plan.md              
├── research.md          
├── data-model.md        
├── quickstart.md        
└── tasks.md             
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── shared/
│       └── widgets/
│           └── animated_badge.dart
├── features/
│   └── Profile/
│       ├── UI/
│       │   ├── profile_screen.dart
│       │   ├── widgets/
│       │   │   ├── hero_section.dart
│       │   │   ├── stats_section.dart
│       │   │   ├── weekly_progress.dart
│       │   │   └── challenge_card.dart
│       │   └── dialogs/
│       │       └── avatar_selection_dialog.dart
│       ├── bloc/
│       │   ├── profile_cubit.dart
│       │   └── profile_state.dart
│       └── repository/
│           └── profile_repository.dart
```

**Structure Decision**: A new `Profile` feature module will be created. It contains the UI logic, state management (Cubit), and repository which interfaces with the app's global Drift database.

## Complexity Tracking

*(No violations)*
