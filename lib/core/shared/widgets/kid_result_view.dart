import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../localization/app_localizations.dart';
import '../style/kid_ui.dart';

/// Shared end-of-game celebration.
///
/// Kids get a proportional reward instead of a flat "Level Complete": one to
/// three stars that pop in one at a time, the score they actually earned, and
/// two very large buttons. Both buttons are always reachable without scrolling
/// because the whole view scrolls if the screen is short.
class KidResultView extends StatefulWidget {
  const KidResultView({
    required this.metrics,
    required this.score,
    required this.maxScore,
    required this.onPlayAgain,
    super.key,
    this.onExit,
    this.title,
  });

  final KidMetrics metrics;
  final int score;
  final int maxScore;
  final VoidCallback onPlayAgain;
  final VoidCallback? onExit;
  final String? title;

  /// One to three stars, so finishing always feels like an achievement while
  /// still leaving something to beat next time.
  static int starsFor(int score, int maxScore) {
    if (maxScore <= 0) return 1;
    final ratio = score / maxScore;
    if (ratio >= 0.9) return 3;
    if (ratio >= 0.6) return 2;
    return 1;
  }

  @override
  State<KidResultView> createState() => _KidResultViewState();
}

class _KidResultViewState extends State<KidResultView> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = widget.metrics;
    final stars = KidResultView.starsFor(widget.score, widget.maxScore);
    final starSize = m.size(72, min: 44, max: 96);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(m.pagePadding),
          // A scroll view hands its child unbounded height, so centring only
          // works against an explicit minimum: fills the screen when it fits,
          // scrolls when it does not.
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: m.height - m.pagePadding * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: m.gap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final earned = index < stars;
                    final star = Icon(
                      earned ? Icons.star_rounded : Icons.star_border_rounded,
                      size: starSize * (index == 1 ? 1.2 : 1.0),
                      color: earned ? KidUi.hint : Colors.white70,
                    );
                    if (!earned) return star;
                    return star
                        .animate(delay: Duration(milliseconds: 250 * index))
                        .scale(
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.2, 0.2),
                        );
                  }),
                ),
                SizedBox(height: m.gap),
                Text(
                  widget.title ?? l10n.levelComplete,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: m.size(34, min: 24, max: 44),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: KidUi.textHalo,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),
                SizedBox(height: m.gap * 0.6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: m.size(24, min: 16, max: 32),
                    vertical: m.size(12, min: 8, max: 18),
                  ),
                  decoration: BoxDecoration(
                    color: KidUi.surface,
                    borderRadius: BorderRadius.circular(KidUi.radiusPill),
                    boxShadow: KidUi.shadow(KidUi.hint),
                  ),
                  child: Text(
                    '${l10n.finalScore}  ${widget.score}',
                    style: TextStyle(
                      fontSize: m.size(24, min: 17, max: 30),
                      fontWeight: FontWeight.w900,
                      color: KidUi.ink,
                    ),
                  ),
                ).animate(delay: 300.ms).fadeIn().scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),
                SizedBox(height: m.gap * 1.5),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: m.gap,
                  runSpacing: m.gap,
                  children: [
                    _BigButton(
                      metrics: m,
                      label: l10n.playAgain,
                      icon: Icons.replay_rounded,
                      background: KidUi.correct,
                      onTap: () {
                        KidHaptics.tap();
                        widget.onPlayAgain();
                      },
                    ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.4),
                    _BigButton(
                      metrics: m,
                      label: l10n.exit,
                      icon: Icons.home_rounded,
                      background: KidUi.surface,
                      foreground: KidUi.ink,
                      onTap: () {
                        KidHaptics.tap();
                        (widget.onExit ??
                            () => Navigator.of(context).maybePop())();
                      },
                    ).animate(delay: 550.ms).fadeIn().slideY(begin: 0.4),
                  ],
                ),
                SizedBox(height: m.gap),
              ],
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 22,
          minBlastForce: 6,
          maxBlastForce: 18,
          minimumSize: const Size(8, 8),
          maximumSize: const Size(14, 14),
          gravity: 0.25,
          emissionFrequency: 0.04,
          colors: KidUi.confettiColors,
          createParticlePath: _starPath,
        ),
      ],
    );
  }
}

/// Five-pointed confetti: stars read as "reward" to a child, squares do not.
Path _starPath(Size size) {
  const points = 5;
  final path = Path();
  final outer = size.width / 2;
  final inner = outer / 2.5;
  final step = pi / points;
  for (var i = 0; i < points * 2; i++) {
    final radius = i.isEven ? outer : inner;
    final angle = i * step - pi / 2;
    final x = outer + radius * cos(angle);
    final y = outer + radius * sin(angle);
    i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
  }
  path.close();
  return path;
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.metrics,
    required this.label,
    required this.icon,
    required this.background,
    required this.onTap,
    this.foreground = Colors.white,
  });

  final KidMetrics metrics;
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fontSize = metrics.size(22, min: 16, max: 26);

    return Material(
      color: background,
      elevation: 6,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(KidUi.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KidUi.radiusPill),
        child: Container(
          constraints:
              BoxConstraints(minHeight: metrics.size(60, min: 52, max: 72)),
          padding: EdgeInsets.symmetric(
            horizontal: metrics.size(28, min: 20, max: 36),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: fontSize * 1.3),
              SizedBox(width: fontSize * 0.5),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
