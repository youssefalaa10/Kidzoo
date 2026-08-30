import 'package:flutter/material.dart';

import '../style/kid_ui.dart';

/// Full-bleed background + safe area + responsive metrics for a mini game.
///
/// Every kid game used to build its own Scaffold and background Container,
/// which is why they drifted apart visually. They now share this shell so a
/// child moving between games keeps the same mental model.
class KidGameShell extends StatelessWidget {
  const KidGameShell({
    required this.builder,
    super.key,
    this.backgroundAsset,
    this.fallbackColor = KidUi.cream,
    this.maxContentWidth = 900,
  });

  final Widget Function(BuildContext context, KidMetrics metrics) builder;
  final String? backgroundAsset;
  final Color fallbackColor;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fallbackColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Only the backdrop cross-fades. Animating the whole subtree meant
          // that a game which changes scene every round (Feed The Animal) blew
          // the entire board away and restarted its animations each time.
          AnimatedSwitcher(
            duration: KidUi.medium,
            child: Container(
              key: ValueKey(backgroundAsset ?? 'plain'),
              decoration: BoxDecoration(
                color: fallbackColor,
                image: backgroundAsset != null
                    ? DecorationImage(
                        image: AssetImage(backgroundAsset!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: LayoutBuilder(
                  builder: (context, constraints) =>
                      builder(context, KidMetrics.of(constraints)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back button, round progress, live score and a "say it again" speaker.
///
/// Progress is drawn as one segment per round rather than "3 / 10" because a
/// pre-reader can count filled segments but cannot parse a fraction.
class KidTopBar extends StatelessWidget {
  const KidTopBar({
    required this.metrics,
    required this.current,
    required this.total,
    super.key,
    this.score,
    this.onReplayPrompt,
    this.onBack,
    this.accent = KidUi.primary,
  });

  final KidMetrics metrics;

  /// 1-based index of the round being played.
  final int current;
  final int total;
  final int? score;
  final VoidCallback? onReplayPrompt;
  final VoidCallback? onBack;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final buttonSize = metrics.size(52, min: 44, max: 62);

    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_rounded,
          size: buttonSize,
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        SizedBox(width: metrics.gap * 0.75),
        Expanded(
          child: _ProgressTrack(
            metrics: metrics,
            current: current,
            total: total,
            accent: accent,
          ),
        ),
        if (score != null) ...[
          SizedBox(width: metrics.gap * 0.75),
          _ScoreChip(metrics: metrics, score: score!),
        ],
        if (onReplayPrompt != null) ...[
          SizedBox(width: metrics.gap * 0.75),
          _CircleButton(
            icon: Icons.volume_up_rounded,
            size: buttonSize,
            onTap: () {
              KidHaptics.tap();
              onReplayPrompt!();
            },
          ),
        ],
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KidUi.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: KidUi.ink, size: size * 0.5),
        ),
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({
    required this.metrics,
    required this.current,
    required this.total,
    required this.accent,
  });

  final KidMetrics metrics;
  final int current;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final height = metrics.size(16, min: 12, max: 22);

    return Semantics(
      label: '$current / $total',
      child: Container(
        height: height,
        padding: EdgeInsets.all(height * 0.18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(KidUi.radiusPill),
          boxShadow: KidUi.shadow(Colors.black, strength: 0.5),
        ),
        child: Row(
          children: List.generate(total, (index) {
            final done = index < current - 1;
            final active = index == current - 1;
            return Expanded(
              child: AnimatedContainer(
                duration: KidUi.medium,
                curve: Curves.easeOut,
                margin: EdgeInsets.symmetric(horizontal: height * 0.06),
                decoration: BoxDecoration(
                  color: done
                      ? KidUi.correct
                      : (active ? accent : accent.withValues(alpha: 0.18)),
                  borderRadius: BorderRadius.circular(KidUi.radiusPill),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.metrics, required this.score});

  final KidMetrics metrics;
  final int score;

  @override
  Widget build(BuildContext context) {
    final fontSize = metrics.size(20, min: 14, max: 24);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.size(14, min: 10, max: 18),
        vertical: metrics.size(8, min: 6, max: 12),
      ),
      decoration: BoxDecoration(
        color: KidUi.surface,
        borderRadius: BorderRadius.circular(KidUi.radiusPill),
        boxShadow: KidUi.shadow(KidUi.hint, strength: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: KidUi.hint, size: fontSize * 1.15),
          SizedBox(width: fontSize * 0.25),
          Text(
            '$score',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: KidUi.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// The spoken instruction, written down.
///
/// The games used to rely on text-to-speech alone; a child who looked away, or
/// whose device is muted, had no way to recover the question. The banner keeps
/// the prompt on screen and doubles as a big "say it again" button.
class KidPromptBanner extends StatelessWidget {
  const KidPromptBanner({
    required this.metrics,
    required this.text,
    super.key,
    this.hint,
    this.onSpeak,
    this.accent = KidUi.primary,
  });

  final KidMetrics metrics;
  final String text;
  final String? hint;
  final VoidCallback? onSpeak;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fontSize = metrics.size(24, min: 17, max: 30);
    final speakerSize = metrics.size(48, min: 40, max: 58);

    return Semantics(
      button: onSpeak != null,
      label: text,
      child: GestureDetector(
        onTap: onSpeak == null
            ? null
            : () {
                KidHaptics.tap();
                onSpeak!();
              },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: metrics.size(18, min: 12, max: 26),
            vertical: metrics.size(14, min: 10, max: 20),
          ),
          decoration: BoxDecoration(
            color: KidUi.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(KidUi.radiusCard),
            boxShadow: KidUi.shadow(accent, strength: 0.9),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        color: KidUi.ink,
                        height: 1.2,
                      ),
                    ),
                    if (hint != null) ...[
                      SizedBox(height: metrics.size(4, min: 2, max: 8)),
                      Text(
                        hint!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize * 0.6,
                          fontWeight: FontWeight.w600,
                          color: KidUi.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onSpeak != null) ...[
                SizedBox(width: metrics.gap * 0.75),
                Container(
                  width: speakerSize,
                  height: speakerSize,
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Icon(
                    Icons.hearing_rounded,
                    color: Colors.white,
                    size: speakerSize * 0.55,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
