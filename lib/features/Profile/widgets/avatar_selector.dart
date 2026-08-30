import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class AvatarSelector extends StatelessWidget {
  const AvatarSelector({
    required this.avatarAssets,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<String> avatarAssets;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: avatarAssets.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final isSelected = index == selectedIndex;
        return _AvatarTile(
          asset: avatarAssets[index],
          isSelected: isSelected,
          onTap: () => onSelected(index),
        );
      },
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.asset,
    required this.isSelected,
    required this.onTap,
  });

  final String asset;
  final bool isSelected;
  final VoidCallback onTap;

  static const List<Color> _bubbleColors = [
    Color(0xFFFFE0B2),
    Color(0xFFB3E5FC),
    Color(0xFFF8BBD0),
    Color(0xFFC8E6C9),
    Color(0xFFD1C4E9),
  ];

  @override
  Widget build(BuildContext context) {
    final bubbleColor = _bubbleColors[asset.hashCode.abs() % _bubbleColors.length];

    return Semantics(
      label: AppLocalizations.of(context).avatarOptionLabel,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: isSelected ? bubbleColor : bubbleColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF1AA6A0) : Colors.transparent,
                width: 4,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1AA6A0).withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Image.asset(asset, fit: BoxFit.contain),
                ),
                if (isSelected)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
