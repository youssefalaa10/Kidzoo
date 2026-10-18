# Research: Kid Profile

## Context

The Kid Profile feature requires a responsive, playfully animated UI built natively with Flutter, backed by a persistent layer.

## Findings

### Animation Approaches
- **Decision**: Use implicit animations (`AnimatedContainer`, `AnimatedSwitcher`, `AnimatedOpacity`, and `TweenAnimationBuilder`) for the majority of the UI (progress bars, badge unlocking, avatar changes). Use `Transform.scale` or simple `AnimationController` for looping idle animations (e.g. bouncing avatar).
- **Rationale**: Implicit animations are highly performant and require minimal boilerplate, keeping the UI declarative and clean, perfectly fitting the goal of a 60 FPS fluid interface.
- **Alternatives considered**: Explicit `AnimationController` for everything (too much boilerplate), external animation packages like Rive/Lottie (overkill for simple bounces and fades).

### Persistence & Data Structure
- **Decision**: Integrate Profile tables into the existing Drift database.
- **Rationale**: Follows the Constitution. Creating a separate Drift instance or using SharedPreferences would fracture the data model and violate rules.
- **Alternatives considered**: SharedPreferences (violates Constitution for primary data storage).

### Responsive Layout
- **Decision**: Use `LayoutBuilder` combined with `SingleChildScrollView` and `Wrap` or constraints (`ConstrainedBox`) to handle tablet and landscape orientations. Use `fluid_container` if it exists.
- **Rationale**: Ensures no RenderFlex overflows across drastically different form factors without needing completely separate screens.

### State Management
- **Decision**: Use `ProfileCubit` emitting `ProfileState`. 
- **Rationale**: Fits perfectly with the app architecture. Cubit can fetch from Drift via `ProfileRepository` and emit updated data to the UI.
