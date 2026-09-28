import 'dart:async';

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

/// One thing hidden in the scene.
@immutable
class HiddenClue {
  const HiddenClue({
    required this.id,
    required this.position,
    required this.imageAsset,
    required this.label,
    this.scale = 1.0,
  });

  final String id;

  /// Normalized 0..1 within the scene box.
  ///
  /// Normalized rather than pixels so a scene authored once works on a phone, a
  /// tablet and in landscape. It is also why hidden-object content does **not**
  /// mirror in Arabic: the painted scene is a picture, not a line of text, and
  /// a mirrored jungle simply looks wrong.
  final Offset position;

  final String imageAsset;
  final LocalizedText label;

  /// Relative to the computed base size; lets an author make one clue harder by
  /// making it smaller rather than by moving it somewhere unfair.
  final double scale;
}

class HiddenClueContent extends ActivityContent {
  const HiddenClueContent({
    required this.clues,
    required this.sceneImage,
    required this.visualNoise,
    required this.revealOnIdleSeconds,
    required this.hitToleranceFraction,
  });

  final List<HiddenClue> clues;
  final String? sceneImage;

  /// Decorative items scattered to make the search real rather than trivial.
  final List<PackItem> visualNoise;

  /// After this long with no progress, the scene nudges the target. Searching
  /// is the point; being stuck is not.
  final int revealOnIdleSeconds;

  /// How close a tap must land, as a fraction of the scene's smaller side.
  ///
  /// Generous by default. A child who found the clue but missed it by a few
  /// millimetres has a motor problem, and recording that as "did not find it"
  /// would be a measurement error rather than a finding.
  final double hitToleranceFraction;

  Iterable<String> get assetPaths => <String>[
        if (sceneImage != null) sceneImage!,
        ...clues.map((HiddenClue clue) => clue.imageAsset),
        ...visualNoise.map((PackItem item) => item.imageAsset),
      ];
}

class HiddenClueStep extends ActivityStep {
  const HiddenClueStep({
    required String stepId,
    required this.clue,
    required this.noisePositions,
    this.revealOnIdleSeconds = 0,
  }) : super(stepId);

  final HiddenClue clue;

  /// Decoy positions, fixed at build time so the scene never shifts under a
  /// finger mid-search.
  final List<MapEntry<PackItem, Offset>> noisePositions;

  /// Carried on the step so the board can honour it without reaching back into
  /// the cubit for content — the same rule every other board follows.
  final int revealOnIdleSeconds;
}

class HiddenClueCubit extends ActivityCubit<HiddenClueContent, HiddenClueStep> {
  HiddenClueCubit(super.session);

  @override
  List<HiddenClueStep> buildSteps() {
    return content.clues.map((HiddenClue clue) {
      final List<MapEntry<PackItem, Offset>> noise =
          <MapEntry<PackItem, Offset>>[];
      for (final PackItem item in content.visualNoise) {
        Offset candidate;
        int guard = 0;
        do {
          candidate = Offset(
            0.1 + services.random.nextDouble() * 0.8,
            0.12 + services.random.nextDouble() * 0.72,
          );
          guard++;
          // Decoys must not sit on top of the clue, or the search becomes luck
          // rather than search. The keep-out radius grew with the art: at the
          // old 0.14 a decoy could land close enough to physically cover a clue
          // drawn at the new size, and a clue you cannot see is not hidden, it
          // is absent.
        } while ((candidate - clue.position).distance < 0.24 && guard < 24);
        noise.add(MapEntry<PackItem, Offset>(item, candidate));
      }
      return HiddenClueStep(
        stepId: 'clue_${clue.id}',
        clue: clue,
        noisePositions: noise,
        revealOnIdleSeconds: content.revealOnIdleSeconds,
      );
    }).toList(growable: false);
  }

  @override
  ActivityJudgement judge(HiddenClueStep step, ActivityAttempt attempt) {
    if (attempt is ChoiceAttempt) {
      return attempt.optionId == step.clue.id
          ? const ActivityJudgement.correct()
          : const ActivityJudgement.wrongItem();
    }
    if (attempt is! TapPointAttempt) {
      return const ActivityJudgement.wrongItem();
    }
    final double distance = (attempt.normalized - step.clue.position).distance;
    return distance <= content.hitToleranceFraction
        ? const ActivityJudgement.correct()
        : const ActivityJudgement.wrongItem();
  }

  @override
  ActivityStepView describe(HiddenClueStep step, ScaffoldLevel level) {
    return ActivityStepView(
      prompt: spec.narration.prompt,
      // Named out loud the moment it is found, so the child hears what they
      // just recovered rather than only seeing it vanish.
      revealLine: step.clue.label,
      liveOptionIds: <String>[step.clue.id],
      // At `modelled` the scene points straight at it. A search the child
      // cannot finish is worse than one that gives itself away.
      highlightOptionId: level == ScaffoldLevel.modelled ? step.clue.id : null,
    );
  }
}

