# 2048 Game - KidZoo

A complete, beautiful implementation of the classic 2048 puzzle game for the KidZoo educational app.

## 📋 Features Implemented

### Core Game Mechanics
- ✅ Classic 4×4 game board (expandable to 3×3, 5×5)
- ✅ Swipe gestures (up, down, left, right)
- ✅ Arrow key controls for desktop/keyboard support
- ✅ Tile merging logic (2+2=4, 4+4=8, etc.)
- ✅ Random tile generation (2 or 4) after each move
- ✅ Win detection (2048 tile reached)
- ✅ Loss detection (no valid moves available)
- ✅ Continue playing after winning

### User Interface
- ✅ Beautiful, pixel-perfect UI with smooth animations
- ✅ Gradient color scheme for different tile values
- ✅ Smooth tile movement animations
- ✅ Scale animations for new and merged tiles
- ✅ Score display (current and best)
- ✅ Confetti effect on winning
- ✅ Clean, modern design with no local images (icons only)

### Home Screen
- ✅ Best score display with gradient card
- ✅ New Game button
- ✅ Continue button (only shown if saved game exists)
- ✅ Statistics dashboard:
  - Games Played
  - Max Tile Achieved
  - Total Play Time
  - Win Count
- ✅ Game History viewer with detailed match stats

### Game Features
- ✅ **Undo functionality** - Revert up to 5 moves (toggleable)
- ✅ **Auto-save** - Game state persists between sessions
- ✅ **Best score tracking** - Automatically saved locally
- ✅ **Match history** - Stores last 50 games with stats
- ✅ **Win/Loss dialogs** - Beautiful result screens with options

### Data Persistence
- ✅ SharedPreferences for local storage
- ✅ Saves: best score, games played, max tile, total time, win count
- ✅ Saves current game state for continuation
- ✅ Saves game settings (board size, sound, haptic, undo)
- ✅ Saves complete game history

### Animations & Polish
- ✅ Elastic scale animation for new tiles
- ✅ Smooth position transitions for moving tiles
- ✅ Pulse effect for merged tiles
- ✅ Confetti celebration for winning
- ✅ Dialog entrance animations
- ✅ Responsive touch feedback

## 🎮 How to Play

1. **Navigate to Fun Games** section from home
2. **Tap on "2048 Game"** card
3. From home screen:
   - Tap **"New Game"** to start fresh
   - Tap **"Continue"** to resume saved game
4. **Swipe** in any direction to move tiles
5. **Merge** tiles with same numbers
6. **Reach 2048** to win!

## 🏗️ Architecture

### Directory Structure
```
Game2048/
├── data/
│   ├── models/
│   │   ├── tile_model.dart         # Tile entity
│   │   ├── board_model.dart        # Board & Position models
│   │   ├── game_state_model.dart   # Game state & status enum
│   │   └── game_settings.dart      # Settings model
│   └── logic/
│       ├── game_logic.dart         # Core game mechanics
│       ├── game_storage.dart       # Persistence layer
│       └── game_cubit.dart         # State management
└── UI/
    ├── game_2048_home.dart         # Home screen with stats
    ├── game_2048_screen.dart       # Main game screen
    └── widgets/
        ├── game_board.dart         # Game board widget
        ├── tile_widget.dart        # Static tile rendering
        ├── animated_tile.dart      # Animated tile wrapper
        └── game_dialog.dart        # Win/Loss dialogs

```

### State Management
- **BLoC/Cubit pattern** using `flutter_bloc`
- **Equatable** for efficient state comparison
- **Stream-based** reactive UI updates

### Key Components

#### GameLogic
- Pure game mechanics (movement, merging, win/loss detection)
- Board transformations (rotation, transpose, flip)
- Move validation and scoring

#### GameCubit
- Manages game state lifecycle
- Handles user actions (move, undo, new game)
- Integrates with storage layer
- Tracks play time and statistics

#### GameStorage
- SharedPreferences integration
- JSON serialization for complex data
- Async operations for persistence
- History management (last 50 games)

## 🎨 UI/UX Details

### Color Palette
- Background: `#FAF8EF` (cream)
- Board: `#BBADA0` (brown-gray)
- Empty cells: `#CDC1B4` with transparency
- Tiles: Gradient from light (2) to dark (2048+)

### Tile Colors
- 2: `#EEE4DA`
- 4: `#EDE0C8`
- 8: `#F2B179`
- 16: `#F59563`
- 32: `#F67C5F`
- 64: `#F65E3B`
- 128-512: Yellow gradient
- 1024+: Gold
- 4096+: Dark `#3C3A32`

### Animations
- **Tile Movement**: 200ms ease-out
- **Tile Scale (new)**: 200ms elastic-out from 0 to 1
- **Tile Merge**: Pulse effect (1.0 to 1.1 scale)
- **Dialog**: 400ms elastic-out entrance
- **Confetti**: 3 seconds on win

## 📊 Statistics Tracked

1. **Best Score** - Highest score ever achieved
2. **Games Played** - Total number of games started
3. **Max Tile** - Highest tile value reached
4. **Total Play Time** - Cumulative play time across all sessions
5. **Win Count** - Number of games won (reached 2048)

## 🔧 Settings (Expandable)

The architecture supports these settings (can be added to UI):
- Board size selection (3×3, 4×4, 5×5)
- Sound effects toggle
- Haptic feedback toggle
- Undo feature toggle
- Target tile (for custom difficulty)

## 🎯 Future Enhancements

Potential additions:
- [ ] Sound effects for moves and merges
- [ ] Haptic feedback on iOS/Android
- [ ] Themes/color palettes
- [ ] Leaderboards
- [ ] Achievements system
- [ ] Different board sizes selector in UI
- [ ] Daily challenges
- [ ] Multiplayer mode

## 📝 Notes

- **No local images used** - All UI elements use icons and colors
- **Offline-first** - Works completely offline
- **Auto-save** - Never lose progress
- **Performance optimized** - Smooth 60fps animations
- **Responsive** - Works on all screen sizes
- **Accessible** - Keyboard support for desktop

## 🚀 Integration

The game is integrated into KidZoo's Fun Games section and appears as a card alongside:
- Tic Tac Toe
- Flappy Bird
- Missing Letter Game

Access via: Home → Fun Games → 2048 Game

