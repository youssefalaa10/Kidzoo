import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/shadow_play/shadow_play_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/shadow_play/shadow_play_cubit.dart';

/// Two views of one experiment, and they move together.
///
/// **The wall**, face on: whatever is painted on it, the outline the shadow
/// has to fit, and the shadow itself. **The track**, side on: the light, the
/// object, and the cone of light with the dark wedge the object cuts out of
/// it. Moving the object in one view changes the other in the same frame, so
/// the child sees *why* the shadow grew — it is closer to the light, so it
/// blocks more of the cone — rather than only that it did.
///
/// Nothing is judged while the child experiments. Dragging, tapping the track
/// and the arrows all just move the object; the shine button is the answer.
/// A board that judged every drag release would punish exactly the trying
/// the activity exists for.
class ShadowPlayBoard extends StatefulWidget {
  const ShadowPlayBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final ShadowStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<ShadowPlayBoard> createState() => _ShadowPlayBoardState();
}

class _ShadowPlayBoardState extends State<ShadowPlayBoard> {
  late double _percent;

  @override
  void initState() {
    super.initState();
    _percent = widget.step.round.startPercent.toDouble();
  }

  @override
  void didUpdateWidget(ShadowPlayBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      _percent = widget.step.round.startPercent.toDouble();
    }
  }

  ShadowPlayContent get _content => widget.step.content;

  bool get _mirrored => widget.state.languageCode == 'ar';

  bool get _locked => widget.state.isBoardLocked;

  Color get _accent => _content.accentColorValue == null
      ? KidUi.primary
      : Color(_content.accentColorValue!);

  bool get _demonstrating =>
      widget.state.view?.highlightOptionId == shadowTargetOptionId;

  /// From narrowed onwards the arrow that points the right way lights up —
  /// a direction, not an answer; the child still has to find where to stop.
  bool get _showsDirection =>
      widget.state.scaffoldLevel == ScaffoldLevel.narrowed ||
      widget.state.scaffoldLevel == ScaffoldLevel.modelled;

  double get _step => math.max(2, _content.tolerancePercent / 2);

  void _moveTo(double percent) {
    if (_locked) {
      return;
    }
    final double next = percent.clamp(
      _content.trackMinPercent.toDouble(),
      _content.trackMaxPercent.toDouble(),
    );
    if ((next - _percent).abs() < 0.01) {
      return;
    }
    // A soft tick each time the shadow crosses a whole step, so the size
    // change can be felt as well as seen.
    if ((next / _step).floor() != (_percent / _step).floor()) {
      HapticFeedback.selectionClick();
    }
    setState(() => _percent = next);
  }

  void _shine() {
    if (_locked) {
      return;
    }
    widget.submit(QuantityAttempt(_percent.round()));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360;
        final double height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 480;
        final bool wide = width > height * 1.25;
        final double gap = math.max(6, math.min(width, height) * 0.03);
        final double wallSide = wide
            ? math.min(height, width * 0.48)
            : math.min(width, (height - gap) * 0.56);
        final Size trackBox = wide
            ? Size(width - wallSide - gap, height)
            : Size(width, height - wallSide - gap);

        final Widget wall = _Wall(
          side: wallSide,
          content: _content,
          round: widget.step.round,
          percent: _percent,
          accent: _accent,
          languageCode: widget.state.languageCode,
        );
        final Widget track = _Track(
          box: trackBox,
          content: _content,
          round: widget.step.round,
          percent: _percent,
          mirrored: _mirrored,
          locked: _locked,
          demonstrating: _demonstrating,
          showsDirection: _showsDirection,
          accent: _accent,
          languageCode: widget.state.languageCode,
          step: _step,
          onMove: _moveTo,
          onShine: _shine,
        );
        final List<Widget> children = <Widget>[
          wall,
          SizedBox(width: gap, height: gap),
          track,
        ];
        // Physical layout is decided here, not by the ambient direction: the
        // light sits at the reading start and the wall at the end, and an RTL
        // Row would flip it a second time.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: wide
              ? Row(
                  children: _mirrored ? children : children.reversed.toList(),
                )
              : Column(children: children),
        );
      },
    );
  }
}

/// The wall, face on.
class _Wall extends StatelessWidget {
  const _Wall({
    required this.side,
    required this.content,
    required this.round,
    required this.percent,
    required this.accent,
    required this.languageCode,
  });

  final double side;
  final ShadowPlayContent content;
  final ShadowRound round;
  final double percent;
  final Color accent;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final double full = side * 0.9;
    final double target = full * content.shadowScaleAt(round.targetPercent.toDouble());
    final double shadow = full * content.shadowScaleAt(percent);
    final String image = round.item.imageAsset;
    final int decodeWidth = (full * 2).round();

