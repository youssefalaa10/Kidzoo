import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';

/// The object an activity is working on, shown changing as the work is done.
///
/// This is the answer to "what did I just change?" — the question a step
/// counter cannot answer for a child who cannot read it. The basket fills, the
/// turtle lights up, the raft comes together, and it happens *because* of the
/// step the child just finished.
///
/// It knows nothing about any subject. Content names an asset and a mode; the
/// host drives it from [ActivityState.progress], which every engine already
/// reports. That is what lets the same widget carry a market cart, a jungle
/// vine and an ocean lift with no code between them.
///
/// **It renders inline, in the prompt banner's row.** Vertical space is the
/// scarcest thing on this screen — at 780x390 the board has barely 200dp — so a
/// stage that took its own band would have to be removed on exactly the devices
/// that need it most. Sitting beside the instruction also puts it where the
/// child is already looking.
class ActivityStage extends StatelessWidget {
  const ActivityStage({
    required this.spec,
    required this.progress,
    required this.size,
    super.key,
  });

  final ActivityStageSpec spec;

  /// 0..1. Not clamped by the caller, so clamp here rather than trusting it.
  final double progress;

  final double size;

  @override
  Widget build(BuildContext context) {
    final double t = progress.clamp(0.0, 1.0);

    // A ghost of the finished object sits under the filled part, so the child
    // can see what they are working towards rather than only what they have.
    final Widget ghost = Opacity(
      opacity: 0.22,
      child: Image.asset(spec.art, fit: BoxFit.contain),
    );

    Widget filled = Image.asset(spec.art, fit: BoxFit.contain);

    if (spec.brightens) {
      // Dim and desaturated at zero, full colour at one. Saturation carries
      // more of "not lit yet" than opacity alone does, and both are paint-only.
      filled = Opacity(
        opacity: 0.45 + 0.55 * t,
        child: ColorFiltered(
          colorFilter: _saturation(0.25 + 0.75 * t),
          child: filled,
        ),
      );
    }

    if (spec.fills) {
      // Clip in from the bottom, the way anything actually fills.
      filled = ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: t.clamp(0.001, 1.0),
          child: SizedBox(
            height: size,
            width: size,
            child: filled,
          ),
        ),
      );
      filled = Align(alignment: Alignment.bottomCenter, child: filled);
    }

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        // Keyed on the step, so each completed step gives one soft cross-fade
        // instead of the picture sliding continuously and reading as decoration.
        duration: KidUi.medium,
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (Widget child, Animation<double> animation) =>
            ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Stack(
          key: ValueKey<int>((t * 1000).round()),
          fit: StackFit.expand,
          children: <Widget>[
            if (spec.fills) ghost,
            filled,
          ],
        ),
      ),
    );
  }

  /// A saturation matrix. Written out rather than pulled from a package because
  /// it is five numbers and one dependency is not worth five numbers.
  static ColorFilter _saturation(double value) {
    const double lr = 0.2126;
    const double lg = 0.7152;
    const double lb = 0.0722;
    final double sr = (1 - value) * lr;
    final double sg = (1 - value) * lg;
    final double sb = (1 - value) * lb;
    return ColorFilter.matrix(<double>[
      sr + value, sg, sb, 0, 0, //
      sr, sg + value, sb, 0, 0, //
      sr, sg, sb + value, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }
}
