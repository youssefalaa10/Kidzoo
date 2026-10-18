import 'package:kidzo/core/badges/badge_stats_snapshot.dart';

/// Whether a badge has been earned, given everything known about a child.
///
/// A plain function rather than a subclass per badge: the rules are one-liners
/// and keeping them as data in the catalog means the whole badge set can be
/// read in one screenful, which is what makes it reviewable.
typedef BadgeUnlockRule = bool Function(BadgeStatsSnapshot stats);
