import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/deduction/deduction_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/deduction/deduction_cubit.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';

/// The clue at the top, the candidates below, and the evidence so far.
///
/// Every clue the child has already applied stays on screen as a chip. The
/// answer is the one card that agrees with *all* of them, so the chips are
/// the reasoning, laid out: by the last clue the child can look along the row
/// and check the survivor against each one.
///
/// A card that fits the clue and is tapped anyway shakes and shows the clue's
/// picture on itself — "this one has a tail too" — which is the reason it
/// stays, rather than a buzzer that only says it does.
class DeductionBoard extends StatefulWidget {
  const DeductionBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final DeductionStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<DeductionBoard> createState() => _DeductionBoardState();
}

class _DeductionBoardState extends State<DeductionBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(DeductionBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ActivityState now = widget.state;
    final ActivityState before = oldWidget.state;
    if (now.lastOutcome == AttemptOutcome.wrongItem &&
        (before.lastOutcome != AttemptOutcome.wrongItem ||
            before.wrongAttemptsOnStep != now.wrongAttemptsOnStep)) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  DeductionContent get _content => widget.step.content;

  Color get _accent => _content.accentColorValue == null
      ? KidUi.primary
      : Color(_content.accentColorValue!);

  @override
  Widget build(BuildContext context) {
    final ActivityStepView? view = widget.state.view;
    final Set<String> setAside =
        (view?.dimmedOptionIds ?? const <String>[]).toSet();
    final Set<String> live = (view?.liveOptionIds ?? const <String>[]).toSet();
    final String? highlighted = view?.highlightOptionId;
    final String language = widget.state.languageCode;
    final String? refused = widget.state.lastOutcome == AttemptOutcome.wrongItem
        ? widget.state.lastAttemptedOptionId
        : null;
    final int clueIndex = widget.step.clueIndex;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360;
        final double height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 480;
        final double clueHeight = (height * 0.2).clamp(44.0, 96.0);
        const double gap = 10;
        final double gridHeight = math.max(0, height - clueHeight - gap);
        final _Grid grid =
            _Grid.best(_content.candidates.length, width, gridHeight, gap);

        return Column(
          children: <Widget>[
            SizedBox(
              height: clueHeight,
              child: _ClueRow(
                clues: _content.clues,
                current: clueIndex,
                height: clueHeight,
                accent: _accent,
              ),
            ),
            const SizedBox(height: gap),
            SizedBox(
              width: grid.columns * grid.cell + (grid.columns - 1) * gap,
              height: gridHeight,
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  for (final PackItem item in _content.candidates)
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (BuildContext context, Widget? child) {
                        final double dx = item.id == refused
                            ? math.sin(_shake.value * math.pi * 6) *
                                (1 - _shake.value) *
                                grid.cell *
                                0.06
                            : 0;
                        return Transform.translate(
                            offset: Offset(dx, 0), child: child);
                      },
                      child: _CandidateCard(
                        item: item,
                        size: grid.cell,
                        language: language,
                        setAside: setAside.contains(item.id),
                        live: live.contains(item.id),
                        highlighted: highlighted == item.id,
                        fitsBadge: item.id == refused
                            ? widget.step.clue.image
                            : null,
                        accent: _accent,
                        onTap: () {
                          if (widget.state.isBoardLocked ||
                              setAside.contains(item.id) ||
                              !live.contains(item.id)) {
                            return;
                          }
                          widget.submit(ChoiceAttempt(item.id));
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The column count that makes the cards biggest in the space given.
@immutable
class _Grid {
  const _Grid(this.columns, this.cell);

  final int columns;
  final double cell;

  static _Grid best(int count, double width, double height, double gap) {
    _Grid best = const _Grid(1, 0);
    for (int columns = 1; columns <= count; columns++) {
      final int rows = (count / columns).ceil();
      final double cell = math.min(
        (width - gap * (columns - 1)) / columns,
        (height - gap * (rows - 1)) / rows,
      );
      if (cell > best.cell) {
        best = _Grid(columns, cell);
      }
    }
    return _Grid(best.columns, math.max(0, best.cell - 0.5));
  }
}

/// Past clues small, the current one large, clues to come not shown — the
/// next clue is news, and a row of blanks would turn it into a countdown.
class _ClueRow extends StatelessWidget {
  const _ClueRow({
    required this.clues,
    required this.current,
    required this.height,
    required this.accent,
  });

  final List<DeductionClue> clues;
  final int current;
  final double height;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int index = 0; index <= current; index++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: height * 0.08),
            child: _ClueChip(
              clue: clues[index],
              size: index == current ? height : height * 0.62,
              done: index < current,
              accent: accent,
            ),
          ),
      ],
    );
  }
}

class _ClueChip extends StatelessWidget {
  const _ClueChip({
    required this.clue,
    required this.size,
    required this.done,
    required this.accent,
  });

  final DeductionClue clue;
  final double size;
  final bool done;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: KidUi.medium,
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KidUi.surface.withValues(alpha: done ? 0.75 : 0.95),
        border: Border.all(
          color: done ? KidUi.correct : KidUi.hint,
          width: done ? 3 : 4,
        ),
      ),
      child: clue.image == null
          ? Icon(Icons.search_rounded, color: accent, size: size * 0.5)
          : Image.asset(clue.image!,
              fit: BoxFit.contain, cacheWidth: (size * 2).round()),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.item,
    required this.size,
    required this.language,
    required this.setAside,
    required this.live,
    required this.highlighted,
    required this.fitsBadge,
    required this.accent,
    required this.onTap,
  });

  final PackItem item;
  final double size;
  final String language;
  final bool setAside;
  final bool live;
  final bool highlighted;

  /// The clue's picture, shown on a card that fits it and was tapped anyway.
  final String? fitsBadge;

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label = item.label.resolve(language);
    final bool showLabel = size >= 84;
    return Semantics(
      button: !setAside,
      enabled: live && !setAside,
      label: label,
      value: setAside ? 'set aside' : 'still a suspect',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: KidUi.medium,
          opacity: setAside ? 0.28 : (live ? 1 : 0.55),
          child: AnimatedScale(
            duration: KidUi.medium,
            scale: setAside ? 0.82 : 1,
            child: Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(size * 0.08),
              decoration: BoxDecoration(
                color: KidUi.surface,
                borderRadius: BorderRadius.circular(KidUi.radiusCard * 0.7),
                border: Border.all(
                  color: highlighted ? KidUi.hint : accent.withValues(alpha: 0.5),
                  width: highlighted ? 5 : 3,
                ),
                boxShadow: <BoxShadow>[
                  if (highlighted)
                    BoxShadow(
                      color: KidUi.hint.withValues(alpha: 0.6),
                      blurRadius: size * 0.2,
                    ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Expanded(
                        child: Image.asset(
                          item.imageAsset,
                          fit: BoxFit.contain,
                          cacheWidth: (size * 2).round(),
                        ),
                      ),
                      if (showLabel)
                        ActivityGlyphText(
                          label,
                          languageCode: language,
                          fontSize: size * 0.12,
                          color: KidUi.ink,
                          maxLines: 1,
                        ),
                    ],
                  ),
                  if (setAside)
                    Center(
                      child: Icon(Icons.close_rounded,
                          size: size * 0.6, color: KidUi.inkSoft),
                    ),
                  if (fitsBadge != null && !setAside)
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: Container(
                        width: size * 0.34,
                        height: size * 0.34,
                        padding: EdgeInsets.all(size * 0.04),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: KidUi.hint,
                        ),
                        child: Image.asset(fitsBadge!,
                            cacheWidth: (size * 0.7).round()),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
