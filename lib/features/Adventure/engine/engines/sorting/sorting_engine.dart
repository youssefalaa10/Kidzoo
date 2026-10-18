import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kidzo/core/helpers/speech.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_pick_card.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// What a token does when it arrives in a bin, and what it does when it is put
/// in the wrong one.
///
/// This is the difference between a sorting activity and a quiz about sorting.
/// A bin that is "the sea floor" and a bin that is "the surface" are not two
/// equivalent boxes: a thing that floats *cannot stay* on the sea floor, and
/// showing it drift back up is a better answer than any sound a button could
/// make. The engine has no idea what water is — content says which way each bin
/// sends things, and the board plays it.
enum SettleMotion {
  /// Arrives from below and bobs. Used for floats, balloons, lifts.
  rise,

  /// Arrives from above and lands heavily. Used for weights, stones, drops.
  sink,

  /// Just settles in place. The neutral default, and what every existing
  /// sorting activity keeps without being edited.
  settle;

  static SettleMotion parse(String raw, String path) {
    for (final SettleMotion motion in SettleMotion.values) {
      if (motion.name == raw) {
        return motion;
      }
    }
    throw ActivityContentException(
      path,
      '"$raw" is not a settle motion; expected one of '
      '${SettleMotion.values.map((SettleMotion m) => m.name).toList()}',
    );
  }

  /// Vertical direction, as a multiplier on a travel distance. Negative is up.
  double get direction => switch (this) {
        SettleMotion.rise => -1,
        SettleMotion.sink => 1,
        SettleMotion.settle => 0,
      };
}

/// One destination a token can go to.
@immutable
class SortingBin {
  const SortingBin({
    required this.id,
    required this.attributeValue,
    required this.label,
    this.spokenLabel,
    this.imageAsset,
    this.settleMotion = SettleMotion.settle,
  });

  final String id;
  final String attributeValue;
  final LocalizedText label;

  /// What the narrator reads when this bin is tapped for inspection (without a
  /// token selected). Defaults to [label] when absent. Lets the market stall
  /// say something richer than its display name, like the kinds of things that
  /// belong there.
  final LocalizedText? spokenLabel;

  final String? imageAsset;
  final SettleMotion settleMotion;
}

/// A token that has already been sorted, kept so the bin it went into can go on
/// showing it.
///
/// Carried on the step rather than accumulated in the board's own state,
/// because the board is a pure function of the state by contract — and because
/// a child who leaves half way through and comes back must find the bins as
/// full as they left them, which board-local state would not survive.
@immutable
class SortedToken {
  const SortedToken({required this.item, required this.binId});

  final PackItem item;
  final String binId;
}

class SortingContent extends ActivityContent {
  const SortingContent({
    required this.activeAttribute,
    required this.heldConstant,
    required this.bins,
    required this.items,
    required this.itemsPerRound,
    required this.roundCount,
  });

  /// The one attribute being taught this round.
  final String activeAttribute;

  /// Attributes deliberately held identical across all items.
  ///
  /// This is the whole craft of a sorting activity. Young children attend to
  /// the most salient attribute — usually colour — even when it is irrelevant,
  /// so teaching "sort by size" while the sizes also differ in colour teaches
  /// colour. Holding the others constant is what makes the target attribute the
  /// only thing that can be sorted on.
  final List<String> heldConstant;

  final List<SortingBin> bins;
  final List<PackItem> items;
  final int itemsPerRound;
  final int roundCount;

  Iterable<String> get assetPaths => <String>[
        ...items.map((PackItem item) => item.imageAsset),
        ...bins.map((SortingBin bin) => bin.imageAsset).whereType<String>(),
      ];
}

class SortingStep extends ActivityStep {
  const SortingStep({
    required String stepId,
    required this.index,
    required this.item,
    required this.correctBinId,
    required this.bins,
    this.alreadySorted = const <SortedToken>[],
  }) : super(stepId);

  /// Where this token sits in the round, from zero.
  ///
  /// Carried because the *first* token is the one the instruction is for. Every
  /// token after it gets its own name spoken instead, which is what an adult
  /// sitting beside the child would do: say what to do once, then just name the
  /// next thing as they hand it over.
  final int index;

