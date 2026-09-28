import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:kidzo/core/badges/badge_definition.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/reward_burst_painter.dart';

/// The moment a badge is earned.
///
/// Modelled on `AdventureRewardOverlay`, deliberately: a child who has watched
/// a story page fly into their book already knows what this kind of animation
/// means, and giving the two rewards different grammar would teach them that
/// badges are a different sort of thing.
///
/// Three phases — arrive, hold, settle — with the middle one long enough to
/// read the name. Tapping anywhere skips it, because the fourth time a child
/// sees this they want to get back to the game.
class BadgeEarnedOverlay extends StatefulWidget {
  const BadgeEarnedOverlay({
    required this.badge,
    required this.title,
    required this.description,
    required this.caption,
    required this.onDone,
    super.key,
  });

  final BadgeDefinition badge;

  /// Already resolved by the host, which has the localizations.
  final String title;
  final String description;

  /// The short line above the medallion. "New badge!"
  final String caption;

  /// Called exactly once, when the celebration is over or skipped.
  final VoidCallback onDone;

  /// Slightly longer than the story reward's 2100ms: there are two lines of
  /// text here rather than one.
  static const Duration duration = Duration(milliseconds: 2400);

  @override
  State<BadgeEarnedOverlay> createState() => _BadgeEarnedOverlayState();
}

class _BadgeEarnedOverlayState extends State<BadgeEarnedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final ConfettiController _confetti;

  // Phase boundaries as fractions of the whole, named so the intervals read as
  // the story they tell rather than as magic numbers.
  static const double _arriveEnd = 0.30;
  static const double _holdEnd = 0.80;

  late final Animation<double> _arrive = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, _arriveEnd, curve: Curves.easeOutBack),
  );
  late final Animation<double> _text = CurvedAnimation(
    parent: _controller,
    curve: const Interval(_arriveEnd, _holdEnd, curve: Curves.easeOut),
  );
  late final Animation<double> _settle = CurvedAnimation(
    parent: _controller,
    curve: const Interval(_holdEnd, 1, curve: Curves.easeInCubic),
  );
  late final Animation<double> _scrim = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, _arriveEnd, curve: Curves.easeOut),
  );

  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 1));
    _controller = AnimationController(
      vsync: this,
      duration: BadgeEarnedOverlay.duration,
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _finish();
        }
      });
    _controller.forward();
    _confetti.play();
    KidHaptics.success();
  }

  /// Guarded, because the status listener and a tap-to-skip both reach here.
  void _finish() {
    if (_hasFinished) {
      return;
    }
    _hasFinished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.badge.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          final double fade = 1 - _settle.value;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(
                      alpha: 0.55 * _scrim.value * fade,
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: fade.clamp(0, 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Opacity(
                      opacity: _text.value,
                      child: Text(
                        widget.caption,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: KidUi.textHalo,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Medallion(
                      accent: accent,
                      icon: widget.badge.icon,
                      scale: _arrive.value,
                      spin: _controller.value * math.pi,
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: _text.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: <Widget>[
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: KidUi.textHalo,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 18,
                  minBlastForce: 6,
                  maxBlastForce: 16,
                  gravity: 0.3,
                  emissionFrequency: 0.05,
                  colors: KidUi.confettiColors,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The badge itself: its icon on a coloured disc, over a rotating burst.
class _Medallion extends StatelessWidget {
  const _Medallion({
    required this.accent,
    required this.icon,
    required this.scale,
    required this.spin,
  });

  final Color accent;
  final IconData icon;
  final double scale;
  final double spin;

  @override
  Widget build(BuildContext context) {
    const double side = 148;
    return Transform.scale(
      scale: scale.clamp(0, 1.2),
      child: SizedBox(
        width: side,
        height: side,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.rotate(
              angle: spin,
              child: CustomPaint(
                size: const Size(side, side),
                painter: RewardBurstPainter(accent),
              ),
            ),
            Container(
              width: side * 0.66,
              height: side * 0.66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    accent,
                    Color.lerp(accent, Colors.black, 0.3) ?? accent,
                  ],
                ),
                boxShadow: KidUi.shadow(accent),
              ),
              child: Icon(icon, color: Colors.white, size: side * 0.34),
            ),
          ],
        ),
      ),
    );
  }
}
