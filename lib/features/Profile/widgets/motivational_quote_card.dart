import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class MotivationalQuoteCard extends StatelessWidget {
  const MotivationalQuoteCard({
    required this.quote,
    required this.onRefresh,
    super.key,
  });

  final String quote;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB84D), Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A65).withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
                      .animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                quote,
                key: ValueKey<String>(quote),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: AppLocalizations.of(context).showAnotherQuote,
            button: true,
            child: Material(
              color: Colors.white.withValues(alpha: 0.3),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRefresh,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