  final PackItem item;
  final String correctBinId;

  /// Carried on the step so the board is a pure function of the state and does
  /// not have to reach back into the cubit for its own content.
  final List<SortingBin> bins;

  /// Everything sorted before this token, in the bin it belongs to.
  ///
  /// The point is not bookkeeping: it is that the child can see the thing they
  /// are building. Eight placements into a float/sink round, the surface bin
  /// visibly holds a lift and the floor visibly holds ballast, and that is the
  /// activity's output rather than a number in the corner of the screen.
  final List<SortedToken> alreadySorted;

  Iterable<SortedToken> sortedInto(String binId) => alreadySorted
      .where((SortedToken token) => token.binId == binId);

  SortingBin? binById(String id) {
    for (final SortingBin bin in bins) {
      if (bin.id == id) {
        return bin;
      }
    }
    return null;
  }
}

class SortingCubit extends ActivityCubit<SortingContent, SortingStep> {
  SortingCubit(super.session);

  @override
  List<SortingStep> buildSteps() {
    final List<PackItem> pool = List<PackItem>.of(content.items)
      ..shuffle(services.random);
    final int total = (content.itemsPerRound * content.roundCount)
        .clamp(1, pool.length * content.roundCount);

    final List<SortingStep> steps = <SortingStep>[];
    final List<SortedToken> sorted = <SortedToken>[];
    for (int index = 0; index < total; index++) {
      final PackItem item = pool[index % pool.length];
      final String? value = item.attribute(content.activeAttribute);
      if (value == null) {
        throw ActivityContentException(
          '${spec.sourcePath} > payload.activeAttribute',
          'item "${item.id}" has no "${content.activeAttribute}" attribute, so '
              'it cannot be sorted by it',
        );
      }
      final SortingBin bin = content.bins.firstWhere(
        (SortingBin candidate) => candidate.attributeValue == value,
        orElse: () => throw ActivityContentException(
          '${spec.sourcePath} > payload.bins',
          'no bin accepts "${content.activeAttribute}=$value" (item '
              '"${item.id}")',
        ),
      );
      steps.add(SortingStep(
        stepId: 'sort_${index}_${item.id}',
        index: index,
        item: item,
        correctBinId: bin.id,
        bins: content.bins,
        alreadySorted: List<SortedToken>.unmodifiable(sorted),
      ));
      sorted.add(SortedToken(item: item, binId: bin.id));
    }
    return steps;
  }

  @override
  ActivityJudgement judge(SortingStep step, ActivityAttempt attempt) {
    // Tap-to-select names a bin without dragging anything, which is a
    // legitimate way to express a placement and the only way for a child who
    // cannot drag reliably. Judge it the same way.
    if (attempt is ChoiceAttempt) {
      return attempt.optionId == step.correctBinId
          ? const ActivityJudgement.correct()
          : const ActivityJudgement.wrongItem();
    }
    if (attempt is! PlacementAttempt) {
      return const ActivityJudgement.wrongItem();
    }
    if (attempt.targetId == step.correctBinId) {
      return const ActivityJudgement.correct();
    }
    // The motor/knowledge split: a drop that landed very close to the right bin
    // is a miss, not a misunderstanding, and the two need different responses.
    final double? distance = attempt.droppedAtDistance;
    if (distance != null && distance < 0.25) {
      return const ActivityJudgement.wrongSlotButRightItem();
    }
    return const ActivityJudgement.wrongItem();
  }

  @override
  ActivityStepView describe(SortingStep step, ScaffoldLevel level) {
    final List<String> allIds =
        content.bins.map((SortingBin bin) => bin.id).toList(growable: false);
    final List<String> live = services.coach.liveOptionsFor(
      level: level,
      allOptionIds: allIds,
      correctOptionId: step.correctBinId,
      random: services.random,
    );
    return ActivityStepView(
      prompt: spec.narration.prompt,
      // The written prompt stays the instruction — it is on screen the whole
      // time — while what is *said* changes per token. Repeating one sentence
      // once per animal made the activity sound stuck; naming the animal tells
      // the child something new every time and costs no new content, because
      // pack labels are already authored per locale with harakat.
      spokenPrompt: step.index == 0 ? null : step.item.label,
      liveOptionIds: live,
      dimmedOptionIds: allIds
          .where((String id) => !live.contains(id))
          .toList(growable: false),
      highlightOptionId:
          level == ScaffoldLevel.modelled ? step.correctBinId : null,
    );
  }
}

