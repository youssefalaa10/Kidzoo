import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';
import 'package:kidzo/features/Difficulty/logic/difficulty_load_status.dart';
import 'package:kidzo/features/Difficulty/logic/difficulty_select_cubit.dart';

/// What the picker opens, against a real database.
///
/// The unlock rule is the whole feature, so the cases worth writing down are
/// the ones where a tier must *not* open.
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

  DifficultySelectCubit buildCubit({String gameKey = 'memory_game'}) =>
      DifficultySelectCubit(
        gameScoresDao: gameScoresDao,
        profileDao: profileDao,
        gameKey: gameKey,
      );

  Future<void> recordWin({
    required int level,
    int score = 100,
    int? stars,
    String gameKey = 'memory_game',
  }) {
    return gameScoresDao.insertScore(GameScoresCompanion.insert(
      profileId: profileId,
      gameKey: gameKey,
      score: score,
      level: Value<int?>(level),
      starsEarned: Value<int?>(stars),
    ));
  }

  test('a child who has never played sees Easy only', () async {
    final DifficultySelectCubit cubit = buildCubit();
    await cubit.loadProgress();
    expect(cubit.state.status, DifficultyLoadStatus.ready);
    expect(cubit.state.isUnlocked(KidDifficulty.easy), isTrue);
    expect(cubit.state.isUnlocked(KidDifficulty.medium), isFalse);
    expect(cubit.state.isUnlocked(KidDifficulty.hard), isFalse);
    await cubit.close();
  });

  test('clearing Easy opens Medium but not Hard', () async {
    await recordWin(level: 1, stars: 1);
    final DifficultySelectCubit cubit = buildCubit();
    await cubit.loadProgress();
    expect(cubit.state.isUnlocked(KidDifficulty.medium), isTrue);
    expect(cubit.state.isUnlocked(KidDifficulty.hard), isFalse);
    await cubit.close();
  });

  test('one star is enough — finishing is the toll, not mastery', () async {
    await recordWin(level: 1, stars: 1);
    await recordWin(level: 2, stars: 1);
    final DifficultySelectCubit cubit = buildCubit();
    await cubit.loadProgress();
    expect(cubit.state.isUnlocked(KidDifficulty.hard), isTrue);
    await cubit.close();
  });

  test('a row with no stars still unlocks the next tier', () async {
    // Pins the plays-not-stars invariant. Rows written before starsEarned
    // existed leave it null, and gating on stars would re-lock a tier the
    // child had already finished.
    await recordWin(level: 1);
    final DifficultySelectCubit cubit = buildCubit();
    await cubit.loadProgress();
    expect(cubit.state.isUnlocked(KidDifficulty.medium), isTrue);
    expect(cubit.state.starsFor(KidDifficulty.easy), 0);
    await cubit.close();
  });

  test('another game does not unlock this one', () async {
    await recordWin(level: 1, gameKey: 'puzzle');
    final DifficultySelectCubit cubit = buildCubit();
    await cubit.loadProgress();
    expect(cubit.state.isUnlocked(KidDifficulty.medium), isFalse);
    await cubit.close();
  });

  test('best stars and best score surface per tier', () async {
    await recordWin(level: 1, score: 40, stars: 1);
    await recordWin(level: 1, score: 90, stars: 3);
    final DifficultySelectCubit cubit = buildCubit();
    await cubit.loadProgress();
    expect(cubit.state.starsFor(KidDifficulty.easy), 3);
    expect(cubit.state.bestScoreFor(KidDifficulty.easy), 90);
    expect(cubit.state.bestScoreFor(KidDifficulty.medium), isNull);
    await cubit.close();
  });

  test('a profile-less install degrades to Easy, not to everything', () async {
    await database.delete(database.gameScores).go();
    await database.delete(database.profiles).go();
    final DifficultySelectCubit cubit = buildCubit();
    await cubit.loadProgress();
    expect(cubit.state.status, DifficultyLoadStatus.ready);
    expect(cubit.state.isUnlocked(KidDifficulty.easy), isTrue);
    expect(cubit.state.isUnlocked(KidDifficulty.medium), isFalse);
    await cubit.close();
  });

  test('a read failure never strands the child on a spinner', () async {
    await database.close();
    final DifficultySelectCubit cubit = buildCubit();
    await cubit.loadProgress();
    expect(cubit.state.status, DifficultyLoadStatus.failed);
    expect(cubit.state.isUnlocked(KidDifficulty.easy), isTrue);
    await cubit.close();
    database = AppDatabase(NativeDatabase.memory());
  });
}
