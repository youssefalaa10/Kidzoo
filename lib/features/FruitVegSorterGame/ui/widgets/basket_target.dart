import 'package:flutter/material.dart';

import '../../../../core/shared/style/kid_ui.dart';
import '../../data/sorter_models.dart';

/// A basket that accepts a dropped food **or** a tap.
///
/// Both interactions matter: dragging is hard for young children, so the tap
/// path (pick a food, tap a basket) is the primary route and drag is the bonus.
class BasketTarget extends StatefulWidget {
  const BasketTarget({
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
    required this.onFoodDropped,
    super.key,
    this.isHinted = false,
    this.isArmed = false,
    this.isWrong = false,
  });

  final String label;
  final Color color;

  /// Shortest edge available to the basket; everything scales from it.
  final double size;
  final VoidCallback onTap;
  final void Function(FoodItem) onFoodDropped;

  /// The child has struggled: point at the right basket.
  final bool isHinted;

  /// A food is picked up and waiting for a destination.
  final bool isArmed;

  /// This basket just refused an item.
  final bool isWrong;

  @override
  State<BasketTarget> createState() => _BasketTargetState();
}

class _BasketTargetState extends State<BasketTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant BasketTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final shouldPulse = widget.isHinted || widget.isArmed;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<FoodItem>(
      onAcceptWithDetails: (details) => widget.onFoodDropped(details.data),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        final accent = widget.isWrong ? KidUi.wrong : widget.color;
        final emphasised = hovering || widget.isHinted || widget.isWrong;

        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_pulse.value);
            return Transform.scale(
              scale: hovering ? 1.08 : 1 + t * 0.05,
              child: child,
            );
          },
          child: Semantics(
            button: true,
            label: widget.label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                KidHaptics.tap();
                widget.onTap();
              },
              child: _BasketBody(
                size: widget.size,
                label: widget.label,
                accent: accent,
                emphasised: emphasised,
                hovering: hovering,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BasketBody extends StatelessWidget {
  const _BasketBody({
    required this.size,
    required this.label,
    required this.accent,
    required this.emphasised,
    required this.hovering,
  });

  final double size;
  final String label;
  final Color accent;
  final bool emphasised;
  final bool hovering;

  @override
  Widget build(BuildContext context) {
    final rimHeight = size * 0.14;
    final labelSize = (size * 0.14).clamp(13.0, 24.0);

    return AnimatedContainer(
      duration: KidUi.fast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(size * 0.14),
          bottom: Radius.circular(size * 0.32),
        ),
        border: Border.all(
          color: accent,
          width: emphasised ? size * 0.045 : size * 0.02,
        ),
        boxShadow: KidUi.shadow(accent, strength: emphasised ? 1.4 : 0.8),
      ),
      child: Column(
        children: [
          // The rim reads as "this is a container you put things into",
          // which a flat square never did.
          Container(
            height: rimHeight,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(size * 0.1),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(size * 0.06),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(
                      child: Icon(
                        hovering
                            ? Icons.arrow_downward_rounded
                            : Icons.shopping_basket_rounded,
                        color: accent,
                      ),
                    ),
                  ),
                  SizedBox(height: size * 0.04),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w900,
                      color: KidUi.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