    return Semantics(
      label: round.item.label.resolve(languageCode),
      value: 'shadow ${(shadow / target * 100).round()} percent of the outline',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KidUi.radiusCard * 0.6),
        child: SizedBox(
          width: side,
          height: side,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: content.wallImage == null
                    ? ColoredBox(
                        color: Color.lerp(accent, Colors.black, 0.7)!,
                      )
                    : Image.asset(content.wallImage!,
                        fit: BoxFit.cover, cacheWidth: (side * 2).round()),
              ),
              // The outline: where the shadow has to land. Drawn as the
              // object's own silhouette so "the same shape, this big" needs
              // no words.
              Image.asset(
                image,
                width: target,
                height: target,
                fit: BoxFit.contain,
                color: KidUi.hint.withValues(alpha: 0.45),
                colorBlendMode: BlendMode.srcIn,
                cacheWidth: decodeWidth,
              ),
              // The shadow. Opaque enough that what is on the wall behind it
              // is gone, which is the cause and effect the round is about.
              Image.asset(
                image,
                width: shadow,
                height: shadow,
                fit: BoxFit.contain,
                color: Colors.black.withValues(alpha: 0.82),
                colorBlendMode: BlendMode.srcIn,
                cacheWidth: decodeWidth,
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(KidUi.radiusCard * 0.6),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.7), width: 3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The experiment, side on, and the controls under it.
class _Track extends StatelessWidget {
  const _Track({
    required this.box,
    required this.content,
    required this.round,
    required this.percent,
    required this.mirrored,
    required this.locked,
    required this.demonstrating,
    required this.showsDirection,
    required this.accent,
    required this.languageCode,
    required this.step,
    required this.onMove,
    required this.onShine,
  });

  final Size box;
  final ShadowPlayContent content;
  final ShadowRound round;
  final double percent;
  final bool mirrored;
  final bool locked;
  final bool demonstrating;
  final bool showsDirection;
  final Color accent;
  final String languageCode;
  final double step;
  final ValueChanged<double> onMove;
  final VoidCallback onShine;

  @override
  Widget build(BuildContext context) {
    final double button = (box.height * 0.34).clamp(48.0, KidUi.minTouch);
    // The shine button is the tallest thing in the row.
    final double laneHeight = math.max(0, box.height - button * 1.1 - 8);
    final double lightSize = math.min(laneHeight * 0.6, box.width * 0.2);
    final double wallBar = math.max(6, box.width * 0.025);
    // Where the light and the wall sit on the lane, in pixels from the start.
    final double lightX = lightSize * 0.55;
    final double wallX = box.width - wallBar;
    final double span = math.max(1, wallX - lightX);
    // The picture is drawn big enough to see and to grab; the wedge behind it
    // uses the true geometry, sized so the side view and the wall face agree
    // — a full-height shadow at the nearest point, shrinking as 1/distance.
    // The picture covers where the wedge starts, so the two sizes never meet.
    final double objectSide =
        (laneHeight * 0.42).clamp(36.0, 96.0).clamp(0.0, box.width * 0.2);
    final double occluderHalf =
        laneHeight * 0.47 * content.trackMinPercent / 100;

    double xFor(double p) {
      final double x = lightX + span * p / 100;
      return mirrored ? box.width - x : x;
    }

    double percentFor(double localX) {
      final double x = mirrored ? box.width - localX : localX;
      return (x - lightX) / span * 100;
    }

    // The buttons are physical: left moves it left. Which of those is
    // "toward the light" depends on the reading direction.
    final double leftDelta = mirrored ? step : -step;
    final bool targetIsLeft =
        xFor(round.targetPercent.toDouble()) < xFor(percent);

    return SizedBox(
      width: box.width,
      height: box.height,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: laneHeight,
            child: Semantics(
              slider: true,
              label: round.item.label.resolve(languageCode),
              value: '${percent.round()}',
              increasedValue: '${math.min(content.trackMaxPercent.toDouble(), percent + step).round()}',
              decreasedValue: '${math.max(content.trackMinPercent.toDouble(), percent - step).round()}',
              onIncrease: () => onMove(percent + step),
              onDecrease: () => onMove(percent - step),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (TapDownDetails d) =>
                    onMove(percentFor(d.localPosition.dx)),
                onHorizontalDragUpdate: (DragUpdateDetails d) => onMove(
                  percent + d.delta.dx / span * 100 * (mirrored ? -1 : 1),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _ConePainter(
                            lightX: mirrored ? box.width - lightX : lightX,
                            wallX: mirrored ? box.width - wallX : wallX,
                            objectX: xFor(percent),
                            objectHalf: occluderHalf,
                            wallBar: wallBar,
                            accent: accent,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (mirrored ? box.width - lightX : lightX) -
                          lightSize / 2,
                      top: laneHeight / 2 - lightSize / 2,
                      child: _Light(
                          size: lightSize, image: content.lightImage),
                    ),
                    if (demonstrating)
                      Positioned(
                        left: xFor(round.targetPercent.toDouble()) -
                            objectSide / 2,
                        top: laneHeight / 2 - objectSide / 2,
                        child: Opacity(
                          opacity: 0.45,
                          child: _ObjectPicture(
                            image: round.item.imageAsset,
                            side: objectSide,
                          ),
                        ),
                      ),
                    Positioned(
                      left: xFor(percent) - objectSide / 2,
                      top: laneHeight / 2 - objectSide / 2,
                      child: _ObjectPicture(
                        image: round.item.imageAsset,
                        side: objectSide,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _RoundButton(
                size: button,
                icon: Icons.arrow_back_rounded,
                semantic: mirrored ? 'closer to the wall' : 'closer to the light',
                glow: showsDirection && targetIsLeft,
                enabled: !locked,
                onTap: () => onMove(percent + leftDelta),
              ),
              SizedBox(width: button * 0.3),
              _RoundButton(
                size: button * 1.1,
                icon: Icons.flare_rounded,
                semantic: 'shine',
                filled: true,
                accent: accent,
                enabled: !locked,
                onTap: onShine,
              ),
              SizedBox(width: button * 0.3),
              _RoundButton(
                size: button,
                icon: Icons.arrow_forward_rounded,
                semantic: mirrored ? 'closer to the light' : 'closer to the wall',
                glow: showsDirection && !targetIsLeft,
                enabled: !locked,
                onTap: () => onMove(percent - leftDelta),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Light extends StatelessWidget {
  const _Light({required this.size, required this.image});

  final double size;
  final String? image;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: KidUi.hint.withValues(alpha: 0.55),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: image == null
            ? const DecoratedBox(
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: KidUi.hint))
            : Image.asset(image!,
                fit: BoxFit.contain, cacheWidth: (size * 2).round()),
      ),
    );
  }
}

class _ObjectPicture extends StatelessWidget {
  const _ObjectPicture({required this.image, required this.side});

  final String image;
  final double side;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: side,
      height: side,
      child: Image.asset(image,
          fit: BoxFit.contain, cacheWidth: (side * 2).round()),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.size,
    required this.icon,
    required this.semantic,
    required this.enabled,
    required this.onTap,
    this.glow = false,
    this.filled = false,
    this.accent = KidUi.primary,
  });

  final double size;
  final IconData icon;
  final String semantic;
  final bool enabled;
  final VoidCallback onTap;
  final bool glow;
  final bool filled;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semantic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: KidUi.fast,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? accent : KidUi.surface,
            border: Border.all(
              color: glow ? KidUi.hint : accent.withValues(alpha: 0.6),
              width: glow ? 5 : 3,
            ),
            boxShadow: glow
                ? <BoxShadow>[
                    BoxShadow(
                      color: KidUi.hint.withValues(alpha: 0.6),
                      blurRadius: size * 0.3,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Icon(icon,
                size: size * 0.55, color: filled ? KidUi.surface : KidUi.ink),
          ),
        ),
      ),
    );
  }
}

