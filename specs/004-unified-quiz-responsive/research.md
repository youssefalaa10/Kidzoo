# Research & Decisions: Project-Wide Adaptive Architecture

## Resolving Adaptive Layout Strategy
**Decision**: Adopt **Fluid Responsive Design** across all screens. Use a shared `FluidContainer` wrapper widget that leverages `ConstrainedBox` to set a `maxWidth` on core UI elements, while expanding padding and adjusting spacing based on available `MediaQuery` width.
**Rationale**: Rebuilding completely separate structural layouts (e.g., `DesktopLayout` vs `MobileLayout`) for 25+ screens is heavily prone to technical debt and visual inconsistency. A fluid approach guarantees the widget hierarchy remains identical while effectively utilizing whitespace on tablets and desktops.
**Alternatives considered**: Separate structural layouts (rejected by user as it violates visual hierarchy consistency).

## Physics-Based Games Adaptation
**Decision**: Create a `PhysicsGameCanvas` widget that enforces an `AspectRatio` box. The game logic stays inside this box, which is centered on the screen. The remaining exterior space is filled with decorative backgrounds loaded from the `BackgroundResolver`.
**Rationale**: Physics values (like jumping velocity or collision boundaries) are extremely fragile and tied to exact logical pixel dimensions. Dynamically altering physics based on screen width fundamentally changes gameplay difficulty. Centering a fixed aspect ratio canvas preserves 100% of the game logic.
**Alternatives considered**: Dynamically altering physics engine properties (rejected, modifies gameplay difficulty). Showing black bars (explicitly rejected by user).

## BackgroundResolver Implementation
**Decision**: The `BackgroundResolver` class initialized with `BuildContext`. It uses `MediaQuery.of(context).size.width` to classify the device and return the corresponding asset path.
**Rationale**: Keeps UI code clean while avoiding static helper functions. strictly follows the "Zero Static State" architecture.
