import 'package:flutter/material.dart';
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

/// One destination a token can go to.
@immutable
class SortingBin {
  const SortingBin({
    required this.id,
    required this.attributeValue,
    required this.label,
    this.imageAsset,
  });

  final String id;
  final String attributeValue;
  final LocalizedText label;
  final String? imageAsset;
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
        ...bins
            .map((SortingBin bin) => bin.imageAsset)
            .whereType<String>(),
      ];
}

class SortingStep extends ActivityStep {
  const SortingStep({
    required String stepId,
    required this.item,
    required this.correctBinId,
    required this.bins,
  }) : super(stepId);

  final PackItem item;
  final String correctBinId;

  /// Carried on the step so the board is a pure function of the state and does
  /// not have to reach back into the cubit for its own content.
  final List<SortingBin> bins;

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
        item: item,
        correctBinId: bin.id,
        bins: content.bins,
      ));
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
      liveOptionIds: live,
      dimmedOptionIds:
          allIds.where((String id) => !live.contains(id)).toList(growable: false),
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
          ContentParameter.list('bins', isRequired: true),
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
        imageAsset: binReader.optionalString('image'),
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

class _SortingBoardState extends State<_SortingBoard> {
  /// Set when the child taps the token rather than dragging it.
  ///
  /// Tap-to-select is not a fallback here. Drag succeeds as little as 30% of
  /// the time for some school-age children, and WCAG 2.2 requires a
  /// single-pointer alternative to every drag, so both routes are first-class.
  bool _isTokenSelected = false;

  @override
  void didUpdateWidget(_SortingBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      _isTokenSelected = false;
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
            KidPickCard<String>(
              imageAsset: widget.step.item.imageAsset,
              size: tokenSize,
              dragData: widget.step.item.id,
              state: _isTokenSelected
                  ? KidCardState.selected
                  : KidCardState.idle,
              label: widget.step.item.label.resolve(widget.state.languageCode),
              onTap: () => setState(() => _isTokenSelected = !_isTokenSelected),
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
                    onAccept: () => _place(bin.id),
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
    required this.onAccept,
  });

  final String binId;
  final double size;
  final bool isLive;
  final bool isHighlighted;
  final bool isArmed;
  final String languageCode;
  final String label;
  final String? imageAsset;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      // Note: translucent is already the default. It is called out rather than
      // set, because an opaque ancestor in a Stack can still swallow the hit,
      // which is the classic reason a Flutter drop silently does nothing.
      onWillAcceptWithDetails: (_) => isLive,
      onAcceptWithDetails: (_) => onAccept(),
      builder: (BuildContext context, List<String?> candidates, List<dynamic> _) {
        final bool isPreviewing = candidates.isNotEmpty;
        return GestureDetector(
          onTap: isLive && isArmed ? onAccept : null,
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
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (imageAsset != null)
                      Expanded(
                        child: Image.asset(imageAsset!, fit: BoxFit.contain),
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
