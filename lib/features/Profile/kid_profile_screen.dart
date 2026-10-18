import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/badges/badge_service.dart';
import 'package:kidzo/core/badges/badge_stats_reader.dart';
import 'package:kidzo/core/badges/default_badge_catalog.dart';
import 'package:kidzo/core/catalog/default_game_catalog.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/badge_dao.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/core/helpers/media_query.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/shared/style/image_manager.dart';
import 'package:kidzo/core/shared/widgets/fluid_container.dart';

import 'profile_analytics_cubit.dart';
import 'profile_analytics_state.dart';
import 'profile_cubit.dart';
import 'profile_state.dart';
import 'widgets/profile_me_tab.dart';
import 'widgets/profile_progress_tab.dart';

class KidProfileScreen extends StatelessWidget {
  const KidProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GameScoresDao gameScoresDao = context.read<GameScoresDao>();
    final StoryDao storyDao = context.read<StoryDao>();
    return BlocProvider<ProfileAnalyticsCubit>(
      create: (BuildContext _) => ProfileAnalyticsCubit(
        gameScoresDao: gameScoresDao,
        storyDao: storyDao,
        badgeDao: context.read<BadgeDao>(),
        badgeCatalog: buildDefaultBadgeCatalog(),
        badgeStatsReader: BadgeStatsReader(
          gameScoresDao: gameScoresDao,
          storyDao: storyDao,
        ),
        gameCatalog: buildDefaultGameCatalog(),
        badgeService: context.read<BadgeService>(),
      ),
      child: const _KidProfileView(),
    );
  }
}

class _KidProfileView extends StatefulWidget {
  const _KidProfileView();

  @override
  State<_KidProfileView> createState() => _KidProfileViewState();
}

