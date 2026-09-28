import 'package:flutter/material.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/shared/style/image_manager.dart';

import 'age_selector.dart';
import 'avatar_selector.dart';
import 'motivational_quote_card.dart';
import 'profile_header.dart';
import 'profile_section_title.dart';

/// Who the child is, and the controls for changing it.
///
/// A straight re-parenting of what the Profile screen already showed, in the
/// same order. All the state still lives on the screen, passed down as values
/// and callbacks, so the save flow is untouched by the tab split.
class ProfileMeTab extends StatelessWidget {
  const ProfileMeTab({
    required this.displayName,
    required this.age,
    required this.selectedAvatarIndex,
    required this.quote,
    required this.nameField,
    required this.saveButton,
    required this.onAvatarSelected,
    required this.onAgeChanged,
    required this.onRefreshQuote,
    required this.onEditTap,
    required this.bottomPadding,
    super.key,
  });

  final String displayName;
  final int age;
  final int selectedAvatarIndex;
  final String quote;

  /// Built by the screen, which owns the controller, the error text and the
  /// GlobalKey that "edit your name" scrolls to.
  final Widget nameField;
  final Widget saveButton;

  final ValueChanged<int> onAvatarSelected;
  final ValueChanged<int> onAgeChanged;
  final VoidCallback onRefreshQuote;
  final VoidCallback onEditTap;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ProfileHeader(
            avatarAsset: ImageManager.kidAvatars[selectedAvatarIndex],
            name: displayName,
            age: age,
            greeting:
                '${l10n.helloKidName(displayName)} ${l10n.readyForAdventure}',
            onEditTap: onEditTap,
          ),
          const SizedBox(height: 18),
          MotivationalQuoteCard(quote: quote, onRefresh: onRefreshQuote),
          const SizedBox(height: 24),
          ProfileSectionTitle(
            title: l10n.chooseYourHero,
            subtitle: l10n.pickAvatarSubtitle,
          ),
          const SizedBox(height: 12),
          AvatarSelector(
            avatarAssets: ImageManager.kidAvatars,
            selectedIndex: selectedAvatarIndex,
            onSelected: onAvatarSelected,
          ),
          const SizedBox(height: 24),
          ProfileSectionTitle(title: l10n.whatsYourName),
          const SizedBox(height: 12),
          nameField,
          const SizedBox(height: 24),
          ProfileSectionTitle(title: l10n.age),
          const SizedBox(height: 12),
          AgeSelector(age: age, onChanged: onAgeChanged),
          const SizedBox(height: 28),
          saveButton,
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}