/// Sorting and classification.
class SortingEngine extends ActivityEngine<SortingContent> {
  const SortingEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'sorting',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.classification},
        interactionModes: <InteractionMode>{InteractionMode.dragToTarget},
        contentParameters: <ContentParameter>[
          ContentParameter.text('activeAttribute', isRequired: true),
          ContentParameter.list('heldConstant',
              description: 'attributes kept identical so the target attribute '
                  'is the only thing that varies'),
          ContentParameter.list('bins', isRequired: true,
              description: 'each with id, value, label, optional image and an '
                  'optional settleMotion (rise | sink | settle) saying which '
                  'way this bin sends things — which is how a wrong placement '
                  'gets answered by the world instead of by a buzzer'),
          ContentParameter.integer('itemsPerRound', minValue: 1, maxValue: 12),
          ContentParameter.integer('roundCount', minValue: 1, maxValue: 8),
          ContentParameter.text('itemsRef'),
          ContentParameter.list('itemIds'),
        ],
        adaptationAxis: 'itemsPerRound',
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  SortingContent parseContent(ActivitySpec spec, ItemPackResolver packs) {
    final JsonReader reader = spec.payloadReader;
    final String path = '${spec.sourcePath} > payload';

    final ItemPack pack = packs.require(
      reader.optionalString('itemsRef') ?? 'packs/fruits',
      debugPath: '$path.itemsRef',
    );
    final List<PackItem> items = pack.select(
      reader.optionalStringList('itemIds'),
      debugPath: '$path.itemIds',
    );

    final List<Map<String, dynamic>> rawBins = reader.optionalMapList('bins');
    if (rawBins.length < 2) {
      throw ActivityContentException(
          '$path.bins', 'sorting needs at least two bins');
    }
    final List<SortingBin> bins = <SortingBin>[];
    for (int index = 0; index < rawBins.length; index++) {
      final Map<String, dynamic> raw = rawBins[index];
      final JsonReader binReader = JsonReader(raw, '$path.bins[$index]');
      bins.add(SortingBin(
        id: binReader.requireString('id'),
        attributeValue: binReader.requireString('value'),
        label: LocalizedText.fromJson(raw['label'],
            debugPath: '$path.bins[$index].label'),
        spokenLabel: raw['spokenLabel'] == null
            ? null
            : LocalizedText.fromJson(raw['spokenLabel'],
                debugPath: '$path.bins[$index].spokenLabel'),
        imageAsset: binReader.optionalString('image'),
        settleMotion: SettleMotion.parse(
          binReader.optionalString('settleMotion') ?? 'settle',
          '$path.bins[$index].settleMotion',
        ),
      ));
    }

    return SortingContent(
      activeAttribute: reader.requireString('activeAttribute'),
      heldConstant: reader.optionalStringList('heldConstant'),
      bins: bins,
      items: items,
      itemsPerRound: reader.optionalInt('itemsPerRound') ?? 4,
      roundCount: reader.optionalInt('roundCount') ?? 1,
    );
  }

  @override
  Iterable<String> assetsFor(SortingContent content) => content.assetPaths;

  @override
  ActivityCubit<SortingContent, dynamic> createCubit(
    ActivitySession<SortingContent> session,
  ) =>
      SortingCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! SortingStep) {
        return const SizedBox.shrink();
      }
      return _SortingBoard(step: step, state: state, submit: submit);
    };
  }
}

class _SortingBoard extends StatefulWidget {
  const _SortingBoard({
    required this.step,
    required this.state,
    required this.submit,
  });

  final SortingStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<_SortingBoard> createState() => _SortingBoardState();
}

