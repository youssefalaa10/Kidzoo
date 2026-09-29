import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One visual difference between the two panels.
@immutable
class DiffSpot {
  const DiffSpot({
    required this.id,
    required this.fractionLeft,
    required this.fractionRight,
    required this.hitRadius,
    required this.label,
    required this.revealLine,
  });

  final String id;

  /// Where this spot sits in the left panel, as a fraction of panel size.
  final Offset fractionLeft;

  /// Where this spot sits in the right panel, as a fraction of panel size.
  final Offset fractionRight;

  /// How close a tap must be, as a fraction of panel width. Larger = easier.
  final double hitRadius;

  /// Short spoken label used as the "look for this" hint between steps.
  final LocalizedText label;

  /// Spoken when the child finds this spot.
  final LocalizedText revealLine;
}

/// Everything `spot_the_diff` needs, parsed.
@immutable
class SpotDiffContent extends ActivityContent {
  const SpotDiffContent({
    required this.spots,
    required this.imageLeft,
    required this.imageRight,
    this.accentColorValue,
  });

  final List<DiffSpot> spots;

  /// The unmodified scene.
  final String imageLeft;

  /// The scene with the differences introduced.
  final String imageRight;

  final int? accentColorValue;

  Iterable<String> get assetPaths => <String>[imageLeft, imageRight];
}

/// One spot to find in this step.
///
/// Each step focuses on ONE target but carries ALL spots and the set of spots
/// already found before this step began. The board uses [foundIds] only to
/// initialise its own accumulated found-set; the cubit's [judge] accepts any
/// spot not yet in [foundIds] as the correct answer so the child's own
/// discovery order is always honoured.
@immutable
class SpotDiffStep extends ActivityStep {
  const SpotDiffStep({
    required String stepId,
    required this.target,
    required this.allSpots,
    required this.foundIds,
    required this.imageLeft,
    required this.imageRight,
    this.accentColorValue,
  }) : super(stepId);

  /// The spot this step's scaffold is for (hint highlight, revealLine).
  final DiffSpot target;

  /// Every spot in the activity, for rendering all of them on the board.
  final List<DiffSpot> allSpots;

  /// Spots confirmed found before this step began (not including [target]).
  final Set<String> foundIds;

  final String imageLeft;
  final String imageRight;
  final int? accentColorValue;

  bool isFound(String id) => foundIds.contains(id);
}

class SpotDiffCubit extends ActivityCubit<SpotDiffContent, SpotDiffStep> {
  SpotDiffCubit(super.session);

  @override
  List<SpotDiffStep> buildSteps() {
    // Shuffle so every run offers the spots in a different order, which is what
    // keeps a child who has done this before from recognising the route rather
    // than finding the differences.
    final List<DiffSpot> order = List<DiffSpot>.of(content.spots)
      ..shuffle(services.random);
    final List<SpotDiffStep> steps = <SpotDiffStep>[];
    final Set<String> found = <String>{};
    for (final DiffSpot spot in order) {
      steps.add(SpotDiffStep(
        stepId: 'diff_${spot.id}',
        target: spot,
        allSpots: content.spots,
        foundIds: Set<String>.unmodifiable(found),
        imageLeft: content.imageLeft,
        imageRight: content.imageRight,
        accentColorValue: content.accentColorValue,
      ));
      found.add(spot.id);
    }
    return steps;
  }

  @override
  ActivityJudgement judge(SpotDiffStep step, ActivityAttempt attempt) {
    if (attempt is! ChoiceAttempt) {
      return const ActivityJudgement.wrongItem();
    }
    // A spot the step already counted is a duplicate tap the board should
    // have blocked, not a new find. Everything else is correct.
    if (step.foundIds.contains(attempt.optionId)) {
      return const ActivityJudgement.wrongItem();
    }
    return const ActivityJudgement.correct();
  }

  @override
  ActivityStepView describe(SpotDiffStep step, ScaffoldLevel level) {
    // liveOptionIds: all spots not yet found. The scaffold can highlight one
    // and dim the rest, but every unfound spot is still tappable.
    final List<String> unfound = step.allSpots
        .where((DiffSpot s) => !step.foundIds.contains(s.id))
        .map((DiffSpot s) => s.id)
        .toList(growable: false);
    return ActivityStepView(
      prompt: spec.narration.prompt,
      spokenPrompt: step.target.label,
      revealLine: step.target.revealLine,
      liveOptionIds: unfound,
      dimmedOptionIds: step.allSpots
          .where((DiffSpot s) => step.foundIds.contains(s.id))
          .map((DiffSpot s) => s.id)
          .toList(growable: false),
      highlightOptionId:
          level == ScaffoldLevel.modelled ? step.target.id : null,
    );
  }
}

