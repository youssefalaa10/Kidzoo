import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/helpers/media_query.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/shared/style/image_manager.dart';
import 'package:kidzo/core/shared/widgets/fluid_container.dart';

import 'profile_analytics_cubit.dart';
import 'profile_analytics_state.dart';
import 'profile_cubit.dart';
import 'profile_state.dart';
import 'widgets/achievement_badge.dart';
import 'widgets/age_selector.dart';
import 'widgets/avatar_selector.dart';
import 'widgets/game_analytics_card.dart';
import 'widgets/motivational_quote_card.dart';
import 'widgets/profile_header.dart';
import 'widgets/score_summary.dart';

class KidProfileScreen extends StatelessWidget {
  const KidProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileAnalyticsCubit(context.read<GameScoresDao>()),
      child: const _KidProfileView(),
    );
  }
}

class _KidProfileView extends StatefulWidget {
  const _KidProfileView();

  @override
  State<_KidProfileView> createState() => _KidProfileViewState();
}

class _KidProfileViewState extends State<_KidProfileView> {
  final _nameController = TextEditingController();
  final _nameFieldKey = GlobalKey();
  final _random = Random();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showEntrance = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initFromProfile(Profile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile.name;
    _selectedAvatarIndex = profile.avatarIndex.clamp(0, ImageManager.kidAvatars.length - 1);
    _age = profile.age;
    _currentQuote = _pickQuote(context);
    context.read<ProfileAnalyticsCubit>().load(profile.id, AppLocalizations.of(context));
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

  void _scrollToName() {
    final ctx = _nameFieldKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400));
    }
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _saveProfile(Profile profile) {
    final name = _nameController.text.trim();
    final l10n = AppLocalizations.of(context);
    if (name.isEmpty) {
      setState(() => _nameError = l10n.nameEmptyError);
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        content: Row(
                          children: [
                            const Icon(Icons.celebration_rounded, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(child: Text(l10n.profileSavedMessage)),
                          ],
                        ),
                      ),
                    );
                  }
                  final profile = state.currentProfile!;
                  if (_loadedProfileId != profile.id) {
                    context.read<ProfileAnalyticsCubit>().load(profile.id, l10n);
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

              final profile = state.currentProfile!;
              _initFromProfile(profile);

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
                          offset: _showEntrance ? Offset.zero : const Offset(0, 0.05),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => Navigator.of(context).maybePop(),
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
                                const SizedBox(height: 8),
                                ProfileHeader(
                                  avatarAsset: ImageManager.kidAvatars[_selectedAvatarIndex],
                                  name: _nameController.text.isEmpty
                                      ? profile.name
                                      : _nameController.text,
                                  age: _age,
                                  greeting:
                                      '${l10n.helloKidName(_nameController.text.isEmpty ? profile.name : _nameController.text)} ${l10n.readyForAdventure}',
                                  onEditTap: _scrollToName,
                                ),
                                const SizedBox(height: 18),
                                MotivationalQuoteCard(
                                  quote: _currentQuote ?? l10n.youAreDoingAmazing,
                                  onRefresh: _refreshQuote,
                                ),
                                const SizedBox(height: 24),
                                _SectionTitle(title: l10n.chooseYourHero, subtitle: l10n.pickAvatarSubtitle),
                                const SizedBox(height: 12),
                                AvatarSelector(
                                  avatarAssets: ImageManager.kidAvatars,
                                  selectedIndex: _selectedAvatarIndex,
                                  onSelected: (index) =>
                                      setState(() => _selectedAvatarIndex = index),
                                ),
                                const SizedBox(height: 24),
                                _SectionTitle(title: l10n.whatsYourName),
                                const SizedBox(height: 12),
                                _NameField(
                                  key: _nameFieldKey,
                                  controller: _nameController,
                                  errorText: _nameError,
                                  hintText: l10n.namePlaceholder,
                                  onChanged: (_) {
                                    if (_nameError != null) setState(() => _nameError = null);
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(height: 24),
                                _SectionTitle(title: l10n.age),
                                const SizedBox(height: 12),
                                AgeSelector(
                                  age: _age,
                                  onChanged: (value) => setState(() => _age = value),
                                ),
                                const SizedBox(height: 24),
                                BlocBuilder<ProfileAnalyticsCubit, ProfileAnalyticsState>(
                                  builder: (context, analyticsState) {
                                    if (analyticsState is! ProfileAnalyticsLoaded) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 24),
                                        child: Center(child: CircularProgressIndicator()),
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        ScoreSummary(
                                          metrics: [
                                            ScoreMetric(
                                              icon: Icons.stars_rounded,
                                              label: l10n.totalScoreLabel,
                                              value: '${analyticsState.totalScore}',
                                              color: const Color(0xFF7C4DFF),
                                            ),
                                            ScoreMetric(
                                              icon: Icons.auto_awesome_rounded,
                                              label: l10n.starsEarnedLabel,
                                              value: '${analyticsState.stars}',
                                              color: const Color(0xFFFFC107),
                                            ),
                                            ScoreMetric(
                                              icon: Icons.videogame_asset_rounded,
                                              label: l10n.gamesPlayedLabel,
                                              value: '${analyticsState.gamesPlayed}',
                                              color: const Color(0xFF26C6DA),
                                            ),
                                            ScoreMetric(
                                              icon: Icons.local_fire_department_rounded,
                                              label: l10n.currentStreakLabel,
                                              value:
                                                  '${analyticsState.currentStreak} ${l10n.daysSuffix}',
                                              color: const Color(0xFFFF5252),
                                            ),
                                            ScoreMetric(
                                              icon: Icons.emoji_events_rounded,
                                              label: l10n.bestScoreLabel,
                                              value: '${analyticsState.bestScore}',
                                              color: const Color(0xFF66BB6A),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        _SectionTitle(title: l10n.gameProgressTitle),
                                        const SizedBox(height: 12),
                                        ...analyticsState.categories
                                            .map((c) => GameAnalyticsCard(category: c)),
                                        const SizedBox(height: 12),
                                        _SectionTitle(title: l10n.achievementsTitle),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 168,
                                          child: ListView(
                                            scrollDirection: Axis.horizontal,
                                            children: analyticsState.achievements
                                                .map((a) => AchievementBadge(achievement: a))
                                                .toList(),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 28),
                                _SaveButton(
                                  label: l10n.saveMyProfile,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _saveProfile(profile);
                                  },
                                ),
                                SizedBox(height: mq.height(3)),
                              ],
                            ),
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
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 20,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B81),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2D3142),
              ),
            ),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
            Positioned(top: -70, right: -50, child: _Blob(size: 190, color: Color(0x33FF8A65))),
            Positioned(top: 190, left: -60, child: _Blob(size: 150, color: Color(0x331AA6A0))),
            Positioned(bottom: -80, right: -60, child: _Blob(size: 230, color: Color(0x33FFD166))),
            Positioned(bottom: 260, left: -40, child: _Blob(size: 110, color: Color(0x33FF6B81))),
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
