import 'package:flutter/material.dart';

/// A heading on the Profile, with an optional line underneath.
///
/// Promoted out of `kid_profile_screen.dart` when the screen split into tabs:
/// both tabs need it, and one export per file is the house rule.
class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Sits at the end of the heading row. The badge wall puts its
  /// "3 of 7" count here.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 6,
              height: 20,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B81),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D3142),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 14),
            child: Text(
              subtitle!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
            ),
          ),
      ],
    );
  }
}
