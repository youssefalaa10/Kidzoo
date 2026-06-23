# Research & Technical Decisions: Splash & Home Polish

## Technology Choices & Implementations

### 1. Localization & Dynamic Text Injection
- **Decision**: Utilize the existing `AppLocalizations.of(context)` engine for all UI strings.
- **Rationale**: The Kidzoo project already contains a localization setup (`l10n`). Reusing this avoids duplicate dependencies and leverages built-in Flutter best practices for internationalization.
- **Alternatives considered**: None. Standard Flutter localizations are the optimal path.

### 2. Dynamic Asset Path Injection
- **Decision**: Utilize the existing `ImageManager` and data models (`OptionItem`) for resolving asset paths instead of hardcoded raw strings. Provide any runtime variations via `ProfileCubit` or `SettingsCubit` state.
- **Rationale**: Removes raw strings (`'assets/images/...'`) directly from UI widgets. Centralizes asset management.
- **Alternatives considered**: Passing strings directly from Cubit state (rejected to avoid polluting state logic with UI asset paths).

### 3. Layout Bug Resolution
- **Decision**: Wrap critical scaling elements in `Flexible`, `Expanded`, or `SingleChildScrollView` depending on the exact layout constraint violations identified during the refactor. Use the existing `CustomMQ` media query helper for responsive sizing.
- **Rationale**: Standard Flutter layout tools ensure safety across multiple screen sizes without requiring a massive third-party UI framework.
