<!-- Sync Impact Report
Version Change: 0.0.0 -> 1.0.0
Modified Principles: Initialized from project rules
Added Sections: Core Principles, Governance
Removed Sections: Template Placeholders
Templates requiring updates: ✅ None
Follow-up TODOs: None
-->
# Kidzoo Constitution

## Core Principles

### I. Zero Static State
No `static` variables, global state, or singleton game states are permitted anywhere in the codebase. All game state and application state must be instance-owned.

### II. State Management via BLoC / Cubit
All state management must strictly use the BLoC or Cubit patterns (`flutter_bloc`). Local ephemeral state within a widget is permissible via `StatefulWidget`, but business logic and shared state must reside in a BLoC/Cubit.

### III. Class-Based Widgets Only
All UI components must be implemented as class widgets (e.g., extending `StatelessWidget` or `StatefulWidget`). Functional widgets (functions that return a `Widget`) are strictly prohibited, even within the same file or class.

### IV. Drift as Persistence Layer
Drift is the sole permissible local persistence layer. Other local databases or shared preferences mechanisms should be avoided in favor of Drift for consistency and safety.

### V. Injected Services
External hardware and OS services (such as TTS, audio players, etc.) must be implemented as injected services. They must not be instantiated as static singletons.

### VI. Descriptive Naming
Naming for classes, variables, and methods must be highly descriptive and meaningful. The name must accurately represent the purpose of the entity, regardless of the resulting length.

## Governance

This Constitution supersedes all other practices within the Kidzoo project. 
- All Pull Requests and code additions must be reviewed against these core principles.
- Amendments to these architectural rules require explicit project consensus and a corresponding update to this document.
- The versioning of this document will follow semantic versioning based on the scale of changes.

**Version**: 1.0.0 | **Ratified**: 2026-06-23 | **Last Amended**: 2026-06-23
