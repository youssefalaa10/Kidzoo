import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/engines/flashlight/flashlight_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/flashlight/flashlight_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/hidden_clue/scene_props.dart';

/// A dark scene with a light the child carries.
///
/// The difference from a hidden-object board is not the picture, it is who
/// decides what is visible. There, the scene is lit and the answer is merely
/// small; here nothing is visible until the child puts the light on it, so
/// moving the light *is* the activity and finding something is a consequence
/// of having looked there.
///
/// Everything is painted rather than clipped. A hard circular crop reads as a
/// hole cut in a sheet of black; a feathered falloff reads as a torch, and the
/// soft edge is also what lets a shape be half-seen — which is the entire
/// mechanic behind the big silhouette.
class FlashlightBoard extends StatefulWidget {
  const FlashlightBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final FlashlightStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<FlashlightBoard> createState() => _FlashlightBoardState();
}

class _FlashlightBoardState extends State<FlashlightBoard>
    with SingleTickerProviderStateMixin {
  /// Where the light is, normalized 0..1 in the scene box.
  late Offset _beam;

  /// The beam radius as a fraction of the box's short side.
  late double _radius;

  /// Drives the slow idle life of the scene: weed swaying, the big shape
  /// breathing, a found object settling. One controller for all of it, because
  /// the alternative is a controller per object and a scene that costs more to
  /// animate than to draw.
  late final AnimationController _life;

  @override
  void initState() {
    super.initState();
    _beam = widget.step.content.beamStart;
    _radius = widget.step.content.beamFraction;
    _life = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  FlashlightContent get _content => widget.step.content;

  Color get _accent => _content.accentColorValue == null
      ? KidUi.primary
      : Color(_content.accentColorValue!);

  /// True when [find] is inside the beam right now.
  ///
  /// The creature's extra condition is checked here rather than in the cubit
  /// because it is a fact about the picture, not about the answer: the cubit
  /// judges *what* was touched, and the board decides what can be touched.
  bool _isLit(DarkFind find) {
    final double reach = _radius + find.scale * 0.04;
    if ((find.position - _beam).distance > reach) {
      return false;
    }
    final double? required = find.requiresBeamFraction;
    return required == null || _radius >= required - 0.001;
  }

  /// The creature seen but not yet resolved — lit by the beam, still too big
  /// for it. The moment the whole "is it a monster?" beat lives in.
  bool _isLooming(DarkFind find) {
    if (!find.isCreature) {
      return false;
    }
    final double? required = find.requiresBeamFraction;
    if (required == null) {
      return false;
    }
    return _radius < required - 0.001 &&
        (find.position - _beam).distance < _radius + find.scale * 0.22;
  }

  bool _isFound(DarkFind find) =>
      widget.step.alreadyFound.any((DarkFind other) => other.id == find.id);

  bool get _isLive =>
      !widget.state.isBoardLocked &&
      (widget.state.view?.liveOptionIds.contains(widget.step.target.id) ??
          true);

  void _moveBeamTo(Offset local, Size box) {
    // Clamped in normalized space against the *short* side, which is the unit
    // the radius is in. Clamping each axis to 0..1 instead would let the beam's
    // edge leave a wide board on the long axis while looking correct on a
    // square one.
    final double shortSide = math.min(box.width, box.height);
    final double marginX = _radius * shortSide / box.width * 0.35;
    final double marginY = _radius * shortSide / box.height * 0.35;
    setState(() {
      _beam = Offset(
        (local.dx / box.width).clamp(marginX, 1 - marginX),
        (local.dy / box.height).clamp(marginY, 1 - marginY),
      );
    });
  }

  void _widenBy(double deltaFraction) {
    setState(() {
      _radius = (_radius + deltaFraction)
          .clamp(_content.beamFraction, _content.maxBeamFraction);
    });
  }

  void _touch(DarkFind find) {
    if (!_isLive || !_isLit(find)) {
      return;
    }
    widget.submit(ChoiceAttempt(find.id));
  }

  @override
  Widget build(BuildContext context) {
    final String language = widget.state.languageCode;
    final bool demonstrating = widget.state.isDemonstrating;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size box = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 360,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 480,
        );
        final double shortSide = math.min(box.width, box.height);
        // One base size for every object in the scene, off the short side, so
        // the layout a person authored in percentages is the layout they get in
        // landscape as well as in portrait.
        final double base = shortSide * 0.16;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (DragStartDetails d) => _moveBeamTo(d.localPosition, box),
          onPanUpdate: (DragUpdateDetails d) =>
              _moveBeamTo(d.localPosition, box),
          onTapDown: (TapDownDetails d) => _moveBeamTo(d.localPosition, box),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // 1. The scene, fully painted and fully ordinary.
              if (_content.sceneImage != null)
                Image.asset(_content.sceneImage!, fit: BoxFit.cover),
              if (_content.ground != null)
                _Placed(
                  position: _content.ground!.position,
                  box: box,
                  child: ScenePropView(
                    prop: _content.ground!,
                    size: shortSide * 1.4,
                    accent: _accent,
                  ),
                ),
              for (final SceneProp prop in _content.props)
                _Placed(
                  position: prop.position,
                  box: box,
                  child: ScenePropView(
                    prop: prop,
                    size: base * prop.scale,
                    accent: _accent,
                  ),
                ),
              for (final DarkFind find in _content.finds)
                _Placed(
                  position: find.position,
                  box: box,
                  child: AnimatedBuilder(
                    animation: _life,
                    builder: (BuildContext context, Widget? child) => _Find(
                      find: find,
                      size: base * find.scale * (find.isCreature ? 3.4 : 1),
                      lit: _isLit(find),
                      looming: _isLooming(find),
                      found: _isFound(find),
                      highlighted: demonstrating &&
                          widget.state.view?.highlightOptionId == find.id,
                      phase: _life.value,
                      accent: _accent,
                      label: find.label.resolve(language),
                      onTap: () => _touch(find),
                    ),
                  ),
                ),

              // 2. The dark, painted over all of it with a hole where the
              //    child is pointing. Painted last so nothing can escape it,
              //    and ignoring pointers so the scene underneath stays live.
              IgnorePointer(
                child: CustomPaint(
                  painter: _DarkWaterPainter(
                    beam: _beam,
                    radiusFraction: _radius,
                    accent: _accent,
                  ),
                ),
              ),

              // 3. The handle, on top of the dark because it is the one thing
              //    that is never in shadow — the child is holding it.
              _Placed(
                position: _beam,
                box: box,
                child: _BeamHandle(
                  size: math.max(KidUi.minTouch, shortSide * 0.18),
                  accent: _accent,
                  canWiden: _content.canWidenBeam,
                  atFullWidth: _radius >= _content.maxBeamFraction - 0.001,
                  onWiden: () => _widenBy(0.05),
                  onDrag: (Offset delta) => _moveBeamTo(
                    Offset(_beam.dx * box.width, _beam.dy * box.height) + delta,
                    box,
                  ),
                  onWidenDrag: (double outward) =>
                      _widenBy(outward / shortSide),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Puts a child at a normalized position, centred on it.
class _Placed extends StatelessWidget {
  const _Placed({
    required this.position,
    required this.box,
    required this.child,
  });

  final Offset position;
  final Size box;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx * box.width,
      top: position.dy * box.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: child,
      ),
    );
  }
}

/// One object in the dark.
class _Find extends StatelessWidget {
  const _Find({
    required this.find,
    required this.size,
    required this.lit,
    required this.looming,
    required this.found,
    required this.highlighted,
    required this.phase,
    required this.accent,
    required this.label,
    required this.onTap,
  });

  final DarkFind find;
  final double size;
  final bool lit;
  final bool looming;
  final bool found;
  final bool highlighted;

  /// 0..1, one slow loop. Every object breathes off the same clock, at its own
  /// offset, so the scene moves without any two things moving in lockstep.
  final double phase;

  final Color accent;
  final String label;
  final VoidCallback onTap;

  /// A stable per-object offset into the shared clock, from the id. Stable so
  /// a test pumping the same scene twice gets the same frame, and per-object
  /// so nothing pulses in time with anything else.
  double get _offset => (find.id.hashCode % 1000) / 1000;

  double get _breath => math.sin((phase + _offset) * 2 * math.pi) * 0.5 + 0.5;

  @override
  Widget build(BuildContext context) {
    // Found things stay lit for good. That is the world reacting: the scene the
    // child can see at the end is the scene they uncovered, and it is a better
    // account of what they did than any number would be.
    final bool visible = lit || found || looming;
    final double glow = found ? 1 : (lit ? 1 : (looming ? 0.35 : 0));

    final Widget body = find.isCreature && !lit
        // Before it resolves, the creature is a shape, not a picture: the same
        // art flattened to a silhouette. The startle comes from the outline
        // being too big for the light, and it is undone by the child widening
        // the light rather than by anything happening to them.
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(
              Color.lerp(accent, Colors.black, 0.78) ?? Colors.black,
              BlendMode.srcATop,
            ),
            child: Image.asset(find.imageAsset,
                width: size, height: size, fit: BoxFit.contain),
          )
        : Image.asset(find.imageAsset,
            width: size, height: size, fit: BoxFit.contain);

    return Semantics(
      label: label,
      button: !found,
      enabled: lit && !found,
      // The creature's state is the story beat, so it has to be in the
      // accessible tree too rather than only in the picture.
      value: found
          ? 'found'
          : lit
              ? 'lit'
              : looming
                  ? 'a large shape in the dark'
                  : 'dark',
      child: GestureDetector(
        onTap: lit && !found ? onTap : null,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: KidUi.fast,
          child: Transform.scale(
            // The creature breathes; everything else drifts a little, as
            // things do underwater. Both are small on purpose — a scene that
            // is busy in the dark is harder to search, not livelier.
            scale: find.isCreature
                ? 1 + _breath * 0.035
                : 1 + (visible ? _breath * 0.02 : 0),
            child: Transform.translate(
              offset: Offset(0, math.sin((phase + _offset) * 2 * math.pi) * 2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: glow == 0
                      ? const <BoxShadow>[]
                      : <BoxShadow>[
                          BoxShadow(
                            color: KidUi.hint.withValues(
                              alpha: 0.5 * glow * (highlighted ? 1.6 : 1),
                            ),
                            blurRadius: size * (highlighted ? 0.6 : 0.35),
                            spreadRadius: size * 0.04,
                          ),
                        ],
                ),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark, and the hole in it.
///
/// A radial gradient rather than a clip, because the falloff is the difference
/// between a torch and a stencil — and because a soft edge is what lets the big
/// shape be half-lit, which is the thing the whole scene is built around.
class _DarkWaterPainter extends CustomPainter {
  const _DarkWaterPainter({
    required this.beam,
    required this.radiusFraction,
    required this.accent,
  });

  final Offset beam;
  final double radiusFraction;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Offset centre = Offset(beam.dx * size.width, beam.dy * size.height);
    final double radius = math.min(size.width, size.height) * radiusFraction;

    // Deep water rather than black: the chapter's own colour taken almost all
    // the way down. Black would be a curtain over a picture; this is the sea
    // with no light in it.
    final Color deep = Color.lerp(accent, Colors.black, 0.88) ?? Colors.black;

    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(bounds, Paint()..color = deep);
    // Punching the hole with dstOut and a soft gradient gives a beam whose
    // edge fades over roughly a third of its radius — bright core, believable
    // penumbra, full dark beyond it.
    canvas.drawCircle(
      centre,
      radius * 1.55,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..shader = const RadialGradient(
          colors: <Color>[
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: <double>[0, 0.52, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: radius * 1.55)),
    );
    canvas.restore();

    // A faint warm wash inside the beam, so the lit water looks lit rather
    // than merely uncovered.
    canvas.drawCircle(
      centre,
      radius * 1.3,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            KidUi.hint.withValues(alpha: 0.16),
            KidUi.hint.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: radius * 1.3)),
    );
  }

  @override
  bool shouldRepaint(_DarkWaterPainter old) =>
      old.beam != beam ||
      old.radiusFraction != radiusFraction ||
      old.accent != accent;
}

/// The torch itself: drag it to look, drag the ring to open it wider.
///
/// The widening gesture is a drag outward and a plain tap, never a pinch.
/// Pinch needs two fingers held steady on a small screen, which is beyond a
/// lot of four-year-olds, and the tap alternative means the beam can always be
/// opened with the single pointer WCAG 2.2 SC 2.5.7 requires.
class _BeamHandle extends StatelessWidget {
  const _BeamHandle({
    required this.size,
    required this.accent,
    required this.canWiden,
    required this.atFullWidth,
    required this.onWiden,
    required this.onDrag,
    required this.onWidenDrag,
  });

  final double size;
  final Color accent;
  final bool canWiden;
  final bool atFullWidth;
  final VoidCallback onWiden;
  final void Function(Offset delta) onDrag;
  final void Function(double outward) onWidenDrag;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'the light',
      hint: canWiden && !atFullWidth
          ? 'drag to move it, tap to make it bigger'
          : 'drag to move it',
      button: true,
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails d) => onDrag(d.delta),
        onTap: canWiden && !atFullWidth ? onWiden : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KidUi.hint.withValues(alpha: 0.9),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: KidUi.hint.withValues(alpha: 0.6),
                      blurRadius: size * 0.4,
                      spreadRadius: size * 0.05,
                    ),
                  ],
                ),
              ),
              if (canWiden)
                // The ring is the affordance for "bigger": dragging it away
                // from the centre opens the beam, which is the same direction
                // the light then grows in.
                GestureDetector(
                  onPanUpdate: (DragUpdateDetails d) {
                    final Offset from = Offset(size / 2, size / 2);
                    final Offset at = d.localPosition;
                    onWidenDrag((at - from).distance > size * 0.3
                        ? d.delta.distance
                        : -d.delta.distance);
                  },
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (atFullWidth ? accent : KidUi.hint)
                            .withValues(alpha: atFullWidth ? 0.35 : 0.75),
                        width: 3,
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
