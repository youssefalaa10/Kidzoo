import 'package:flutter/material.dart';
import 'package:kidzo/core/localization/app_localizations.dart';

import '../models/recent_activity_entry.dart';

/// The "lately" feed: games, story beats and badges in one list.
class RecentActivityList extends StatelessWidget {
  const RecentActivityList({required this.entries, super.key});

  final List<RecentActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          l10n.recentActivityEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
        ),
      );
    }
    return Container(
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: <Widget>[
          for (final RecentActivityEntry entry in entries)
            _RecentActivityRow(entry: entry),
        ],
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.entry});

  final RecentActivityEntry entry;

  /// Very short, because it sits at the end of a narrow row and a child is not
  /// reading it anyway — it is there for the adult next to them.
  String _relativeTime(AppLocalizations l10n, DateTime when) {
    final Duration ago = DateTime.now().difference(when);
    if (ago.inHours < 1) {
      return l10n.justNow;
    }
    if (ago.inHours < 24) {
      return l10n.hoursAgoShort(ago.inHours);
    }
    return l10n.daysAgoShort(ago.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(entry.icon, color: entry.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D3142),
                  ),
                ),
                if (entry.subtitle != null)
                  Text(
                    entry.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeTime(l10n, entry.occurredAt),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB0B0B0),
            ),
          ),
        ],
      ),
    );
  }
}
