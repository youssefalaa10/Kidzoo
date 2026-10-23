import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'body_artwork.dart';
import 'body_game_cubit.dart';
import 'body_parts.dart';

class BodyBoard extends StatefulWidget {
  const BodyBoard({required this.state, required this.text, super.key});
  final BodyGameState state;
  final BodyText text;
  @override
  State<BodyBoard> createState() => _BodyBoardState();
}

class _BodyBoardState extends State<BodyBoard>
    with SingleTickerProviderStateMixin {
  final GlobalKey _surfaceKey = GlobalKey();
  late final AnimationController _animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 850))
    ..value = 1;
  BodyPartId? _hover;
  bool _overview = true;

  @override
  void didUpdateWidget(BodyBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.stage != widget.state.stage) {
      _overview = widget.state.stage == 0;
      _hover = null;
    }
    if (widget.state.stage == 0 &&
        widget.state.selected != null &&
        widget.state.hintVisible &&
        (widget.state.selected != oldWidget.state.selected ||
            !oldWidget.state.hintVisible)) {
      _overview = false;
    }
    if (widget.state.stage == 0 &&
        widget.state.placed.isEmpty &&
        oldWidget.state.placed.isNotEmpty) {
      _overview = true;
    }
    if (widget.state.lastPlaced != null &&
        widget.state.lastPlaced != oldWidget.state.lastPlaced) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _animation.value = 1;
      } else {
        _animation.forward(from: 0);
      }
    }
  }

  Offset _scenePosition(Offset global, BodyViewport viewport) {
    final RenderBox box =
        _surfaceKey.currentContext!.findRenderObject()! as RenderBox;
    return viewport.toScene(box.globalToLocal(global));
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BodyGameCubit cubit = context.read<BodyGameCubit>();
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .8),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFE9E0F6), width: 2)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (context, constraints) {
        final Size size = constraints.biggest;
        final BodyViewport viewport = BodyViewport(
            size: size,
            stage: widget.state.stage,
            overview: _overview || widget.state.complete);
        return Stack(children: [
          Positioned.fill(
              child: DragTarget<BodyPartId>(
            onWillAcceptWithDetails: (details) =>
                widget.state.available.any((part) => part.id == details.data),
            onMove: (details) {
              final BodyPartId? hit = const BodyParts().hitTest(
                  _scenePosition(details.offset, viewport),
                  widget.state.available);
              final BodyPartId? highlight = hit == details.data ? hit : null;
              if (_hover != highlight) {
                setState(() => _hover = highlight);
                if (highlight != null) KidHaptics.tap();
              }
            },
            onLeave: (_) => setState(() => _hover = null),
            onAcceptWithDetails: (details) {
              final bool correct = cubit.placeAt(
                  details.data, _scenePosition(details.offset, viewport));
              if (correct) KidHaptics.success();
              setState(() => _hover = null);
            },
            builder: (context, candidates, rejected) => GestureDetector(
              key: _surfaceKey,
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final BodyPartId? selected = widget.state.selected;
                if (selected != null) {
                  if (cubit.placeAt(
                      selected, viewport.toScene(details.localPosition))) {
                    KidHaptics.success();
                  }
                } else {
                  cubit.hint();
                }
              },
              child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) => CustomPaint(
                        size: size,
                        painter: BodyCharacterPainter(
                            placed: widget.state.placed,
                            stage: widget.state.stage,
                            viewport: viewport,
                            highlight: _hover ??
                                (widget.state.hintVisible
                                    ? widget.state.selected
                                    : null),
                            lastPlaced: widget.state.lastPlaced,
                            animation: _animation.value,
                            complete: widget.state.complete),
                      )),
            ),
          )),
          // Screen readers can select and place with the same validation as a
          // pointer. These semantic nodes do not intercept ordinary dragging.
          for (final BodyPart part in widget.state.available)
            for (final Offset anchor in part.anchors)
              Positioned(
                  left: viewport.toLocal(anchor).dx - 22,
                  top: viewport.toLocal(anchor).dy - 22,
                  width: 44,
                  height: 44,
                  child: IgnorePointer(
                      child: Semantics(
                          label: widget
                              .text('bodyTarget')
                              .replaceAll('{part}', widget.text(part.nameKey)),
                          button: true,
                          onTap: () {
                            final BodyPartId? selected = widget.state.selected;
                            if (selected == null) {
                              cubit.select(part.id);
                            } else {
                              cubit.placeAt(selected, anchor);
                            }
                          },
                          child: const SizedBox.expand()))),
          if (widget.state.stage < 2)
            Positioned(
                right: 6,
                bottom: 6,
                child: IconButton.filledTonal(
                  tooltip:
                      widget.text(_overview ? 'bodyCloseUp' : 'bodyWholeBody'),
                  onPressed: () => setState(() {
                    _overview = !_overview;
                    _hover = null;
                  }),
                  icon: Icon(_overview
                      ? Icons.zoom_in_rounded
                      : Icons.accessibility_new_rounded),
                )),
        ]);
      }),
    );
  }
}

