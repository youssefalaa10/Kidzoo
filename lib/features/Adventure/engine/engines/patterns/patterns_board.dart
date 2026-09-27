import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_pick_card.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/patterns/patterns_cubit.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_feedback_scope.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';

/// The pattern strip and the tray under it.
///
/// The visual sentence here is deliberately not sorting's. Sorting is loose
/// objects and separate containers: *which box does this belong in?* This is
/// **one continuous ribbon with holes punched in it**, which asks a different
/// question — *what is missing from this?* A child should be able to tell the
/// two apart before anyone says a word, and a run of connected tiles versus a
/// row of boxes is how.
class PatternsBoard extends StatefulWidget {
  const PatternsBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final PatternStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<PatternsBoard> createState() => _PatternsBoardState();
}

class _PatternsBoardState extends State<PatternsBoard>
    with SingleTickerProviderStateMixin {
  /// Time between one tile lighting and the next. Slow enough to be a beat a
  /// child can feel, fast enough that a nine-tile ribbon is over in about a
  /// second and a quarter.
  static const Duration _beat = Duration(milliseconds: 115);
  static const Duration _gateOpen = Duration(milliseconds: 460);

  late final AnimationController _wave;

  /// The finished strip, snapshotted when the wave starts.
  ///
  /// Held rather than read live because the cubit moves to the next round while
  /// the reveal line is being spoken, and the wave must go on running over the
  /// pattern the child actually completed.
  List<String>? _waveStrip;

  /// Tiles that have already ticked, so each one ticks exactly once.
  int _ticked = 0;

  String? _selectedTileId;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(vsync: this)..addListener(_tickSound);
  }

  @override
  void dispose() {
    _wave
      ..removeListener(_tickSound)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PatternsBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      _selectedTileId = null;
    }
    final bool justCorrect =
        widget.state.lastOutcome == AttemptOutcome.correct &&
            oldWidget.state.lastOutcome != AttemptOutcome.correct;
    if (justCorrect && oldWidget.step.isLastGapOfRound) {
      _startWave(oldWidget.step.completedStrip);
    }
  }

  void _startWave(List<String> strip) {
    _waveStrip = strip;
    _ticked = 0;
    _wave
      ..duration = _beat * strip.length + _gateOpen
      ..forward(from: 0);
  }

  /// One soft tick per tile, on the tile.
  ///
  /// The rhythm is the point of this moment, so the sound has to come from
  /// whatever owns the clock — and that is this widget. Driving it from the
  /// cubit instead would make every test sit through a wave it cannot see.
  void _tickSound() {
    final List<String>? strip = _waveStrip;
    if (strip == null) {
      return;
    }
    final double total = strip.length + _gateOpen.inMilliseconds / _beat.inMilliseconds;
    final int reached = (_wave.value * total).floor().clamp(0, strip.length);
    if (reached <= _ticked) {
      return;
    }
    _ticked = reached;
    final ActivitySoundboard? board =
        ActivityFeedbackScope.maybeOf(context)?.soundboard;
    board?.play(ActivitySound.tap);
  }

  void _place(String tileId) {
    setState(() => _selectedTileId = null);
    widget.submit(PlacementAttempt(
      tokenId: tileId,
      targetId: widget.step.slotId,
    ));
  }

  PackItem? _item(String? id) {
    if (id == null) {
      return null;
    }
    for (final PackItem candidate in widget.step.tray) {
      if (candidate.id == id) {
        return candidate;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ActivityStepView? view = widget.state.view;
    final List<String>? waveStrip = _waveStrip;

    // During the wave the ribbon shows the completed pattern, because that is
    // what the child just made and what the wave is running over.
    final List<String?> strip = _wave.isAnimating && waveStrip != null
        ? List<String?>.of(waveStrip)
        : <String?>[
            for (int index = 0; index < widget.step.strip.length; index++)
              widget.step.strip[index],
          ];
    final int activeSlot = _wave.isAnimating ? -1 : widget.step.slotIndex;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _RibbonMetrics ribbon = _RibbonMetrics.forBox(
          constraints,
          tileCount: strip.length,
        );
        final double trayTile = math.min(
          KidUi.minTouchYoung,
          (constraints.maxWidth - 24) / (widget.step.tray.length + 0.4),
        );

        return Column(
          // Centred as one group rather than spread to the corners. On a
          // tablet, spacing these evenly puts a ledge at the top, a tray at the
          // bottom and six hundred pixels of nothing between them, which makes
          // two halves of one action look like two unrelated things.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: AnimatedBuilder(
                animation: _wave,
                builder: (BuildContext context, Widget? _) => _Ribbon(
                  strip: strip,
                  rows: ribbon.rows,
                  tile: ribbon.tile,
                  activeSlot: activeSlot,
                  itemFor: _item,
                  wave: _wave.isAnimating ? _wave.value : null,
                  waveLength: waveStrip?.length ?? strip.length,
                  armedTileId: _selectedTileId,
                  gap: ribbon.gap,
                  accent: widget.step.accentColorValue == null
                      ? KidUi.primary
                      : Color(widget.step.accentColorValue!),
                  onDrop: _place,
                ),
              ),
            ),
            // Enough air to separate the ledge from the tray, capped so it
            // cannot become the gulf that `spaceEvenly` produced.
            SizedBox(
              height: math.min(ribbon.gap * 5, constraints.maxHeight * 0.09),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: ribbon.gap,
              runSpacing: ribbon.gap * 0.6,
              children: <Widget>[
                for (final PackItem item in widget.step.tray)
                  Opacity(
                    opacity:
                        (view?.liveOptionIds.contains(item.id) ?? true) ? 1 : 0.3,
                    child: KidPickCard<String>(
                      imageAsset: item.imageAsset,
                      size: trayTile,
                      dragData: item.id,
                      state: _selectedTileId == item.id
                          ? KidCardState.selected
                          : KidCardState.idle,
                      label: item.label.resolve(widget.state.languageCode),
                      onTap: () => setState(
                        () => _selectedTileId =
                            _selectedTileId == item.id ? null : item.id,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

}

/// How many rows the ribbon needs and how big a tile can be.
///
/// Wrapping is not a nicety. Nine tiles across a 360dp phone is 38dp each
/// before spacing, and the last board to assume one row overflowed by 202px on
/// exactly that device.
@immutable
class _RibbonMetrics {
  const _RibbonMetrics({
    required this.rows,
    required this.tile,
    required this.gap,
  });

  factory _RibbonMetrics.forBox(BoxConstraints box, {required int tileCount}) {
    const double minTile = 34;
    const double maxTile = 86;
    final double gap = box.maxWidth < 420 ? 4 : 8;

    for (int rows = 1; rows <= 3; rows++) {
      final int perRow = (tileCount / rows).ceil();
      // A row is not its tiles. It also spends width on the band's padding
      // both sides, its two-pixel border, the gaps between tiles, one more gap
      // before the gate and the gate itself — and approximating that is what
      // overflowed 360dp by 45px on the first attempt, which is the same
      // failure the `code_path` tray had at exactly the same width.
      final double tile = (box.maxWidth - 4 - gap * (perRow + 2)) /
          (perRow + _gateWidthInTiles);
      // Rows of ribbon plus the tray under them still have to fit the height.
      final double heightBudget = (box.maxHeight * 0.5) / rows - gap * 2;
      final double chosen = math.min(tile, heightBudget);
      if (chosen >= minTile || rows == 3) {
        return _RibbonMetrics(
          rows: rows,
          tile: chosen.clamp(16.0, maxTile),
          gap: gap,
        );
      }
    }
    return _RibbonMetrics(rows: 3, tile: minTile, gap: gap);
  }

  /// How wide the gate is, in tiles. Shared with `_Ribbon` so the thing that
  /// measures a row and the thing that builds one cannot disagree.
  static const double _gateWidthInTiles = 0.7;

  final int rows;
  final double tile;
  final double gap;
}

/// The reef ledge: one connected band with the pattern set into it.
class _Ribbon extends StatelessWidget {
  const _Ribbon({
    required this.strip,
    required this.rows,
    required this.tile,
    required this.activeSlot,
    required this.itemFor,
    required this.wave,
    required this.waveLength,
    required this.armedTileId,
    required this.accent,
    required this.gap,
    required this.onDrop,
  });

  final List<String?> strip;
  final int rows;
  final double tile;

  /// The same spacing the metrics budgeted for. Deriving a second one here
  /// from the tile size is how the row ended up wider than the box it was
  /// measured against.
  final double gap;
  final int activeSlot;
  final PackItem? Function(String id) itemFor;

  /// 0..1 while the wave is running, null otherwise.
  final double? wave;

  final int waveLength;
  final String? armedTileId;

  /// The chapter's colour. Everything the ribbon draws is derived from it, so
  /// a reef, a vine and a row of floor tiles are the same widget.
  final Color accent;

  final void Function(String tileId) onDrop;

  @override
  Widget build(BuildContext context) {
    final int perRow = (strip.length / rows).ceil();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int row = 0; row < rows; row++) ...<Widget>[
          if (row > 0) SizedBox(height: gap * 1.6),
          Container(
            padding: EdgeInsets.all(gap),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(tile * 0.42),
              border: Border.all(
                color: accent.withValues(alpha: 0.28),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int index = row * perRow;
                    index < math.min((row + 1) * perRow, strip.length);
                    index++) ...<Widget>[
                  if (index > row * perRow) SizedBox(width: gap),
                  _Slot(
                    size: tile,
                    itemId: strip[index],
                    item: strip[index] == null ? null : itemFor(strip[index]!),
                    isActive: index == activeSlot,
                    armedTileId: armedTileId,
                    accent: accent,
                    pulse: _pulseAt(index),
                    onDrop: onDrop,
                  ),
                ],
                // Padding for the slots a short last row does not have, so a
                // wrapped ledge stays one shape instead of a long bar with a
                // stub under it.
                for (int pad = math.min((row + 1) * perRow, strip.length);
                    pad < (row + 1) * perRow;
                    pad++) ...<Widget>[
                  SizedBox(width: gap),
                  SizedBox(width: tile, height: tile),
                ],
                SizedBox(width: gap),
                // The gate is only real on the last row; every other row keeps
                // its width so all the rows line up.
                if (row == rows - 1)
                  _Gate(
                    size: tile * _RibbonMetrics._gateWidthInTiles,
                    height: tile,
                    open: _gateOpenness,
                    accent: accent,
                  )
                else
                  SizedBox(
                    width: tile * _RibbonMetrics._gateWidthInTiles,
                    height: tile,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// A short bump travelling along the ribbon: nothing before it, nothing after
  /// it, one tile lit at a time. That is what makes it read as a swell moving
  /// through the reef rather than as everything flashing at once.
  double _pulseAt(int index) {
    final double? t = wave;
    if (t == null) {
      return 0;
    }
    final double head = t * (waveLength + 4) - index;
    if (head < 0 || head > 1.6) {
      return 0;
    }
    return math.sin((head / 1.6) * math.pi);
  }

  double get _gateOpenness {
    final double? t = wave;
    if (t == null) {
      return 0;
    }
    final double start = waveLength / (waveLength + 4);
    if (t <= start) {
      return 0;
    }
    return ((t - start) / (1 - start)).clamp(0.0, 1.0);
  }
}

/// One position in the ribbon: a tile, or a hole waiting for one.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.size,
    required this.itemId,
    required this.item,
    required this.isActive,
    required this.armedTileId,
    required this.accent,
    required this.pulse,
    required this.onDrop,
  });

  final double size;
  final String? itemId;
  final PackItem? item;
  final bool isActive;
  final String? armedTileId;
  final Color accent;
  final double pulse;
  final void Function(String tileId) onDrop;

  @override
  Widget build(BuildContext context) {
    if (itemId == null) {
      return _EmptySlot(
        size: size,
        isActive: isActive,
        armedTileId: armedTileId,
        accent: accent,
        onDrop: onDrop,
      );
    }
    return Transform.scale(
      scale: 1 + pulse * 0.22,
      child: SizedBox(
        width: size,
        height: size,
        child: item == null
            ? const SizedBox.shrink()
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55 + pulse * 0.45),
                  borderRadius: BorderRadius.circular(size * 0.28),
                ),
                child: Padding(
                  padding: EdgeInsets.all(size * 0.08),
                  child: Image.asset(item!.imageAsset, fit: BoxFit.contain),
                ),
              ),
      ),
    );
  }
}

/// A hole in the ledge.
///
/// Drawn as a recess — darker than the band, inset shadow, no card — so it
/// reads as something *missing from* the ribbon rather than as an empty box
/// beside it.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({
    required this.size,
    required this.isActive,
    required this.armedTileId,
    required this.accent,
    required this.onDrop,
  });

  final double size;
  final bool isActive;

  /// The tile the child has tapped, waiting for a hole. Tapping the hole then
  /// places it — the same act as a drag, for a child who cannot drag.
  final String? armedTileId;

  final Color accent;

  final void Function(String tileId) onDrop;

  /// A hole is the ledge in shadow, so it is darker than whatever colour the
  /// ledge happens to be this chapter rather than a fixed navy.
  Color get _recess =>
      Color.lerp(accent, Colors.black, 0.45) ?? accent;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => isActive,
      onAcceptWithDetails: (DragTargetDetails<String> details) =>
          onDrop(details.data),
      builder:
          (BuildContext context, List<String?> candidates, List<dynamic> _) {
        final bool previewing = candidates.isNotEmpty;
        return GestureDetector(
          onTap: isActive && armedTileId != null
              ? () => onDrop(armedTileId!)
              : null,
          child: AnimatedScale(
            scale: previewing ? 1.1 : 1.0,
            duration: KidUi.fast,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _recess.withValues(alpha: isActive ? 0.34 : 0.16),
                borderRadius: BorderRadius.circular(size * 0.28),
                border: Border.all(
                  color: isActive || previewing
                      ? KidUi.hint
                      : _recess.withValues(alpha: 0.25),
                  width: isActive || previewing ? 3.5 : 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The reef gate at the end of the run.
///
/// Two halves that part on the last beat of the wave, so completing the pattern
/// visibly opens the way rather than just scoring a point.
class _Gate extends StatelessWidget {
  const _Gate({
    required this.size,
    required this.height,
    required this.open,
    required this.accent,
  });

  final double size;
  final double height;

  final Color accent;

  /// 0 shut, 1 fully open.
  final double open;

  @override
  Widget build(BuildContext context) {
    final double half = height * 0.44;
    final double travel = half * 0.9 * Curves.easeOutCubic.transform(open);

    return SizedBox(
      width: size,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // The light behind the gate, only visible once it parts.
          Opacity(
            opacity: open,
            child: Container(
              width: size * 0.7,
              height: height * 0.9,
              decoration: BoxDecoration(
                color: KidUi.hint.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(size * 0.2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: KidUi.hint.withValues(alpha: 0.6 * open),
                    blurRadius: size * 0.5,
                    spreadRadius: size * 0.1,
                  ),
                ],
              ),
            ),
          ),
          for (final int side in <int>[-1, 1])
            Transform.translate(
              offset: Offset(0, side * travel),
              child: Align(
                alignment: side < 0 ? Alignment.topCenter : Alignment.bottomCenter,
                child: Container(
                  width: size * 0.94,
                  height: half,
                  decoration: BoxDecoration(
                    color: Color.lerp(accent, Colors.black, 0.25) ??
                        accent,
                    borderRadius: BorderRadius.circular(size * 0.16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
