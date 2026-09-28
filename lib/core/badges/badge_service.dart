import 'dart:async';

import 'package:kidzo/core/badges/badge_catalog.dart';
import 'package:kidzo/core/badges/badge_definition.dart';
import 'package:kidzo/core/badges/badge_stats_reader.dart';
import 'package:kidzo/core/badges/badge_stats_snapshot.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/badge_dao.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';

/// Decides which badges a child has just earned, and records them.
///
/// Called at the moment something finishes — a game writing its score, a story
/// node completing — so the answer is "what changed just now", never "what is
/// true". That difference is the whole feature: a badge is worth celebrating
/// once.
///
/// Nothing here ever throws outward. A child has just finished something and
/// is looking at their stars; a badge is the least important thing on screen
/// and must never be the thing that breaks it.
class BadgeService {
  BadgeService({
    required this.badgeCatalog,
    required this.badgeDao,
    required this.badgeStatsReader,
    required this.profileDao,
  });

  final BadgeCatalog badgeCatalog;
  final BadgeDao badgeDao;
  final BadgeStatsReader badgeStatsReader;
  final ProfileDao profileDao;

  final StreamController<List<BadgeDefinition>> _earned =
      StreamController<List<BadgeDefinition>>.broadcast();

  /// Each batch of newly earned badges, as it happens.
  ///
  /// The celebration cubit is the only thing that should listen: this is the
  /// pop-up trigger, not a source of truth. What a child actually owns lives
  /// in `EarnedBadges` and is read from there.
  Stream<List<BadgeDefinition>> get earnedBadgeStream => _earned.stream;

  /// Evaluates every rule and returns only the badges that were **not**
  /// already held.
  ///
  /// Pass `celebrate: false` to record without firing the pop-up. That exists
  /// for the first evaluation on an install that already has play history,
  /// where every already-true badge would otherwise queue up at once and play
  /// eight celebrations back to back over whatever screen the child opened.
  Future<List<BadgeDefinition>> evaluateForProfile(
    int profileId, {
    bool celebrate = true,
  }) async {
    try {
      final BadgeStatsSnapshot snapshot =
          await badgeStatsReader.readSnapshot(profileId);
      final Set<String> alreadyHeld =
          await badgeDao.earnedBadgeIdsFor(profileId);
      final List<BadgeDefinition> newlyEarned = <BadgeDefinition>[];
      for (final BadgeDefinition definition in badgeCatalog.all) {
        if (alreadyHeld.contains(definition.badgeId)) {
          continue;
        }
        if (!definition.isEarnedBy(snapshot)) {
          continue;
        }
        final bool inserted = await badgeDao.grantBadge(
          profileId: profileId,
          badgeId: definition.badgeId,
        );
        if (inserted) {
          newlyEarned.add(definition);
        }
      }
      if (newlyEarned.isNotEmpty && celebrate && !_earned.isClosed) {
        _earned.add(newlyEarned);
      }
      return newlyEarned;
    } catch (_) {
      // Deliberately silent; see the class doc.
      return const <BadgeDefinition>[];
    }
  }

  /// Resolves the current profile the way the rest of the app does, then
  /// evaluates. For callers that have no profile id to hand.
  Future<List<BadgeDefinition>> evaluateForCurrentProfile({
    bool celebrate = true,
  }) async {
    try {
      final List<Profile> profiles = await profileDao.getAllProfiles();
      if (profiles.isEmpty) {
        return const <BadgeDefinition>[];
      }
      return await evaluateForProfile(profiles.first.id, celebrate: celebrate);
    } catch (_) {
      return const <BadgeDefinition>[];
    }
  }

  /// Records everything already true without celebrating any of it.
  ///
  /// Used once, on an install that has play history but no badges yet, so the
  /// wall is populated the first time the child opens their Profile instead of
  /// erupting over whatever they happened to be doing.
  Future<void> backfillSilently(int profileId) async {
    try {
      if (await badgeDao.badgeCountFor(profileId) > 0) {
        return;
      }
      await evaluateForProfile(profileId, celebrate: false);
    } catch (_) {
      // Silent by design.
    }
  }

  Future<void> dispose() => _earned.close();
}