class BodyPartTray extends StatelessWidget {
  const BodyPartTray(
      {required this.state,
      required this.text,
      this.vertical = false,
      super.key});
  final BodyGameState state;
  final BodyText text;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (state.stageComplete) return const SizedBox.shrink();
    return ListView.separated(
      key: ValueKey('body-tray-${state.stage}'),
      scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
      padding: const EdgeInsets.all(6),
      itemCount: state.available.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10, height: 10),
      itemBuilder: (context, index) {
        final BodyPart part = state.available[index];
        final bool selected = state.selected == part.id;
        final BodyGameCubit cubit = context.read<BodyGameCubit>();
        return Draggable<BodyPartId>(
          key: ValueKey('body-drag-${part.id.name}'),
          data: part.id,
          // The pointer is the drop coordinate on touch and on desktop. The
          // feedback is centered visually without shifting that coordinate.
          dragAnchorStrategy: pointerDragAnchorStrategy,
          maxSimultaneousDrags: 1,
          onDragStarted: () => cubit.select(part.id, forDrag: true),
          onDraggableCanceled: (_, __) => cubit.reject(part.id),
          feedback: FractionalTranslation(
              translation: const Offset(-.5, -.5),
              child: Material(
                  color: Colors.transparent,
                  child: Container(
                      width: 94,
                      height: 94,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: KidUi.cream.withValues(alpha: .95),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: KidUi.shadow(KidUi.primary)),
                      child: BodyPartIllustration(part: part.id)))),
          childWhenDragging: Opacity(
              opacity: .3,
              child: BodyTrayCard(
                  part: part,
                  text: text,
                  selected: selected,
                  vertical: vertical)),
          child: BodyTrayCard(
              part: part,
              text: text,
              selected: selected,
              vertical: vertical,
              onSelect: () => cubit.select(part.id)),
        );
      },
    );
  }
}

class BodyTrayCard extends StatelessWidget {
  const BodyTrayCard(
      {required this.part,
      required this.text,
      required this.selected,
      required this.vertical,
      this.onSelect,
      super.key});
  final BodyPart part;
  final BodyText text;
  final bool selected;
  final bool vertical;
  final VoidCallback? onSelect;
  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        label: text(part.nameKey),
        child: SizedBox(
            width: vertical ? null : 116,
            height: vertical ? 118 : null,
            child: Material(
              color: selected ? const Color(0xFFF0E7FF) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                      color: selected ? KidUi.primary : const Color(0xFFE7DFF1),
                      width: selected ? 3 : 1.5)),
              child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onSelect,
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(children: [
                        Expanded(
                            child: SizedBox(
                                width: 76,
                                child: BodyPartIllustration(part: part.id))),
                        const SizedBox(height: 5),
                        Text(text(part.nameKey),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                color: KidUi.ink)),
                      ]))),
            )),
      );
}
