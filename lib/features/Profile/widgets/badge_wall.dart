import 'package:flutter/material.dart';
import 'package:kidzo/core/badges/badge_pillar.dart';
import 'package:kidzo/core/localization/app_localizations.dart';

import '../models/badge_view.dart';
import 'achievement_badge.dart';
import 'profile_section_title.dart';

/// Every badge, grouped by pillar, earned ones first.
///
/// Locked badges are shown rather than hidden: the point of a badge wall for a
/// child this age is the gaps in it. Each one names what would earn it, so the
/// wall reads as a list of things to try next rather than a scoreboard.
class BadgeWall extends StatelessWidget {
  const BadgeWall({required this.badges, super.key});

  final List<BadgeView> badges;

  /// Fixed order, so the wall does not reshuffle as badges are earned.
  static const List<BadgePillar> _pillarOrder = <BadgePillar>[
    BadgePillar.story,
    BadgePillar.games,
    BadgePillar.education,
    BadgePillar.habit,
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final BadgePillar pillar in _pillarOrder)
          ..._buildPillar(context, l10n, pillar),
      ],
    );
  }

  List<Widget> _buildPillar(
    BuildContext context,
    AppLocalizations l10n,
    BadgePillar pillar,
  ) {
    final List<BadgeView> inPillar = badges
        .where((BadgeView badge) => badge.pillar == pillar)
        .toList(growable: false)
      // Earned first, so a child sees what they have before what they have
      // not. Ties keep catalog order, which is roughly easiest-first.
      ..sort((BadgeView a, BadgeView b) {
        if (a.isEarned == b.isEarned) {
          return 0;
        }
        return a.isEarned ? -1 : 1;
      });
    if (inPillar.isEmpty) {
      return const <Widget>[];
    }
    final int earned =
        inPillar.where((BadgeView badge) => badge.isEarned).length;
    return <Widget>[
      ProfileSectionTitle(
        title: l10n.resolve(pillar.localizationKey),
        trailing: Text(
          l10n.badgeWallCount(earned, inPillar.length),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        // The whole tab is one scroll view; a second scrollable inside it
        // would swallow the drag.
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
        children: <Widget>[
          for (final BadgeView badge in inPillar)
            AchievementBadge(badge: badge),
        ],
      ),
      const SizedBox(height: 24),
    ];
  }
}
