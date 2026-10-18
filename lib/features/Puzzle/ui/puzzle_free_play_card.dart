import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Puzzle/bloc/cubit.dart';
import 'package:kidzo/features/Puzzle/puzzle_screen.dart';

/// The fourth card on the Puzzle picker: pick any picture, no tier.
///
/// Puzzle alone has an image chooser, which the old level map reached by
/// asking for "level 4". Rather than delete it along with the rest of the
/// level-map remnants, it becomes an always-open bonus below the three tiers.
/// It records no score, so it neither unlocks anything nor counts as a play.
class PuzzleFreePlayCard extends StatelessWidget {
  const PuzzleFreePlayCard({required this.metrics, super.key});

  final KidMetrics metrics;

  void _openPicker(BuildContext context) {
    KidHaptics.tap();
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (BuildContext _) => BlocProvider<PuzzleCubit>(
        create: (BuildContext _) => PuzzleCubit(),
        child: const ImageSelectionPage(gridSize: 3),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.freePlayCard,
      child: Material(
        color: KidUi.primary,
        borderRadius: BorderRadius.circular(KidUi.radiusCard),
        elevation: 6,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(KidUi.radiusCard),
          onTap: () => _openPicker(context),
          child: Container(
            constraints: BoxConstraints(
              minHeight: metrics.size(76, min: KidUi.minTouch, max: 96),
            ),
            padding: EdgeInsets.all(metrics.size(16, min: 12, max: 22)),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                  size: metrics.size(34, min: 26, max: 44),
                ),
                SizedBox(width: metrics.gap),
                Expanded(
                  child: Text(
                    l10n.freePlayCard,
                    style: TextStyle(
                      fontSize: metrics.size(19, min: 15, max: 24),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: metrics.size(30, min: 24, max: 38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
