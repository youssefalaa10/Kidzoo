import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/features/Difficulty/ui/difficulty_select_screen.dart';

import '../support/test_localizations.dart';

/// The picker as a child meets it.
///
/// The cubit tests prove the unlock rule; these prove the screen honours it —
/// specifically that a locked card cannot start a game, which is the one
/// failure that would make the whole gate decorative.
void main() {
  late AppDatabase database;
  late GameScoresDao gameScoresDao;
  late ProfileDao profileDao;
  late int profileId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    gameScoresDao = GameScoresDao(database);
    profileDao = ProfileDao(database);
    profileId = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
  });

  tearDown(() async => database.close());

  Future<void> recordWin({required int level, int? stars}) {
    return gameScoresDao.insertScore(GameScoresCompanion.insert(
      profileId: profileId,
      gameKey: 'memory_game',
      score: 100,
      level: Value<int?>(level),
      starsEarned: Value<int?>(stars),
    ));
  }

  Widget wrap(Widget child) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<GameScoresDao>.value(value: gameScoresDao),
        RepositoryProvider<ProfileDao>.value(value: profileDao),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          TestAppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  Widget buildPicker({Widget? bonus}) {
    return wrap(DifficultySelectScreen(
      activityId: 'memory_game',
      titleLocalizationKey: 'memoryGame',
      descriptionKeyPrefix: 'memory',
      gameBuilder: (KidDifficulty difficulty) =>
          _GameStub(difficulty: difficulty),
      bonusCardBuilder:
          bonus == null ? null : (BuildContext _, dynamic __) => bonus,
    ));
  }

  testWidgets('shows a card for each tier', (WidgetTester tester) async {
    await tester.pumpWidget(buildPicker());
    await tester.pumpAndSettle();
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('4 pairs to match'), findsOneWidget);
  });

  testWidgets('locks every tier above Easy for a new child',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildPicker());
    await tester.pumpAndSettle();
    // Two locks: Medium and Hard. Easy shows a play arrow instead.
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('tapping a locked tier starts nothing',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildPicker());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hard'));
    await tester.pumpAndSettle();
    expect(find.byType(_GameStub), findsNothing);
    // The child is told why, rather than nothing happening at all.
    expect(find.textContaining('Finish'), findsWidgets);
  });

  testWidgets('tapping Easy starts the game at that tier',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildPicker());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Easy'));
    await tester.pumpAndSettle();
    expect(find.byType(_GameStub), findsOneWidget);
    expect(
      tester.widget<_GameStub>(find.byType(_GameStub)).difficulty,
      KidDifficulty.easy,
    );
  });

  testWidgets('a cleared tier unlocks the next one',
      (WidgetTester tester) async {
    await recordWin(level: 1, stars: 2);
    await tester.pumpWidget(buildPicker());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<_GameStub>(find.byType(_GameStub)).difficulty,
      KidDifficulty.medium,
    );
  });

  testWidgets('earned stars appear on the card', (WidgetTester tester) async {
    await recordWin(level: 1, stars: 2);
    await tester.pumpWidget(buildPicker());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
    expect(find.text('Best: 100'), findsOneWidget);
  });

  testWidgets('an unplayed unlocked tier says so', (WidgetTester tester) async {
    await tester.pumpWidget(buildPicker());
    await tester.pumpAndSettle();
    expect(find.text('Not played yet'), findsOneWidget);
  });

  testWidgets('the bonus card appears only when one is given',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildPicker());
    await tester.pumpAndSettle();
    expect(find.text('BONUS'), findsNothing);

    await tester.pumpWidget(buildPicker(bonus: const Text('BONUS')));
    await tester.pumpAndSettle();
    expect(find.text('BONUS'), findsOneWidget);
  });
}

class _GameStub extends StatelessWidget {
  const _GameStub({required this.difficulty});

  final KidDifficulty difficulty;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('playing ${difficulty.name}')));
}
