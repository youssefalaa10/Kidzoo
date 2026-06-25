import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';

class GameExitButton extends StatelessWidget {

  const GameExitButton({super.key, this.onExit});
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    // Read the primary color from the Theme instead of a static color.
    final primaryColor = Theme.of(context).primaryColor;

    // Read localized text for exit (fallback to generic if missing from localization)
    final exitText = AppLocalizations.of(context).exit;

    return GestureDetector(
      onTap: onExit ?? () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              exitText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
