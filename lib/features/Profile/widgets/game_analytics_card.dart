import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/game_category_progress.dart';

class GameAnalyticsCard extends StatelessWidget {
  const GameAnalyticsCard({required this.category, super.key});

  final GameCategoryProgress category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.gameAnalyticsSemanticLabel(
          category.title, category.score, category.gamesPlayed, category.bestScore),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(category.icon, color: category.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        category.encouragement,
                        style: TextStyle(color: category.color, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${category.score}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: category.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: category.progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: category.color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(category.color),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.playedBestLabel(category.gamesPlayed, category.bestScore),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                ),
                Text(
                  '${(category.progress * 100).round()}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: category.color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
