import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens shared by the kid-facing mini games.
///
/// The numbers here follow accessibility guidance for pre-readers (ages 3-8):
/// touch targets close to 2cm, generous spacing so a stray finger does not
/// trigger the neighbouring card, and one accent colour per meaning so a child
/// learns "green = right, red = try again, yellow = hint" once and reuses it in
/// every game.
class KidUi {
  const KidUi._();

  // --- Surfaces -------------------------------------------------------------
  static const Color cream = Color(0xFFFFF7E2);
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF3B3350);
  static const Color inkSoft = Color(0xFF7A7290);

  // --- Semantic accents -----------------------------------------------------
  static const Color correct = Color(0xFF4AC49A);
  static const Color wrong = Color(0xFFEE4964);
  static const Color hint = Color(0xFFFFC53D);
  static const Color primary = Color(0xFF7C4DFF);
  static const Color fruit = Color(0xFFFF8A3D);
  static const Color vegetable = Color(0xFF5FBF5A);

  static const List<Color> confettiColors = [
    Color(0xFFFFC53D),
    Color(0xFF4AC49A),
    Color(0xFF7C4DFF),
    Color(0xFFEE4964),
    Color(0xFF4FC3F7),
  ];

  // --- Geometry -------------------------------------------------------------
  static const double radiusCard = 28;
  static const double radiusPill = 999;

  /// Minimum interactive edge for chrome: back buttons, pips, replay.
  ///
  /// Comfortably above the 48dp adult minimum, but the comment this replaced
  /// claimed it was the ~2cm young-child target and it is not — 76dp is about
  /// 1.2cm on a typical phone. Use [minTouchYoung] for anything a child aims at
  /// to answer.
  static const double minTouch = 76;

  /// Minimum edge for a **primary** target inside an activity board.
  ///
  /// NN/g's guidance for young children is 2cm x 2cm, roughly 96-120dp: about
  /// four times the adult minimum. Children aged 7-10 miss 7mm targets around
  /// 30% of the time, and a miss recorded as a wrong answer is a measurement
  /// error, not a learning signal. Engine boards size their cards from this.
  static const double minTouchYoung = 112;

  // --- Motion ---------------------------------------------------------------
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration celebrate = Duration(milliseconds: 700);

  static List<BoxShadow> shadow(Color tint, {double strength = 1}) {
    return [
      BoxShadow(
        color: tint.withValues(alpha: 0.22 * strength),
        blurRadius: 18 * strength,
        offset: Offset(0, 8 * strength),
      ),
    ];
  }

  /// Text with a soft outline so it stays readable on busy game backgrounds.
  static List<Shadow> get textHalo => const [
        Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
      ];
}

/// Feedback a child can feel. Every meaningful action gets a distinct pattern,
/// which is one of the strongest signals for users who cannot read yet.
class KidHaptics {
  const KidHaptics._();

  static void tap() => HapticFeedback.selectionClick();

  static void success() => HapticFeedback.mediumImpact();

  static void error() => HapticFeedback.heavyImpact();
}

/// Turns the space a game actually got into type sizes and card sizes.
///
/// Games are played on everything from a 5" phone in portrait to a tablet in
/// landscape, so nothing in the kid games hard-codes pixels: they ask
/// [KidMetrics] instead and stay inside the box they were given.
class KidMetrics {
  KidMetrics._(this.width, this.height, this.scale);

  factory KidMetrics.of(BoxConstraints constraints) {
    final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
    final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 640.0;
    // Reference frame is a 390x780 phone; clamp so tablets do not balloon and
    // small phones stay legible.
    final raw = (w / 390 + h / 780) / 2;
    return KidMetrics._(w, h, raw.clamp(0.72, 1.35));
  }

  final double width;
  final double height;
  final double scale;

  bool get isLandscape => width > height;
  bool get isTablet => width >= 600;

  /// Scaled size with a floor and ceiling so text never becomes unreadable.
  double size(double base, {double? min, double? max}) =>
      (base * scale).clamp(min ?? base * 0.7, max ?? base * 1.35);

  double get gap => size(16, min: 8, max: 24);
  double get pagePadding => size(20, min: 12, max: 36);
}

/// Largest square card size that fits [count] cards inside [box].
///
/// Tries every column count and keeps the roomiest arrangement, which is why
/// the trays no longer overflow when a round adds a fifth choice on a small
/// phone: the cards shrink instead of the row clipping.
double kidFitCardSize({
  required int count,
  required Size box,
  required double spacing,
  double minSize = 52,
  double maxSize = 150,
}) {
  if (count <= 0) return minSize;
  var best = minSize;
  for (var columns = count; columns >= 1; columns--) {
    final rows = (count / columns).ceil();
    final w = (box.width - spacing * (columns - 1)) / columns;
    final h = (box.height - spacing * (rows - 1)) / rows;
    final candidate = w < h ? w : h;
    if (candidate > best) best = candidate;
  }
  return best.clamp(minSize, maxSize);
}
