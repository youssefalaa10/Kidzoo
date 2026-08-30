import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';

/// Leave-the-game button.
///
/// It collapses to a round icon when the space it is given cannot hold the
/// label. It used to be a fixed icon-plus-text row, which overflowed by 8px
/// wherever it was dropped into a narrow slot - an `AppBar` `leading`, for
/// instance, is only as wide as `leadingWidth`.
class GameExitButton extends StatelessWidget {
  const GameExitButton({super.key, this.onExit});

  final VoidCallback? onExit;

  /// Below this the label is dropped and only the icon is drawn.
  static const double _labelBreakpoint = 104;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final exitText = AppLocalizations.of(context).exit;
    final onTap = onExit ?? () => Navigator.of(context).maybePop();

    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabel = constraints.maxWidth.isFinite
            ? constraints.maxWidth >= _labelBreakpoint
            : true;

        return Semantics(
          button: true,
          label: exitText,
          child: Tooltip(
            message: exitText,
            child: Material(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
              elevation: 4,
              shadowColor: Colors.black38,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  // Stays a comfortable target for small hands in both forms.
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: showLabel ? 16 : 10,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.close_rounded,
                          color: Colors.white, size: 24),
                      if (showLabel) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            exitText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