/// Find-the-object scenes.
class HiddenClueEngine extends ActivityEngine<HiddenClueContent> {
  const HiddenClueEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'hidden_clue',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.visualSearch},
        interactionModes: <InteractionMode>{InteractionMode.tapInScene},
        contentParameters: <ContentParameter>[
          ContentParameter.list('clues',
              isRequired: true,
              description: 'each with id, normalized position and art'),
          ContentParameter.integer('visualNoiseCount',
              minValue: 0, maxValue: 24),
          ContentParameter.integer('revealOnIdleSeconds',
              minValue: 5, maxValue: 120),
          ContentParameter.text('sceneImage'),
          ContentParameter.text('itemsRef'),
          ContentParameter.list('noiseItemIds',
              description: 'which pack items to scatter as decoys'),
          ContentParameter.integer('hitToleranceFraction',
              description: 'how close a tap must land, as a fraction of the '
                  'scene. Generous on purpose: a near miss is a motor problem, '
                  'not a failure to find the clue'),
        ],
        adaptationAxis: 'visualNoiseCount',
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  HiddenClueContent parseContent(ActivitySpec spec, ItemPackResolver packs) {
    final JsonReader reader = spec.payloadReader;
    final String path = '${spec.sourcePath} > payload';

    final List<Map<String, dynamic>> rawClues = reader.optionalMapList('clues');
    if (rawClues.isEmpty) {
      throw ActivityContentException('$path.clues', 'need at least one clue');
    }

    final List<HiddenClue> clues = <HiddenClue>[];
    for (int index = 0; index < rawClues.length; index++) {
      final Map<String, dynamic> raw = rawClues[index];
      final JsonReader clueReader = JsonReader(raw, '$path.clues[$index]');
      final List<int> rawPosition =
          clueReader.optionalIntList('positionPercent');
      if (rawPosition.length != 2) {
        throw ActivityContentException(
          '$path.clues[$index].positionPercent',
          'expected [x, y] as whole percentages of the scene',
        );
      }
      clues.add(HiddenClue(
        id: clueReader.requireString('id'),
        position: Offset(rawPosition[0] / 100, rawPosition[1] / 100),
        imageAsset: clueReader.requireString('image'),
        label: LocalizedText.fromJson(raw['label'],
            debugPath: '$path.clues[$index].label'),
        scale: clueReader.optionalDouble('scale') ?? 1.0,
      ));
    }

    final int noiseCount = reader.optionalInt('visualNoiseCount') ?? 6;
    List<PackItem> noise = const <PackItem>[];
    final String? itemsRef = reader.optionalString('itemsRef');
    if (noiseCount > 0 && itemsRef != null) {
      final ItemPack pack =
          packs.require(itemsRef, debugPath: '$path.itemsRef');
      final List<PackItem> available = pack.select(
        reader.optionalStringList('noiseItemIds'),
        debugPath: '$path.noiseItemIds',
      );
      noise = List<PackItem>.generate(
        noiseCount,
        (int index) => available[index % available.length],
      );
    }

    return HiddenClueContent(
      clues: clues,
      sceneImage:
          reader.optionalString('sceneImage') ?? spec.presentation.sceneImage,
      visualNoise: noise,
      revealOnIdleSeconds: reader.optionalInt('revealOnIdleSeconds') ?? 15,
      hitToleranceFraction:
          reader.optionalDouble('hitToleranceFraction') ?? 0.12,
    );
  }

  @override
  Iterable<String> assetsFor(HiddenClueContent content) => content.assetPaths;

  @override
  ActivityCubit<HiddenClueContent, dynamic> createCubit(
    ActivitySession<HiddenClueContent> session,
  ) =>
      HiddenClueCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! HiddenClueStep) {
        return const SizedBox.shrink();
      }
      return _HiddenClueBoard(
        step: step,
        state: state,
        submit: submit,
        idleSeconds: idleSecondsFor(state),
      );
    };
  }

  /// How long the board waits before nudging, read back off the running state.
  ///
  /// The board builder is handed only the state, so the authored value reaches
  /// it through the step rather than through the content object.
  static int idleSecondsFor(ActivityState state) {
    final Object? step = state.engineStep;
    return step is HiddenClueStep ? step.revealOnIdleSeconds : 0;
  }
}

class _HiddenClueBoard extends StatefulWidget {
  const _HiddenClueBoard({
    required this.step,
    required this.state,
    required this.submit,
    required this.idleSeconds,
  });

  final HiddenClueStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  /// Seconds of no progress before the scene offers help by itself.
  final int idleSeconds;

  @override
  State<_HiddenClueBoard> createState() => _HiddenClueBoardState();
}

