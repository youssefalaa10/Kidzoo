import 'package:flutter/material.dart';

import '../models/achievement.dart';

class AchievementBadge extends StatefulWidget {
  const AchievementBadge({required this.achievement, super.key});

  final Achievement achievement;

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    if (widget.achievement.isUnlocked) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final isUnlocked = achievement.isUnlocked;

    return Semantics(
      label: '${achievement.title}: ${achievement.description}${isUnlocked ? '' : ', locked'}',
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 116,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: achievement.color.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isUnlocked
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [achievement.color, achievement.color.withValues(alpha: 0.65)],
                          )
                        : null,
                    color: isUnlocked ? null : const Color(0xFFEDEDED),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnlocked ? achievement.icon : Icons.lock_rounded,
                    color: isUnlocked ? Colors.white : const Color(0xFFB0B0B0),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    achievement.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      achievement.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, height: 1.2, color: Color(0xFF9E9E9E)),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isUnlocked ? achievement.color : const Color(0xFFEDEDED),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
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
