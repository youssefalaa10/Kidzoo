import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/badges/badge_celebration_cubit.dart';
import 'package:kidzo/core/badges/badge_celebration_state.dart';
import 'package:kidzo/core/badges/badge_definition.dart';
import 'package:kidzo/core/badges/ui/badge_earned_overlay.dart';
import 'package:kidzo/core/localization/app_localizations.dart';

/// Paints the badge pop-up above everything else in the app.
///
/// Installed as `MaterialApp.builder`, which wraps the `Navigator` rather than
/// sitting inside it. That placement is the whole reason this works: several
/// games pop or replace their own route the moment they finish, and a pop-up
/// living inside a game's widget tree would be torn down mid-animation at
/// exactly the moment it was meant to play.
///
/// It is still inside `Localizations`, `Directionality` and `MediaQuery`, so
/// resolving strings and laying out right-to-left both behave normally.
class BadgeCelebrationHost extends StatelessWidget {
  const BadgeCelebrationHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BadgeCelebrationCubit, BadgeCelebrationState>(
      builder: (BuildContext context, BadgeCelebrationState state) {
        final BadgeDefinition? badge = state.current;
        if (badge == null) {
          return child;
        }
        final AppLocalizations l10n = AppLocalizations.of(context);
        return Stack(
          children: <Widget>[
            child,
            Positioned.fill(
              // Sitting above the Navigator means being above every Scaffold's
              // Material too, and bare Text needs one to paint.
              child: Material(
                type: MaterialType.transparency,
                child: BadgeEarnedOverlay(
                  // A fresh State per badge, so a queued second badge restarts
                  // the animation instead of inheriting a finished controller.
                  key: ValueKey<String>(badge.badgeId),
                  badge: badge,
                  title: l10n.resolve(badge.titleLocalizationKey),
                  description: l10n.resolve(badge.descriptionLocalizationKey),
                  caption: l10n.badgeEarnedCaption,
                  onDone: context
                      .read<BadgeCelebrationCubit>()
                      .dismissCurrentBadge,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
