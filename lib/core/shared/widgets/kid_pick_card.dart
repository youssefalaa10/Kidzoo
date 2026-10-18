import 'dart:math';

import 'package:flutter/material.dart';

import '../style/kid_ui.dart';

/// Visual state of a choice card, shared by every kid game so the colour
/// language stays identical across them.
enum KidCardState {
  idle,

  /// Picked up with a tap and waiting for its destination.
  selected,

  /// Answered correctly.
  correct,

  /// Answered incorrectly - shakes, then returns to [idle].
  wrong,

  /// Nudged after repeated wrong tries.
  hint,

  /// Already used this round; keeps its slot but fades out.
  done,
}

/// A big, forgiving choice card that works by **tap or drag**.
///
/// Dragging is hard for children under about nine, so every draggable card in
/// these games is also a plain button: tap picks it, tap the target drops it.
/// Drag stays available for the kids who enjoy it.
class KidPickCard<T extends Object> extends StatefulWidget {
  const KidPickCard({
    required this.imageAsset,
    required this.size,
    required this.onTap,
    super.key,
    this.label,
    this.dragData,
    this.state = KidCardState.idle,
    this.accent = KidUi.primary,
    this.semanticLabel,
  });

  final String imageAsset;

  /// Edge of the card; the caller derives it from the space it actually has.
  final double size;
  final VoidCallback onTap;
  final String? label;

  /// When non-null the card can also be dragged onto a [DragTarget].
  final T? dragData;
  final KidCardState state;
  final Color accent;
  final String? semanticLabel;

  @override
  State<KidPickCard<T>> createState() => _KidPickCardState<T>();
}

class _KidPickCardState<T extends Object> extends State<KidPickCard<T>>
    with TickerProviderStateMixin {
  late final AnimationController _shake;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _syncAnimations(null);
  }

  @override
  void didUpdateWidget(covariant KidPickCard<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncAnimations(oldWidget.state);
    }
  }

  void _syncAnimations(KidCardState? previous) {
    if (widget.state == KidCardState.wrong && previous != KidCardState.wrong) {
      _shake.forward(from: 0);
    }
    final shouldPulse = widget.state == KidCardState.hint ||
        widget.state == KidCardState.selected;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Color get _borderColor {
    switch (widget.state) {
      case KidCardState.correct:
        return KidUi.correct;
      case KidCardState.wrong:
        return KidUi.wrong;
      case KidCardState.hint:
        return KidUi.hint;
      case KidCardState.selected:
        return widget.accent;
      case KidCardState.idle:
      case KidCardState.done:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The card keeps its slot when it is spent so the tray does not reflow
    // under the child's finger mid-round.
    if (widget.state == KidCardState.done) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    final radius = widget.size * 0.24;
    final hasLabel = widget.label != null;
    final labelSize = (widget.size * 0.135).clamp(11.0, 20.0);
    final highlighted = _borderColor != Colors.transparent;

    final card = AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Transform.scale(scale: 1 + t * 0.06, child: child);
      },
      child: AnimatedContainer(
        duration: KidUi.fast,
        width: widget.size,
        height: widget.size,
        padding: EdgeInsets.all(widget.size * 0.1),
        decoration: BoxDecoration(
          color: KidUi.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: highlighted ? _borderColor : Colors.black12,
            width: highlighted ? widget.size * 0.055 : 2,
          ),
          boxShadow: KidUi.shadow(
            highlighted ? _borderColor : Colors.black,
            strength: highlighted ? 1.2 : 0.7,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                widget.imageAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => Icon(
                  Icons.image_not_supported_outlined,
                  color: KidUi.inkSoft,
                  size: widget.size * 0.4,
                ),
              ),
            ),
            if (hasLabel) ...[
              SizedBox(height: widget.size * 0.04),
              // Naming the picture is half the lesson, so the label is part of
              // the card rather than an optional extra.
              Text(
                widget.label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w800,
                  color: KidUi.ink,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final shaken = AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        if (_shake.isDismissed) return child!;
        final dx = sin(_shake.value * pi * 6) * widget.size * 0.08;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: card,
    );

    final scaled = AnimatedScale(
      scale: widget.state == KidCardState.correct ? 1.12 : 1.0,
      duration: KidUi.medium,
      curve: Curves.easeOutBack,
      child: shaken,
    );

    final tappable = Semantics(
      button: true,
      selected: widget.state == KidCardState.selected,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          KidHaptics.tap();
          widget.onTap();
        },
        child: scaled,
      ),
    );

    if (widget.dragData == null) return tappable;

    return Draggable<T>(
      data: widget.dragData as T,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: KidHaptics.tap,
      feedback: Transform.translate(
        // Lift the card above the finger so the child can see what they hold.
        offset: Offset(-widget.size / 2, -widget.size * 0.75),
        child: Material(
          color: Colors.transparent,
          child: Transform.scale(scale: 1.15, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: tappable,
    );
  }
}
