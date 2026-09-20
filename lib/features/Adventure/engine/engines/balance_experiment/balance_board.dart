import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/engines/balance_experiment/balance_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/balance_experiment/balance_engine.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';

/// A beam, two pans, and a counter of things to put on them.
///
/// Everything here is reversible until the child says they are done. Adding
/// and removing are not attempts, they are the experiment; only handing the
/// pan over is an answer. That split is the whole design, and it is why this
/// board reports most of what the child does as a tally rather than as a try.
class BalanceBoard extends StatefulWidget {
  const BalanceBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final BalanceStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<BalanceBoard> createState() => _BalanceBoardState();
}

class _BalanceBoardState extends State<BalanceBoard> {
  /// What is on the pan, in the order it was put there, so the newest thing is
  /// the easiest to take back off.
  final List<WeighedItem> _onPan = <WeighedItem>[];

  /// Set while the correct load is being shown rather than built.
  bool _isGhosting = false;

  int get _total =>
      _onPan.fold(0, (int sum, WeighedItem item) => sum + item.weight);

  bool get _isLevel => widget.step.isLevel(_total);

  @override
  void didUpdateWidget(BalanceBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      setState(() {
        _onPan.clear();
        _isGhosting = false;
      });
    }
    if (!oldWidget.state.isDemonstrating && widget.state.isDemonstrating) {
      _demonstrate();
    }
  }

  /// Fills the pan with a working load so the child can see it come level,
  /// then empties it so they do it themselves.
  void _demonstrate() {
    final List<WeighedItem> solution = widget.step.round.oneSolution;
    if (solution.isEmpty) {
      return;
    }
    setState(() {
      _onPan
        ..clear()
        ..addAll(solution);
      _isGhosting = true;
    });
  }

  void _add(WeighedItem item) {
    if (widget.state.isBoardLocked) {
      return;
    }
    KidHaptics.tap();
    setState(() {
      _isGhosting = false;
      _onPan.add(item);
    });
    // Not an answer, and deliberately not judged: the cubit says the new total
    // out loud and nothing else happens. A child who hears "one... three...
    // five" as they load a pan is doing the counting the activity is for.
    widget.submit(TallyAttempt(_total));
  }

  void _removeAt(int index) {
    if (widget.state.isBoardLocked || index >= _onPan.length) {
      return;
    }
    KidHaptics.tap();
    setState(() {
      _isGhosting = false;
      _onPan.removeAt(index);
    });
    if (_total > 0) {
      widget.submit(TallyAttempt(_total));
    }
  }

  /// The one action that counts as an answer.
  void _handOver() {
    if (widget.state.isBoardLocked || _onPan.isEmpty) {
      return;
    }
    KidHaptics.tap();
    widget.submit(QuantityAttempt(_total));
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.step.accentColorValue == null
        ? KidUi.primary
        : Color(widget.step.accentColorValue!);
    final String? highlighted = widget.state.view?.highlightOptionId;
    final String languageCode = widget.state.languageCode;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final KidMetrics metrics = KidMetrics.of(constraints);
        // The counter and the hand-over control are laid out first and the
        // scale takes the rest, so a short landscape window loses beam height
        // rather than losing the things the child touches.
        final double idealEdge =
            metrics.size(KidUi.minTouchYoung, min: 64, max: 128);
        final double trayEdge = <double>[
          idealEdge,
          constraints.maxHeight * 0.3,
        ].reduce((double a, double b) => a < b ? a : b);

        return Column(
          children: <Widget>[
            Expanded(
              child: _Scale(
                target: widget.step.round.target,
                total: _total,
                tolerance: widget.step.tolerance,
                onPan: _onPan,
                accent: accent,
                languageCode: languageCode,
                unitLabel: widget.step.unitLabel.resolve(languageCode),
                targetImage: widget.step.targetImage,
                isGhosting: _isGhosting,
                onRemoveAt: _removeAt,
              ),
            ),
            SizedBox(height: metrics.gap * 0.5),
            _Counter(
              items: widget.step.round.available,
              edge: trayEdge,
              accent: accent,
              languageCode: languageCode,
              highlightedId: highlighted,
              isEnabled: !widget.state.isBoardLocked,
              onPick: _add,
            ),
            SizedBox(height: metrics.gap * 0.5),
            _HandOverButton(
              edge: trayEdge * 0.82,
              accent: accent,
              // Level is a suggestion, not a gate. The control works whatever
              // the beam says, because a child who hands over the wrong load
              // should be answered by the seller rather than by a button that
              // silently refused to be pressed.
              isReady: _isLevel,
              isEnabled: !widget.state.isBoardLocked && _onPan.isNotEmpty,
              onTap: _handOver,
            ),
          ],
        );
      },
    );
  }
}

