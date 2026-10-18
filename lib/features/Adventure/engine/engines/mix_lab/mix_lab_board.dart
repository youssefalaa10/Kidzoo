import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/engines/mix_lab/mix_lab_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/mix_lab/mix_lab_cubit.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';

/// A vessel, the colour to make, and the inks.
///
/// Tapping an ink puts it in; tapping it again takes it out. The vessel shows
/// what is in it *now*, so every combination is an experiment with a visible
/// result before anything is judged. Only the commit button answers.
///
/// Mixing is never shown as a formula. The target is a colour, not a recipe,
/// and the only way to learn that yellow and blue make green is to try it.
class MixLabBoard extends StatefulWidget {
  const MixLabBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final MixStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<MixLabBoard> createState() => _MixLabBoardState();
}

class _MixLabBoardState extends State<MixLabBoard> {
  final Set<String> _inVessel = <String>{};

  @override
  void didUpdateWidget(MixLabBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      _inVessel.clear();
    }
  }

  MixLabContent get _content => widget.step.content;

  bool get _locked => widget.state.isBoardLocked;

  String get _language => widget.state.languageCode;

  Color get _accent => _content.accentColorValue == null
      ? KidUi.primary
      : Color(_content.accentColorValue!);

  Set<String> get _pointed {
    final String? raw = widget.state.view?.highlightOptionId;
    return raw == null ? const <String>{} : raw.split('+').toSet();
  }

  void _toggle(String inkId) {
    if (_locked) {
      return;
    }
    setState(() {
      if (!_inVessel.remove(inkId)) {
        _inVessel.add(inkId);
      }
    });
  }

  void _commit() {
    if (_locked || _inVessel.isEmpty) {
      return;
    }
    widget.submit(SequenceAttempt(_inVessel.toList()..sort()));
  }

  @override
  Widget build(BuildContext context) {
    final MixResult? now = _content.resultOf(_inVessel);
    final Color mixColor =
        Color(now?.colorValue ?? _content.emptyColorValue);
    final MixResult target = widget.step.target;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360;
        final double height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 480;
        final bool wide = width > height * 1.3;
        final int buttons = _content.inks.length + 1;
        final double controlWidth = wide ? width * 0.5 : width;
        final double button = ((controlWidth - 12.0 * buttons) / buttons)
            .clamp(48.0, KidUi.minTouch * 1.1);
        final double controlsHeight = wide ? height : button * 1.7;
        final double vesselBox = wide
            ? math.min(width - controlWidth, height)
            : math.max(0, math.min(width, height - controlsHeight - 8));

        final Widget vessel = _VesselArea(
          side: vesselBox,
          mixColor: mixColor,
          targetColor: Color(target.colorValue),
          vesselImage: _content.vesselImage,
          label: now?.label.resolve(_language) ?? '',
          language: _language,
          accent: _accent,
        );
        final Widget controls = SizedBox(
          width: controlWidth,
          height: controlsHeight,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              for (final MixInk ink in _content.inks)
                _InkButton(
                  size: button,
                  color: Color(ink.colorValue),
                  label: ink.label.resolve(_language),
                  inVessel: _inVessel.contains(ink.id),
                  pointed: _pointed.contains(ink.id),
                  enabled: !_locked,
                  onTap: () => _toggle(ink.id),
                ),
              _CommitButton(
                size: button * 1.1,
                accent: _accent,
                enabled: !_locked && _inVessel.isNotEmpty,
                onTap: _commit,
              ),
            ],
          ),
        );
        return wide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[vessel, controls],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[vessel, controls],
              );
      },
    );
  }
}

/// The vessel, and beside it the colour it has to become.
class _VesselArea extends StatelessWidget {
  const _VesselArea({
    required this.side,
    required this.mixColor,
    required this.targetColor,
    required this.vesselImage,
    required this.label,
    required this.language,
    required this.accent,
  });

  final double side;
  final Color mixColor;
  final Color targetColor;
  final String? vesselImage;
  final String label;
  final String language;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double vessel = side * 0.62;
    final double swatch = side * 0.24;
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // An implicit tween: the colour eases between mixes with no
          // controller to own or dispose.
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: mixColor),
            duration: KidUi.medium,
            builder: (BuildContext context, Color? color, Widget? _) {
              final Color shown = color ?? mixColor;
              return Container(
                width: vessel,
                height: vessel,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: shown.withValues(alpha: 0.55),
                      blurRadius: vessel * 0.3,
                      spreadRadius: vessel * 0.02,
                    ),
                  ],
                ),
                child: vesselImage == null
                    ? DecoratedBox(
                        decoration:
                            BoxDecoration(shape: BoxShape.circle, color: shown))
                    : Image.asset(
                        vesselImage!,
                        fit: BoxFit.contain,
                        color: shown,
                        colorBlendMode: BlendMode.modulate,
                        cacheWidth: (vessel * 2).round(),
                      ),
              );
            },
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            child: Semantics(
              label: 'the colour to make',
              child: Container(
                width: swatch,
                height: swatch,
                padding: EdgeInsets.all(swatch * 0.12),
                decoration: BoxDecoration(
                  color: KidUi.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 3),
                ),
                child: vesselImage == null
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: targetColor))
                    : Image.asset(
                        vesselImage!,
                        color: targetColor,
                        colorBlendMode: BlendMode.modulate,
                        cacheWidth: (swatch * 2).round(),
                      ),
              ),
            ),
          ),
          if (label.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ActivityGlyphText(
                label,
                languageCode: language,
                fontSize: math.max(12, side * 0.07),
                color: KidUi.surface,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _InkButton extends StatelessWidget {
  const _InkButton({
    required this.size,
    required this.color,
    required this.label,
    required this.inVessel,
    required this.pointed,
    required this.enabled,
    required this.onTap,
  });

  final double size;
  final Color color;
  final String label;
  final bool inVessel;
  final bool pointed;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: inVessel,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: KidUi.fast,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: pointed
                  ? KidUi.hint
                  : (inVessel ? KidUi.surface : color.withValues(alpha: 0.4)),
              width: pointed || inVessel ? 5 : 2,
            ),
            boxShadow: <BoxShadow>[
              if (pointed)
                BoxShadow(
                  color: KidUi.hint.withValues(alpha: 0.7),
                  blurRadius: size * 0.35,
                ),
            ],
          ),
          // "In" reads as a tick on the drop, so the vessel's contents are
          // legible without the colour-naming a pre-reader cannot do.
          child: inVessel
              ? Icon(Icons.check_rounded,
                  color: KidUi.surface, size: size * 0.5)
              : null,
        ),
      ),
    );
  }
}

class _CommitButton extends StatelessWidget {
  const _CommitButton({
    required this.size,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final double size;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'use this',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: KidUi.fast,
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              border: Border.all(color: KidUi.surface, width: 3),
            ),
            child: Icon(Icons.flare_rounded,
                color: KidUi.surface, size: size * 0.55),
          ),
        ),
      ),
    );
  }
}
