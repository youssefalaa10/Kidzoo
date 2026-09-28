import 'dart:async';
import 'dart:math';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// Where a stop sits on the journey.
enum MapStopState {
  /// Finished. The page is in the book, and it can be played again.
  completed,

  /// Playable now.
  open,

  /// A real Adventure the child has not reached yet.
  locked,

  /// A place that does not exist as content yet.
  ///
  /// Distinct from [locked] on purpose. "Locked" implies a door that opening
  /// the right thing will open; a stop that has not been written should not
  /// promise that a child who plays enough will reach it this week.
  comingSoon,
}

/// One stop on the trail: **one whole story**.
///
/// Not one activity, and not one narration beat. Opening a stop plays its
/// Adventure from its first line to its last without coming back here, so
/// showing its internal activities as separate map nodes would advertise a
/// structure the child never experiences — and padding the trail with beats
/// would make it look busier by misrepresenting how much there is to play.
@immutable
class MapStop {
  const MapStop({
    required this.id,
    required this.title,
    required this.teaser,
    required this.state,
    this.accentValue,
    this.art,
    this.icon,
  });

  final String id;
  final LocalizedText title;

  /// One line, or empty. Empty is the normal case for a stop the child has not
  /// earned a look at.
  final LocalizedText teaser;

  final MapStopState state;
  final int? accentValue;

  /// The page this stop gave up, worn by the bead once it is finished.
  final String? art;

  /// A motif name for a place that is not written yet — `market`, `ocean`,
  /// `stars`. Deliberately not an asset path: what a locked stop looks like is
  /// the map's business, not content's.
  final String? icon;

  bool get isReachable =>
      state == MapStopState.open || state == MapStopState.completed;
}

/// Where a bead sits, as a pure function of its index.
///
/// This is the whole answer to "the map must take any number of stories". There
/// is no coordinate table and no per-stop authoring: bead *n* is wherever the
/// lane cycle says bead *n* goes, so appending a story to the arc appends a
/// bead to the path and nothing else has to change. It also means a slot can be
/// built lazily without knowing anything about the slots it cannot see.
class TrailGeometry {
  const TrailGeometry._();

  /// Horizontal lane, as a fraction of the trail's width.
  ///
  /// Six lanes rather than a sine wave: a sine gives a regular zigzag that
  /// reads as a chart, while an irregular cycle reads as a road someone laid
  /// out. The period is coprime with nothing in particular — it just has to be
  /// long enough that the eye does not catch the repeat.
  static const List<double> lanes = <double>[0.30, 0.63, 0.78, 0.55, 0.24, 0.45];

  static double xFor(int index) => lanes[index % lanes.length];

  /// Vertical room per bead. Generous on purpose: with only a handful of
  /// stories authored, spacing and scenery are what stop the trail reading as
  /// a short list with gaps in it.
  static double slotHeight(KidMetrics metrics) =>
      metrics.size(196, min: 156, max: 268);

  static double beadSize(KidMetrics metrics) =>
      metrics.size(82, min: 68, max: 108);
}

/// The journey, as a winding path rather than a column of rows.
///
/// A `ListView.builder`, so it is lazy and unbounded — the cost of the
/// hundredth story is the same as the cost of the second.
class JourneyTrail extends StatelessWidget {
  const JourneyTrail({
    required this.stops,
    required this.languageCode,
    required this.metrics,
    required this.controller,
    required this.topInset,
    required this.statusLabelFor,
    required this.onOpen,
    super.key,
    this.justUnlockedStopId,
  });

  final List<MapStop> stops;
  final String languageCode;
  final KidMetrics metrics;
  final ScrollController controller;

  /// Room for the floating header, so the first bead never starts underneath it.
  final double topInset;

  /// Resolved by the screen, which owns the localizations.
  final String Function(MapStop stop) statusLabelFor;

  /// Null for a stop that cannot be played.
  final void Function(MapStop stop)? onOpen;

  final String? justUnlockedStopId;

  /// Scroll offset that puts bead [index] a little above centre.
  static double offsetFor({
    required int index,
    required KidMetrics metrics,
    required double viewportHeight,
    required double topInset,
  }) {
    final double slot = TrailGeometry.slotHeight(metrics);
    final double beadCentre = topInset + slot * index + slot / 2;
    return max(0, beadCentre - viewportHeight * 0.55);
  }

