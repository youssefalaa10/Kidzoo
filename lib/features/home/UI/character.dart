import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/helpers/media_query.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/mixins/background_music_mixin.dart';
import 'package:kidzo/core/shared/style/image_manager.dart';
import 'package:kidzo/features/AppCategory/education_screen.dart';
import 'package:kidzo/features/AppCategory/games_screen.dart';
import 'package:kidzo/features/settings/settings_screen.dart';

import '../../../core/localization/language_provider.dart';
import '../../../core/services/background_resolver.dart';
import '../../../core/shared/widgets/fluid_container.dart';
import '../../Alphabets/bloc/alphabet_bloc.dart';
import '../../LevelsMap/Data/Logic/cubit/levelmap_cubit.dart';
import '../../LevelsMap/levelmap_screen.dart';
import '../../Profile/profile_cubit.dart';
import '../../Profile/profile_state.dart';

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
    final mq = CustomMQ(context);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(BackgroundResolver(context, BackgroundType.tech).resolveBackground()!),
            fit: BoxFit.cover,
          ),
        ),
        child: FluidContainer(
          child: Column(
              children: [
                // Header section
                _buildHeader(mq, isLandscape),
                SizedBox(height: isLandscape ? mq.height(1) : mq.height(2.5)),
                // Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isLandscape ? size.width * 0.2 : mq.width(8)),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: mq.width(3),
                      vertical: mq.height(1),
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
                      style: TextStyle(
                        fontSize: isLandscape ? size.height * 0.06 : mq.width(7),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
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
                SizedBox(height: isLandscape ? mq.height(1.5) : mq.height(3.5)),
                // Carousel section
                Expanded(
                  child: OverlappedCarousel(
                    items: _getCategories(context),
                    selectedIndex: _selectedIndex,
                    mq: mq,
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
      ),
    );
  }

  Widget _buildHeader(CustomMQ mq, bool isLandscape) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        String avatarPath = 'assets/gen/images/avatar/avatar-monstar.png';
        if (state is ProfileLoaded && state.currentProfile != null) {
            final avatars = [
              'assets/gen/images/avatar/avatar-monstar.png',
              'assets/gen/images/avatar/avatar-boy.png',
              'assets/gen/images/avatar/avatar-girl.png',
              'assets/gen/images/avatar/avatar-astronaut.png',
            ];
            final idx = state.currentProfile!.avatarIndex;
            if (idx >= 0 && idx < avatars.length) {
               avatarPath = avatars[idx];
            }
        }
        
        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: mq.width(5), vertical: mq.height(1.5)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar on one side
              Container(
                width: isLandscape ? mq.height(15) : mq.width(12),
                height: isLandscape ? mq.height(15) : mq.width(12),
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
                child: ClipOval(
                  child: Image.asset(avatarPath, fit: BoxFit.cover),
                ),
              ),
              
              // Settings and Lang on the other side
              Row(
                children: [
                  // Language Toggle
                  GestureDetector(
                    onTap: () {
                      context.read<LanguageCubit>().toggleLanguage();
                    },
                    child: Container(
                      width: isLandscape ? mq.height(12) : mq.width(10),
                      height: isLandscape ? mq.height(12) : mq.width(10),
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
                      child: Center(
                        child: Text(
                          context.read<LanguageCubit>().isArabic ? 'EN' : 'ع',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                            fontSize: mq.width(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: mq.width(3)),
                  // Settings Icon
                  GestureDetector(
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ),
                    child: Container(
                      width: isLandscape ? mq.height(12) : mq.width(10),
                      height: isLandscape ? mq.height(12) : mq.width(10),
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
                        size: mq.width(5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
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
    required this.mq,
    super.key,
  });
  final List<CharacterCategory> items;
  final int selectedIndex;
  final void Function(int) onItemChanged;
  final CustomMQ mq;

  @override
  State<OverlappedCarousel> createState() => _OverlappedCarouselState();
}

class _OverlappedCarouselState extends State<OverlappedCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.8,
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
                    mq: widget.mq,
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
    required this.mq,
    super.key,
  });
  final CharacterCategory category;
  final bool isSelected;
  final String characterImage;
  final CustomMQ mq;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: mq.width(2.5), vertical: isLandscape ? mq.height(1) : mq.height(2.5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Character image container with rounded corners
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
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
                    ? Padding(
                        padding: EdgeInsets.all(isLandscape ? 8.0 : 16.0),
                        child: Image.asset(
                          characterImage,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Container(), // Empty for non-selected cards
              ),
            ),
          ),
          SizedBox(height: isLandscape ? mq.height(1) : mq.height(2)),

          // Character name
          Flexible(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                category.characterName,
                style: TextStyle(
                  fontSize: isLandscape ? size.height * 0.06 : mq.width(6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: isLandscape ? mq.height(0.5) : mq.height(1)),

          // Character description
          Flexible(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: mq.width(4)),
              child: Text(
                category.characterDesc,
                textAlign: TextAlign.center,
                maxLines: isLandscape ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isLandscape ? size.height * 0.04 : mq.width(3.5),
                  color: Colors.grey[600],
                  height: 1.2,
                ),
              ),
            ),
          ),
          SizedBox(height: isLandscape ? mq.height(1) : mq.height(2)),

          // Coins indicator
          Flexible(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? size.width * 0.04 : mq.width(6), 
                    vertical: isLandscape ? size.height * 0.015 : mq.height(1.5)),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.buttonLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isLandscape ? size.height * 0.04 : mq.width(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
