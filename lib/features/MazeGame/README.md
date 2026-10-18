# Maze Game - لعبة المتاهة 🧩

A classic maze game where players draw a path from start to finish without touching the walls.

## Overview

Players must navigate through a maze by drawing a continuous line from the start point to the finish point. The game features three difficulty levels with different challenges and requirements.

## Features

### 🎯 Three Difficulty Levels

#### 🟢 Easy (سهل)
- **Grid Size**: 5×5
- **Challenge**: Clear and short path
- **Stars Required**: None
- **Time Limit**: None
- **Perfect for**: Young children and beginners

#### 🟡 Medium (متوسط)
- **Grid Size**: 10×10
- **Challenge**: Branching paths
- **Stars Required**: 3 stars must be collected
- **Time Limit**: None
- **Perfect for**: Kids ready for more challenge

#### 🔴 Hard (صعب)
- **Grid Size**: 20×20
- **Challenge**: Complex maze with dead ends
- **Stars Required**: 5 stars must be collected
- **Time Limit**: 2 minutes (120 seconds)
- **Perfect for**: Advanced players

### 🎮 Gameplay Features

- **Touch Controls**: Draw your path by dragging your finger
- **Wall Detection**: Game ends if you touch a wall
- **Star Collection**: Collect required stars before reaching the finish
- **Real-time Timer**: Countdown timer for hard difficulty
- **Visual Feedback**: Clear path visualization
- **Bilingual**: Arabic and English labels

### 🌟 Game Elements

- **Start Point** (ابدأ): Green circle marking the beginning
- **Finish Point** (نهاية): Red circle marking the end
- **Stars** (⭐): Yellow stars to collect along the way
- **Walls**: Black lines creating the maze structure
- **Path**: Blue line showing your drawn route

## How to Play

### Arabic Instructions (التعليمات بالعربية)

1. **ابدأ من نقطة البداية**: المس النقطة الخضراء وابدأ الرسم
2. **تحرك خلال الممرات**: ارسم طريقك دون لمس الجدران
3. **اجمع النجوم**: مرر على النجوم المطلوبة (في المستويات المتوسطة والصعبة)
4. **اصل للنهاية**: اكمل الطريق إلى النقطة الحمراء
5. **احذر الجدران**: إذا لمست جدار، ستخسر اللعبة!

### English Instructions

1. **Start at the Start Point**: Touch the green circle to begin
2. **Navigate the Corridors**: Draw your path without touching walls
3. **Collect Stars**: Pass through required stars (medium & hard)
4. **Reach the Finish**: Complete your path to the red circle
5. **Avoid Walls**: Touching a wall ends the game!

## Technical Architecture

### Data Models (`data/models/`)
- **maze_models.dart**:
  - `MazePosition`: Grid coordinates
  - `MazeCell`: Cell with walls and properties
  - `MazeDifficulty`: Difficulty enum
  - `MazeGameStatus`: Game state enum

- **maze_state.dart**:
  - Complete game state
  - Path tracking
  - Star collection
  - Timer management

### Logic (`data/logic/`)
- **maze_generator.dart**: 
  - Recursive backtracking algorithm
  - Maze generation for all difficulty levels
  - Star placement
  - Dead-end creation for complexity

- **maze_cubit.dart**:
  - Game state management
  - Path validation
  - Wall collision detection
  - Star collection tracking
  - Timer management
  - Win/lose conditions

### UI (`UI/`)
- **maze_game_screen.dart**: Main game screen
- **widgets/maze_painter.dart**: Custom painting for maze visualization
- **widgets/interactive_maze.dart**: Touch/gesture handling

## Algorithm: Maze Generation

The maze is generated using the **Recursive Backtracking** algorithm:

1. Start with a grid where all cells have walls
2. Pick a random starting cell and mark it visited
3. Randomly visit an unvisited neighbor
4. Remove the wall between current cell and chosen neighbor
5. Recursively continue from the new cell
6. Backtrack when no unvisited neighbors exist
7. Continue until all cells are visited

This creates a perfect maze (single solution path).

### Additional Features by Difficulty:
- **Medium**: Strategic star placement across the maze
- **Hard**: Additional dead-ends and complexity added after generation

## Win Conditions

Player wins when:
1. ✅ Path starts from start position
2. ✅ Path reaches end position
3. ✅ All required stars are collected
4. ✅ No walls were touched
5. ✅ Time limit not exceeded (hard difficulty)

## Lose Conditions

Player loses when:
- ❌ Touched a wall while drawing
- ❌ Time runs out (hard difficulty)

## Integration

### Level Map System
- Integrated as Stage 6, 12, and 18 in the level progression
- Purple color coding in level map
- Replaces Crossword game in level sequence
- Maps to 3 difficulty levels based on stage

### Fun Games Section  
- Crossword game has been moved to Fun Games
- Now accessible alongside other fun games

## Visual Design

- **Clean Interface**: Clear visual distinction between elements
- **Color Coding**:
  - Green: Start point
  - Red: Finish point
  - Yellow: Stars
  - Black: Walls
  - Blue: Player's path
- **Bilingual**: Arabic and English labels throughout
- **Responsive**: Adapts to different screen sizes

## Future Enhancements (Potential)

- Multiple maze themes (forest, castle, space)
- Power-ups (wall pass, time freeze)
- Hint system showing partial solution
- Ghost mode to see previous attempts
- Multiplayer racing
- Daily challenge mazes
- Achievement system
- Maze editor for custom mazes

## Educational Value

- **Spatial Reasoning**: Understanding 2D navigation
- **Problem Solving**: Finding paths and solutions
- **Planning**: Thinking ahead to avoid dead ends
- **Fine Motor Skills**: Precise touch control
- **Patience**: Careful, methodical approach
- **Pattern Recognition**: Understanding maze structures

