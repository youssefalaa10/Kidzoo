import 'dart:async';
import 'dart:math';

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
import 'package:kidzo/features/Adventure/engine/engines/hidden_clue/scene_props.dart';
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
    this.props = const <SceneProp>[],
    this.covers = const <SceneProp>[],
    this.ground,
    this.accentColorValue,
  });

  final List<HiddenClue> clues;
  final String? sceneImage;

  /// Scenery. Authored, never interactive, drawn behind everything.
  ///
  /// A clue floating on a photograph is a picture of an object; a clue lying
  /// among bushes and stones is somewhere a thing could plausibly have landed,
  /// which is the difference between spotting it and finding it.
  final List<SceneProp> props;

  /// Things resting **over** the clue that the child can move aside.
  ///
  /// Authored so that each one leaves part of the clue showing. Moving them is
  /// optional: the exposed part stays tappable throughout, so the scene is
  /// always winnable without touching a cover. That is what keeps it very easy
  /// while still feeling discovered rather than handed over.
  final List<SceneProp> covers;

  /// A soft band along the bottom, so objects sit on something.
  final SceneProp? ground;

  /// Parsed from `presentation.accent`, as `0xRRGGBB` with full alpha.
  final int? accentColorValue;

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
        // Precached like everything else: a leaf that pops in after the prompt
        // has told the child to look under it is worse than no leaf at all.
        for (final SceneProp prop in <SceneProp>[
          ...props,
          ...covers,
          if (ground != null) ground!,
        ])
          if (prop.image != null) prop.image!,
      ];
}

class HiddenClueStep extends ActivityStep {
  const HiddenClueStep({
    required String stepId,
    required this.clue,
    required this.noisePositions,
    this.revealOnIdleSeconds = 0,
    this.props = const <SceneProp>[],
    this.covers = const <SceneProp>[],
    this.ground,
    this.accentColorValue,
  }) : super(stepId);

  final HiddenClue clue;

  /// Carried on the step for the same reason everything else is: the board is
  /// handed a step, never the content object.
  final List<SceneProp> props;
  final List<SceneProp> covers;
  final SceneProp? ground;

  /// Decoy positions, fixed at build time so the scene never shifts under a
  /// finger mid-search.
  final List<MapEntry<PackItem, Offset>> noisePositions;

  /// Carried on the step so the board can honour it without reaching back into
  /// the cubit for content — the same rule every other board follows.
  final int revealOnIdleSeconds;

  /// The Adventure's colour, so drawn scenery belongs to this scene.
  final int? accentColorValue;
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
        props: content.props,
        covers: content.covers,
        ground: content.ground,
        accentColorValue: content.accentColorValue,
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
          ContentParameter.list('props',
              description: 'scenery: shape or image, positionPercent, scale, '
                  'turn, flip. Never interactive'),
          ContentParameter.list('covers',
              description: 'things lying over the clue that the child can move '
                  'aside. Each must leave part of the clue showing'),
          ContentParameter.text('ground',
              description: 'a named shape for the floor the scene sits on'),
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

    final String? groundShape = reader.optionalString('ground');