/// Runs the idle nudge the content has always asked for.
///
/// `revealOnIdleSeconds` was parsed, documented and declared as a content
/// parameter, and then **nothing ever read it** — so a child who could not find
/// the page simply sat in front of a jungle indefinitely. Searching is the
/// point; being stuck is not, and a hidden-object scene is the one activity
/// where a child can be stuck while producing no attempts at all, which means
/// the no-fail ladder never hears about it. The timer is what gives the ladder
/// something to respond to.
class _HiddenClueBoardState extends State<_HiddenClueBoard> {
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _restartIdleTimer();
  }

  @override
  void didUpdateWidget(_HiddenClueBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Any change of step, or any attempt landing, is progress: start the clock
    // again rather than nudging someone who is actively trying.
    if (oldWidget.step.stepId != widget.step.stepId ||
        oldWidget.state.scaffoldLevel != widget.state.scaffoldLevel ||
        oldWidget.state.isBoardLocked != widget.state.isBoardLocked) {
      _restartIdleTimer();
    }
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    if (widget.idleSeconds <= 0) {
      return;
    }
    if (widget.state.isBoardLocked ||
        widget.state.scaffoldLevel == ScaffoldLevel.modelled) {
      return;
    }
    _idleTimer = Timer(
      Duration(seconds: widget.idleSeconds),
      () {
        if (!mounted || widget.state.isBoardLocked) {
          return;
        }
        // Routed through the ordinary help request, so an idle child gets
        // exactly the same escalation as one who asked — one rung at a time,
        // ending at a scene that points straight at the page.
        widget.submit(const HelpRequestedAttempt());
      },
    );
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  HiddenClueStep get step => widget.step;
  ActivityState get state => widget.state;
  ActivityAttemptCallback get submit => widget.submit;

  /// How big a searchable object is, as a fraction of the scene's short side.
  ///
  /// Raised from 0.16. At 0.16 the clue came out around 50dp on a phone — under
  /// half [KidUi.minTouchYoung] and well inside the size band where children
  /// miss targets about a third of the time, so "did not find it" was partly a
  /// measurement of finger size. The search stays a real search because the
  /// *decoys* grew with it: what makes a hidden object hard is how much it
  /// looks like its neighbours, not how few pixels it is.
  static const double _clueFraction = 0.24;

  /// Decoys sit slightly smaller than the clue so the scene has a focal size,
  /// but not so much smaller that the clue is findable by size alone.
  static const double _noiseFraction = 0.88;

  @override
  Widget build(BuildContext context) {
    final bool isRevealed = state.view?.highlightOptionId == step.clue.id;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size box = Size(constraints.maxWidth, constraints.maxHeight);
        final double baseSize =
            (box.shortestSide * _clueFraction).clamp(72.0, 190.0);
        final double noiseSize = baseSize * _noiseFraction;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails details) {
            final Offset normalized = Offset(
              details.localPosition.dx / box.width,
              details.localPosition.dy / box.height,
            );
            submit(TapPointAttempt(normalized));
          },
          child: Stack(
            children: <Widget>[
              // Decoys first, so the clue always sits above them and can never
              // be covered by a decoy that happened to land on top.
              for (final MapEntry<PackItem, Offset> entry
                  in step.noisePositions)
                Positioned(
                  left: entry.value.dx * box.width - noiseSize / 2,
                  top: entry.value.dy * box.height - noiseSize / 2,
                  child: Opacity(
                    opacity: 0.85,
                    child: Image.asset(
                      entry.key.imageAsset,
                      width: noiseSize,
                      height: noiseSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              Positioned(
                left: step.clue.position.dx * box.width -
                    (baseSize * step.clue.scale) / 2,
                top: step.clue.position.dy * box.height -
                    (baseSize * step.clue.scale) / 2,
                child: _ClueTarget(
                  clue: step.clue,
                  size: baseSize * step.clue.scale,
                  isRevealed: isRevealed,
                  languageCode: state.languageCode,
                  onTap: () => submit(ChoiceAttempt(step.clue.id)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClueTarget extends StatelessWidget {
  const _ClueTarget({
    required this.clue,
    required this.size,
    required this.isRevealed,
    required this.languageCode,
    required this.onTap,
  });

  final HiddenClue clue;
  final double size;
  final bool isRevealed;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: clue.label.resolve(languageCode),
      child: GestureDetector(
        onTap: () {
          KidHaptics.tap();
          onTap();
        },
        child: AnimatedScale(
          // The reveal grows the target as well as ringing it. A glow alone is
          // easy to miss on a busy painted background; a glow that also makes
          // the thing bigger is unmistakably pointing at something.
          duration: KidUi.medium,
          curve: Curves.easeOutBack,
          scale: isRevealed ? 1.18 : 1.0,
          child: AnimatedContainer(
            duration: KidUi.medium,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isRevealed ? KidUi.hint : Colors.transparent,
                width: isRevealed ? size * 0.06 : 0,
              ),
              boxShadow:
                  isRevealed ? KidUi.shadow(KidUi.hint, strength: 1.6) : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.04),
              child: Image.asset(clue.imageAsset, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
