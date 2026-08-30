# Phase 0: Research & Architecture Decisions

## Unified Quiz Engine Architecture
- **Decision**: Create a single `QuizCubit` and `QuizEngineScreen` that dynamically loads data (Questions and Options) from a provided data source.
- **Rationale**: Removes code duplication across Vehicles, Fruits, and Vegetables games.
- **Alternatives considered**: Separate cubits and screens for each game. Rejected because they share the exact same UI and state machine (Question -> Answer -> Feedback -> Score).

## Profile Onboarding Flow
- **Decision**: Introduce a `ProfileSetupScreen` as the initial destination after the `SplashScreen` if no profiles exist in the Drift database.
- **Rationale**: Ensures the system always has an active profile to attach `GameScores` to.
- **Alternatives considered**: Anonymous playing. Rejected because tracking scores is a core requirement of Phase 8.

## Audio & TTS Integration
- **Decision**: Inject `FlutterTts` and `AudioPlayer` instances into the `QuizCubit` (or provide them via a Service Locator like `RepositoryProvider`).
- **Rationale**: Adheres to Constitution Principle V (Injected Services, no static singletons).
