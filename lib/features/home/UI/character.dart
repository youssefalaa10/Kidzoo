import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/core/localization/app_localizations.dart';
import 'package:kidzoo/core/mixins/background_music_mixin.dart';
import 'package:kidzoo/core/shared/style/image_manager.dart';
import 'package:kidzoo/features/AppCategory/education_screen.dart';
import 'package:kidzoo/features/AppCategory/games_screen.dart';
import 'package:kidzoo/features/settings/settings_screen.dart';

import '../../Alphabets/bloc/alphabet_bloc.dart';
import '../../LevelsMap/Data/Logic/cubit/levelmap_cubit.dart';
import '../../LevelsMap/levelmap_screen.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen>
    with BackgroundMusicMixin {
  int _selectedIndex = 1; // Default selected card (middle one)

  // Define our character categories
  List<CharacterCategory> _getCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      CharacterCategory(
        name: l10n.games,
        characterName: l10n.games,
        characterDesc: l10n.enjoyAndHaveFun,
        color: Colors.blue.shade100,
        buttonLabel: l10n.play,
        characterImage: ImageManager.gamepad,
        screen: BlocProvider(
          create: (context) => AlphabetBloc(),
          child: const GamesScreen(),
        ),
      ),
      CharacterCategory(
        name: l10n.education,
        characterName: l10n.education,
        characterDesc: l10n.learnNewThings,
        color: Colors.orange.shade300,
        buttonLabel: l10n.learn,
        characterImage: ImageManager.letters,
        screen: BlocProvider(
          create: (context) => AlphabetBloc(),
          child: const EducationScreen(),
        ),
      ),
      CharacterCategory(
        name: l10n.challenge,
        characterName: l10n.challenge,
        characterDesc: l10n.challengeYourself,
        color: Colors.purple.shade100,
        buttonLabel: l10n.compete,
        characterImage: ImageManager.brainstorming,
        screen: BlocProvider(
          create: (context) => LevelCubit(),
          child: const LevelMapScreen(),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              ImageManager.techBg,
              fit: BoxFit.cover,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header section
                _buildHeader(),
                const SizedBox(height: 20),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade200,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      AppLocalizations.of(context).improveYourSkills,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Carousel section
                Expanded(
                  child: OverlappedCarousel(
                    items: _getCategories(context),
                    selectedIndex: _selectedIndex,
                    onItemChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const SettingsScreen(),
              ),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.9),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.settings_outlined,
                color: Colors.blue[800],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterCategory {
  CharacterCategory({
    required this.name,
    required this.characterName,
    required this.characterDesc,
    required this.color,
    required this.buttonLabel,
    required this.characterImage,
    required this.screen,
  });
  final String name;
  final String characterName;
  final String characterDesc;
  final Color color;
  final String buttonLabel;
  final String characterImage;
  final Widget screen;
}

class OverlappedCarousel extends StatefulWidget {
  const OverlappedCarousel({
    required this.items,
    required this.selectedIndex,
    required this.onItemChanged,
    super.key,
  });
  final List<CharacterCategory> items;
  final int selectedIndex;
  final void Function(int) onItemChanged;

  @override
  State<OverlappedCarousel> createState() => _OverlappedCarouselState();
}

class _OverlappedCarouselState extends State<OverlappedCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.65,
      initialPage: widget.selectedIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.items.length,
      onPageChanged: widget.onItemChanged,
      itemBuilder: (context, index) {
        final category = widget.items[index];
        final isSelected = index == widget.selectedIndex;
        final double scale = isSelected ? 1.0 : 0.8;
        final double opacity = isSelected ? 1.0 : 0.8;

        return TweenAnimationBuilder(
          tween: Tween<double>(begin: scale, end: scale),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return GestureDetector(
              onTap: isSelected
                  ? () => Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => category.screen,
                        ),
                      )
                  : null,
              child: Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: opacity,
                  child: CharacterCard(
                    category: widget.items[index],
                    isSelected: isSelected,
                    characterImage: widget.items[index].characterImage,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CharacterCard extends StatelessWidget {
  const CharacterCard({
    required this.category,
    required this.isSelected,
    required this.characterImage,
    super.key,
  });
  final CharacterCategory category;
  final bool isSelected;
  final String characterImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Character image container with rounded corners
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: isSelected
                  ? Image.asset(
                      characterImage,
                      height: 180,
                      width: 180,
                    )
                  : Container(), // Empty for non-selected cards
            ),
          ),
          const SizedBox(height: 20),

          // Character name
          Text(
            category.characterName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Character description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              category.characterDesc,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Coins indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // const Icon(Icons.monetization_on,
                //     color: Colors.yellow, size: 18),
                // const SizedBox(width: 8),
                Text(
                  category.buttonLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