/// Find the differences between two side-by-side underwater scenes.
class SpotDiffEngine extends ActivityEngine<SpotDiffContent> {
  const SpotDiffEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'spot_the_diff',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.visualSearch},
        interactionModes: <InteractionMode>{InteractionMode.compareScene},
        contentParameters: <ContentParameter>[
          ContentParameter.text('imageLeft', isRequired: true,
              description: 'asset path for the unmodified panel'),
          ContentParameter.text('imageRight', isRequired: true,
              description: 'asset path for the panel with differences'),
          ContentParameter.list('spots', isRequired: true,
              description:
                  'list of difference spots, each with id, posLeft [x,y], '
                  'posRight [x,y], hitRadius, label, revealLine'),
        ],
        adaptationAxis: null,
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  SpotDiffContent parseContent(ActivitySpec spec, ItemPackResolver packs) {
    final JsonReader reader = spec.payloadReader;
    final String path = '${spec.sourcePath} > payload';

    final String imageLeft = reader.requireString('imageLeft');
    final String imageRight = reader.requireString('imageRight');

    final List<Map<String, dynamic>> rawSpots =
        reader.optionalMapList('spots');
    if (rawSpots.isEmpty) {
      throw ActivityContentException(
          '$path.spots', 'need at least one difference to find');
    }

    final List<DiffSpot> spots = <DiffSpot>[];
    for (int i = 0; i < rawSpots.length; i++) {
      final Map<String, dynamic> raw = rawSpots[i];
      final String where = '$path.spots[$i]';
      final JsonReader sr = JsonReader(raw, where);

      List<double> pos(String key) {
        final List<dynamic> raw2 = (raw[key] as List<dynamic>?) ?? <dynamic>[];
        if (raw2.length != 2) {
          throw ActivityContentException(
              '$where.$key', 'expected [x, y] in 0..1');
        }
        return raw2.map((dynamic v) => (v as num).toDouble()).toList();
      }

      final List<double> left = pos('posLeft');
      final List<double> right = pos('posRight');

      spots.add(DiffSpot(
        id: sr.requireString('id'),
        fractionLeft: Offset(left[0], left[1]),
        fractionRight: Offset(right[0], right[1]),
        hitRadius: (raw['hitRadius'] as num?)?.toDouble() ?? 0.12,
        label:
            LocalizedText.fromJson(raw['label'], debugPath: '$where.label'),
        revealLine: LocalizedText.fromJson(raw['revealLine'],
            debugPath: '$where.revealLine'),
      ));
    }

    return SpotDiffContent(
      spots: spots,
      imageLeft: imageLeft,
      imageRight: imageRight,
      accentColorValue: _accentValue(spec.presentation.accent),
    );
  }

  @override
  Iterable<String> assetsFor(SpotDiffContent content) => content.assetPaths;

  @override
  ActivityCubit<SpotDiffContent, dynamic> createCubit(
    ActivitySession<SpotDiffContent> session,
  ) =>
      SpotDiffCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! SpotDiffStep) {
        return const SizedBox.shrink();
      }
      return SpotDiffBoard(step: step, state: state, submit: submit);
    };
  }
}

/// The two-panel board. Side by side, with a divider in the centre.
class SpotDiffBoard extends StatefulWidget {
  const SpotDiffBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final SpotDiffStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<SpotDiffBoard> createState() => _SpotDiffBoardState();
}

