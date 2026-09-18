import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'core/database/config.dart';
import 'core/database/daos/game_scores_dao.dart';
import 'core/database/daos/profile_dao.dart';
import 'core/helpers/speech.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/language_provider.dart';
import 'core/managers/game_asset_manager.dart';
import 'core/services/cubit/music_cubit.dart';
import 'features/Alphabets/bloc/alphabet_bloc.dart';
import 'features/Profile/profile_cubit.dart';
import 'features/Profile/profile_setup_screen.dart';
import 'features/Profile/profile_state.dart';
import 'features/home/UI/character.dart';
import 'features/settings/cubit/settings_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final profileDao = ProfileDao(database);
  final gameScoresDao = GameScoresDao(database);
  final flutterTts = FlutterTts();
  final audioPlayer = AudioPlayer();
  // Speech goes through one facade so the device-or-cloud decision is made
  // once. A separate player is used for synthesized audio so a spoken prompt
  // never cuts off a game sound effect.
  Speech.attach(tts: flutterTts, player: AudioPlayer());
  // Resolve the voice up front using the language the user last chose, so the
  // first prompt of a saved Arabic session already uses the right voice
  // instead of switching a moment later.
  unawaited(
    Speech.configureLanguage(await LanguageCubit.savedLanguageCode())
        // Survey the device's Arabic capability up front, whatever language
        // the UI is in, so the first-launch prompt has something to act on.
        .then((_) => Speech.surveyArabic())
        .then((_) => Speech.logDiagnostics()),
  );
  final gameAssetManager = GameAssetManager();

  runApp(MyApp(
    database: database,
    profileDao: profileDao,
    gameScoresDao: gameScoresDao,
    flutterTts: flutterTts,
    audioPlayer: audioPlayer,
    gameAssetManager: gameAssetManager,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.database,
    required this.profileDao,
    required this.gameScoresDao,
    required this.flutterTts,
    required this.audioPlayer,
    required this.gameAssetManager,
    super.key,
  });
  /// Provided to the widget tree so Adventure Mode can build its own DAO.
  /// Passed down rather than reached for globally, per the injected-services
  /// rule that this feature's registry and services also follow.
  final AppDatabase database;

  final ProfileDao profileDao;
  final GameScoresDao gameScoresDao;
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
        RepositoryProvider.value(value: flutterTts),
        RepositoryProvider.value(value: audioPlayer),
        RepositoryProvider.value(value: gameAssetManager),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => LanguageCubit()),
          BlocProvider(create: (context) => SettingsCubit()),
          BlocProvider(create: (context) => MusicCubit()),
          BlocProvider(
              create: (context) =>
                  ProfileCubit(context.read<ProfileDao>())..checkProfile()),
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
                      body: Center(child: CircularProgressIndicator()),
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
