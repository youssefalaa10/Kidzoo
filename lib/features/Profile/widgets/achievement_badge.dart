import 'package:flutter/material.dart';
import 'package:kidzo/core/localization/app_localizations.dart';

import '../models/badge_view.dart';

/// One tile on the badge wall.
///
/// Kept from the original achievement row rather than replaced: the elastic
/// pop-in, the locked padlock at half opacity and the coloured foot are what
/// the wall already looked like. What changed is the fixed width — it now
/// sizes to its grid cell — and the earned date, which the old model had no
/// way of knowing.
class AchievementBadge extends StatefulWidget {
  const AchievementBadge({required this.badge, super.key});

  final BadgeView badge;

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    if (widget.badge.isEarned) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Short and absolute: a four-year-old cannot read "3 weeks ago", but a
  /// parent looking over their shoulder can read a date.
  String _formatEarnedOn(DateTime when) =>
      '${when.day}/${when.month}/${when.year}';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BadgeView badge = widget.badge;
    final bool isEarned = badge.isEarned;

    return Semantics(
      label: '${badge.title}: ${badge.description}'
          '${isEarned ? '' : ', ${l10n.badgeLockedLabel}'}',
      child: Opacity(
        opacity: isEarned ? 1.0 : 0.5,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: isEarned
                      ? badge.color.withValues(alpha: 0.28)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: isEarned ? 12 : 6,
                  offset: Offset(0, isEarned ? 6 : 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 14),
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isEarned
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              badge.color,
                              badge.color.withValues(alpha: 0.65),
                            ],
                          )
                        : null,
                    color: isEarned ? null : const Color(0xFFEDEDED),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEarned ? badge.icon : Icons.lock_rounded,
                    color: isEarned ? Colors.white : const Color(0xFFB0B0B0),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    badge.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      isEarned
                          ? l10n.badgeEarnedOnLabel(
                              _formatEarnedOn(badge.earnedAt!))
                          : badge.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, height: 1.2, color: Color(0xFF9E9E9E)),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isEarned ? badge.color : const Color(0xFFEDEDED),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