/// The side view: the cone of light from the source to the wall, the dark
/// wedge the object throws, and the wall edge-on.
class _ConePainter extends CustomPainter {
  const _ConePainter({
    required this.lightX,
    required this.wallX,
    required this.objectX,
    required this.objectHalf,
    required this.wallBar,
    required this.accent,
  });

  final double lightX;
  final double wallX;
  final double objectX;
  final double objectHalf;
  final double wallBar;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double wallHalf = size.height * 0.47;
    final Offset light = Offset(lightX, midY);

    final Path cone = Path()
      ..moveTo(light.dx, light.dy)
      ..lineTo(wallX, midY - wallHalf)
      ..lineTo(wallX, midY + wallHalf)
      ..close();
    canvas.drawPath(cone, Paint()..color = KidUi.hint.withValues(alpha: 0.2));

    // The wedge behind the object: its top and bottom edges projected from
    // the light onto the wall. This is the diagram of why the shadow grows.
    final double distance = objectX - lightX;
    if (distance.abs() > 1) {
      final double reach = (wallX - lightX) / distance;
      final double spread = math.min(objectHalf * reach, wallHalf);
      final Path wedge = Path()
        ..moveTo(objectX, midY - objectHalf)
        ..lineTo(wallX, midY - spread)
        ..lineTo(wallX, midY + spread)
        ..lineTo(objectX, midY + objectHalf)
        ..close();
      canvas.drawPath(
          wedge, Paint()..color = Colors.black.withValues(alpha: 0.35));
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(wallX, midY),
          width: wallBar,
          height: wallHalf * 2,
        ),
        Radius.circular(wallBar / 2),
      ),
      Paint()..color = Color.lerp(accent, Colors.black, 0.4)!,
    );
  }

  @override
  bool shouldRepaint(_ConePainter old) =>
      old.objectX != objectX ||
      old.lightX != lightX ||
      old.wallX != wallX ||
      old.objectHalf != objectHalf ||
      old.accent != accent;
}
