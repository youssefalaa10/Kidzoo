import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_cubit.dart';

/// The counting board: a scene to count, and numerals to answer with.
class CountingBoard extends StatefulWidget {
  const CountingBoard({
    required this.step,
    required this.state,
    required this.submit,
    required this.languageCode,
    super.key,
  });

  final CountingStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;
  final String languageCode;

  @override
  State<CountingBoard> createState() => _CountingBoardState();
}

class _CountingBoardState extends State<CountingBoard> {
  /// Which scene items the child has tagged.
  ///
  /// This is not decoration. The one-to-one principle says every counted object
  /// needs a visible state change as it is tagged; without one, children
  /// double-count and lose track. Tapping an item marks it and does **not**
  /// submit an answer — the count is a separate act from stating the total.
  final Set<int> _taggedIndexes = <int>{};

  @override
  void didUpdateWidget(CountingBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      _taggedIndexes.clear();
    }
  }

  void _toggleTag(int index) {
    setState(() {
      if (!_taggedIndexes.remove(index)) {
        _taggedIndexes.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final KidMetrics metrics = KidMetrics.of(constraints);
        // Numerals need a fixed, generous strip; the scene takes the rest.
        final double padHeight = metrics.size(120, min: 96, max: 150);
        return Column(
          children: <Widget>[
            Expanded(
              child: _CountingScene(
                step: widget.step,
                taggedIndexes: _taggedIndexes,
                onTapItem: _toggleTag,
              ),
            ),
            SizedBox(height: metrics.gap * 0.5),
            SizedBox(
              height: padHeight,
              child: _NumeralPad(
                step: widget.step,
                state: widget.state,
                metrics: metrics,
                languageCode: widget.languageCode,
                onPick: (int value) => widget.submit(QuantityAttempt(value)),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Lays the countable items out according to the step's layout.
class _CountingScene extends StatelessWidget {
  const _CountingScene({
    required this.step,
    required this.taggedIndexes,
    required this.onTapItem,
  });

  final CountingStep step;
  final Set<int> taggedIndexes;
  final void Function(int index) onTapItem;

  /// Dice pip positions, in normalized scene coordinates.
  static const Map<int, List<Offset>> _dicePatterns = <int, List<Offset>>{
    1: <Offset>[Offset(0.5, 0.5)],
    2: <Offset>[Offset(0.28, 0.28), Offset(0.72, 0.72)],
    3: <Offset>[Offset(0.25, 0.25), Offset(0.5, 0.5), Offset(0.75, 0.75)],
    4: <Offset>[
      Offset(0.28, 0.28),
      Offset(0.72, 0.28),
      Offset(0.28, 0.72),
      Offset(0.72, 0.72),
    ],
    5: <Offset>[
      Offset(0.25, 0.25),
      Offset(0.75, 0.25),
      Offset(0.5, 0.5),
      Offset(0.25, 0.75),
      Offset(0.75, 0.75),
    ],
    6: <Offset>[
      Offset(0.27, 0.2),
      Offset(0.27, 0.5),
      Offset(0.27, 0.8),
      Offset(0.73, 0.2),
      Offset(0.73, 0.5),
      Offset(0.73, 0.8),
    ],
  };

  List<Offset> _positionsFor(int count, CountingLayout layout) {
    switch (layout) {
      case CountingLayout.dice:
        final List<Offset>? pattern = _dicePatterns[count];
        if (pattern != null) {
          return pattern;
        }
        return _positionsFor(count, CountingLayout.tenFrame);
      case CountingLayout.tenFrame:
        return List<Offset>.generate(count, (int index) {
          final int column = index % 5;
          final int row = index ~/ 5;
          return Offset(0.14 + column * 0.18, count > 5 ? 0.33 + row * 0.34 : 0.5);
        });
      case CountingLayout.linear:
        return List<Offset>.generate(count, (int index) {
          final double spacing = 1 / (count + 1);
          return Offset(spacing * (index + 1), 0.5);
        });
      case CountingLayout.scatter:
        // Deterministic but irregular: two interleaved rows, offset so the eye
        // cannot sweep them as a single line.
        return List<Offset>.generate(count, (int index) {
          final double x = 0.13 + (index % 4) * 0.25;
          final double y = 0.3 + (index ~/ 4) * 0.3 + (index.isEven ? 0 : 0.1);
          return Offset(x, y.clamp(0.15, 0.85));
        });
      case CountingLayout.random:
        return List<Offset>.generate(count, (int index) {
          // A fixed pseudo-scatter keyed on the index, so the scene is stable
          // across rebuilds — items that move while being counted are unfair.
          final double x = 0.12 + ((index * 37) % 76) / 100;
          final double y = 0.16 + ((index * 53) % 68) / 100;
          return Offset(x, y);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final List<Offset> positions =
            _positionsFor(step.targetCount, step.layout);
        // Big enough to hit reliably: young children miss small targets often
        // enough that a miss would otherwise read as a counting error.
        final double itemSize = (constraints.maxWidth / 6)
            .clamp(56.0, KidUi.minTouchYoung.toDouble());

        return Stack(
          children: <Widget>[
            for (int index = 0; index < positions.length; index++)
              Positioned(
                left: positions[index].dx * constraints.maxWidth - itemSize / 2,
                top: positions[index].dy * constraints.maxHeight - itemSize / 2,
                child: _CountableItem(
                  imageAsset: step.item.imageAsset,
                  size: itemSize,
                  isTagged: taggedIndexes.contains(index),
                  onTap: () => onTapItem(index),
                  semanticLabel: 'item ${index + 1}',
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One countable thing, which visibly changes when tagged.
class _CountableItem extends StatelessWidget {
  const _CountableItem({
    required this.imageAsset,
    required this.size,
    required this.isTagged,
    required this.onTap,
    required this.semanticLabel,
  });

  final String imageAsset;
  final double size;
  final bool isTagged;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isTagged,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () {
          KidHaptics.tap();
          onTap();
        },
        child: AnimatedContainer(
          duration: KidUi.fast,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // The tag is a ring plus a check, not just a colour shift: colour
            // alone is invisible to a colour-blind child and easy to miss.
            border: Border.all(
              color: isTagged ? KidUi.primary : Colors.transparent,
              width: isTagged ? 4 : 0,
            ),
            color: isTagged
                ? KidUi.primary.withValues(alpha: 0.18)
                : Colors.transparent,
          ),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(size * 0.1),
                child: Image.asset(imageAsset, fit: BoxFit.contain),
              ),
              if (isTagged)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: KidUi.primary,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(size * 0.06),
                    child: Icon(
                      Icons.check_rounded,
                      size: size * 0.22,
                      color: Colors.white,
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

/// The numerals the child answers with.
class _NumeralPad extends StatelessWidget {
  const _NumeralPad({
    required this.step,
    required this.state,
    required this.metrics,
    required this.languageCode,
    required this.onPick,
  });

  final CountingStep step;
  final ActivityState state;
  final KidMetrics metrics;
  final String languageCode;
  final void Function(int value) onPick;

  /// Eastern Arabic-Indic digits for Arabic, Western otherwise.
  ///
  /// Formatted here rather than by the engine, so digit choice is a host
  /// concern and every engine gets it right for free.
  static String formatDigits(int value, String languageCode) {
    if (languageCode != 'ar') {
      return '$value';
    }
    const List<String> easternDigits = <String>[
      '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩',
    ];
    return value
        .toString()
        .split('')
        .map((String digit) => easternDigits[int.parse(digit)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final ActivityStepView? view = state.view;
    final List<String> live = view?.liveOptionIds ?? const <String>[];
    final String? highlight = view?.highlightOptionId;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (final int value in step.numeralOptions)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: metrics.gap * 0.35),
            child: _NumeralButton(
              label: formatDigits(value, languageCode),
              size: metrics.size(92, min: 72, max: KidUi.minTouchYoung + 16),
              // Options removed by the ladder stay in place and fade. Removing
              // them would reflow the row under a finger already in motion.
              isLive: live.isEmpty || live.contains(step.optionIdFor(value)),
              isHighlighted: highlight == step.optionIdFor(value),
              onTap: () => onPick(value),
            ),
          ),
      ],
    );
  }
}

class _NumeralButton extends StatelessWidget {
  const _NumeralButton({
    required this.label,
    required this.size,
    required this.isLive,
    required this.isHighlighted,
    required this.onTap,
  });

  final String label;
  final double size;
  final bool isLive;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isLive,
      label: label,
      child: AnimatedOpacity(
        duration: KidUi.medium,
        opacity: isLive ? 1 : 0.28,
        child: GestureDetector(
          onTap: isLive
              ? () {
                  KidHaptics.tap();
                  onTap();
                }
              : null,
          child: AnimatedContainer(
            duration: KidUi.fast,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(KidUi.radiusCard),
              border: Border.all(
                color: isHighlighted ? KidUi.primary : Colors.transparent,
                width: isHighlighted ? 5 : 0,
              ),
              boxShadow: KidUi.shadow(KidUi.primary,
                  strength: isHighlighted ? 1.2 : 0.7),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * 0.46,
                fontWeight: FontWeight.w800,
                color: KidUi.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
