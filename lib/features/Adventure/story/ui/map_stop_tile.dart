import 'package:flutter/material.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// Where a stop sits on the journey.
enum MapStopState {
  /// Finished. The page is in the book, and it can be played again.
  completed,

  /// Playable now.
  open,

  /// A real Adventure the child has not reached yet.
  locked,

  /// A place that does not exist as content yet.
  ///
  /// Distinct from [locked] on purpose. "Locked" implies a door that opening
  /// the right thing will open; a stop that has not been written should not
  /// promise that a child who plays enough will reach it this week.
  comingSoon,
}

/// One stop, flattened from either an Adventure or an upcoming destination.
///
/// The map draws stops, not Adventures. Keeping that a single type is what lets
/// the path render as one continuous journey instead of two lists stacked on
/// top of each other with a visible seam between "real" and "coming".
@immutable
class MapStop {
  const MapStop({
    required this.id,
    required this.title,
    required this.teaser,
    required this.state,
    this.accentValue,
    this.art,
  });

  final String id;
  final LocalizedText title;

  /// One line, or empty. Empty is the normal case for a stop the child has not
  /// earned a look at.
  final LocalizedText teaser;

  final MapStopState state;
  final int? accentValue;
  final String? art;
}

/// A stop on the map, plus the road to the next one.
///
/// Deliberately a row on a path rather than a pin on a picture. Hand-placed
/// pins over a painted background is what the old level map did, and it could
/// not grow: every new stop meant new coordinates, and nothing about it worked
/// on a tablet without re-authoring. A path that flows down the screen adds a
/// stop by adding a stop.
class MapStopTile extends StatelessWidget {
  const MapStopTile({
    required this.stop,
    required this.isLast,
    required this.isJustUnlocked,
    required this.isInProgress,
    required this.languageCode,
    required this.metrics,
    required this.l10n,
    required this.onOpen,
    super.key,
  });

  final MapStop stop;

  /// The last stop draws no road onward.
  final bool isLast;

  /// True for exactly one stop, on exactly one build: the one that just became
  /// reachable because the Adventure before it was finished.
  final bool isJustUnlocked;

  final bool isInProgress;
  final String languageCode;
  final KidMetrics metrics;
  final AppLocalizations l10n;

  /// Null for a stop that cannot be played.
  final VoidCallback? onOpen;

  bool get _isReachable =>
      stop.state == MapStopState.open || stop.state == MapStopState.completed;

  Color get _accent {
    if (!_isReachable) {
      return KidUi.inkSoft;
    }
    return stop.accentValue == null ? KidUi.primary : Color(stop.accentValue!);
  }

  IconData get _badgeIcon {
    switch (stop.state) {
      case MapStopState.completed:
        return Icons.check_rounded;
      case MapStopState.open:
        return Icons.play_arrow_rounded;
      case MapStopState.locked:
      case MapStopState.comingSoon:
        return Icons.lock_rounded;
    }
  }