  @override
  Widget build(BuildContext context) {
    final double slot = TrailGeometry.slotHeight(metrics);

    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.only(top: topInset, bottom: slot * 0.6),
      // One extra slot: the road does not stop dead at the last written story,
      // it fades onward. A path that ends in a wall says the game is over.
      itemCount: stops.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == stops.length) {
          return _TrailTail(
            height: slot * 0.7,
            fromX: TrailGeometry.xFor(index - 1),
            toX: TrailGeometry.xFor(index),
          );
        }
        final MapStop stop = stops[index];
        return SizedBox(
          height: slot,
          child: _TrailSlot(
            index: index,
            stop: stop,
            previousX: index == 0 ? null : TrailGeometry.xFor(index - 1),
            nextX: TrailGeometry.xFor(index + 1),
            languageCode: languageCode,
            metrics: metrics,
            statusLabel: statusLabelFor(stop),
            isJustUnlocked: stop.id == justUnlockedStopId,
            onOpen: stop.isReachable && onOpen != null
                ? () => onOpen!(stop)
                : null,
          ),
        );
      },
    );
  }
}

/// One bead and the half-segments of road on either side of it.
///
/// Each slot paints the half toward the slot above and the half toward the slot
/// below, meeting its neighbours exactly on the boundary. That is what keeps
/// the road continuous while every slot stays independent — no slot needs to
/// know about any slot it cannot see, which is what makes the list lazy.
class _TrailSlot extends StatelessWidget {
  const _TrailSlot({
    required this.index,
    required this.stop,
    required this.previousX,
    required this.nextX,
    required this.languageCode,
    required this.metrics,
    required this.statusLabel,
    required this.isJustUnlocked,
    required this.onOpen,
  });

  final int index;
  final MapStop stop;
  final double? previousX;
  final double nextX;
  final String languageCode;
  final KidMetrics metrics;
  final String statusLabel;
  final bool isJustUnlocked;
  final VoidCallback? onOpen;

  Color get _accent {
    if (!stop.isReachable) {
      return KidUi.inkSoft;
    }
    return stop.accentValue == null ? KidUi.primary : Color(stop.accentValue!);
  }

