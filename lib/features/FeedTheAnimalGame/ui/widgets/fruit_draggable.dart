import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/feed_animal_models.dart';

class FruitDraggable extends StatelessWidget {
  final FeedItem food;
  final bool isDropped;
  final bool showHint;
  final FlutterTts flutterTts;

  const FruitDraggable({
    super.key,
    required this.food,
    this.isDropped = false,
    this.showHint = false,
    required this.flutterTts,
  });

  @override
  Widget build(BuildContext context) {
    if (isDropped) {
      return const SizedBox(width: 120, height: 160);
    }

    final l10n = AppLocalizations.of(context);
    final localizedName = food.getLocalizedName(l10n);

    final foodWidget = GestureDetector(
      onTap: () {
        try {
          flutterTts.speak(localizedName);
        } catch (_) {}
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: showHint ? Colors.amber : Colors.blue.shade100,
            width: showHint ? 5 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: showHint
                  ? Colors.amber.withValues(alpha: 0.5)
                  : Colors.black12,
              blurRadius: showHint ? 15 : 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(food.imageAsset, height: 90, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              localizedName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );

    return Draggable<FeedItem>(
      data: food,
      feedback: Transform.scale(
        scale: 1.1,
        child: Material(
          color: Colors.transparent,
          child: foodWidget,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: foodWidget,
      ),
      child: foodWidget,
    );
  }
}
