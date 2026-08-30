import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class AgeSelector extends StatelessWidget {
  const AgeSelector({
    required this.age,
    required this.onChanged,
    super.key,
    this.minAge = 3,
    this.maxAge = 14,
  });

  final int age;
  final int minAge;
  final int maxAge;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundIconButton(
            icon: Icons.remove_rounded,
            color: const Color(0xFFFF9F43),
            semanticLabel: l10n.decreaseAge,
            onTap: age > minAge ? () => onChanged(age - 1) : null,
          ),
          Column(
            children: [
              Text(
                '$age',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF6B35),
                ),
              ),
              Text(
                l10n.yearsOld,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E7B5A),
                ),
              ),
            ],
          ),
          _RoundIconButton(
            icon: Icons.add_rounded,
            color: const Color(0xFFFF9F43),
            semanticLabel: l10n.increaseAge,
            onTap: age < maxAge ? () => onChanged(age + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: enabled ? color : color.withValues(alpha: 0.3),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
