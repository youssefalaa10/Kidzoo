import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/shared/style/kid_ui.dart';
import '../../data/feed_animal_models.dart';

/// The animal: a drop target, a tap target, and the stage for the eat
/// animation.
///
/// It fills the box it is given rather than assuming a 350px height, so the
/// same widget works on a small phone in portrait and a tablet in landscape.
class AnimalTarget extends StatefulWidget {
  const AnimalTarget({
    required this.animal,
    required this.isSuccess,
    required this.isError,
    required this.onTap,
    required this.onFoodDropped,
    this.eatenFood,
    this.isArmed = false,
    super.key,
  });

  final AnimalItem animal;
  final bool isSuccess;
  final bool isError;
  final VoidCallback onTap;
  final void Function(FeedItem) onFoodDropped;
  final FeedItem? eatenFood;

  /// A food is picked and waiting: invite the child to tap the animal.
  final bool isArmed;

  @override
  State<AnimalTarget> createState() => _AnimalTargetState();
}

class _AnimalTargetState extends State<AnimalTarget>
    with TickerProviderStateMixin {
  late final AnimationController _shake;
  late final AnimationController _invite;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _invite = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _syncInvite();
  }

  @override
  void didUpdateWidget(covariant AnimalTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isError && !oldWidget.isError) {
      _shake.forward(from: 0);
    }
    _syncInvite();
  }

  void _syncInvite() {
    if (widget.isArmed && !_invite.isAnimating) {
      _invite.repeat(reverse: true);
    } else if (!widget.isArmed && _invite.isAnimating) {
      _invite
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _invite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 300,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 300,
        );
        final stage = min(box.width, box.height);

        return DragTarget<FeedItem>(
          // Deliberately forgiving: anywhere on the animal's box counts. Asking
          // a four-year-old to hit a mouth-sized hotspot is a losing game.
          onAcceptWithDetails: (details) => widget.onFoodDropped(details.data),
          builder: (context, candidates, rejected) {
            final hovering = candidates.isNotEmpty;

            return Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  KidHaptics.tap();
                  widget.onTap();
                },
                child: SizedBox(
                  width: box.width,
                  height: box.height,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_shake, _invite]),
                    builder: (context, child) {
                      final dx = _shake.isDismissed
                          ? 0.0
                          : sin(_shake.value * pi * 4) * stage * 0.05;
                      final bob = Curves.easeInOut.transform(_invite.value);
                      return Transform.translate(
                        offset: Offset(dx, -bob * stage * 0.03),
                        child: child,
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (widget.isArmed || hovering)
                          _Halo(size: stage, strong: hovering),
                        AnimatedScale(
                          scale: widget.isSuccess ? 1.12 : 1.0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutBack,
                          child: Image.asset(
                            widget.animal.imageAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) => Icon(
                              Icons.pets_rounded,
                              size: stage * 0.5,
                              color: KidUi.inkSoft,
                            ),
                          ),
                        ),
                        if (widget.isSuccess && widget.eatenFood != null)
                          _EatenFood(food: widget.eatenFood!, stage: stage),
                        if (widget.isSuccess) _RisingStar(stage: stage),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Soft ring behind the animal that says "drop it here".
class _Halo extends StatelessWidget {
  const _Halo({required this.size, required this.strong});

  final double size;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: KidUi.fast,
      width: size * (strong ? 0.95 : 0.85),
      height: size * (strong ? 0.95 : 0.85),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KidUi.correct.withValues(alpha: strong ? 0.28 : 0.14),
        border: Border.all(
          color: KidUi.correct.withValues(alpha: strong ? 0.9 : 0.5),
          width: size * 0.02,
        ),
      ),
    );
  }
}

/// The food travelling into the animal's mouth.
///
/// Both the start offset and the size are derived from the stage, so the food
/// lands on the animal at every screen size; the previous version used fixed
/// pixel offsets and drifted off the sprite on small phones.
class _EatenFood extends StatelessWidget {
  const _EatenFood({required this.food, required this.stage});

  final FeedItem food;
  final double stage;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInCubic,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, (1 - t) * stage * 0.45),
          child: Transform.scale(
            scale: 1 - t * 0.85,
            child: Opacity(opacity: 1 - t * 0.4, child: child),
          ),
        );
      },
      child: Image.asset(
        food.imageAsset,
        height: stage * 0.25,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _RisingStar extends StatelessWidget {
  const _RisingStar({required this.stage});

  final double stage;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, -stage * (0.25 + t * 0.3)),
          child: Opacity(opacity: 1 - t, child: child),
        );
      },
      child: Icon(
        Icons.star_rounded,
        color: KidUi.hint,
        size: stage * 0.22,
      ),
    );
  }
}
