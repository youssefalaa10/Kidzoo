# Data Models: Project-Wide Adaptive Architecture

## Core Classes

This feature does not introduce new persistent database entities. Instead, it introduces shared UI configuration and layout wrappers.

### BackgroundResolver

A service class responsible for determining the correct background asset path.

```dart
class BackgroundResolver {
  final BuildContext context;

  const BackgroundResolver(this.context);

  /// Returns the appropriate background image path based on screen dimensions and orientation.
  String resolveBackground() {
    // Mobile: width < 600
    // Tablet: width >= 600 && width < 900
    // Desktop: width >= 900
  }
}
```

### Shared Fluid Components

1. `FluidContainer`: 
   A wrapper widget utilizing `ConstrainedBox` to set a `maxWidth` (e.g., 600 or 800) for regular screens. It ensures the visual hierarchy remains intact and prevents extreme stretching on desktop monitors.

2. `PhysicsGameCanvas`:
   A wrapper widget utilizing `AspectRatio` and `Center`. It encapsulates games like Flappy Bird or Maze Game, locking their physical dimensions to a predictable ratio while leaving the exterior space to be filled by the `BackgroundResolver`.
