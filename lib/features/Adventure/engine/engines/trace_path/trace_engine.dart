import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_content.dart';

/// One figure to draw.
class TraceStep extends ActivityStep {
  const TraceStep({
    required String stepId,
    required this.figure,
    required this.tolerance,
    required this.accentColorValue,
  }) : super(stepId);

  final TraceFigure figure;
  final double tolerance;
  final int? accentColorValue;
}

class TraceCubit extends ActivityCubit<TraceContent, TraceStep> {
  TraceCubit(super.session);

  @override
  List<TraceStep> buildSteps() {
    return <TraceStep>[
      for (int index = 0; index < content.figures.length; index++)
        TraceStep(
          stepId: 'figure_${index}_${content.figures[index].id}',
          figure: content.figures[index],
          tolerance: content.tolerance,
          accentColorValue: content.accentColorValue,
        ),
    ];
  }

  @override
  ActivityJudgement judge(TraceStep step, ActivityAttempt attempt) {
    // A tap on an anchor. The board only sends one of these when the tap is
    // *wrong*, or when it is the one that finishes the figure — the ordinary
    // taps in between are the child drawing, and interrupting those to judge
    // them would turn one drawing into six questions.
    if (attempt is ChoiceAttempt) {
      return attempt.optionId == step.figure.lastAnchor.id
          ? const ActivityJudgement.correct()
          : const ActivityJudgement.wrongItem();
    }

    // A continuous line, sent when the finger lifts. This is the variant the
    // contract reserved in Phase 1 with no consumer; it is here now because
    // stroke quality is a real signal that a sequence of taps cannot carry.
    if (attempt is StrokeAttempt) {
      final int reached = traceProgressOf(
        figure: step.figure,
        stroke: attempt.points,
        tolerance: step.tolerance,
      );
      final int needed = step.figure.walk.length - 1;
      if (reached >= needed) {
        return const ActivityJudgement.correct();
      }
      // Followed the line and stopped part-way: the hand ran out, not the
      // understanding. Distinct from a line that went somewhere else entirely,
      // because one of those means "make the target bigger" and the other
      // means "show them the shape again".
      return reached >= 0
          ? const ActivityJudgement.wrongSlotButRightItem()
          : const ActivityJudgement.wrongItem();
    }

    return const ActivityJudgement.wrongItem();
  }

  @override
  ActivityStepView describe(TraceStep step, ScaffoldLevel level) {
    // Anchors are never removed. There is no such thing as a distractor in a
    // shape — taking a point out does not narrow the choice, it changes what
    // is being drawn. Help is the road getting brighter, not shorter.
    final List<String> everyAnchor = step.figure.anchors
        .map((TraceAnchor anchor) => anchor.id)
        .toList(growable: false);

    return ActivityStepView(
      prompt: step.figure.label,
      revealLine: step.figure.revealLine,
      liveOptionIds: everyAnchor,
      highlightOptionId: switch (level) {
        ScaffoldLevel.initial => null,
        // From the first hint onward the next point pulses. It is the only
        // hint a shape can usefully be given, and it is entirely visual —
        // no narration can say "that corner, the one up and to the left"
        // to someone who cannot yet hold four words of direction in mind.
        ScaffoldLevel.gentleRetry ||
        ScaffoldLevel.narrowed ||
        ScaffoldLevel.modelled =>
          step.figure.anchors.first.id,
      },
    );
  }
}

/// Drawing a line through points, in order.
///
/// Deliberately **not** "letter tracing". A figure is an ordered list of
/// anchors and two flags: whether the points are numbered, and whether the
/// road between them is drawn. Turn the numbers on and it is a dot-to-dot;
/// turn the road on and it is tracing; turn both on and it is a first figure
/// for a child who has never done either. Shapes, numerals, symbols, routes
/// and — when the letterform content exists — glyphs are all the same model,
/// which is why they are one engine rather than several.
///
/// The engine holds no glyph content of its own, so nothing here has to change
/// when Arabic letterforms arrive: they are authored point runs like anything
/// else. The narration around a figure is bilingual; the figure itself is
/// language-neutral, and that is an honest claim rather than a checkbox.
class TracePathEngine extends ActivityEngine<TraceContent> {
  const TracePathEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'trace_path',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.spatialReasoning},
        interactionModes: <InteractionMode>{InteractionMode.traceStroke},
        contentParameters: <ContentParameter>[
          ContentParameter.list('figures',
              isRequired: true,
              description: 'each with id, an ordered points list as whole '
                  'percentages of the box, a label, and the flags closed / '
                  'showNumbers / showGuide'),
          ContentParameter.integer('tolerancePercent',
              minValue: 1,
              maxValue: 40,
              description: 'how near the line must pass a point, as a '
                  'percentage of the box. Generous: a near miss is a finger '
                  'problem, not a misunderstanding of the shape'),
        ],
        adaptationAxis: 'tolerancePercent',
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  TraceContent parseContent(ActivitySpec spec, ItemPackResolver packs) =>
      parseTraceContent(spec);

  @override
  Iterable<String> assetsFor(TraceContent content) => content.assetPaths;

  @override
  ActivityCubit<TraceContent, dynamic> createCubit(
    ActivitySession<TraceContent> session,
  ) =>
      TraceCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! TraceStep) {
        return const SizedBox.shrink();
      }
      return TraceBoard(step: step, state: state, submit: submit);
    };
  }
}
