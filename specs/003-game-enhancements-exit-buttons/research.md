# Research & Decisions: Game Enhancements & Exit Buttons

## Asset Management Approach

- **Decision**: Utilize standard Flutter context-injected services for UI tokens (`Theme.of(context)` for colors, `AppLocalizations.of(context)` for strings) and introduce a `GameAssetManager` injected via `RepositoryProvider` for images, icons, and audio.
- **Rationale**: This strictly adheres to the "Zero Static State" and "Injected Services" principles of the project Constitution. It leverages built-in Flutter mechanisms for localization and theming while providing a clean, non-static service for other assets.
- **Alternatives considered**: 
  - *Static classes for assets*: Rejected due to Constitution violation (Zero Static State).
  - *GetIt/Service Locator*: Rejected because the project currently uses `RepositoryProvider` for DI (as seen in `main.dart`), so we maintain consistency.

## Reusable Exit Button Component

- **Decision**: Create a `GameExitButton` class-based widget that reads from `Theme`, `AppLocalizations`, and the injected `GameAssetManager` to render its visuals, invoking `Navigator.of(context).pop()` when tapped.
- **Rationale**: Fulfills the requirement for a centralized, reusable exit button across Phase 4 and 5 games without relying on hardcoded values.
- **Alternatives considered**: 
  - *Functional widgets*: Rejected due to Constitution violation (Class-Based Widgets Only).
  - *Duplicating exit logic in each game*: Rejected as it violates DRY principles and makes theming/localization updates harder.
