import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'core/badges/badge_celebration_cubit.dart';
import 'core/badges/badge_service.dart';
import 'core/badges/badge_stats_reader.dart';
import 'core/badges/default_badge_catalog.dart';
import 'core/badges/ui/badge_celebration_host.dart';
import 'core/database/config.dart';
import 'core/database/daos/badge_dao.dart';
import 'core/database/daos/game_scores_dao.dart';
import 'core/database/daos/profile_dao.dart';
import 'core/database/daos/story_dao.dart';
import 'core/helpers/speech.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/language_provider.dart';
import 'core/managers/game_asset_manager.dart';
import 'core/scoring/game_score_recorder.dart';
import 'core/services/background_resolver.dart';
import 'core/services/cubit/music_cubit.dart';
import 'core/shared/style/image_manager.dart';
import 'features/Alphabets/bloc/alphabet_bloc.dart';
import 'features/Profile/profile_cubit.dart';
import 'features/Profile/profile_setup_screen.dart';
import 'features/Profile/profile_state.dart';
import 'features/home/UI/character.dart';
import 'features/settings/cubit/settings_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(_StartupApp(initialization: _initializeApp()));
}

Future<MyApp> _initializeApp() async {
  final database = AppDatabase();
  final profileDao = ProfileDao(database);
  final gameScoresDao = GameScoresDao(database);
  final storyDao = StoryDao(database);
  final badgeDao = BadgeDao(database);
  final badgeService = BadgeService(
    badgeCatalog: buildDefaultBadgeCatalog(),
    badgeDao: badgeDao,
    badgeStatsReader: BadgeStatsReader(
      gameScoresDao: gameScoresDao,
      storyDao: storyDao,
    ),
    profileDao: profileDao,
  );
  final gameScoreRecorder = GameScoreRecorder(
    gameScoresDao: gameScoresDao,
    profileDao: profileDao,
    badgeService: badgeService,
  );
  final flutterTts = FlutterTts();
  final audioPlayer = AudioPlayer();
  // Speech goes through one facade so the device-or-cloud decision is made
  // once. A separate player is used for synthesized audio so a spoken prompt
  // never cuts off a game sound effect.
  Speech.attach(tts: flutterTts, player: AudioPlayer());
  // Resolve the voice up front using the language the user last chose, so the
  // first prompt of a saved Arabic session already uses the right voice
  // instead of switching a moment later.
  final String savedLanguage = await LanguageCubit.savedLanguageCode();
  unawaited(
    Speech.configureLanguage(savedLanguage)
        // Survey the device's Arabic capability up front, whatever language
        // the UI is in, so the first-launch prompt has something to act on.
        .then((_) => Speech.surveyArabic())
        .then((_) => Speech.logDiagnostics()),
  );
  final gameAssetManager = GameAssetManager();

  // Read the profile before building the home screen so the splash can cover
  // the correct destination while it renders.
  final profileCubit = ProfileCubit(profileDao, badgeService: badgeService);
  await profileCubit.checkProfile();

  return MyApp(
    initialLanguage: savedLanguage,
    profileCubit: profileCubit,
    database: database,
    profileDao: profileDao,
    gameScoresDao: gameScoresDao,
    gameScoreRecorder: gameScoreRecorder,
    storyDao: storyDao,
    badgeDao: badgeDao,
    badgeService: badgeService,
    flutterTts: flutterTts,
    audioPlayer: audioPlayer,
    gameAssetManager: gameAssetManager,
  );
}

class _StartupApp extends StatefulWidget {
  const _StartupApp({required this.initialization});

  final Future<MyApp> initialization;

  @override
  State<_StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<_StartupApp> {
  final _splashKey = GlobalKey<_AnimatedSplashState>();
  MyApp? _app;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    widget.initialization.then((app) {
      if (!mounted) return;
      setState(() => _app = app);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_showHomeWhenReady());
      });
    });
  }

  Future<void> _showHomeWhenReady() async {
    final splashContext = _splashKey.currentContext;
    final app = _app;
    if (!mounted || splashContext == null || app == null) return;

    final profileState = app.profileCubit.state;
    if (profileState is ProfileLoaded && profileState.currentProfile != null) {
      final background = BackgroundResolver(
        splashContext,
        BackgroundType.tech,
      ).resolveBackground()!;
      final avatarIndex = profileState.currentProfile!.avatarIndex;
      final avatar =
          avatarIndex >= 0 && avatarIndex < ImageManager.kidAvatars.length
              ? ImageManager.kidAvatars[avatarIndex]
              : ImageManager.kidAvatars.first;
      await Future.wait([
        for (final asset in [
          background,
          avatar,
          ImageManager.gamepad,
          ImageManager.letters,
          ImageManager.brainstorming,
        ])
          precacheImage(AssetImage(asset), splashContext),
      ]);
    }

    if (mounted) setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.expand,
        children: [
          if (_app != null)
            KeyedSubtree(key: const ValueKey('ready-app'), child: _app!),
          if (_showSplash)
            KeyedSubtree(
              key: const ValueKey('startup-splash'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                home: _AnimatedSplash(key: _splashKey),
              ),
            ),
        ],
      );
}

