# Level Progression System

## Overview

The level progression system implements a structured game flow where players progress through different game types in a specific order, with increasing difficulty levels.

## Level Structure

### Stage Progression

The system follows this progression pattern:

**Level 1 Cycle (Stages 1-4):**

- Stage 1: Animal Quiz (Level 1)
- Stage 2: Memory Game (Level 1)
- Stage 3: Puzzle (Level 1)
- Stage 4: Math Game (Level 1)

**Level 2 Cycle (Stages 5-8):**

- Stage 5: Animal Quiz (Level 2)
- Stage 6: Memory Game (Level 2)
- Stage 7: Puzzle (Level 2)
- Stage 8: Math Game (Level 2)

**Level 3 Cycle (Stages 9-12):**

- Stage 9: Animal Quiz (Level 3)
- Stage 10: Memory Game (Level 3)
- Stage 11: Puzzle (Level 3)
- Stage 12: Math Game (Level 3)

## Key Components

### 1. StageMapping (`map_stage_model.dart`)

- Defines the fixed stage progression
- Maps stage numbers to game types and difficulty levels
- Provides helper methods for level progression

### 2. GameSequence (`game_sequence_model.dart`)

- Creates game instances based on stage numbers
- Handles game type and difficulty level mapping
- Provides utility methods for progression

### 3. LevelCubit (`levelmap_cubit.dart`)

- Manages level state and progression
- Handles level unlocking and completion
- Persists progress using SharedPreferences

### 4. LevelMapScreen (`levelmap_screen.dart`)

- Displays the level map interface
- Handles navigation to games
- Shows completion dialogs and progression

## Game Integration

Each game must return `true` when completed to signal successful completion:

### Animal Quiz

```dart
Navigator.of(context).pop(true); // Return completion status
```

### Memory Game

```dart
Navigator.of(context).pop(true); // Return completion status
```

### Puzzle

```dart
Navigator.of(context).pop(true); // Return completion status
```

### Math Game

```dart
Navigator.of(context).pop(true); // Return completion status
```

## Features

### Automatic Progression

- When a game is completed, the next level is automatically unlocked
- Players can choose to continue to the next level or stay on the map
- Progress is saved automatically

### Level Locking

- Levels are locked until previous levels are completed
- First level (Animal Quiz Level 1) is unlocked by default
- Visual indicators show locked/unlocked status

### Completion Dialogs

- Shows congratulations message when level is completed
- Displays information about the next level
- Allows players to continue or stay on map

### Progress Persistence

- Progress is saved using SharedPreferences
- Highest unlocked level is remembered
- Current level is tracked

## Usage

### Starting a Level

1. Navigate to the Level Map screen
2. Tap on an unlocked level button
3. Confirm the game details in the dialog
4. Play the game
5. Complete the game to unlock the next level

### Level Completion Flow

1. Game detects completion
2. Returns `true` to level map
3. Level map unlocks next level
4. Shows completion dialog
5. Player can continue to next level or stay on map

## Technical Implementation

### Clean Architecture Principles

- **Separation of Concerns**: Each component has a specific responsibility
- **Single Responsibility**: Each class handles one aspect of the system
- **Dependency Inversion**: High-level modules don't depend on low-level modules
- **Open/Closed**: System is open for extension but closed for modification

### State Management

- Uses BLoC pattern for state management
- Cubit for simple state management
- SharedPreferences for persistence

### Navigation

- Uses NavigationService for protected navigation
- Proper back navigation handling
- Completion status propagation

## Future Enhancements

1. **Achievement System**: Add achievements for completing levels
2. **Statistics Tracking**: Track completion times and scores
3. **Custom Difficulty**: Allow players to choose difficulty levels
4. **Replay System**: Allow replaying completed levels
5. **Social Features**: Share progress with friends
