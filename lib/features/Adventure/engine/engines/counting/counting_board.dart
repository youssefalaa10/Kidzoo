import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_cubit.dart';
import 'package:kidzo/features/Adventure/engine/support/number_words.dart';

/// The counting board: a scene to count, a running tally, and numerals to
/// answer with.
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
  /// Which scene items the child has tagged, **in the order they tagged them**.
  ///
  /// Order, not a set. The one-to-one principle says every counted object needs
  /// a visible state change as it is tagged, and the state change that actually
  /// teaches is the *ordinal*: this one is the first, this one is the second.
  /// A set could only say "counted", which leaves a child who loses their place
  /// no way to recover it without starting over.
  ///
  /// Tapping an item marks it and does **not** submit an answer — stating the
  /// total is a separate act from counting, and conflating them is how a board
  /// ends up answering on the child's behalf.
  final List<int> _tagOrder = <int>[];

  @override
  void didUpdateWidget(CountingBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      _tagOrder.clear();
    }
  }

  /// Counts [index] once, and only once.
  ///
  /// Re-tapping something already counted does nothing to the tally. That is
  /// the single most common way a young child's count goes wrong — touching the
  /// same object twice and carrying on — and the old toggle behaviour made it
  /// worse than a no-op: the second tap silently *removed* the item from the
  /// count, so a child who double-tapped ended up one short with no idea why.
  void _count(int index) {
    if (_tagOrder.contains(index)) {
      // Acknowledged so the tap does not feel dead, but the number does not
      // move. The badge already on the item is the explanation.
      KidHaptics.tap();
      return;
    }
    KidHaptics.tap();
    setState(() => _tagOrder.add(index));
    // The cubit owns the narrator, so the board reports and it speaks.
    widget.submit(TallyAttempt(_tagOrder.length));
  }

  void _resetCount() {
    if (_tagOrder.isEmpty) {
      return;
    }
    KidHaptics.tap();
    setState(_tagOrder.clear);
  }

  @override
  Widget build(BuildContext context) {
    // "How many are there?" and "bring me five" are two different questions,
    // and only the second one tests cardinality — a child can recite
    // "one, two, three" over three objects without yet understanding that
    // *three* is the set. The mode was in the content schema from the start
    // with no board behind it, which meant an author could ask for the harder
    // question and silently get the easier one.
    if (widget.step.mode == CountingMode.giveN) {
      return _GiveNBoard(
        step: widget.step,
        state: widget.state,
        submit: widget.submit,
        languageCode: widget.languageCode,
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final KidMetrics metrics = KidMetrics.of(constraints);
        final double padHeight = metrics.size(124, min: 100, max: 168);
        final bool isAllCounted = _tagOrder.length == widget.step.targetCount;

        return Column(
          children: <Widget>[
            _TallyStrip(
              metrics: metrics,
              count: _tagOrder.length,
              isComplete: isAllCounted,
              languageCode: widget.languageCode,
              itemAsset: widget.step.item.imageAsset,
              onReset: _tagOrder.isEmpty ? null : _resetCount,
            ),
            SizedBox(height: metrics.gap * 0.4),
            Expanded(
              child: _CountingScene(
                step: widget.step,
                tagOrder: _tagOrder,
                languageCode: widget.languageCode,
                onTapItem: _count,
              ),
            ),
            SizedBox(height: metrics.gap * 0.4),
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

/// The running total, shown as it grows.
///
/// A count a child cannot see is a count they have to hold in their head, and
/// holding a number in your head while also tracking which animals you already
/// touched is two jobs. Showing it makes the activity about the counting rather
/// than about the remembering.
class _TallyStrip extends StatelessWidget {
  const _TallyStrip({
    required this.metrics,
    required this.count,
    required this.isComplete,
    required this.languageCode,
    required this.itemAsset,
    required this.onReset,
  });

  final KidMetrics metrics;
  final int count;
  final bool isComplete;
  final String languageCode;
  final String itemAsset;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final double height = metrics.size(64, min: 54, max: 84);
    // Complete turns the strip solid rather than only recolouring it, so the
    // "that is all of them" moment survives colour-blindness and a dim screen.
    final Color background = isComplete ? KidUi.correct : Colors.white;
    final Color foreground = isComplete ? Colors.white : KidUi.ink;

    return Semantics(
      liveRegion: true,
      label: '$count',
      child: AnimatedContainer(
        duration: KidUi.medium,
        height: height,
        padding: EdgeInsets.symmetric(
            horizontal: metrics.size(14, min: 10, max: 20)),
        decoration: BoxDecoration(
          color: background.withValues(alpha: isComplete ? 0.95 : 0.92),
          borderRadius: BorderRadius.circular(KidUi.radiusPill),
          boxShadow: KidUi.shadow(
            isComplete ? KidUi.correct : KidUi.primary,
            strength: isComplete ? 1.2 : 0.6,
          ),
        ),
        child: Row(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(height * 0.12),
              child: Image.asset(itemAsset, height: height * 0.72),
            ),
            SizedBox(width: metrics.gap * 0.4),
            // The number itself, big. It is the only thing on this strip a
            // pre-reader can actually read.
            KeyedSubtree(
              key: countTotalKey,
              child: AnimatedSwitcher(
                duration: KidUi.fast,
                transitionBuilder:
                    (Widget child, Animation<double> animation) =>
                        ScaleTransition(scale: animation, child: child),
                child: Text(
                  NumberWords.digits(count, languageCode),
                  key: ValueKey<int>(count),
                  style: TextStyle(
                    fontSize: height * 0.58,
                    fontWeight: FontWeight.w900,
                    color: foreground,
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (isComplete)
              Icon(Icons.check_circle_rounded,
                  size: height * 0.5, color: foreground),
            if (onReset != null) ...<Widget>[
              SizedBox(width: metrics.gap * 0.3),
              Semantics(
                button: true,
                label: 'reset count',
                child: GestureDetector(
                  key: countResetKey,
                  onTap: onReset,
                  child: Container(
                    width: height * 0.76,
                    height: height * 0.76,
                    decoration: BoxDecoration(
                      color: foreground.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.refresh_rounded,
                        size: height * 0.42, color: foreground),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Where each countable item sits, and how big it can be.
@immutable
class _SceneLayout {
  const _SceneLayout({required this.centres, required this.itemSize});

  /// Centres in pixels within the scene box.
  final List<Offset> centres;
  final double itemSize;
}

/// Lays the countable items out according to the step's layout.
class _CountingScene extends StatelessWidget {
  const _CountingScene({
    required this.step,
    required this.tagOrder,
    required this.languageCode,
    required this.onTapItem,
  });

  final CountingStep step;
  final List<int> tagOrder;
  final String languageCode;
  final void Function(int index) onTapItem;

  /// Dice pip positions, normalized within the scene box.
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

  /// The smallest a countable object is ever allowed to get.
  ///
  /// A counting target is a *primary* target: the child aims at it to do the
  /// activity, so it answers to [KidUi.minTouchYoung], not to the adult 48dp
  /// minimum. The previous board clamped the **maximum** to that number, which
  /// is the same constant used backwards — it treated the young-child floor as
  /// a ceiling and so produced 56dp animals on a phone.
  static const double _minItem = 76;
  static const double _maxItem = 168;

  /// Grid-shaped layouts place items in real cells and take the largest size
  /// the cell allows, which is what keeps five animals on a small phone legible
  /// without letting three animals on a tablet balloon.
  _SceneLayout _gridLayout(int count, Size box, {required int maxColumns}) {
    final int columns = math.min(count, maxColumns);
    final int rows = (count / columns).ceil();
    final double cellWidth = box.width / columns;
    final double cellHeight = box.height / rows;
    final double size = math
        .min(cellWidth * 0.84, cellHeight * (rows == 1 ? 0.8 : 0.84))
        .clamp(_minItem, _maxItem);

    final List<Offset> centres = <Offset>[];
    for (int index = 0; index < count; index++) {
      final int column = index % columns;
      final int row = index ~/ columns;
      // The last row is centred rather than left-packed, so a 7 does not read
      // as "a full row and a stray".
      final int itemsInRow = math.min(columns, count - row * columns);
      final double rowWidth = itemsInRow * cellWidth;
      final double rowLeft = (box.width - rowWidth) / 2;
      centres.add(Offset(
        rowLeft + (column + 0.5) * cellWidth,
        (row + 0.5) * cellHeight,
      ));
    }
    return _SceneLayout(centres: centres, itemSize: size);
  }

  _SceneLayout _freeLayout(List<Offset> normalized, Size box) {
    // A free arrangement has no cells to measure against, so size comes from
    // the closest pair: whatever keeps the two nearest items from overlapping.
    double closest = double.infinity;
    for (int a = 0; a < normalized.length; a++) {
      for (int b = a + 1; b < normalized.length; b++) {
        final Offset delta = Offset(
          (normalized[a].dx - normalized[b].dx) * box.width,
          (normalized[a].dy - normalized[b].dy) * box.height,
        );
        closest = math.min(closest, delta.distance);
      }
    }
    final double size =
        (closest.isFinite ? closest * 0.92 : box.shortestSide * 0.4)
            .clamp(_minItem, _maxItem);
    return _SceneLayout(
      centres: normalized
          .map((Offset p) => Offset(p.dx * box.width, p.dy * box.height))
          .toList(growable: false),
      itemSize: size,
    );
  }

  _SceneLayout _layoutFor(int count, CountingLayout layout, Size box) {
    switch (layout) {
      case CountingLayout.dice:
        final List<Offset>? pattern = _dicePatterns[count];
        if (pattern != null) {
          return _freeLayout(pattern, box);
        }
        return _layoutFor(count, CountingLayout.tenFrame, box);
      case CountingLayout.tenFrame:
        return _gridLayout(count, box, maxColumns: 5);
      case CountingLayout.linear:
        return _gridLayout(count, box, maxColumns: count);
      case CountingLayout.scatter:
        // Deterministic but irregular: interleaved rows, offset so the eye
        // cannot sweep them as a single line.
        return _freeLayout(
          List<Offset>.generate(count, (int index) {
            final double x = 0.15 + (index % 4) * 0.23;
            final double y =
                0.28 + (index ~/ 4) * 0.3 + (index.isEven ? 0 : 0.1);
            return Offset(x, y.clamp(0.18, 0.82));
          }),
          box,
        );
      case CountingLayout.random:
        return _freeLayout(
          List<Offset>.generate(count, (int index) {
            // A fixed pseudo-scatter keyed on the index, so the scene is stable
            // across rebuilds — items that move while being counted are unfair.
            final double x = 0.14 + ((index * 37) % 72) / 100;
            final double y = 0.18 + ((index * 53) % 64) / 100;
            return Offset(x, y);
          }),
          box,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size box = Size(constraints.maxWidth, constraints.maxHeight);
        final _SceneLayout layout =
            _layoutFor(step.targetCount, step.layout, box);
        final double size = layout.itemSize;

        return Stack(
          children: <Widget>[
            for (int index = 0; index < layout.centres.length; index++)
              Positioned(
                left: layout.centres[index].dx - size / 2,
                top: layout.centres[index].dy - size / 2,
                child: _CountableItem(
                  // Stable per position, so a test (and a screen reader) can
                  // name one object across taps even as its badge appears.
                  key: countableKey(index),
                  imageAsset: step.item.imageAsset,
                  size: size,
                  // 1-based: the badge shows the child what number this object
                  // landed on, which is the whole lesson.
                  ordinal: tagOrder.indexOf(index) + 1,
                  languageCode: languageCode,
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

/// Identifies the countable object at [index] within the scene.
ValueKey<String> countableKey(int index) =>
    ValueKey<String>('countable_$index');

/// Identifies the control that starts the count over.
const ValueKey<String> countResetKey = ValueKey<String>('count_reset');

/// Identifies the running-total number on the tally strip.
///
/// Named because the count appears in two places at once — here, and as an
/// ordinal badge on each object the child has touched — so "find the text 2"
/// is ambiguous by design.
const ValueKey<String> countTotalKey = ValueKey<String>('count_total');

/// One countable thing, which visibly changes when counted.
class _CountableItem extends StatelessWidget {
  const _CountableItem({
    required this.imageAsset,
    required this.size,
    required this.ordinal,
    required this.languageCode,
    required this.onTap,
    required this.semanticLabel,
    super.key,
  });

  final String imageAsset;
  final double size;

  /// The number this object landed on, or 0 when it has not been counted.
  final int ordinal;

  final String languageCode;
  final VoidCallback onTap;
  final String semanticLabel;

  bool get _isCounted => ordinal > 0;

  @override
  Widget build(BuildContext context) {
    final double badge = size * 0.36;

    return Semantics(
      button: true,
      selected: _isCounted,
      label: semanticLabel,
      value: _isCounted ? '$ordinal' : '',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              AnimatedContainer(
                duration: KidUi.fast,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // The mark is a ring, a wash and a number, not just a colour
                  // shift: colour alone is invisible to a colour-blind child
                  // and easy to miss at arm's length.
                  border: Border.all(
                    color: _isCounted ? KidUi.correct : Colors.transparent,
                    width: _isCounted ? size * 0.05 : 0,
                  ),
                  color: _isCounted
                      ? KidUi.correct.withValues(alpha: 0.18)
                      : Colors.transparent,
                ),
                child: Padding(
                  padding: EdgeInsets.all(size * 0.1),
                  child: Image.asset(imageAsset, fit: BoxFit.contain),
                ),
              ),
              if (_isCounted)
                Positioned(
                  right: -badge * 0.12,
                  top: -badge * 0.12,
                  child: Container(
                    width: badge,
                    height: badge,
                    decoration: BoxDecoration(
                      color: KidUi.correct,
                      shape: BoxShape.circle,
                      boxShadow: KidUi.shadow(KidUi.correct, strength: 0.7),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      NumberWords.digits(ordinal, languageCode),
                      style: TextStyle(
                        fontSize: badge * 0.62,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final ActivityStepView? view = state.view;
    final List<String> live = view?.liveOptionIds ?? const <String>[];
    final String? highlight = view?.highlightOptionId;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int count = step.numeralOptions.length;
        final double spacing = metrics.gap * 0.6;
        // Sized to the row it actually has to fit in. A fixed 92 with fixed
        // padding overflowed a small phone as soon as a fourth numeral
        // appeared, and an overflowing answer row is an unanswerable question.
        final double button = math
            .min(
              (constraints.maxWidth - spacing * (count - 1)) / count,
              constraints.maxHeight,
            )
            .clamp(56.0, 116.0);

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: spacing * 0.5,
            children: <Widget>[
              for (final int value in step.numeralOptions)
                _NumeralButton(
                  label: NumberWords.digits(value, languageCode),
                  size: button,
                  // Options removed by the ladder stay in place and fade.
                  // Removing them would reflow the row under a finger already
                  // in motion.
                  isLive:
                      live.isEmpty || live.contains(step.optionIdFor(value)),
                  isHighlighted: highlight == step.optionIdFor(value),
                  onTap: () => onPick(value),
                ),
            ],
          ),
        );
      },
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


/// Producing a set of a stated size, rather than naming the size of one shown.
///
/// The child moves things into the bowl one at a time and hands it over when
/// they think it is right. Taking something back out is as easy as putting it
/// in, because a count you cannot correct is a count a four-year-old abandons.
///
/// Nothing here is judged until the bowl is handed over: filling and emptying
/// report a tally, which the cubit speaks and does not score.
class _GiveNBoard extends StatefulWidget {
  const _GiveNBoard({
    required this.step,
    required this.state,
    required this.submit,
    required this.languageCode,
  });

  final CountingStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;
  final String languageCode;

  @override
  State<_GiveNBoard> createState() => _GiveNBoardState();
}

class _GiveNBoardState extends State<_GiveNBoard> {
  int _inBowl = 0;

  /// How many are on the counter to draw from.
  ///
  /// Comfortably more than the answer. A supply that held exactly the right
  /// number would answer the question for the child — take everything, hand it
  /// over — which is the classic way a give-N task is accidentally defeated.
  int get _supply => widget.step.targetCount + 3;

  @override
  void didUpdateWidget(_GiveNBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      setState(() => _inBowl = 0);
    }
    if (!oldWidget.state.isDemonstrating && widget.state.isDemonstrating) {
      // Fill it correctly so the child sees what the number looks like, then
      // empty it so they are the one who makes it.
      setState(() => _inBowl = widget.step.targetCount);
    } else if (oldWidget.state.isDemonstrating &&
        !widget.state.isDemonstrating) {
      setState(() => _inBowl = 0);
    }
  }

  void _take() {
    if (widget.state.isBoardLocked || _inBowl >= _supply) {
      return;
    }
    KidHaptics.tap();
    setState(() => _inBowl++);
    widget.submit(TallyAttempt(_inBowl));
  }

  void _putBack() {
    if (widget.state.isBoardLocked || _inBowl == 0) {
      return;
    }
    KidHaptics.tap();
    setState(() => _inBowl--);
    if (_inBowl > 0) {
      widget.submit(TallyAttempt(_inBowl));
    }
  }

  void _handOver() {
    if (widget.state.isBoardLocked || _inBowl == 0) {
      return;
    }
    KidHaptics.tap();
    widget.submit(QuantityAttempt(_inBowl));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final KidMetrics metrics = KidMetrics.of(constraints);
        final double itemEdge =
            metrics.size(KidUi.minTouchYoung, min: 64, max: 132);

        return Column(
          children: <Widget>[
            // The counter: everything still to be taken from.
            Expanded(
              child: _Tray(
                count: _supply - _inBowl,
                itemAsset: widget.step.item.imageAsset,
                itemEdge: itemEdge * 0.7,
                label: widget.step.item.label.resolve(widget.languageCode),
                isEnabled: !widget.state.isBoardLocked,
                onTapItem: _take,
                isBowl: false,
              ),
            ),
            SizedBox(height: metrics.gap * 0.4),
            // The bowl: what will actually be handed over.
            Expanded(
              child: _Tray(
                count: _inBowl,
                itemAsset: widget.step.item.imageAsset,
                itemEdge: itemEdge * 0.7,
                label: widget.step.item.label.resolve(widget.languageCode),
                isEnabled: !widget.state.isBoardLocked,
                onTapItem: _putBack,
                isBowl: true,
              ),
            ),
            SizedBox(height: metrics.gap * 0.4),
            Semantics(
              button: true,
              enabled: !widget.state.isBoardLocked && _inBowl > 0,
              label: 'Hand it over',
              child: GestureDetector(
                key: giveNHandOverKey,
                onTap: _handOver,
                child: Container(
                  height: metrics.size(KidUi.minTouch, min: 56, max: 92),
                  width: metrics.size(200, min: 150, max: 280),
                  decoration: BoxDecoration(
                    color: _inBowl == 0
                        ? KidUi.primary.withValues(alpha: 0.4)
                        : KidUi.correct,
                    borderRadius: BorderRadius.circular(KidUi.radiusPill),
                    boxShadow: KidUi.shadow(KidUi.correct, strength: 0.7),
                  ),
                  child: Icon(
                    Icons.pan_tool_alt_rounded,
                    color: Colors.white,
                    size: metrics.size(30, min: 24, max: 40),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A counter or a bowl: the same thing, drawn twice.
class _Tray extends StatelessWidget {
  const _Tray({
    required this.count,
    required this.itemAsset,
    required this.itemEdge,
    required this.label,
    required this.isEnabled,
    required this.onTapItem,
    required this.isBowl,
  });

  final int count;
  final String itemAsset;
  final double itemEdge;
  final String label;
  final bool isEnabled;
  final VoidCallback onTapItem;
  final bool isBowl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(itemEdge * 0.12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isBowl ? 0.9 : 0.62),
        borderRadius: BorderRadius.circular(KidUi.radiusCard),
        border: isBowl
            ? Border.all(color: KidUi.correct, width: itemEdge * 0.05)
            : null,
      ),
      child: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: itemEdge * 0.16,
          runSpacing: itemEdge * 0.16,
          children: <Widget>[
            for (int index = 0; index < count; index++)
              Semantics(
                button: true,
                enabled: isEnabled,
                label: label,
                child: GestureDetector(
                  key: index == 0
                      ? (isBowl ? giveNBowlItemKey : giveNSupplyItemKey)
                      : null,
                  onTap: isEnabled ? onTapItem : null,
                  child: Image.asset(
                    itemAsset,
                    width: itemEdge,
                    height: itemEdge,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Handles for the widget tests, which otherwise would have to find an image
/// by its asset path and would go green the moment the art changed.
const Key giveNSupplyItemKey = Key('giveN.supplyItem');
const Key giveNBowlItemKey = Key('giveN.bowlItem');
const Key giveNHandOverKey = Key('giveN.handOver');
