import 'package:flutter/material.dart';

/// Game modes available
enum ColorMemoryGameMode {
  classic, // Sequence increases step by step
  timed, // Each tap must be within time limit
  endless, // Continue until error
}

/// Color palettes for the game
class ColorPalette {
  const ColorPalette({
    required this.name,
    required this.colors,
    required this.highlightColors,
    required this.names,
  });

  final String name;
  final List<Color> colors;
  final List<Color> highlightColors;
  final List<String> names;
}

/// Predefined color palettes
class ColorPalettes {
  static const classic = ColorPalette(
    name: 'Classic',
    colors: [
      Color(0xFF4CAF50), // Green
      Color(0xFFF44336), // Red
      Color(0xFF2196F3), // Blue
      Color(0xFFFFEB3B), // Yellow
      Color(0xFFFF9800), // Orange
      Color(0xFF9C27B0), // Purple
      Color(0xFF00BCD4), // Cyan
      Color(0xFFE91E63), // Pink
    ],
    highlightColors: [
      Color(0xFF81C784), // Light Green
      Color(0xFFEF5350), // Light Red
      Color(0xFF64B5F6), // Light Blue
      Color(0xFFFFF176), // Light Yellow
      Color(0xFFFFB74D), // Light Orange
      Color(0xFFBA68C8), // Light Purple
      Color(0xFF4DD0E1), // Light Cyan
      Color(0xFFF06292), // Light Pink
    ],
    names: [
      'Green',
      'Red',
      'Blue',
      'Yellow',
      'Orange',
      'Purple',
      'Cyan',
      'Pink',
    ],
  );

  static const pastel = ColorPalette(
    name: 'Pastel',
    colors: [
      Color(0xFFB2DFDB), // Pastel Teal
      Color(0xFFFFCCBC), // Pastel Orange
      Color(0xFFC5CAE9), // Pastel Indigo
      Color(0xFFF8BBD0), // Pastel Pink
      Color(0xFFDCEDC8), // Pastel Green
      Color(0xFFFFE0B2), // Pastel Amber
      Color(0xFFD1C4E9), // Pastel Purple
      Color(0xFFFFCDD2), // Pastel Red
    ],
    highlightColors: [
      Color(0xFF80CBC4),
      Color(0xFFFF8A65),
      Color(0xFF9FA8DA),
      Color(0xFFF48FB1),
      Color(0xFFAED581),
      Color(0xFFFFB74D),
      Color(0xFFB39DDB),
      Color(0xFFE57373),
    ],
    names: [
      'Teal',
      'Orange',
      'Indigo',
      'Pink',
      'Green',
      'Amber',
      'Purple',
      'Red',
    ],
  );

  static const vibrant = ColorPalette(
    name: 'Vibrant',
    colors: [
      Color(0xFFE91E63), // Pink
      Color(0xFF9C27B0), // Purple
      Color(0xFF3F51B5), // Indigo
      Color(0xFF00BCD4), // Cyan
      Color(0xFF4CAF50), // Green
      Color(0xFFFFEB3B), // Yellow
      Color(0xFFFF9800), // Orange
      Color(0xFFFF5722), // Deep Orange
    ],
    highlightColors: [
      Color(0xFFF06292),
      Color(0xFFBA68C8),
      Color(0xFF7986CB),
      Color(0xFF4DD0E1),
      Color(0xFF81C784),
      Color(0xFFFFF176),
      Color(0xFFFFB74D),
      Color(0xFFFF8A65),
    ],
    names: [
      'Pink',
      'Purple',
      'Indigo',
      'Cyan',
      'Green',
      'Yellow',
      'Orange',
      'Red',
    ],
  );

  static List<ColorPalette> get all => [classic, pastel, vibrant];
}

/// Game configuration based on level
class LevelConfig {
  const LevelConfig({
    required this.gridSize,
    required this.colorCount,
    required this.initialSequenceLength,
    required this.timePerStep,
    required this.maxRounds,
  });

  final int gridSize; // 2x2, 3x3, 4x4, 5x5
  final int colorCount; // Number of colors to use
  final int initialSequenceLength; // Starting sequence length
  final double timePerStep; // Time limit per step in timed mode (seconds)
  final int maxRounds; // Number of rounds to complete the level

  static LevelConfig forLevel(int level) {
    switch (level) {
      case 1:
        return const LevelConfig(
          gridSize: 2,
          colorCount: 4,
          initialSequenceLength: 3,
          timePerStep: 3.0,
          maxRounds: 2,
        );
      case 2:
        return const LevelConfig(
          gridSize: 3,
          colorCount: 6,
          initialSequenceLength: 4,
          timePerStep: 2.5,
          maxRounds: 3,
        );
      case 3:
        return const LevelConfig(
          gridSize: 4,
          colorCount: 8,
          initialSequenceLength: 5,
          timePerStep: 2.0,
          maxRounds: 4,
        );
      default: // Level 4+
        return const LevelConfig(
          gridSize: 5,
          colorCount: 8,
          initialSequenceLength: 6,
          timePerStep: 1.5,
          maxRounds: 5,
        );
    }
  }
}

/// Game constants
class ColorMemoryConstants {
  static const double sequenceDisplayInterval =
      0.6; // Seconds between color shows
  static const double colorHighlightDuration =
      0.4; // Duration of color highlight
  static const double pauseBetweenRounds = 1.0; // Pause before new sequence
  static const int maxSequenceLength = 50; // Maximum sequence length

  // Animation durations
  static const Duration tapAnimationDuration = Duration(milliseconds: 200);
  static const Duration wrongAnswerShakeDuration = Duration(milliseconds: 500);
  static const Duration successCelebrationDuration =
      Duration(milliseconds: 1000);

  // Sound and haptics
  static const bool defaultSoundEnabled = true;
  static const bool defaultHapticsEnabled = true;
  static const bool defaultColorBlindMode = false;

  // UI
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color cardBackgroundColor = Colors.white;
  static const double borderRadius = 16.0;
  static const double gridPadding = 16.0;
  static const double gridSpacing = 12.0;

  // Scoring
  static const int pointsPerCorrectStep = 10;
  static const int bonusForPerfectRound = 50;
}