  String get _statusLabel {
    switch (stop.state) {
      case MapStopState.completed:
        return l10n.resolve('adventureReplay', fallback: 'Again');
      case MapStopState.open:
        return isInProgress
            ? l10n.resolve('adventureResume', fallback: 'Continue')
            : l10n.resolve('adventureStart', fallback: 'Start');
      case MapStopState.locked:
        return l10n.resolve('adventureLocked', fallback: 'Not yet');
      case MapStopState.comingSoon:
        return l10n.resolve('adventureComingSoon', fallback: 'Coming soon');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double badge = metrics.size(72, min: 58, max: 92);
    final String teaser = stop.teaser.resolve(languageCode);

    final Widget tile = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            _StopBadge(
              size: badge,
              accent: _accent,
              icon: _badgeIcon,
              art: stop.state == MapStopState.completed ? stop.art : null,
              isMuted: !_isReachable,
              isPulsing: stop.state == MapStopState.open,
            ),
            if (!isLast)
              _Road(
                height: metrics.size(34, min: 24, max: 46),
                width: badge * 0.1,
                // The road ahead is dotted and grey; the road already walked is
                // solid and coloured. A child reads "this is how far I got"
                // off the path itself without anything having to say it.
                isWalked: stop.state == MapStopState.completed,
                accent: _accent,
              ),
          ],
        ),
        SizedBox(width: metrics.gap * 0.8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: metrics.gap * 0.6),
            child: Container(
              padding: EdgeInsets.all(metrics.size(16, min: 12, max: 24)),
              decoration: BoxDecoration(
                color:
                    Colors.white.withValues(alpha: _isReachable ? 0.94 : 0.62),
                borderRadius: BorderRadius.circular(KidUi.radiusCard),
                boxShadow: KidUi.shadow(
                  _accent,
                  strength: _isReachable ? 1 : 0.4,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ActivityGlyphText(
                    stop.title.resolve(languageCode),
                    languageCode: languageCode,
                    fontSize: metrics.size(20, min: 16, max: 26),
                    textAlign: TextAlign.start,
                    color: _isReachable ? KidUi.ink : KidUi.inkSoft,
                  ),
                  SizedBox(height: metrics.gap * 0.25),
                  ActivityGlyphText(
                    _statusLabel,
                    languageCode: languageCode,
                    fontSize: metrics.size(15, min: 12, max: 19),
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.start,
                    color: _accent,
                  ),
                  if (teaser.isNotEmpty) ...<Widget>[
                    SizedBox(height: metrics.gap * 0.3),
                    ActivityGlyphText(
                      teaser,
                      languageCode: languageCode,
                      fontSize: metrics.size(14, min: 12, max: 18),
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.start,
                      color: KidUi.inkSoft,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );

    final Widget interactive = onOpen == null
        ? Semantics(label: stop.title.resolve(languageCode), child: tile)
        : Semantics(
            button: true,
            label: stop.title.resolve(languageCode),
            child: GestureDetector(
              onTap: () {
                KidHaptics.tap();
                onOpen!();
              },
              child: tile,
            ),
          );

    if (!isJustUnlocked) {
      return interactive;
    }
    // The unlock. Small, once, and on the stop that changed — a whole-screen
    // celebration here would compete with the page that just flew into the
    // book thirty seconds ago, and the child would not know which one was
    // telling them something.
    return _UnlockReveal(accent: _accent, child: interactive);
  }
}

/// The circular marker on the path.
class _StopBadge extends StatefulWidget {
  const _StopBadge({
    required this.size,
    required this.accent,
    required this.icon,
    required this.art,
    required this.isMuted,
    required this.isPulsing,
  });

  final double size;
  final Color accent;
  final IconData icon;
  final String? art;
  final bool isMuted;

  /// The stop the child should play next breathes gently. One moving thing on
  /// the screen, and it is the thing to touch.
  final bool isPulsing;

  @override
  State<_StopBadge> createState() => _StopBadgeState();
}

class _StopBadgeState extends State<_StopBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPulsing) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StopBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isPulsing && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, Widget? child) => Transform.scale(
        scale: 1 + _pulse.value * 0.06,
        child: child,
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.isMuted
              ? Colors.white.withValues(alpha: 0.55)
              : widget.accent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: widget.size * 0.06),
          boxShadow: KidUi.shadow(
            widget.accent,
            strength: widget.isMuted ? 0.3 : 0.9,
          ),
        ),
        alignment: Alignment.center,
        child: widget.art != null
            // A finished stop wears the page it gave up, which is the clearest
            // possible statement of what playing it was for.
            ? Padding(
                padding: EdgeInsets.all(widget.size * 0.16),
                child: Image.asset(widget.art!, fit: BoxFit.contain),
              )
            : Icon(
                widget.icon,
                color: widget.isMuted ? KidUi.inkSoft : Colors.white,
                size: widget.size * 0.46,
              ),
      ),
    );
  }
}

/// The path between two stops.
class _Road extends StatelessWidget {
  const _Road({
    required this.height,
    required this.width,
    required this.isWalked,
    required this.accent,
  });

  final double height;
  final double width;
  final bool isWalked;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const int dots = 3;
    return SizedBox(
      height: height,
      width: width * 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          for (int index = 0; index < dots; index++)
            Container(
              width: width,
              height: width,
              decoration: BoxDecoration(
                color: isWalked ? accent : Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

/// A short, self-contained "this just opened" flourish.
class _UnlockReveal extends StatefulWidget {
  const _UnlockReveal({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  State<_UnlockReveal> createState() => _UnlockRevealState();
}

class _UnlockRevealState extends State<_UnlockReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeOutBack.transform(
          _controller.value.clamp(0.0, 1.0),
        );
        // A glow that blooms and fades, over a stop that grows into place. It
        // is over in under a second: the point is to draw the eye to something
        // that changed, not to make the child wait.
        final double glow =
            (1 - (_controller.value - 0.35).abs() * 2.6).clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.9 + 0.1 * t,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KidUi.radiusCard),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.55 * glow),
                  blurRadius: 34 * glow,
                  spreadRadius: 6 * glow,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
