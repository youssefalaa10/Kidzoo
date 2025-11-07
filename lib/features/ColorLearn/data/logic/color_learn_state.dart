import '../model/color_model.dart';

class ColorLearnState {
  ColorLearnState({
    required this.level,
    required this.availableColors,
    required this.remainingColors,
    required this.matchedColors,
    required this.languageCode,
    required this.score,
    required this.isGameComplete,
    this.lastMatchedColor,
    this.showWrongFeedback = false,
  });

  factory ColorLearnState.initial() {
    return ColorLearnState(
      level: 1,
      availableColors: [],
      remainingColors: [],
      matchedColors: [],
      languageCode: 'en',
      score: 0,
      isGameComplete: false,
    );
  }
  final int level;
  final List<ColorModel> availableColors;
  final List<ColorModel> remainingColors;
  final List<ColorModel> matchedColors;
  final String languageCode;
  final int score;
  final bool isGameComplete;
  final ColorModel? lastMatchedColor;
  final bool showWrongFeedback;

  ColorLearnState copyWith({
    int? level,
    List<ColorModel>? availableColors,
    List<ColorModel>? remainingColors,
    List<ColorModel>? matchedColors,
    String? languageCode,
    int? score,
    bool? isGameComplete,
    ColorModel? lastMatchedColor,
    bool? showWrongFeedback,
  }) {
    return ColorLearnState(
      level: level ?? this.level,
      availableColors: availableColors ?? this.availableColors,
      remainingColors: remainingColors ?? this.remainingColors,
      matchedColors: matchedColors ?? this.matchedColors,
      languageCode: languageCode ?? this.languageCode,
      score: score ?? this.score,
      isGameComplete: isGameComplete ?? this.isGameComplete,
      lastMatchedColor: lastMatchedColor ?? this.lastMatchedColor,
      showWrongFeedback: showWrongFeedback ?? this.showWrongFeedback,
    );
  }
}