  @override
  Widget build(BuildContext context) {
    final double bead = TrailGeometry.beadSize(metrics);
    final double x = TrailGeometry.xFor(index);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        final Widget marker = _TrailBead(
          stop: stop,
          accent: _accent,
          size: bead,
          languageCode: languageCode,
          metrics: metrics,
          statusLabel: statusLabel,
          onOpen: onOpen,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _TrailPathPainter(
                    slotIndex: index,
                    x: x,
                    previousX: previousX,
                    nextX: nextX,
                    accent: _accent,
                    isWalkedIn: stop.state == MapStopState.completed,
                    // The road *onward* is only walked once this stop is done.
                    isWalkedOut: stop.state == MapStopState.completed,
                    strokeWidth: metrics.size(16, min: 12, max: 24),
                  ),
                ),
              ),
            ),
            Positioned(
              left: x * width - bead * 0.9,
              top: height / 2 - bead * 0.9,
              width: bead * 1.8,
              height: bead * 1.8,
              child: Center(
                child: isJustUnlocked
                    ? _UnlockReveal(accent: _accent, child: marker)
                    : marker,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The road, and the ground it runs over.
class _TrailPathPainter extends CustomPainter {
  const _TrailPathPainter({
    required this.slotIndex,
    required this.x,
    required this.previousX,
    required this.nextX,
    required this.accent,
    required this.isWalkedIn,
    required this.isWalkedOut,
    required this.strokeWidth,
  });

  final int slotIndex;
  final double x;
  final double? previousX;
  final double nextX;
  final Color accent;
  final bool isWalkedIn;
  final bool isWalkedOut;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    _paintScenery(canvas, size);

    final Offset centre = Offset(x * size.width, size.height / 2);

    if (previousX != null) {
      final double boundaryX = (previousX! + x) / 2 * size.width;
      final Path incoming = Path()
        ..moveTo(boundaryX, 0)
        ..quadraticBezierTo(
          x * size.width,
          size.height * 0.22,
          centre.dx,
          centre.dy,
        );
      _strokeRoad(canvas, incoming, isWalkedIn);
    }

    final double onwardX = (x + nextX) / 2 * size.width;
    final Path outgoing = Path()
      ..moveTo(centre.dx, centre.dy)
      ..quadraticBezierTo(
        x * size.width,
        size.height * 0.78,
        onwardX,
        size.height,
      );
    _strokeRoad(canvas, outgoing, isWalkedOut);
  }

  /// A walked road is solid and carries the story's colour; the road ahead is
  /// pale and dashed. A child reads "this is how far I got" off the path itself
  /// without anything having to tell them.
  void _strokeRoad(Canvas canvas, Path path, bool isWalked) {
    final Paint shoulder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + 8
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawPath(path, shoulder);

    final Paint surface = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = isWalked ? accent : Colors.white.withValues(alpha: 0.5);

    if (isWalked) {
      canvas.drawPath(path, surface);
      return;
    }
    canvas.drawPath(_dashed(path, strokeWidth * 0.9, strokeWidth * 0.9), surface);
  }

  /// Turns a path into dashes. `PathMetric` walks the curve itself, so the
  /// dashes follow the bend instead of being spaced along a straight line.
  Path _dashed(Path source, double on, double off) {
    final Path result = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = min(distance + on, metric.length);
        result.addPath(metric.extractPath(distance, next), Offset.zero);
        distance = next + off;
      }
    }
    return result;
  }

  /// A few soft shapes either side of the road, seeded from the slot index.
  ///
  /// Deterministic, so a bead does not grow a different bush every time the
  /// list rebuilds it. Kept faint: this sits over a painted map, and scenery
  /// that competes with the background makes both harder to read.
  void _paintScenery(Canvas canvas, Size size) {
    final Random random = Random(slotIndex * 7919);
    final Paint foliage = Paint()
      ..color = KidUi.correct.withValues(alpha: 0.12);
    final Paint stone = Paint()
      ..color = Colors.white.withValues(alpha: 0.14);

    for (int i = 0; i < 3; i++) {
      // Pushed away from the lane so nothing ever sits under the road.
      final bool left = random.nextBool();
      final double cx = left
          ? random.nextDouble() * size.width * 0.22
          : size.width * (0.78 + random.nextDouble() * 0.22);
      final double cy = random.nextDouble() * size.height;
      final double r = size.width * (0.05 + random.nextDouble() * 0.06);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2.6, height: r * 1.7),
        i.isEven ? foliage : stone,
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPathPainter old) {
    return old.x != x ||
        old.previousX != previousX ||
        old.nextX != nextX ||
        old.accent != accent ||
        old.isWalkedIn != isWalkedIn ||
        old.isWalkedOut != isWalkedOut ||
        old.strokeWidth != strokeWidth;
  }
}

/// The road running off the end of what has been written.
class _TrailTail extends StatelessWidget {
  const _TrailTail({
    required this.height,
    required this.fromX,
    required this.toX,
  });

  final double height;
  final double fromX;
  final double toX;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _TailPainter(fromX: fromX, toX: toX),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter({required this.fromX, required this.toX});

  final double fromX;
  final double toX;