    return HiddenClueContent(
      clues: clues,
      sceneImage:
          reader.optionalString('sceneImage') ?? spec.presentation.sceneImage,
      visualNoise: noise,
      revealOnIdleSeconds: reader.optionalInt('revealOnIdleSeconds') ?? 15,
      hitToleranceFraction:
          reader.optionalDouble('hitToleranceFraction') ?? 0.12,
      props: _readProps(reader.optionalMapList('props'), '$path.props'),
      covers: _readProps(
        reader.optionalMapList('covers'),
        '$path.covers',
        requireMove: true,
      ),
      ground: groundShape == null
          ? null
          : SceneProp(
              position: const Offset(0.5, 0.86),
              shape: _shapeNamed(groundShape, '$path.ground'),
            ),
      accentColorValue: _accentValue(spec.presentation.accent),
    );
  }

  /// Reads scenery. Every field is optional except where it cannot be.
  static List<SceneProp> _readProps(
    List<Map<String, dynamic>> raw,
    String path, {
    bool requireMove = false,
  }) {
    final List<SceneProp> props = <SceneProp>[];
    for (int index = 0; index < raw.length; index++) {
      final JsonReader entry = JsonReader(raw[index], '$path[$index]');
      final List<int> offset = entry.optionalIntList('offsetFromCluePercent');
      final List<int> at = entry.optionalIntList('positionPercent');

      if (requireMove) {
        if (offset.length != 2) {
          throw ActivityContentException(
            '$path[$index].offsetFromCluePercent',
            'expected [dx, dy] as whole percentages of the clue size. A cover '
            'is placed against the clue, not against the scene, so the overlap '
            'survives landscape',
          );
        }
      } else if (at.length != 2) {
        throw ActivityContentException(
          '$path[$index].positionPercent',
          'expected [x, y] as whole percentages of the scene',
        );
      }
      final String? image = entry.optionalString('image');
      final String? shape = entry.optionalString('shape');
      if (image == null && shape == null) {
        throw ActivityContentException(
          '$path[$index]',
          'needs either an image path or a shape name',
        );
      }
      final String? move = entry.optionalString('move');
      if (requireMove && move == null) {
        throw ActivityContentException(
          '$path[$index].move',
          'a cover the child cannot move is scenery; put it in props',
        );
      }
      props.add(SceneProp(
        position:
            at.length == 2 ? Offset(at[0] / 100, at[1] / 100) : Offset.zero,
        offsetFromClue: offset.length == 2
            ? Offset(offset[0] / 100, offset[1] / 100)
            : null,
        shape: shape == null ? null : _shapeNamed(shape, '$path[$index].shape'),
        image: image,
        scale: entry.optionalDouble('scale') ?? 1.0,
        // Authored in degrees, which is what a person laying out a scene
        // thinks in; stored in turns, which is what the renderer wants.
        turns: (entry.optionalDouble('turn') ?? 0) / 360,
        flip: raw[index]['flip'] == true,
        id: entry.optionalString('id'),
        move: move == null ? null : _moveNamed(move, '$path[$index].move'),
      ));
    }
    return props;
  }

  /// `#4AC49A` to an opaque colour value. A malformed accent is not worth
  /// failing an Adventure over — the scene falls back to its own greens.
  static int? _accentValue(String? hex) {
    if (hex == null) {
      return null;
    }
    final int? rgb = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return rgb == null ? null : 0xFF000000 | rgb;
  }

  static ScenePropShape _shapeNamed(String name, String path) {
    for (final ScenePropShape shape in ScenePropShape.values) {
      if (shape.name == name) {
        return shape;
      }
    }
    throw ActivityContentException(
      path,
      'unknown shape "$name"; known: '
      '${ScenePropShape.values.map((ScenePropShape s) => s.name).toList()}',
    );
  }

  static CoverMove _moveNamed(String name, String path) {
    for (final CoverMove move in CoverMove.values) {
      if (move.name == name) {
        return move;
      }
    }
    throw ActivityContentException(
      path,
      'unknown move "$name"; known: '
      '${CoverMove.values.map((CoverMove m) => m.name).toList()}',
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

  /// Scenery is drawn a good deal larger than a searchable object.
  ///
  /// A bush the size of the page would make the scene a second search rather
  /// than a place; scenery has to read as background at a glance.
  static const double _propFraction = 0.34;

  /// How big a cover is relative to the clue it lies over.
  ///
  /// Bigger than the clue, so it plausibly hides it, but nowhere near big
  /// enough to swallow it whole — the authored offset is what leaves the
  /// corner showing, and [_assertClueStaysVisible] checks that it did.
  static const double _coverFraction = 0.30;

  /// True while a cover should draw attention to itself.
  bool get _isNudging => state.scaffoldLevel == ScaffoldLevel.gentleRetry;

  /// True once the scene should simply get out of the child's way.
  ///
  /// The no-fail ladder already decides when a child has had enough of
  /// searching; the covers just listen to it. Nothing here is a new rule, and
  /// nothing here can fail the child — the worst case is that the page ends up
  /// fully uncovered and glowing.
  bool get _shouldClearCovers =>
      state.scaffoldLevel == ScaffoldLevel.narrowed ||
      state.scaffoldLevel == ScaffoldLevel.modelled;

  /// Covers that actually lie over the clue, and so are worth hinting at.
  ///
  /// Measured in clue-sizes: anything within one of them is touching the page.
  bool _isOverClue(SceneProp cover) =>
      (cover.offsetFromClue ?? Offset.zero).distance < 1.0;

  @override
  Widget build(BuildContext context) {
    final bool isRevealed = state.view?.highlightOptionId == step.clue.id;
    final bool isFound = state.lastOutcome == AttemptOutcome.correct;
    final Color accent = _accent;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size box = Size(constraints.maxWidth, constraints.maxHeight);
        final double baseSize =
            (box.shortestSide * _clueFraction).clamp(72.0, 190.0);
        final double noiseSize = baseSize * _noiseFraction;
        final double propSize =
            (box.shortestSide * _propFraction).clamp(90.0, 260.0);
        final double coverSize =
            (box.shortestSide * _coverFraction).clamp(84.0, 240.0);
        final double clueSize = baseSize * step.clue.scale;

        assert(
          _assertClueStaysVisible(box, clueSize, coverSize),
          'a cover fully hides ${step.clue.id}: the page must always be '
          'partly visible, or the child has nothing to find',
        );

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
              if (step.ground != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: box.height * 0.34,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: ScenePropPainter(
                        shape: step.ground!.shape ?? ScenePropShape.ground,
                        accent: accent,
                      ),
                    ),
                  ),
                ),
              // Scenery, then decoys, then the clue, then the covers over it.
              for (final SceneProp prop in step.props)
                _place(
                  box: box,
                  position: prop.position,
                  size: propSize * prop.scale,
                  child: ScenePropView(
                    prop: prop,
                    size: propSize * prop.scale,
                    accent: accent,
                  ),
                ),
              for (final MapEntry<PackItem, Offset> entry in step.noisePositions)
                _place(
                  box: box,
                  position: entry.value,
                  size: noiseSize,
                  child: IgnorePointer(
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
                ),
              _place(
                box: box,
                position: step.clue.position,
                size: clueSize,
                child: _ClueTarget(
                  clue: step.clue,
                  size: clueSize,
                  isRevealed: isRevealed,
                  isFound: isFound,
                  languageCode: state.languageCode,
                  onTap: () => submit(ChoiceAttempt(step.clue.id)),
                ),
              ),
              // Covers last, so they sit *on* the page. Today's rule is that
              // the clue is always topmost, which exists so a randomly placed
              // decoy can never bury it. These are authored, not random, and
              // each one is checked above to leave the page partly showing, so
              // the inversion is safe here and nowhere else.
              for (final SceneProp cover in step.covers)
                _placeAt(
                  centre: _coverCentre(cover, box, clueSize),
                  size: coverSize * cover.scale,
                  child: _MovableCover(
                    key: ValueKey<String>('${step.stepId}_${cover.id}'),
                    cover: cover,
                    size: coverSize * cover.scale,
                    accent: accent,
                    isNudging: _isNudging && _isOverClue(cover),
                    // Once the ladder has given up on searching, anything over
                    // the page moves itself. A child who could not find it has
                    // still found it, which is the whole point of errorless.
                    isClearedAway: _shouldClearCovers && _isOverClue(cover),
                    onMoved: () => KidHaptics.tap(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Centres [child] on a normalized [position] within [box].
  Widget _place({
    required Size box,
    required Offset position,
    required double size,
    required Widget child,
  }) {
    return _placeAt(
      centre: Offset(position.dx * box.width, position.dy * box.height),
      size: size,
      child: child,
    );
  }

  Widget _placeAt({
    required Offset centre,
    required double size,
    required Widget child,
  }) {
    return Positioned(
      left: centre.dx - size / 2,
      top: centre.dy - size / 2,
      width: size,
      height: size,
      child: child,
    );
  }

  /// A cover sits against the clue, measured in clue-sizes, so the overlap the
  /// author drew is the overlap every child sees.
  Offset _coverCentre(SceneProp cover, Size box, double clueSize) {
    final Offset clue = Offset(
      step.clue.position.dx * box.width,
      step.clue.position.dy * box.height,
    );
    final Offset offset = cover.offsetFromClue ?? Offset.zero;
    return clue + Offset(offset.dx * clueSize, offset.dy * clueSize);
  }

  Color get _accent {
    final int? value = step.accentColorValue;
    return value == null ? KidUi.correct : Color(value);
  }

  /// Checks that the covers leave enough of the clue showing to be tapped.
  ///
  /// Runs only in debug, and only as an `assert`, but the board is pumped for
  /// every authored activity at three screen sizes — so an author who nudges a
  /// frond too far over the page finds out from the test suite rather than from
  /// a child who cannot finish the story.
  bool _assertClueStaysVisible(Size box, double clueSize, double coverSize) {
    if (step.covers.isEmpty) {
      return true;
    }
    final Rect clue = Rect.fromCenter(
      center: Offset(
        step.clue.position.dx * box.width,
        step.clue.position.dy * box.height,
      ),
      width: clueSize,
      height: clueSize,
    );
    final List<Rect> covers = <Rect>[
      for (final SceneProp cover in step.covers)
        Rect.fromCenter(
          center: _coverCentre(cover, box, clueSize),
          // Drawn art rarely fills its box; treating the cover as its full
          // square is the pessimistic reading, which is the right one here.
          width: coverSize * cover.scale,
          height: coverSize * cover.scale,
        ),
    ];

    // Sample the clue on a grid and count how much of it nothing sits over.
    const int steps = 5;
    int visible = 0;
    for (int row = 0; row < steps; row++) {
      for (int column = 0; column < steps; column++) {
        final Offset point = Offset(
          clue.left + clue.width * (column + 0.5) / steps,
          clue.top + clue.height * (row + 0.5) / steps,
        );
        if (!covers.any((Rect cover) => cover.contains(point))) {
          visible++;
        }
      }
    }
    return visible / (steps * steps) >= 0.25;
  }
}

/// Something lying over the clue that the child can push out of the way.
///
/// Moving it is **not** an attempt: no score, no ladder, no telemetry. It is
/// scenery that happens to be movable, and the distinction matters — a child
/// who lifts three leaves before touching the page has not made three mistakes.
class _MovableCover extends StatefulWidget {
  const _MovableCover({
    required this.cover,
    required this.size,
    required this.accent,
    required this.isNudging,
    required this.isClearedAway,
    required this.onMoved,
    super.key,
  });

  final SceneProp cover;
  final double size;
  final Color accent;

  /// The first rung of help: wobble, so the child learns it can be touched.
  final bool isNudging;

  /// The later rungs: get out of the way without being asked.
  final bool isClearedAway;

  final VoidCallback onMoved;

  @override
  State<_MovableCover> createState() => _MovableCoverState();
}

class _MovableCoverState extends State<_MovableCover>
    with TickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: KidUi.medium,
  );

  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  bool _hasMoved = false;

  @override
  void didUpdateWidget(_MovableCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNudging && !oldWidget.isNudging) {
      _wobble.forward(from: 0);
    }
    if (widget.isClearedAway && !_hasMoved) {
      _move();
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _wobble.dispose();
    super.dispose();
  }

  void _move() {
    if (_hasMoved) {
      return;
    }
    _hasMoved = true;
    _slide.forward();
    widget.onMoved();
  }

  /// Where the cover ends up, as a multiple of its own size. It parks just
  /// clear of the clue and stays there — a cover that sprang back would undo
  /// the child's one action.
  Offset get _destination {
    switch (widget.cover.move ?? CoverMove.slideRight) {
      case CoverMove.slideLeft:
        return const Offset(-0.85, 0.12);
      case CoverMove.slideRight:
        return const Offset(0.85, 0.12);
      case CoverMove.slideUp:
        return const Offset(0.1, -0.8);
      case CoverMove.slideDown:
        return const Offset(0.1, 0.8);
      case CoverMove.lift:
        return const Offset(0.35, -0.55);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Move',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _move,
        // Drag as well as tap. A child who instinctively sweeps a leaf aside
        // should be rewarded for it rather than told to tap instead.
        onPanStart: (DragStartDetails _) => _move(),
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_slide, _wobble]),
          builder: (BuildContext context, Widget? child) {
            final double slid = Curves.easeOutCubic.transform(_slide.value);
            final double wobble =
                sin(_wobble.value * pi * 3) * (1 - _wobble.value) * 0.05;
            return Transform.translate(
              offset: Offset(
                _destination.dx * widget.size * slid,
                _destination.dy * widget.size * slid,
              ),
              child: Transform.rotate(
                angle: wobble + slid * 0.22,
                child: Opacity(opacity: 1 - slid * 0.25, child: child),
              ),
            );
          },
          child: ScenePropView(
            prop: widget.cover,
            size: widget.size,
            accent: widget.accent,
          ),
        ),
      ),
    );
  }
}

class _ClueTarget extends StatelessWidget {
  const _ClueTarget({
    required this.clue,
    required this.size,
    required this.isRevealed,
    required this.isFound,
    required this.languageCode,
    required this.onTap,
  });

  final HiddenClue clue;
  final double size;
  final bool isRevealed;

  /// Set for the moment between the child touching the page and the story
  /// taking over, which is long enough to be worth celebrating in place.
  final bool isFound;

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
          scale: isFound
              ? 1.3
              : isRevealed
                  ? 1.18
                  : 1.0,
          child: AnimatedContainer(
            duration: KidUi.medium,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isFound
                    ? KidUi.correct
                    : isRevealed
                        ? KidUi.hint
                        : Colors.transparent,
                width: isRevealed || isFound ? size * 0.06 : 0,
              ),
              boxShadow: isFound
                  ? KidUi.shadow(KidUi.correct, strength: 2)
                  : isRevealed
                      ? KidUi.shadow(KidUi.hint, strength: 1.6)
                      : null,
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
