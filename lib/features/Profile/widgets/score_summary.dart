import 'package:flutter/material.dart';

class ScoreMetric {
  const ScoreMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class ScoreSummary extends StatelessWidget {
  const ScoreSummary({required this.metrics, super.key});

  final List<ScoreMetric> metrics;

  @override
  Widget build(BuildContext context) {
    // Pills grow taller (never narrower) when the user bumps the system font
    // size, so the value/label column always has room.
    final textScale =
        MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxExtent = constraints.maxWidth >= 600 ? 240.0 : 200.0;
        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.4 / textScale,
          ),
          itemBuilder: (context, index) => _MetricPill(metric: metrics[index]),
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.metric});

  final ScoreMetric metric;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${metric.label}: ${metric.value}',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: metric.color.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keep the badge proportional to the pill so it never crowds out
            // the text on narrow tiles.
            final badgeSize = constraints.maxHeight.isFinite
                ? constraints.maxHeight.clamp(28.0, 48.0)
                : 44.0;

            return Row(
              children: [
                Container(
                  width: badgeSize,
                  height: badgeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        metric.color,
                        metric.color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(badgeSize * 0.36),
                  ),
                  child: Icon(
                    metric.icon,
                    color: Colors.white,
                    size: badgeSize * 0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Flexible so the value can shrink instead of overflowing
                      // when the pill is short.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            metric.value,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: metric.color,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8D8D8D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
