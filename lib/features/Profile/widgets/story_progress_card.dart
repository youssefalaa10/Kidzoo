import 'package:flutter/material.dart';
import 'package:kidzo/core/localization/app_localizations.dart';

/// How far through the story a child is.
///
/// The Profile could see none of this before: Adventure records to its own
/// tables and nothing read them here, so a child who had played nothing but
/// the story saw an empty profile.
class StoryProgressCard extends StatelessWidget {
  const StoryProgressCard({
    required this.nodesCompleted,
    required this.pagesFound,
    required this.adventuresCompleted,
    required this.adventuresStarted,
    super.key,
  });

  final int nodesCompleted;
  final int pagesFound;
  final int adventuresCompleted;

  /// The denominator is adventures *touched*, not every adventure that ships:
  /// showing "1 of 4" to a child who has met one of them advertises content
  /// they have not been offered yet.
  final int adventuresStarted;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double progress =
        adventuresStarted == 0 ? 0 : adventuresCompleted / adventuresStarted;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.auto_stories_rounded,
                  color: Color(0xFF8D6E63), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$adventuresCompleted ${l10n.adventuresCompletedLabel}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFEDEDED),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF8D6E63),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _StoryCounter(
                  value: pagesFound,
                  label: l10n.storyPagesFoundLabel,
                  icon: Icons.description_rounded,
                  color: const Color(0xFF26A69A),
                ),
              ),
              Expanded(
                child: _StoryCounter(
                  value: nodesCompleted,
                  label: l10n.storyBeatsLabel,
                  icon: Icons.flag_rounded,
                  color: const Color(0xFF43A047),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryCounter extends StatelessWidget {
  const _StoryCounter({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9E9E9E), height: 1.15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
