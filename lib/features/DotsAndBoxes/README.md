# Dots and Boxes Game 🎮

A classic strategy game implementation for the KidZoo app with enhanced gameplay features.

## Overview

Dots and Boxes is a paper-and-pencil game where players take turns drawing lines between adjacent dots on a grid. When a player completes the fourth side of a box, they claim it and earn another turn. The game ends when all boxes are claimed, and the player with the most boxes wins.

## ✨ Enhanced Features

### 🎯 Game Modes
- **VS AI**: Challenge the computer with intelligent strategy
  - Interactive mode selection dialog on game start
  - AI adapts based on difficulty level
- **VS Player**: Play against another human player
  - Local multiplayer on the same device

### 🤖 AI Difficulty Levels
- **Easy AI**: Makes mostly random moves with 40% chance to complete boxes
- **Medium AI**: Uses basic strategy to complete boxes and avoid giving opponent opportunities
- **Hard AI**: Plays optimally with advanced strategic evaluation
  - Chain completion for maximum boxes
  - Multi-level move evaluation
  - Strategic center-preference in early game

### 📊 Grid Sizes (Difficulty)
- **Easy**: 3×3 grid (9 boxes)
- **Medium**: 4×4 grid (16 boxes)
- **Hard**: 5×5 grid (25 boxes)

### 🎨 Visual Enhancements
- **Animated Box Completion**: Elastic scale animation when boxes are claimed
- **Hover Preview**: See which line you're about to draw
- **Color Coding**:
  - Player 1: Blue (circle indicator)
  - Player 2: Pink (square indicator)
- **Smooth Transitions**: All game state changes are animated

### 🔥 Combo System
- **Combo Tracking**: Build streaks by claiming multiple boxes in succession
- **Combo Indicator**: Animated fire indicator shows current combo
- **Max Combo Tracking**: Keep track of your best combo in the game

### 📈 Game Statistics
- **Move Counter**: Track total moves made
- **Best Combo**: Display maximum combo achieved
- **End Game Stats**: Summary of moves and combos in result dialog

### 🎮 Gameplay Features
- Interactive board with tap/click support
- Real-time score tracking
- Visual turn indicators
- Animated score updates
- Game mode switching mid-game
- AI difficulty adjustment during play
- Responsive design for all screen sizes

## 🎯 Game Strategy

### Winning Tips
1. **Avoid the third side**: Don't draw the 3rd side of a box unless you're ready to give it to your opponent
2. **Chain reactions**: Look for opportunities to complete multiple boxes in a row
3. **Control the board**: Try to create situations where you have the last move
4. **Center strategy**: Early in the game, controlling the center can be advantageous

### AI Behavior
- **Easy**: Random moves with occasional box completion - great for beginners
- **Medium**: Completes available boxes and tries to avoid giving you opportunities
- **Hard**: Advanced strategy including chain management and positional evaluation - challenging even for experienced players!

## 📁 Architecture

### Data Models (`data/models/`)
- `dots_and_boxes_models.dart`: Core game models
  - `DotPosition`: Represents a point on the grid
  - `Line`: Represents a connection between dots
  - `Box`: Represents a claimable square
  - `Player`: Player enum with color coding
  - `GameDifficulty`: Grid size options
  - `GameMode`: VS AI or VS Player
  - `AIDifficulty`: AI intelligence levels
  
- `game_state_model.dart`: Complete game state
  - Lines drawn
  - Boxes claimed
  - Scores
  - Combo tracking
  - Move counting

### Logic (`data/logic/`)
- `dots_and_boxes_cubit.dart`: Game state management using BLoC pattern
  - Move validation
  - Box completion detection
  - Turn switching logic
  - AI decision making
  - Combo calculation

### UI (`UI/`)
- `dots_and_boxes_screen.dart`: Main game screen
  - Mode selection dialog
  - AI difficulty selection
  - Game controls
  - Statistics display
  
- `widgets/game_board_painter.dart`: Custom painter for rendering
  - Dots rendering
  - Lines with color coding
  - Animated box completion
  - Hover preview
  
- `widgets/interactive_game_board.dart`: Touch/mouse handling
  - Gesture detection
  - Line selection
  - Animation control
  
- `widgets/score_board.dart`: Real-time score display
  - Animated score updates
  - Current turn indicator
  
- `widgets/game_result_dialog.dart`: End game screen
  - Winner display
  - Final scores
  - Game statistics
  - Replay/exit options

## 🎮 How to Play

1. **Choose Mode**: Select VS AI or VS Player when starting the game
2. **Select AI Difficulty** (if playing vs AI): Choose Easy, Medium, or Hard
3. **Draw Lines**: Tap between adjacent dots to draw a line
4. **Complete Boxes**: Draw the 4th side of a box to claim it
5. **Bonus Turns**: When you claim a box, you get another turn immediately
6. **Build Combos**: Chain multiple box claims to build impressive combos!
7. **Win**: The player with the most boxes when the grid is full wins!

## 🎯 Integration

The game is integrated into the **Fun Games** section and can be accessed from:
- **Home → Fun Games → Dots & Boxes**

## 🚀 Future Enhancements (Potential)

- Online multiplayer
- Different grid shapes (hexagonal, triangular)
- Power-ups and special abilities
- Tournament mode
- Leaderboards
- Replay system
- Hints for beginners
- Achievement system

## 💡 Technical Highlights

- **Clean Architecture**: Separation of UI, logic, and models
- **BLoC Pattern**: Predictable state management
- **Custom Painting**: High-performance rendering
- **Responsive Design**: Adapts to all screen sizes
- **Smooth Animations**: 60 FPS gameplay
- **Smart AI**: Multiple difficulty levels with distinct strategies
- **Combo System**: Engaging reward mechanism

## 🎨 Design Philosophy

The game follows KidZoo's design principles:
- **Kid-Friendly**: Bright colors and clear visual feedback
- **Intuitive**: Easy to learn, hard to master
- **Engaging**: Combos and animations keep players motivated
- **Accessible**: Works great on phones and tablets
- **Educational**: Teaches strategic thinking and planning ahead
