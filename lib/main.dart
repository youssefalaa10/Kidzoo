import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'core/database/config.dart';
import 'core/database/daos/game_scores_dao.dart';
import 'core/database/daos/profile_dao.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/language_provider.dart';
import 'core/managers/game_asset_manager.dart';
import 'core/services/cubit/music_cubit.dart';
import 'features/Profile/profile_cubit.dart';
import 'features/Splash/splash_screen.dart';
import 'features/settings/cubit/settings_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();



  final database = AppDatabase();
  final profileDao = ProfileDao(database);
  final gameScoresDao = GameScoresDao(database);
  final flutterTts = FlutterTts();
  final audioPlayer = AudioPlayer();
  final gameAssetManager = GameAssetManager();

  runApp(MyApp(
    profileDao: profileDao,
    gameScoresDao: gameScoresDao,
    flutterTts: flutterTts,
    audioPlayer: audioPlayer,
    gameAssetManager: gameAssetManager,
  ));
}

class MyApp extends StatelessWidget {
  final ProfileDao profileDao;
  final GameScoresDao gameScoresDao;
  final FlutterTts flutterTts;
  final AudioPlayer audioPlayer;
  final GameAssetManager gameAssetManager;

  const MyApp({
    super.key,
    required this.profileDao,
    required this.gameScoresDao,
    required this.flutterTts,
    required this.audioPlayer,
    required this.gameAssetManager,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
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
        child: BlocBuilder<LanguageCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp(
              title: 'kidzo',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
