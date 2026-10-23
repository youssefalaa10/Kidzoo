import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'sorting_activity_content.dart';
import 'sorting_activity_cubit.dart';

/// Coordinates preserve the references in either locale. Only text is RTL;
/// the cloud, washer and sad tooth stay on the left, as in the worksheets.
class SortingWorksheetLayout {
  const SortingWorksheetLayout(this.kind);
  final SortingActivityKind kind;
  static const Size size = Size(700, 970);
  Rect destination(int index) => Rect.fromLTWH(
      12 + index * 350,
      kind == SortingActivityKind.teeth ? 155 : 270,
      326,
      kind == SortingActivityKind.teeth ? 475 : 360);
  Rect hero(int index) => Rect.fromLTWH(
      (kind == SortingActivityKind.teeth ? 55 : 12) + index * 350,
      0,
      kind == SortingActivityKind.teeth ? 240 : 326,
      kind == SortingActivityKind.teeth ? 242 : 260);
  Rect tray(int index) => Rect.fromLTWH(
      12 + (index % 5) * 135.2, 674 + (index ~/ 5) * 142, 135.2, 142);
  Rect item(int index) => tray(index).deflate(10);
  Rect placed(int bin, int index) {
    final box = destination(bin);
    final topInset = kind == SortingActivityKind.teeth ? 100.0 : 18.0;
    final rowHeight = (box.height - topInset - 10) / 3;
    return Rect.fromLTWH(box.left + 25 + (index % 2) * 145,
        box.top + topInset + (index ~/ 2) * rowHeight, 130, rowHeight - 8);
  }
}

class SortingWorksheetBoard extends StatelessWidget {
  const SortingWorksheetBoard(
      {required this.content,
      required this.state,
      required this.languageCode,
      required this.onSelect,
      required this.onPlace,
      required this.onInspect,
      super.key});
  final SortingActivityContent content;
  final SortingActivityState state;
  final String languageCode;
  final ValueChanged<String> onSelect;
  final void Function(String id, String destination) onPlace;
  final ValueChanged<int> onInspect;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final layout = SortingWorksheetLayout(content.kind);
        final scale = constraints.maxWidth / SortingWorksheetLayout.size.width;
        Rect scaled(Rect rect) => Rect.fromLTWH(rect.left * scale,
            rect.top * scale, rect.width * scale, rect.height * scale);
        final positions = <String, Rect>{};
        for (var bin = 0; bin < 2; bin++) {
          var index = 0;
          // Insertion order is the child's placement order, not a shuffled sequence.
          for (final entry in state.placed.entries) {
            if (entry.value == content.destinations[bin].id) {
              positions[entry.key] = layout.placed(bin, index++);
            }
          }
        }
        return SizedBox(
          height: SortingWorksheetLayout.size.height * scale,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(clipBehavior: Clip.none, children: [
              for (var index = 0; index < 2; index++)
                Positioned.fromRect(
                    rect: scaled(layout.destination(index)),
                    child: _ClassificationBox(
                      destination: content.destinations[index],
                      color: content.kind == SortingActivityKind.teeth
                          ? const Color(0xFF777674)
                          : index == 0
                              ? const Color(0xFFDF625B)
                              : const Color(0xFF89B84B),
                      borderWidth:
                          (content.kind == SortingActivityKind.teeth ? 2 : 5) *
                              scale,
                      radius: (content.kind == SortingActivityKind.teeth
                              ? 14
                              : 30) *
                          scale,
                      languageCode: languageCode,
                      enabled: !state.complete,
                      onInspect: () => onInspect(index),
                      onPlace: (id) =>
                          onPlace(id, content.destinations[index].id),
                    )),
              for (var index = 0; index < 2; index++)
                Positioned.fromRect(
                    rect: scaled(layout.hero(index)),
                    child: Semantics(
                        button: true,
                        label: content.destinations[index].label
                            .resolve(languageCode),
                        child: GestureDetector(
                            onTap: () => onInspect(index),
                            child: SortingIllustration(
                                asset: content.destinations[index].image)))),
              for (var i = 0; i < 10; i++)
                Positioned.fromRect(
                    rect: scaled(layout.tray(i)),
                    child: ExcludeSemantics(
                        child: CustomPaint(painter: _CutoutBorder()))),
              for (var i = 0; i < content.items.length; i++)
                AnimatedPositioned.fromRect(
                  key: ValueKey('position-${content.items[i].id}'),
                  rect:
                      scaled(positions[content.items[i].id] ?? layout.item(i)),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  child: _WorksheetItem(
                      item: content.items[i],
                      languageCode: languageCode,
                      placed: state.placed.containsKey(content.items[i].id),
                      selected: state.selected == content.items[i].id,
                      rejected: state.rejected == content.items[i].id,
                      revision: state.revision,
                      onSelect: () => onSelect(content.items[i].id)),
                ),
            ]),
          ),
        );
      });
}

