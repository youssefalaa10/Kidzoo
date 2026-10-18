# Project-Wide Adaptive Refactor Checklist

This document tracks the progress of refactoring the entire Kidzoo application to an Adaptive Layout Architecture. 

## Core Infrastructure
- [x] Implement `BackgroundResolver` service

## Core Screens
- [x] SplashScreen (`lib/features/Splash/`)
- [ ] ProfileSetupScreen (`lib/features/Profile/`)
- [ ] CharacterSelectionScreen (`lib/features/home/UI/character.dart`)
- [ ] HomeScreen (`lib/features/home/`)
- [ ] SettingsScreen (`lib/features/settings/`)
- [ ] AppCategoryScreen (`lib/features/AppCategory/`)
- [ ] LevelMapScreen (`lib/features/LevelsMap/`)

## Educational Games
- [ ] Alphabets (`lib/features/Alphabets/`)
- [ ] AnimalNameGame (`lib/features/AnimalNameGame/`)
- [ ] AnimalQuiz (`lib/features/AnimalQuiz/`)
- [ ] Numbers (`lib/features/Numbers/`)
- [ ] Shapes (`lib/features/Shapes/`)
- [ ] QuizEngine (Unified Quiz) (`lib/features/QuizEngine/`)

## Challenging Games
- [ ] ColorMemoryGame (`lib/features/ColorMemoryGame/`)
- [ ] ColorSwitchGame (`lib/features/ColorSwitchGame/`)
- [ ] DotsAndBoxes (`lib/features/DotsAndBoxes/`)
- [ ] DrawLab (`lib/features/DrawLab/`)
- [ ] FlagGame (`lib/features/FlagGame/`)
- [ ] FlappyBird (`lib/features/FlappyBird/`)
- [ ] Game2048 (`lib/features/Game2048/`)
- [ ] MathGame (`lib/features/MathGame/`)
- [ ] MazeGame (`lib/features/MazeGame/`)
- [ ] MemoryGame (`lib/features/MemoryGame/`)
- [ ] MissingLetterGame (`lib/features/MissingLetterGame/`)
- [ ] PaddleBounce (`lib/features/PaddleBounce/`)
- [ ] Puzzle (`lib/features/Puzzle/`)
- [ ] Tic-Tac-Toe (`lib/features/Tic-Tac-Toe/`)
- [ ] WorldMapGame (`lib/features/WorldMapGame/`)

## Rules
- Mobile ≠ Tablet ≠ Desktop
- No static responsive state
- Use `LayoutBuilder` and `MediaQuery`
- Derive everything from `BuildContext`
- Ensure dedicated `MobileLayout`, `TabletLayout`, `DesktopLayout`
- Dynamic backgrounds per device category
