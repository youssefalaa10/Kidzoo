import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';
import 'package:kidzo/features/Adventure/story/rewards/adventure_reward.dart';

/// The moment a page comes home.
///
/// Three phases, one continuous animation, and deliberately short:
///
/// 1. **Arrive.** The page springs forward out of nothing, over a dimmed
///    screen, with a slow rotating burst behind it.
/// 2. **Hold.** It sits still for long enough to be looked at, while its name
///    fades in underneath. This beat is the reward — without it the page is a
///    thing that flickered past.
/// 3. **Travel.** It flies to the book and shrinks into it.
///
/// Phase 3 is why this exists at all. A page that simply disappears has been
/// *taken*; a page the child watches fly into the book has been **put
/// somewhere**, and the place it went is on screen and still there afterwards.
/// That is the difference between a reward and a notification, and it is the
/// reason the destination is a real widget's position rather than a guess at a
/// corner: the animation has to land on the thing the child will tap next.
///
/// Reusable by construction. It knows nothing about jungles, pages or the arc —
/// it takes a reward, a destination and a callback, so the next Adventure gets
/// the same moment by handing it a different [AdventureReward].
class AdventureRewardOverlay extends StatefulWidget {
  const AdventureRewardOverlay({
    required this.reward,
    required this.languageCode,
    required this.onDone,
    super.key,
    this.destination,
    this.caption,
  });

  final AdventureReward reward;
  final String languageCode;

  /// Where the page flies to, in this overlay's own coordinates. Null sends it
  /// to the top of the screen, which is where the book lives on every layout
  /// this ships with.
  final Offset? destination;

  /// A short line above the page. "A page came home!"
  final String? caption;

  /// Called once, after the page lands.
  final VoidCallback onDone;

  /// Short on purpose. Long enough to register, short enough that a child who
  /// has seen it four times is not waiting for it to be over.
  static const Duration duration = Duration(milliseconds: 2100);

  @override
  State<AdventureRewardOverlay> createState() => _AdventureRewardOverlayState();
}

class _AdventureRewardOverlayState extends State<AdventureRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase boundaries as fractions of the whole, named so the intervals below
  // read as the story they tell rather than as four magic numbers.
  static const double _arriveEnd = 0.34;
  static const double _holdEnd = 0.62;

  late final Animation<double> _arrive = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, _arriveEnd, curve: Curves.easeOutBack),
  );
  late final Animation<double> _travel = CurvedAnimation(
    parent: _controller,
    curve: const Interval(_holdEnd, 1, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _caption = CurvedAnimation(
    parent: _controller,
    curve: const Interval(_arriveEnd, _holdEnd, curve: Curves.easeOut),
  );
  late final Animation<double> _scrim = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, _arriveEnd, curve: Curves.easeOut),
    reverseCurve: const Interval(0, _arriveEnd),
  );

  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AdventureRewardOverlay.duration,
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _finish();
        }
      });
    _controller.forward();
  }

  /// Guarded, because both the status listener and a tap-to-skip can reach it.
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.reward.accentValue == null
        ? KidUi.primary
        : Color(widget.reward.accentValue!);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size box = Size(constraints.maxWidth, constraints.maxHeight);
        final Offset start = Offset(box.width / 2, box.height * 0.42);
        final Offset end =
            widget.destination ?? Offset(box.width / 2, -box.height * 0.08);
        final double pageSize = (box.shortestSide * 0.46).clamp(120.0, 260.0);

        return GestureDetector(
          // Skippable. The fifth time through, a child who wants to get on with
          // it should be able to, and an animation that cannot be dismissed is
          // an animation that becomes an obstacle.
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _controller.stop();
            _finish();
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              final double travel = _travel.value;
              final Offset? centre = Offset.lerp(start, end, travel);
              final double scale = _arrive.value * (1 - travel) + travel * 0.22;

              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Colors.black.withValues(
                          alpha: 0.42 * _scrim.value * (1 - travel),
                        ),
                      ),
                    ),
                  ),
                  if (widget.caption != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: box.height * 0.16,
                      child: Opacity(
                        opacity: _caption.value * (1 - travel),
                        child: ActivityGlyphText(
                          widget.caption!,
                          languageCode: widget.languageCode,
                          fontSize: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Positioned(
                    left: centre?.dx ?? 0 - pageSize / 2,
                    top: centre!.dy - pageSize / 2,
                    child: Transform.scale(
                      scale: scale.clamp(0.0, 1.35),
                      child: SizedBox(
                        width: pageSize,
                        height: pageSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            // The burst turns behind the page the whole time,
                            // so the object reads as arriving rather than as
                            // being pasted on.
                            Opacity(
                              opacity: 0.85 * (1 - travel),
                              child: Transform.rotate(
                                angle: _controller.value * math.pi,
                                child: CustomPaint(
                                  size: Size.square(pageSize * 1.35),
                                  painter: _BurstPainter(accent),
                                ),
                              ),
                            ),
                            if (widget.reward.art != null)
                              Image.asset(
                                widget.reward.art!,
                                width: pageSize,
                                height: pageSize,
                                fit: BoxFit.contain,
                              )
                            else
                              Icon(
                                Icons.description_rounded,
                                size: pageSize * 0.8,
                                color: accent,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: box.height * 0.42 + pageSize * 0.62,
                    child: Opacity(
                      opacity: _caption.value * (1 - travel),
                      child: ActivityGlyphText(
                        widget.reward.title.resolve(widget.languageCode),
                        languageCode: widget.languageCode,
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Soft rays behind the reward. Painted rather than an asset so it takes the
/// Adventure's own accent.
class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 2;
    final Paint paint = Paint()..color = color.withValues(alpha: 0.5);
    const int rays = 12;
    for (int index = 0; index < rays; index++) {
      final double angle = index * (2 * math.pi / rays);
      final Path path = Path()
        ..moveTo(centre.dx, centre.dy)
        ..lineTo(
          centre.dx + radius * math.cos(angle - 0.09),
          centre.dy + radius * math.sin(angle - 0.09),
        )
        ..lineTo(
          centre.dx + radius * math.cos(angle + 0.09),
          centre.dy + radius * math.sin(angle + 0.09),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) => oldDelegate.color != color;
}