class _SpotDiffBoardState extends State<SpotDiffBoard>
    with SingleTickerProviderStateMixin {
  /// All spots confirmed found during this board session, accumulated across
  /// steps. Never reset: once a spot is found it stays found visually, and the
  /// step's own foundIds is used only to initialise this set at the start.
  final Set<String> _found = <String>{};

  /// Drives the pulsing hint rings on unfound spots.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _found.addAll(widget.step.foundIds);
  }

  @override
  void didUpdateWidget(SpotDiffBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Accumulate: a new step means a spot was just confirmed; absorb whatever
    // the step now considers found (it will always be a superset of what we had).
    _found.addAll(widget.step.foundIds);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _accent => widget.step.accentColorValue == null
      ? KidUi.primary
      : Color(widget.step.accentColorValue!);

  String? get _highlightedId => widget.state.view?.highlightOptionId;

  void _onSpotTapped(String spotId) {
    if (widget.state.isBoardLocked) return;
    if (_found.contains(spotId)) return;
    // Optimistically mark found so the board updates immediately, before the
    // cubit round-trips. If the cubit disagrees it will be wrong but won't
    // mark it unfound, so the visual is always at least as complete as truth.
    setState(() => _found.add(spotId));
    widget.submit(ChoiceAttempt(spotId));
  }

  @override
  Widget build(BuildContext context) {
    final SpotDiffStep step = widget.step;
    final String? highlighted = _highlightedId;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double dividerWidth = math.max(2, constraints.maxWidth * 0.015);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: _DiffPanel(
                image: step.imageLeft,
                spots: step.allSpots,
                found: _found,
                useLeft: true,
                accent: _accent,
                highlighted: highlighted,
                pulse: _pulse,
                onTapSpot: _onSpotTapped,
              ),
            ),
            _CentreDivider(width: dividerWidth, accent: _accent),
            Expanded(
              child: _DiffPanel(
                image: step.imageRight,
                spots: step.allSpots,
                found: _found,
                useLeft: false,
                accent: _accent,
                highlighted: highlighted,
                pulse: _pulse,
                onTapSpot: _onSpotTapped,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One half of the scene.
class _DiffPanel extends StatelessWidget {
  const _DiffPanel({
    required this.image,
    required this.spots,
    required this.found,
    required this.useLeft,
    required this.accent,
    required this.highlighted,
    required this.pulse,
    required this.onTapSpot,
  });

  final String image;
  final List<DiffSpot> spots;
  final Set<String> found;
  final bool useLeft;
  final Color accent;
  final String? highlighted;
  final Animation<double> pulse;
  final void Function(String) onTapSpot;

  Offset _fraction(DiffSpot spot) =>
      useLeft ? spot.fractionLeft : spot.fractionRight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;

        return GestureDetector(
          onTapDown: (TapDownDetails details) {
            final Offset local = details.localPosition;
            final Offset tapped = Offset(local.dx / w, local.dy / h);
            DiffSpot? closest;
            double best = double.infinity;
            for (final DiffSpot spot in spots) {
              if (found.contains(spot.id)) continue;
              final double dist =
                  (tapped - _fraction(spot)).distance;
              if (dist < best) {
                best = dist;
                closest = spot;
              }
            }
            if (closest != null && best <= closest.hitRadius) {
              onTapSpot(closest.id);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(image, fit: BoxFit.cover),
              for (final DiffSpot spot in spots)
                if (!found.contains(spot.id))
                  _SpotRing(
                    fraction: _fraction(spot),
                    isHighlighted: highlighted == spot.id,
                    accent: accent,
                    pulse: pulse,
                  ),
              for (final DiffSpot spot in spots)
                if (found.contains(spot.id))
                  _SpotCheck(
                    fraction: _fraction(spot),
                    accent: accent,
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// A pulsing ring that hints at an unfound difference.
///
/// Subtle enough not to give it away immediately, visible enough that a child
/// who is genuinely stuck can find it on their own rather than needing the
/// narrator to spell it out. Two rings, opposite phase, so there is always
/// motion even when neither is fully expanded.
class _SpotRing extends StatelessWidget {
  const _SpotRing({
    required this.fraction,
    required this.isHighlighted,
    required this.accent,
    required this.pulse,
  });

  final Offset fraction;
  final bool isHighlighted;
  final Color accent;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 1,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double cx = fraction.dx * constraints.maxWidth;
            final double cy = fraction.dy * constraints.maxHeight;
            final double base = constraints.maxWidth * 0.08;
            return AnimatedBuilder(
              animation: pulse,
              builder: (BuildContext context, Widget? _) {
                final double t = pulse.value;
                final double scale1 = 1.0 + 0.4 * math.sin(t * math.pi * 2);
                final double scale2 =
                    1.0 + 0.4 * math.sin((t + 0.5) * math.pi * 2);
                final double alpha = isHighlighted ? 0.85 : 0.45;
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: cx - base * scale1,
                      top: cy - base * scale1,
                      child: SizedBox(
                        width: base * scale1 * 2,
                        height: base * scale1 * 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isHighlighted
                                  ? KidUi.hint.withValues(alpha: alpha)
                                  : Colors.white.withValues(alpha: alpha * 0.7),
                              width: isHighlighted ? 3 : 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: cx - base * scale2,
                      top: cy - base * scale2,
                      child: SizedBox(
                        width: base * scale2 * 2,
                        height: base * scale2 * 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: alpha * 0.35),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// A checkmark burst shown once a spot has been found.
class _SpotCheck extends StatelessWidget {
  const _SpotCheck({required this.fraction, required this.accent});

  final Offset fraction;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double r = constraints.maxWidth * 0.07;
          return Stack(
            children: <Widget>[
              Positioned(
                left: fraction.dx * constraints.maxWidth - r,
                top: fraction.dy * constraints.maxHeight - r,
                child: Container(
                  width: r * 2,
                  height: r * 2,
                  decoration: BoxDecoration(
                    color: KidUi.correct,
                    shape: BoxShape.circle,
                    boxShadow: KidUi.shadow(KidUi.correct, strength: 0.7),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: r * 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The decorative line between the two panels.
class _CentreDivider extends StatelessWidget {
  const _CentreDivider({required this.width, required this.accent});

  final double width;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            accent.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.9),
            accent.withValues(alpha: 0.6),
          ],
        ),
      ),
    );
  }
}

int? _accentValue(String? raw) {
  if (raw == null) return null;
  final String hex = raw.replaceFirst('#', '');
  if (hex.length != 6 || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return null;
  }
  return int.parse('FF$hex', radix: 16);
}