  @override
  void paint(Canvas canvas, Size size) {
    // Three dots, each fainter than the last. Cheaper than a gradient shader
    // and it says the same thing: the road carries on, there is just nothing
    // on it yet.
    final double startX = (fromX + toX) / 2 * size.width;
    for (int i = 0; i < 3; i++) {
      final double t = (i + 1) / 4;
      canvas.drawCircle(
        Offset(startX + (toX * size.width - startX) * t, size.height * t),
        size.width * 0.018,
        Paint()..color = Colors.white.withValues(alpha: 0.34 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_TailPainter old) =>
      old.fromX != fromX || old.toX != toX;
}

/// The marker on the path.
class _TrailBead extends StatefulWidget {
  const _TrailBead({
    required this.stop,
    required this.accent,
    required this.size,
    required this.languageCode,
    required this.metrics,
    required this.statusLabel,
    required this.onOpen,
  });

  final MapStop stop;
  final Color accent;
  final double size;
  final String languageCode;
  final KidMetrics metrics;
  final String statusLabel;
  final VoidCallback? onOpen;

  @override
  State<_TrailBead> createState() => _TrailBeadState();
}

class _TrailBeadState extends State<_TrailBead>
    with SingleTickerProviderStateMixin {
  late final AnimationController _alive = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// Shown on demand for a stop the child cannot open, then hidden again.
  ///
  /// This is what replaces a name printed beside every bead. A permanent label
  /// column turns a map into a list; a name that appears when a child asks for
  /// it answers the same question without spending the space.
  bool _showName = false;
  Timer? _hideName;

  bool get _isCurrent => widget.stop.state == MapStopState.open;

  @override
  void initState() {
    super.initState();
    if (_isCurrent) {
      _alive.repeat();
    }
  }

  @override
  void didUpdateWidget(_TrailBead oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCurrent && !_alive.isAnimating) {
      _alive.repeat();
    } else if (!_isCurrent && _alive.isAnimating) {
      _alive.stop();
      _alive.value = 0;
    }
  }

  @override
  void dispose() {
    _hideName?.cancel();
    _alive.dispose();
    super.dispose();
  }

  void _handleTap() {
    KidHaptics.tap();
    final VoidCallback? open = widget.onOpen;
    if (open != null) {
      open();
      return;
    }
    setState(() => _showName = true);
    _hideName?.cancel();
    _hideName = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() => _showName = false);
      }
    });
  }

  IconData get _glyph {
    switch (widget.stop.state) {
      case MapStopState.completed:
        return Icons.check_rounded;
      case MapStopState.open:
        return Icons.play_arrow_rounded;
      case MapStopState.locked:
        return Icons.lock_rounded;
      case MapStopState.comingSoon:
        return _motif;
    }
  }

  /// A silhouette that hints at the place without telling its story.
  IconData get _motif {
    switch (widget.stop.icon) {
      case 'market':
        return Icons.storefront_rounded;
      case 'ocean':
        return Icons.waves_rounded;
      case 'stars':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.lock_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double touch = max(widget.size, KidUi.minTouchYoung);

    return Semantics(
      button: true,
      label: '${widget.stop.title.resolve(widget.languageCode)}, '
          '${widget.statusLabel}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        // Drawn small, touched large. The bead is sized for the look of the
        // map; the target around it is sized for a four-year-old's finger.
        child: SizedBox(
          width: touch,
          height: touch,
          child: AnimatedBuilder(
            animation: _alive,
            builder: (BuildContext context, Widget? child) {
              final double wave = sin(_alive.value * 2 * pi);
              return Transform.translate(
                offset: Offset(0, _isCurrent ? wave * 3 : 0),
                child: child,
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                if (_isCurrent)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _alive,
                        builder: (BuildContext context, Widget? _) =>
                            CustomPaint(
                          painter: _HaloPainter(
                            progress: _alive.value,
                            color: widget.accent,
                            radius: widget.size / 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                _BeadFace(
                  size: widget.size,
                  accent: widget.accent,
                  state: widget.stop.state,
                  art: widget.stop.art,
                  glyph: _glyph,
                ),
                if (_isCurrent || _showName)
                  Positioned(
                    bottom: touch / 2 + widget.size * 0.46,
                    child: _NameBubble(
                      text: widget.stop.title.resolve(widget.languageCode),
                      // The current bead says what tapping it does. Every other
                      // bead, asked directly, gives up whatever the content
                      // chose to reveal - which for an unwritten place is one
                      // teaser line, and only once it has been earned.
                      subtitle: _isCurrent
                          ? widget.statusLabel
                          : widget.stop.teaser.resolve(widget.languageCode),
                      isSubtitleAccented: _isCurrent,
                      languageCode: widget.languageCode,
                      metrics: widget.metrics,
                      accent: widget.accent,
                      isMuted: !widget.stop.isReachable,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BeadFace extends StatelessWidget {
  const _BeadFace({
    required this.size,
    required this.accent,
    required this.state,
    required this.art,
    required this.glyph,
  });

  final double size;
  final Color accent;
  final MapStopState state;
  final String? art;
  final IconData glyph;

  @override
  Widget build(BuildContext context) {
    final bool isReachable =
        state == MapStopState.completed || state == MapStopState.open;
    final bool isSilhouette = state == MapStopState.comingSoon;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isReachable
            ? accent
            : Colors.white.withValues(alpha: isSilhouette ? 0.18 : 0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSilhouette
              ? Colors.white.withValues(alpha: 0.55)
              : Colors.white,
          width: size * 0.065,
        ),
        boxShadow: KidUi.shadow(
          isReachable ? accent : KidUi.inkSoft,
          strength: isReachable ? 0.9 : 0.3,
        ),
      ),
      alignment: Alignment.center,
      child: state == MapStopState.completed && art != null
          // A finished stop wears the page it gave up, which is the clearest
          // possible statement of what playing it was for.
          ? Padding(
              padding: EdgeInsets.all(size * 0.2),
              child: Image.asset(art!, fit: BoxFit.contain),
            )
          : Icon(
              glyph,
              color: isReachable
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.8),
              size: size * 0.44,
            ),
    );
  }
}

/// A ring that grows out of the current bead and fades.
class _HaloPainter extends CustomPainter {
  const _HaloPainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  final double progress;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    // Two rings, half a cycle apart, so the pulse never fully stops.
    for (final double phase in <double>[progress, (progress + 0.5) % 1.0]) {
      final double t = Curves.easeOut.transform(phase);
      canvas.drawCircle(
        centre,
        radius * (0.58 + t * 0.62),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.1 * (1 - t)
          ..color = color.withValues(alpha: 0.5 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.progress != progress || old.color != color || old.radius != radius;
}

/// The floating name above a bead.
class _NameBubble extends StatelessWidget {
  const _NameBubble({
    required this.text,
    required this.subtitle,
    required this.isSubtitleAccented,
    required this.languageCode,
    required this.metrics,
    required this.accent,
    required this.isMuted,
  });

  final String text;

  /// Empty for a bead with nothing more to say.
  final String subtitle;

  final bool isSubtitleAccented;
  final String languageCode;
  final KidMetrics metrics;
  final Color accent;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final bool hasSubtitle = subtitle.trim().isNotEmpty;
    return IgnorePointer(
      child: Container(
        constraints:
            BoxConstraints(maxWidth: metrics.size(190, min: 140, max: 260)),
        padding: EdgeInsets.symmetric(
          horizontal: metrics.size(14, min: 10, max: 20),
          vertical: metrics.size(8, min: 6, max: 12),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          // A pill, not a card: the bubble is a label on the bead, and giving
          // it card weight would make it a second thing to look at.
          borderRadius: BorderRadius.circular(KidUi.radiusCard),
          boxShadow: KidUi.shadow(accent, strength: 0.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ActivityGlyphText(
              text,
              languageCode: languageCode,
              fontSize: metrics.size(15, min: 12, max: 19),
              maxLines: 1,
              color: isMuted ? KidUi.inkSoft : KidUi.ink,
            ),
            if (hasSubtitle)
              Padding(
                padding: EdgeInsets.only(top: metrics.gap * 0.15),
                child: ActivityGlyphText(
                  subtitle,
                  languageCode: languageCode,
                  fontSize: metrics.size(13, min: 11, max: 16),
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                  color: isSubtitleAccented ? accent : KidUi.inkSoft,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A short, self-contained "this just opened" flourish.
class _UnlockReveal extends StatefulWidget {
  const _UnlockReveal({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  State<_UnlockReveal> createState() => _UnlockRevealState();
}

class _UnlockRevealState extends State<_UnlockReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeOutBack.transform(
          _controller.value.clamp(0.0, 1.0),
        );
        // A glow that blooms and fades, over a stop that grows into place. It
        // is over in under a second: the point is to draw the eye to something
        // that changed, not to make the child wait.
        final double glow = (1 - (_controller.value - 0.35).abs() * 2.6)
            .clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.9 + 0.1 * t,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.55 * glow),
                  blurRadius: 34 * glow,
                  spreadRadius: 6 * glow,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
