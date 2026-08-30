// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 16),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _avatarIndexMeta =
      const VerificationMeta('avatarIndex');
  @override
  late final GeneratedColumn<int> avatarIndex = GeneratedColumn<int>(
      'avatar_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
      'age', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(7));
  static const VerificationMeta _totalPointsMeta =
      const VerificationMeta('totalPoints');
  @override
  late final GeneratedColumn<int> totalPoints = GeneratedColumn<int>(
      'total_points', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, avatarIndex, age, totalPoints, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<Profile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar_index')) {
      context.handle(
          _avatarIndexMeta,
          avatarIndex.isAcceptableOrUnknown(
              data['avatar_index']!, _avatarIndexMeta));
    }
    if (data.containsKey('age')) {
      context.handle(
          _ageMeta, age.isAcceptableOrUnknown(data['age']!, _ageMeta));
    }
    if (data.containsKey('total_points')) {
      context.handle(
          _totalPointsMeta,
          totalPoints.isAcceptableOrUnknown(
              data['total_points']!, _totalPointsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      avatarIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}avatar_index'])!,
      age: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age'])!,
      totalPoints: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_points'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String name;
  final int avatarIndex;
  final int age;
  final int totalPoints;
  final DateTime createdAt;
  const Profile(
      {required this.id,
      required this.name,
      required this.avatarIndex,
      required this.age,
      required this.totalPoints,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['avatar_index'] = Variable<int>(avatarIndex);
    map['age'] = Variable<int>(age);
    map['total_points'] = Variable<int>(totalPoints);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      avatarIndex: Value(avatarIndex),
      age: Value(age),
      totalPoints: Value(totalPoints),
      createdAt: Value(createdAt),
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatarIndex: serializer.fromJson<int>(json['avatarIndex']),
      age: serializer.fromJson<int>(json['age']),
      totalPoints: serializer.fromJson<int>(json['totalPoints']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'avatarIndex': serializer.toJson<int>(avatarIndex),
      'age': serializer.toJson<int>(age),
      'totalPoints': serializer.toJson<int>(totalPoints),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Profile copyWith(
          {int? id,
          String? name,
          int? avatarIndex,
          int? age,
          int? totalPoints,
          DateTime? createdAt}) =>
      Profile(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarIndex: avatarIndex ?? this.avatarIndex,
        age: age ?? this.age,
        totalPoints: totalPoints ?? this.totalPoints,
        createdAt: createdAt ?? this.createdAt,
      );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarIndex:
          data.avatarIndex.present ? data.avatarIndex.value : this.avatarIndex,
      age: data.age.present ? data.age.value : this.age,
      totalPoints:
          data.totalPoints.present ? data.totalPoints.value : this.totalPoints,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarIndex: $avatarIndex, ')
          ..write('age: $age, ')
          ..write('totalPoints: $totalPoints, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, avatarIndex, age, totalPoints, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarIndex == this.avatarIndex &&
          other.age == this.age &&
          other.totalPoints == this.totalPoints &&
          other.createdAt == this.createdAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> avatarIndex;
  final Value<int> age;
  final Value<int> totalPoints;
  final Value<DateTime> createdAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarIndex = const Value.absent(),
    this.age = const Value.absent(),
    this.totalPoints = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.avatarIndex = const Value.absent(),
    this.age = const Value.absent(),
    this.totalPoints = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? avatarIndex,
    Expression<int>? age,
    Expression<int>? totalPoints,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarIndex != null) 'avatar_index': avatarIndex,
      if (age != null) 'age': age,
      if (totalPoints != null) 'total_points': totalPoints,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProfilesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? avatarIndex,
      Value<int>? age,
      Value<int>? totalPoints,
      Value<DateTime>? createdAt}) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      age: age ?? this.age,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarIndex.present) {
      map['avatar_index'] = Variable<int>(avatarIndex.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (totalPoints.present) {
      map['total_points'] = Variable<int>(totalPoints.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarIndex: $avatarIndex, ')
          ..write('age: $age, ')
          ..write('totalPoints: $totalPoints, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GameScoresTable extends GameScores
    with TableInfo<$GameScoresTable, GameScore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES profiles (id)'));
  static const VerificationMeta _gameKeyMeta =
      const VerificationMeta('gameKey');
  @override
  late final GeneratedColumn<String> gameKey = GeneratedColumn<String>(
      'game_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
      'score', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _playedAtMeta =
      const VerificationMeta('playedAt');
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
      'played_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, profileId, gameKey, score, level, playedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_scores';
  @override
  VerificationContext validateIntegrity(Insertable<GameScore> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('game_key')) {
      context.handle(_gameKeyMeta,
          gameKey.isAcceptableOrUnknown(data['game_key']!, _gameKeyMeta));
    } else if (isInserting) {
      context.missing(_gameKeyMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('played_at')) {
      context.handle(_playedAtMeta,
          playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameScore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameScore(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id'])!,
      gameKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}game_key'])!,
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}score'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level']),
      playedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}played_at'])!,
    );
  }

  @override
  $GameScoresTable createAlias(String alias) {
    return $GameScoresTable(attachedDatabase, alias);
  }
}

class GameScore extends DataClass implements Insertable<GameScore> {
  final int id;
  final int profileId;
  final String gameKey;
  final int score;
  final int? level;
  final DateTime playedAt;
  const GameScore(
      {required this.id,
      required this.profileId,
      required this.gameKey,
      required this.score,
      this.level,
      required this.playedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['game_key'] = Variable<String>(gameKey);
    map['score'] = Variable<int>(score);
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<int>(level);
    }
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  GameScoresCompanion toCompanion(bool nullToAbsent) {
    return GameScoresCompanion(
      id: Value(id),
      profileId: Value(profileId),
      gameKey: Value(gameKey),
      score: Value(score),
      level:
          level == null && nullToAbsent ? const Value.absent() : Value(level),
      playedAt: Value(playedAt),
    );
  }

  factory GameScore.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameScore(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      gameKey: serializer.fromJson<String>(json['gameKey']),
      score: serializer.fromJson<int>(json['score']),
      level: serializer.fromJson<int?>(json['level']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'gameKey': serializer.toJson<String>(gameKey),
      'score': serializer.toJson<int>(score),
      'level': serializer.toJson<int?>(level),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  GameScore copyWith(
          {int? id,
          int? profileId,
          String? gameKey,
          int? score,
          Value<int?> level = const Value.absent(),
          DateTime? playedAt}) =>
      GameScore(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        gameKey: gameKey ?? this.gameKey,
        score: score ?? this.score,
        level: level.present ? level.value : this.level,
        playedAt: playedAt ?? this.playedAt,
      );
  GameScore copyWithCompanion(GameScoresCompanion data) {
    return GameScore(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      gameKey: data.gameKey.present ? data.gameKey.value : this.gameKey,
      score: data.score.present ? data.score.value : this.score,
      level: data.level.present ? data.level.value : this.level,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameScore(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('gameKey: $gameKey, ')
          ..write('score: $score, ')
          ..write('level: $level, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, gameKey, score, level, playedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameScore &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.gameKey == this.gameKey &&
          other.score == this.score &&
          other.level == this.level &&
          other.playedAt == this.playedAt);
}

class GameScoresCompanion extends UpdateCompanion<GameScore> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> gameKey;
  final Value<int> score;
  final Value<int?> level;
  final Value<DateTime> playedAt;
  const GameScoresCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.gameKey = const Value.absent(),
    this.score = const Value.absent(),
    this.level = const Value.absent(),
    this.playedAt = const Value.absent(),
  });
  GameScoresCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String gameKey,
    required int score,
    this.level = const Value.absent(),
    this.playedAt = const Value.absent(),
  })  : profileId = Value(profileId),
        gameKey = Value(gameKey),
        score = Value(score);
  static Insertable<GameScore> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? gameKey,
    Expression<int>? score,
    Expression<int>? level,
    Expression<DateTime>? playedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (gameKey != null) 'game_key': gameKey,
      if (score != null) 'score': score,
      if (level != null) 'level': level,
      if (playedAt != null) 'played_at': playedAt,
    });
  }

  GameScoresCompanion copyWith(
      {Value<int>? id,
      Value<int>? profileId,
      Value<String>? gameKey,
      Value<int>? score,
      Value<int?>? level,
      Value<DateTime>? playedAt}) {
    return GameScoresCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      gameKey: gameKey ?? this.gameKey,
      score: score ?? this.score,
      level: level ?? this.level,
      playedAt: playedAt ?? this.playedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (gameKey.present) {
      map['game_key'] = Variable<String>(gameKey.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameScoresCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('gameKey: $gameKey, ')
          ..write('score: $score, ')
          ..write('level: $level, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $GameScoresTable gameScores = $GameScoresTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [profiles, gameScores];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  required String name,
  Value<int> avatarIndex,
  Value<int> age,
  Value<int> totalPoints,
  Value<DateTime> createdAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> avatarIndex,
  Value<int> age,
  Value<int> totalPoints,
  Value<DateTime> createdAt,
});

final class $$ProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $ProfilesTable, Profile> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GameScoresTable, List<GameScore>>
      _gameScoresRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.gameScores,
              aliasName: 'profiles__id__game_scores__profile_id');

  $$GameScoresTableProcessedTableManager get gameScoresRefs {
    final manager = $$GameScoresTableTableManager($_db, $_db.gameScores)
        .filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gameScoresRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get avatarIndex => $composableBuilder(
      column: $table.avatarIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalPoints => $composableBuilder(
      column: $table.totalPoints, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> gameScoresRefs(
      Expression<bool> Function($$GameScoresTableFilterComposer f) f) {
    final $$GameScoresTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.gameScores,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GameScoresTableFilterComposer(
              $db: $db,
              $table: $db.gameScores,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get avatarIndex => $composableBuilder(
      column: $table.avatarIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalPoints => $composableBuilder(
      column: $table.totalPoints, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get avatarIndex => $composableBuilder(
      column: $table.avatarIndex, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<int> get totalPoints => $composableBuilder(
      column: $table.totalPoints, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> gameScoresRefs<T extends Object>(
      Expression<T> Function($$GameScoresTableAnnotationComposer a) f) {
    final $$GameScoresTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.gameScores,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GameScoresTableAnnotationComposer(
              $db: $db,
              $table: $db.gameScores,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, $$ProfilesTableReferences),
    Profile,
    PrefetchHooks Function({bool gameScoresRefs})> {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> avatarIndex = const Value.absent(),
            Value<int> age = const Value.absent(),
            Value<int> totalPoints = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ProfilesCompanion(
            id: id,
            name: name,
            avatarIndex: avatarIndex,
            age: age,
            totalPoints: totalPoints,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int> avatarIndex = const Value.absent(),
            Value<int> age = const Value.absent(),
            Value<int> totalPoints = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ProfilesCompanion.insert(
            id: id,
            name: name,
            avatarIndex: avatarIndex,
            age: age,
            totalPoints: totalPoints,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProfilesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({gameScoresRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (gameScoresRefs) db.gameScores],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (gameScoresRefs)
                    await $_getPrefetchedData<Profile, $ProfilesTable,
                            GameScore>(
                        currentTable: table,
                        referencedTable:
                            $$ProfilesTableReferences._gameScoresRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProfilesTableReferences(db, table, p0)
                                .gameScoresRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.profileId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, $$ProfilesTableReferences),
    Profile,
    PrefetchHooks Function({bool gameScoresRefs})>;
typedef $$GameScoresTableCreateCompanionBuilder = GameScoresCompanion Function({
  Value<int> id,
  required int profileId,
  required String gameKey,
  required int score,
  Value<int?> level,
  Value<DateTime> playedAt,
});
typedef $$GameScoresTableUpdateCompanionBuilder = GameScoresCompanion Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> gameKey,
  Value<int> score,
  Value<int?> level,
  Value<DateTime> playedAt,
});

final class $$GameScoresTableReferences
    extends BaseReferences<_$AppDatabase, $GameScoresTable, GameScore> {
  $$GameScoresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('game_scores__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<int>('profile_id')!;

    final manager = $$ProfilesTableTableManager($_db, $_db.profiles)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GameScoresTableFilterComposer
    extends Composer<_$AppDatabase, $GameScoresTable> {
  $$GameScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gameKey => $composableBuilder(
      column: $table.gameKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
      column: $table.playedAt, builder: (column) => ColumnFilters(column));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableFilterComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GameScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $GameScoresTable> {
  $$GameScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gameKey => $composableBuilder(
      column: $table.gameKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
      column: $table.playedAt, builder: (column) => ColumnOrderings(column));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableOrderingComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GameScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameScoresTable> {
  $$GameScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gameKey =>
      $composableBuilder(column: $table.gameKey, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableAnnotationComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GameScoresTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GameScoresTable,
    GameScore,
    $$GameScoresTableFilterComposer,
    $$GameScoresTableOrderingComposer,
    $$GameScoresTableAnnotationComposer,
    $$GameScoresTableCreateCompanionBuilder,
    $$GameScoresTableUpdateCompanionBuilder,
    (GameScore, $$GameScoresTableReferences),
    GameScore,
    PrefetchHooks Function({bool profileId})> {
  $$GameScoresTableTableManager(_$AppDatabase db, $GameScoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> profileId = const Value.absent(),
            Value<String> gameKey = const Value.absent(),
            Value<int> score = const Value.absent(),
            Value<int?> level = const Value.absent(),
            Value<DateTime> playedAt = const Value.absent(),
          }) =>
              GameScoresCompanion(
            id: id,
            profileId: profileId,
            gameKey: gameKey,
            score: score,
            level: level,
            playedAt: playedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int profileId,
            required String gameKey,
            required int score,
            Value<int?> level = const Value.absent(),
            Value<DateTime> playedAt = const Value.absent(),
          }) =>
              GameScoresCompanion.insert(
            id: id,
            profileId: profileId,
            gameKey: gameKey,
            score: score,
            level: level,
            playedAt: playedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GameScoresTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (profileId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.profileId,
                    referencedTable:
                        $$GameScoresTableReferences._profileIdTable(db),
                    referencedColumn:
                        $$GameScoresTableReferences._profileIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GameScoresTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GameScoresTable,
    GameScore,
    $$GameScoresTableFilterComposer,
    $$GameScoresTableOrderingComposer,
    $$GameScoresTableAnnotationComposer,
    $$GameScoresTableCreateCompanionBuilder,
    $$GameScoresTableUpdateCompanionBuilder,
    (GameScore, $$GameScoresTableReferences),
    GameScore,
    PrefetchHooks Function({bool profileId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$GameScoresTableTableManager get gameScores =>
      $$GameScoresTableTableManager(_db, _db.gameScores);
}