/// The beam itself.
class _Scale extends StatelessWidget {
  const _Scale({
    required this.target,
    required this.total,
    required this.tolerance,
    required this.onPan,
    required this.accent,
    required this.languageCode,
    required this.unitLabel,
    required this.targetImage,
    required this.isGhosting,
    required this.onRemoveAt,
  });

  final int target;
  final int total;
  final int tolerance;
  final List<WeighedItem> onPan;
  final Color accent;
  final String languageCode;
  final String unitLabel;
  final String? targetImage;
  final bool isGhosting;
  final void Function(int index) onRemoveAt;

  /// How far the beam leans, in turns.
  ///
  /// Saturating rather than proportional: two units over and ten units over
  /// both look "much too heavy", which is what a real beam does and what makes
  /// the small differences near level readable.
  double get _tilt {
    if ((total - target).abs() <= tolerance) {
      return 0;
    }
    final double ratio = (total - target) / max(target, 1);
    return (ratio.clamp(-1.0, 1.0)) * 0.055;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        // Sized against **both** axes. Taking a third of the width alone gives
        // a 220dp pan inside a 130dp-tall band in phone landscape, which is
        // how a scale that fitted in portrait overflowed the moment the phone
        // was turned. A pan is a square-ish object; it has to answer to the
        // shorter side.
        final double panEdge = <double>[
          width * 0.34,
          constraints.maxHeight * 0.78,
        ].reduce((double a, double b) => a < b ? a : b).clamp(72.0, 220.0);
        final bool isLevel = _tilt == 0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: AnimatedRotation(
                duration: KidUi.medium,
                curve: Curves.easeOut,
                turns: _tilt,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _Pan(
                        edge: panEdge,
                        accent: accent,
                        isGhosting: false,
                        child: _TargetFace(
                          target: target,
                          accent: accent,
                          languageCode: languageCode,
                          unitLabel: unitLabel,
                          image: targetImage,
                          edge: panEdge,
                        ),
                      ),
                    ),
                    Container(
                      width: width * 0.1,
                      height: panEdge * 0.06,
                      decoration: BoxDecoration(
                        color: isLevel ? KidUi.correct : KidUi.bark,
                        borderRadius: BorderRadius.circular(KidUi.radiusPill),
                      ),
                    ),
                    Expanded(
                      child: _Pan(
                        edge: panEdge,
                        accent: accent,
                        isGhosting: isGhosting,
                        child: _LoadedFace(
                          onPan: onPan,
                          edge: panEdge,
                          accent: accent,
                          total: total,
                          languageCode: languageCode,
                          onRemoveAt: onRemoveAt,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Pan extends StatelessWidget {
  const _Pan({
    required this.edge,
    required this.accent,
    required this.isGhosting,
    required this.child,
  });

  final double edge;
  final Color accent;
  final bool isGhosting;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: isGhosting ? 0.5 : 1,
        child: Container(
          width: edge,
          height: edge * 0.86,
          padding: EdgeInsets.all(edge * 0.07),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(edge * 0.08),
              bottom: Radius.circular(edge * 0.34),
            ),
            boxShadow: KidUi.shadow(accent, strength: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// What the order asks for, as a number the child can read off the pan.
class _TargetFace extends StatelessWidget {
  const _TargetFace({
    required this.target,
    required this.accent,
    required this.languageCode,
    required this.unitLabel,
    required this.image,
    required this.edge,
  });

  final int target;
  final Color accent;
  final String languageCode;
  final String unitLabel;
  final String? image;
  final double edge;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (image != null)
          Flexible(child: Image.asset(image!, fit: BoxFit.contain)),
        ActivityGlyphText(
          '$target',
          languageCode: languageCode,
          fontSize: edge * 0.3,
          color: accent,
          maxLines: 1,
        ),
        if (unitLabel.isNotEmpty)
          ActivityGlyphText(
            unitLabel,
            languageCode: languageCode,
            fontSize: edge * 0.11,
            color: KidUi.inkSoft,
            maxLines: 1,
          ),
      ],
    );
  }
}

/// What is on the pan, and the running total beneath it.
class _LoadedFace extends StatelessWidget {
  const _LoadedFace({
    required this.onPan,
    required this.edge,
    required this.accent,
    required this.total,
    required this.languageCode,
    required this.onRemoveAt,
  });

  final List<WeighedItem> onPan;
  final double edge;
  final Color accent;
  final int total;
  final String languageCode;
  final void Function(int index) onRemoveAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: edge * 0.03,
            runSpacing: edge * 0.03,
            children: <Widget>[
              for (int index = 0; index < onPan.length; index++)
                Semantics(
                  button: true,
                  label: onPan[index].label.resolve(languageCode),
                  child: GestureDetector(
                    // Tapping something on the pan takes it back off. Undoing
                    // has to be as easy as doing, or experimenting stops being
                    // free and starts being a commitment.
                    onTap: () => onRemoveAt(index),
                    child: Image.asset(
                      onPan[index].imageAsset,
                      width: edge * 0.26,
                      height: edge * 0.26,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ActivityGlyphText(
          '$total',
          languageCode: languageCode,
          fontSize: edge * 0.22,
          color: accent,
          maxLines: 1,
        ),
      ],
    );
  }
}

/// What is on the counter to choose from.
class _Counter extends StatelessWidget {
  const _Counter({
    required this.items,
    required this.edge,
    required this.accent,
    required this.languageCode,
    required this.highlightedId,
    required this.isEnabled,
    required this.onPick,
  });

  final List<WeighedItem> items;
  final double edge;
  final Color accent;
  final String languageCode;
  final String? highlightedId;
  final bool isEnabled;
  final void Function(WeighedItem) onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: edge * 0.12,
      runSpacing: edge * 0.12,
      children: <Widget>[
        for (final WeighedItem item in items)
          Semantics(
            button: true,
            enabled: isEnabled,
            label: item.label.resolve(languageCode),
            child: GestureDetector(
              onTap: isEnabled ? () => onPick(item) : null,
              // Tap, not drag. Both work for a pan this size, but only one of
              // them works reliably for a four-year-old, so the tap is the
              // primary route rather than the fallback.
              child: AnimatedContainer(
                duration: KidUi.fast,
                width: edge,
                height: edge,
                padding: EdgeInsets.all(edge * 0.1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isEnabled ? 0.94 : 0.5),
                  borderRadius: BorderRadius.circular(edge * 0.24),
                  border: Border.all(
                    color:
                        highlightedId == item.id ? KidUi.hint : Colors.transparent,
                    width: highlightedId == item.id ? edge * 0.07 : 0,
                  ),
                  boxShadow: KidUi.shadow(accent, strength: 0.5),
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Image.asset(item.imageAsset, fit: BoxFit.contain),
                    ),
                    // The weight, on the thing itself. A child cannot plan a
                    // load out of objects whose size they have to remember.
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: edge * 0.1,
                          vertical: edge * 0.02,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius:
                              BorderRadius.circular(KidUi.radiusPill),
                        ),
                        child: ActivityGlyphText(
                          '${item.weight}',
                          languageCode: languageCode,
                          fontSize: edge * 0.2,
                          color: Colors.white,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HandOverButton extends StatelessWidget {
  const _HandOverButton({
    required this.edge,
    required this.accent,
    required this.isReady,
    required this.isEnabled,
    required this.onTap,
  });

  final double edge;
  final Color accent;

  /// True when the beam is level. Changes how the control *looks*, never
  /// whether it works.
  final bool isReady;

  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: 'Hand it over',
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: AnimatedContainer(
          duration: KidUi.medium,
          height: edge,
          width: edge * 2.4,
          decoration: BoxDecoration(
            color: isReady ? KidUi.correct : accent.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(KidUi.radiusPill),
            boxShadow: KidUi.shadow(
              isReady ? KidUi.correct : accent,
              strength: isReady ? 0.9 : 0.4,
            ),
          ),
          child: Opacity(
            opacity: isEnabled ? 1 : 0.4,
            child: Icon(
              Icons.pan_tool_alt_rounded,
              size: edge * 0.52,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