class _AnimatedSplash extends StatefulWidget {
  const _AnimatedSplash({super.key});

  @override
  State<_AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<_AnimatedSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  late final String _mascot = const [
    'assets/gen/images/logo/kidzo-curious.webp',
    'assets/gen/images/logo/kidzo-excited.webp',
    'assets/gen/images/logo/kidzo-learning.webp',
    'assets/gen/images/logo/kidzo-celebrate.webp',
  ][Random().nextInt(4)];

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFEF9F3),
        body: Center(
          child: AnimatedBuilder(
            animation: _motion,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -8 * _motion.value),
              child: Transform.rotate(
                angle: (_motion.value - .5) * .07,
                child: child,
              ),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              builder: (context, opacity, child) => Opacity(
                opacity: opacity,
                child: child,
              ),
              child: Image.asset(_mascot, width: 220, height: 220),
            ),
          ),
        ),
      );
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.initialLanguage,
    required this.profileCubit,
    required this.database,
    required this.profileDao,
    required this.gameScoresDao,
    required this.gameScoreRecorder,
    required this.storyDao,
    required this.badgeDao,
    required this.badgeService,
    required this.flutterTts,
    required this.audioPlayer,
    required this.gameAssetManager,
    super.key,
  });

  /// Provided to the widget tree so Adventure Mode can build its own DAO.
  /// Passed down rather than reached for globally, per the injected-services
  /// rule that this feature's registry and services also follow.
  final AppDatabase database;

  /// Read before [runApp] so the first frame is already in this language.
  final String initialLanguage;

  /// Already holds the loaded profile when the app starts.
  final ProfileCubit profileCubit;

  final ProfileDao profileDao;
  final GameScoresDao gameScoresDao;
  final GameScoreRecorder gameScoreRecorder;
  final StoryDao storyDao;
  final BadgeDao badgeDao;
  final BadgeService badgeService;
  final FlutterTts flutterTts;
  final AudioPlayer audioPlayer;
  final GameAssetManager gameAssetManager;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: database),
        RepositoryProvider.value(value: profileDao),
        RepositoryProvider.value(value: gameScoresDao),
        RepositoryProvider.value(value: gameScoreRecorder),
        RepositoryProvider.value(value: storyDao),
        RepositoryProvider.value(value: badgeDao),
        RepositoryProvider.value(value: badgeService),
        RepositoryProvider.value(value: flutterTts),
        RepositoryProvider.value(value: audioPlayer),
        RepositoryProvider.value(value: gameAssetManager),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (context) =>
                  LanguageCubit(initial: Locale(initialLanguage, ''))),
          BlocProvider(create: (context) => SettingsCubit()),
          BlocProvider<BadgeCelebrationCubit>(
            create: (context) =>
                BadgeCelebrationCubit(badgeService: badgeService),
          ),
          BlocProvider(create: (context) => MusicCubit()),
          BlocProvider<ProfileCubit>.value(value: profileCubit),
        ],
        // The shared FlutterTts instance is configured centrally whenever the
        // app language changes. Individual games used to be responsible for
        // this, and several never did it - Feed The Animal and the Fruit &
        // Vegetable Sorter spoke Arabic text through whatever voice happened
        // to be selected, usually the English one.
        child: BlocListener<LanguageCubit, Locale>(
          listenWhen: (previous, current) =>
              previous.languageCode != current.languageCode,
          listener: (context, locale) {
            Speech.configureLanguage(locale.languageCode);
          },
          child: BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                title: 'kidzo',
                theme: ThemeData(
                  colorScheme:
                      ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                  useMaterial3: true,
                ),
                debugShowCheckedModeBanner: false,
                // Wraps the Navigator, so a badge earned on a game screen is
                // still celebrated after that screen pops itself.
                builder: (BuildContext context, Widget? child) =>
                    BadgeCelebrationHost(child: child ?? const SizedBox()),
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    if (state is ProfileLoaded) {
                      return state.currentProfile == null
                          ? const ProfileSetupScreen()
                          : BlocProvider(
                              create: (context) => AlphabetBloc(),
                              child: const CharacterSelectionScreen(),
                            );
                    }
                    return const Scaffold(
                      backgroundColor: Color(0xFF5E7BB9),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