class _KidProfileViewState extends State<_KidProfileView>
    with SingleTickerProviderStateMixin {
  static const int _minNameLength = 3;

  final _nameController = TextEditingController();
  final _nameFieldKey = GlobalKey();
  final _random = Random();

  late final TabController _tabController;

  int _selectedAvatarIndex = 0;
  int _age = 7;
  bool _initialized = false;
  bool _isSaving = false;
  bool _showEntrance = false;
  bool _showCelebration = false;
  String? _nameError;
  String? _currentQuote;
  int? _loadedProfileId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showEntrance = true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _initFromProfile(Profile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile.name;
    _selectedAvatarIndex =
        profile.avatarIndex.clamp(0, ImageManager.kidAvatars.length - 1);
    _age = profile.age;
    _currentQuote = _pickQuote(context);
    context
        .read<ProfileAnalyticsCubit>()
        .load(profile.id, AppLocalizations.of(context));
    _loadedProfileId = profile.id;
  }

  String _pickQuote(BuildContext context, {String? exclude}) {
    final quotes = AppLocalizations.of(context).motivationalQuotes;
    if (quotes.length <= 1) return quotes.first;
    String next;
    do {
      next = quotes[_random.nextInt(quotes.length)];
    } while (next == exclude);
    return next;
  }

  void _refreshQuote() {
    setState(() => _currentQuote = _pickQuote(context, exclude: _currentQuote));
  }

  /// The name field lives on the Me tab, so reaching it can mean switching
  /// tabs first: the header's edit button is tappable from either one.
  void _scrollToName() {
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
    final ctx = _nameFieldKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 400));
    }
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _saveProfile(Profile profile) {
    final name = _nameController.text.trim();
    final l10n = AppLocalizations.of(context);
    if (name.isEmpty) {
      setState(() => _nameError = l10n.nameEmptyError);
      _scrollToName();
      return;
    }
    // The Profiles table stores name with a min length of 3, so stop short
    // names here instead of letting drift throw an InvalidDataException.
    if (name.length < _minNameLength) {
      setState(() => _nameError = l10n.nameTooShortError);
      _scrollToName();
      return;
    }
    setState(() {
      _nameError = null;
      _isSaving = true;
    });
    context.read<ProfileCubit>().updateProfile(
          id: profile.id,
          name: name,
          age: _age,
          avatarIndex: _selectedAvatarIndex,
        );
  }

  void _celebrateSave() {
    setState(() => _showCelebration = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showCelebration = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mq = CustomMQ(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: MultiBlocListener(
          listeners: [
            BlocListener<ProfileCubit, ProfileState>(
              listener: (context, state) {
                if (state is ProfileLoaded && state.currentProfile != null) {
                  if (_isSaving) {
                    _isSaving = false;
                    _celebrateSave();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        content: Row(
                          children: [
                            const Icon(Icons.celebration_rounded,
                                color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(child: Text(l10n.profileSavedMessage)),
                          ],
                        ),
                      ),
                    );
                  }
                  final profile = state.currentProfile;
                  if (_loadedProfileId != profile!.id) {
                    context
                        .read<ProfileAnalyticsCubit>()
                        .load(profile.id, l10n);
                    _loadedProfileId = profile.id;
                  }
                } else if (state is ProfileError) {
                  _isSaving = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state is! ProfileLoaded || state.currentProfile == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final profile = state.currentProfile;
              _initFromProfile(profile!);
              final displayName = _nameController.text.isEmpty
                  ? profile.name
                  : _nameController.text;

              return Stack(
                children: [
                  const _BackgroundBlobs(),
                  SafeArea(
                    child: FluidContainer(
                      padding: EdgeInsets.symmetric(
                        horizontal: mq.width(4),
                        vertical: mq.height(1.5),
                      ),
                      child: AnimatedOpacity(
                        opacity: _showEntrance ? 1 : 0,
                        duration: const Duration(milliseconds: 450),
                        child: AnimatedSlide(
                          offset: _showEntrance
                              ? Offset.zero
                              : const Offset(0, 0.05),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  Text(
                                    l10n.myProfile,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              _ProfileTabBar(
                                controller: _tabController,
                                meLabel: l10n.profileTabMe,
                                progressLabel: l10n.profileTabProgress,
                              ),
                              const SizedBox(height: 12),
                              // TabBarView clips and scrolls each child
                              // separately, so each tab owns its own scroll
                              // view rather than sharing one for the page.
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    ProfileMeTab(
                                      displayName: displayName,
                                      age: _age,
                                      selectedAvatarIndex: _selectedAvatarIndex,
                                      quote: _currentQuote ??
                                          l10n.youAreDoingAmazing,
                                      nameField: _NameField(
                                        key: _nameFieldKey,
                                        controller: _nameController,
                                        errorText: _nameError,
                                        hintText: l10n.namePlaceholder,
                                        onChanged: (_) {
                                          if (_nameError != null) {
                                            setState(() => _nameError = null);
                                          }
                                          setState(() {});
                                        },
                                      ),
                                      saveButton: _SaveButton(
                                        label: l10n.saveMyProfile,
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          _saveProfile(profile);
                                        },
                                      ),
                                      onAvatarSelected: (index) => setState(
                                          () => _selectedAvatarIndex = index),
                                      onAgeChanged: (value) =>
                                          setState(() => _age = value),
                                      onRefreshQuote: _refreshQuote,
                                      onEditTap: _scrollToName,
                                      bottomPadding: mq.height(3),
                                    ),
                                    BlocBuilder<ProfileAnalyticsCubit,
                                        ProfileAnalyticsState>(
                                      builder: (context, analyticsState) {
                                        if (analyticsState
                                            is! ProfileAnalyticsLoaded) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        return ProfileProgressTab(
                                          analytics: analyticsState,
                                          bottomPadding: mq.height(3),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_showCelebration)
                    IgnorePointer(
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.elasticOut,
                          builder: (context, value, _) => Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 60),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Two pills: who I am, and what I have done.
class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({
    required this.controller,
    required this.meLabel,
    required this.progressLabel,
  });

  final TabController controller;
  final String meLabel;
  final String progressLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: const Color(0xFFFF6B81),
          borderRadius: BorderRadius.circular(999),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF9E9E9E),
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        unselectedLabelStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        tabs: [
          Tab(height: 40, text: meLabel),
          Tab(height: 40, text: progressLabel),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    super.key,
    this.errorText,
  });

  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final ValueChanged<String> onChanged;

  static const int _maxLength = 16;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: _maxLength,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        counterText: '',
        prefixIcon: const Icon(Icons.face_rounded, color: Color(0xFF1AA6A0)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF1AA6A0), width: 2),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        icon: const Icon(Icons.favorite_rounded),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

/// Soft, oversized blurred-looking circles scattered behind the content to
/// give the screen a playful "candyland" feel instead of a flat backdrop.
class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
                top: -70,
                right: -50,
                child: _Blob(size: 190, color: Color(0x33FF8A65))),
            Positioned(
                top: 190,
                left: -60,
                child: _Blob(size: 150, color: Color(0x331AA6A0))),
            Positioned(
                bottom: -80,
                right: -60,
                child: _Blob(size: 230, color: Color(0x33FFD166))),
            Positioned(
                bottom: 260,
                left: -40,
                child: _Blob(size: 110, color: Color(0x33FF6B81))),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