class _SortingBoardState extends State<_SortingBoard>
    with SingleTickerProviderStateMixin {
  /// Set when the child taps the token rather than dragging it.
  ///
  /// Tap-to-select is not a fallback here. Drag succeeds as little as 30% of
  /// the time for some school-age children, and WCAG 2.2 requires a
  /// single-pointer alternative to every drag, so both routes are first-class.
  bool _isTokenSelected = false;

  /// Plays once each time a token is put somewhere it cannot stay.
  ///
  /// The token travels the way it *actually* behaves — a float drifts up, a
  /// weight drops — and comes back. That is the correction: the object tells
  /// the child what it is, which is something they can reason from next time.
  /// A buzzer tells them only that an adult disagreed.
  late final AnimationController _reject;

  @override
  void initState() {
    super.initState();
    _reject = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  @override
  void dispose() {
    _reject.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_SortingBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      _isTokenSelected = false;
      _reject.value = 0;
      return;
    }
    if (widget.state.wrongAttemptsOnStep >
        oldWidget.state.wrongAttemptsOnStep) {
      _reject.forward(from: 0);
    }
  }

  void _place(String binId, {double? distance}) {
    setState(() => _isTokenSelected = false);
    widget.submit(PlacementAttempt(
      tokenId: widget.step.item.id,
      targetId: binId,
      droppedAtDistance: distance,
    ));
  }

  /// Speaks the bin's identity when the child taps it without holding a token.
  ///
  /// Lets the child explore what each stall is for before deciding where to put
  /// something. Skipped while the narrator is speaking (board locked) so the
  /// two voices never overlap.
  void _inspectBin(SortingBin bin) {
    if (widget.state.isBoardLocked) return;
    final String text =
        (bin.spokenLabel ?? bin.label).resolve(widget.state.languageCode);
    if (text.isNotEmpty) Speech.speak(text);
  }

  /// What this token does when it is where it belongs — which is also what it
  /// does when it is somewhere it does not.
  SettleMotion get _trueMotion =>
      widget.step.binById(widget.step.correctBinId)?.settleMotion ??
      SettleMotion.settle;

  @override
  Widget build(BuildContext context) {
    final ActivityStepView? view = widget.state.view;
    // Bin order comes from the step, not from the view: the ladder changes
    // which bins are *live*, and reordering them as it does so would move a
    // target out from under a finger already travelling toward it.
    final List<SortingBin> bins = widget.step.bins;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tokenSize =
            (constraints.maxHeight * 0.3).clamp(KidUi.minTouchYoung, 160.0);
        final double binSize =
            (constraints.maxWidth / (bins.length + 1)).clamp(96.0, 180.0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            AnimatedBuilder(
              animation: _reject,
              builder: (BuildContext context, Widget? child) {
                // Out and back along one arc, so it reads as the object moving
                // under its own weight rather than as a rejection shudder.
                final double travel =
                    math.sin(_reject.value * math.pi) * tokenSize * 0.42;
                return Transform.translate(
                  offset: Offset(0, travel * _trueMotion.direction),
                  child: child,
                );
              },
              child: KidPickCard<String>(
                imageAsset: widget.step.item.imageAsset,
                size: tokenSize,
                dragData: widget.step.item.id,
                state: _isTokenSelected
                    ? KidCardState.selected
                    : KidCardState.idle,
                label:
                    widget.step.item.label.resolve(widget.state.languageCode),
                onTap: () =>
                    setState(() => _isTokenSelected = !_isTokenSelected),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                for (final SortingBin bin in bins)
                  _BinTarget(
                    binId: bin.id,
                    size: binSize,
                    isLive: view?.liveOptionIds.contains(bin.id) ?? true,
                    isHighlighted: view?.highlightOptionId == bin.id,
                    isArmed: _isTokenSelected,
                    languageCode: widget.state.languageCode,
                    label: bin.label.resolve(widget.state.languageCode),
                    imageAsset: bin.imageAsset,
                    settleMotion: bin.settleMotion,
                    contents:
                        widget.step.sortedInto(bin.id).toList(growable: false),
                    onAccept: () => _place(bin.id),
                    onInspect: () => _inspectBin(bin),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BinTarget extends StatelessWidget {
  const _BinTarget({
    required this.binId,
    required this.size,
    required this.isLive,
    required this.isHighlighted,
    required this.isArmed,
    required this.languageCode,
    required this.label,
    required this.imageAsset,
    required this.settleMotion,
    required this.contents,
    required this.onAccept,
    required this.onInspect,
  });

  final String binId;
  final double size;
  final bool isLive;
  final bool isHighlighted;
  final bool isArmed;
  final String languageCode;
  final String label;
  final String? imageAsset;
  final SettleMotion settleMotion;

  /// What is already in here. Floats collect at the top of the bin and weights
  /// at the bottom, which costs one alignment and makes the two bins read as
  /// two different *places* rather than two boxes with different captions.
  final List<SortedToken> contents;

  final VoidCallback onAccept;

  /// Called when the child taps the bin WITHOUT a token selected — an
  /// exploratory tap that asks "what is this?". The board speaks the stall name
  /// or description so the child can learn each bin before committing.
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      // Note: translucent is already the default. It is called out rather than
      // set, because an opaque ancestor in a Stack can still swallow the hit,
      // which is the classic reason a Flutter drop silently does nothing.
      onWillAcceptWithDetails: (_) => isLive,
      onAcceptWithDetails: (_) => onAccept(),
      builder:
          (BuildContext context, List<String?> candidates, List<dynamic> _) {
        final bool isPreviewing = candidates.isNotEmpty;
        return GestureDetector(
          onTap: isLive && isArmed ? onAccept : onInspect,
          child: AnimatedScale(
            // Preview the snap before release, so the child can see it will
            // work before committing to letting go.
            scale: isPreviewing ? 1.08 : 1.0,
            duration: KidUi.fast,
            child: AnimatedOpacity(
              duration: KidUi.medium,
              opacity: isLive ? 1 : 0.3,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(KidUi.radiusCard),
                  border: Border.all(
                    color: isHighlighted || isPreviewing
                        ? KidUi.primary
                        : Colors.transparent,
                    width: isHighlighted || isPreviewing ? 5 : 0,
                  ),
                  boxShadow: KidUi.shadow(KidUi.primary, strength: 0.6),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          if (imageAsset != null)
                            Opacity(
                              opacity: contents.isEmpty ? 1.0 : 0.3,
                              child: Image.asset(imageAsset!,
                                  fit: BoxFit.contain),
                            ),
                          if (contents.isNotEmpty)
                            Padding(
                              // Keeps the pile off the bin's rounded corners,
                              // which otherwise clip the top of whatever
                              // collected at a `rise` bin's ceiling.
                              padding: EdgeInsets.all(size * 0.06),
                              child: Align(
                                alignment: settleMotion == SettleMotion.rise
                                    ? Alignment.topCenter
                                    : Alignment.bottomCenter,
                                child: _BinContents(
                                  contents: contents,
                                  binSize: size,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ActivityGlyphText(
                      label,
                      languageCode: languageCode,
                      fontSize: size * 0.16,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The pile inside a bin.
///
/// Overlapped rather than laid out in a grid, because a heap of things reads as
/// a heap at any count, while a grid reflows every time something lands and
/// makes the whole bin twitch.
class _BinContents extends StatelessWidget {
  const _BinContents({required this.contents, required this.binSize});

  final List<SortedToken> contents;
  final double binSize;

  static const int _maxShown = 6;

  @override
  Widget build(BuildContext context) {
    final List<SortedToken> shown = contents.length <= _maxShown
        ? contents
        : contents.sublist(contents.length - _maxShown);
    final double chip = binSize * 0.32;
    final double step = chip * 0.6;

    return SizedBox(
      height: chip,
      width: step * (shown.length - 1) + chip,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: SizedBox(
                width: chip,
                height: chip,
                child:
                    Image.asset(shown[i].item.imageAsset, fit: BoxFit.contain),
              ),
            ),
        ],
      ),
    );
  }
}