class SortingIllustration extends StatelessWidget {
  const SortingIllustration({required this.asset, super.key});
  final String asset;
  @override
  Widget build(BuildContext context) => Image.asset(asset,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => const Center(
          child:
              Icon(Icons.image_not_supported_outlined, color: KidUi.inkSoft)));
}

class _ClassificationBox extends StatelessWidget {
  const _ClassificationBox(
      {required this.destination,
      required this.color,
      required this.borderWidth,
      required this.radius,
      required this.languageCode,
      required this.enabled,
      required this.onInspect,
      required this.onPlace});
  final SortingDestination destination;
  final Color color;
  final double borderWidth;
  final double radius;
  final String languageCode;
  final bool enabled;
  final VoidCallback onInspect;
  final ValueChanged<String> onPlace;
  @override
  Widget build(BuildContext context) => Semantics(
        label: destination.label.resolve(languageCode),
        button: true,
        child: DragTarget<String>(
          key: ValueKey('box-${destination.id}'),
          onWillAcceptWithDetails: (_) => enabled,
          onAcceptWithDetails: (details) => onPlace(details.data),
          builder: (context, candidates, rejected) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onInspect : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color:
                    candidates.isEmpty ? Colors.white : const Color(0xFFF6FAFE),
                borderRadius: BorderRadius.circular(radius),
                border:
                    Border.all(color: color, width: math.max(1, borderWidth)),
              ),
            ),
          ),
        ),
      );
}

class _WorksheetItem extends StatelessWidget {
  const _WorksheetItem(
      {required this.item,
      required this.languageCode,
      required this.placed,
      required this.selected,
      required this.rejected,
      required this.revision,
      required this.onSelect});
  final PackItem item;
  final String languageCode;
  final bool placed;
  final bool selected;
  final bool rejected;
  final int revision;
  final VoidCallback onSelect;
  @override
  Widget build(BuildContext context) {
    if (placed) {
      return IgnorePointer(
          child: Semantics(
              label: item.label.resolve(languageCode),
              child: SortingIllustration(asset: item.imageAsset)));
    }
    return LayoutBuilder(builder: (context, constraints) {
      final image = AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? KidUi.primary : Colors.transparent,
                  width: 2)),
          child: SortingIllustration(asset: item.imageAsset));
      return Semantics(
        button: true,
        selected: selected,
        label: item.label.resolve(languageCode),
        child: GestureDetector(
          key: ValueKey('item-${item.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: onSelect,
          child: Draggable<String>(
            data: item.id,
            maxSimultaneousDrags: 1,
            onDragStarted: onSelect,
            feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                    width: constraints.maxWidth * 1.1,
                    height: constraints.maxHeight * 1.1,
                    child: SortingIllustration(asset: item.imageAsset))),
            childWhenDragging: const SizedBox.expand(),
            child: TweenAnimationBuilder<double>(
              key: ValueKey('$rejected-${rejected ? revision : 0}'),
              tween: Tween(begin: rejected ? 1 : 0, end: 0),
              duration: const Duration(milliseconds: 420),
              builder: (context, t, child) => Transform.translate(
                  offset: Offset(math.sin(t * math.pi * 4) * 7 * t, 0),
                  child: child),
              child: image,
            ),
          ),
        ),
      );
    });
  }
}

class _CutoutBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    final paint = Paint()
      ..color = const Color(0xFF747474)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 10) {
        canvas.drawPath(
            metric.extractPath(distance, math.min(distance + 5, metric.length)),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CutoutBorder oldDelegate) => false;
}
