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
  static const VerificationMeta _maxScoreMeta =
      const VerificationMeta('maxScore');
  @override
  late final GeneratedColumn<int> maxScore = GeneratedColumn<int>(
      'max_score', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _starsEarnedMeta =
      const VerificationMeta('starsEarned');
  @override
  late final GeneratedColumn<int> starsEarned = GeneratedColumn<int>(
      'stars_earned', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _storyNodeIdMeta =
      const VerificationMeta('storyNodeId');
  @override
  late final GeneratedColumn<String> storyNodeId = GeneratedColumn<String>(
      'story_node_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        gameKey,
        score,
        level,
        playedAt,
        maxScore,
        starsEarned,
        durationSeconds,
        storyNodeId
      ];
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
    if (data.containsKey('max_score')) {
      context.handle(_maxScoreMeta,
          maxScore.isAcceptableOrUnknown(data['max_score']!, _maxScoreMeta));
    }
    if (data.containsKey('stars_earned')) {
      context.handle(
          _starsEarnedMeta,
          starsEarned.isAcceptableOrUnknown(
              data['stars_earned']!, _starsEarnedMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('story_node_id')) {
      context.handle(
          _storyNodeIdMeta,
          storyNodeId.isAcceptableOrUnknown(
              data['story_node_id']!, _storyNodeIdMeta));
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
      maxScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_score']),
      starsEarned: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stars_earned']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds']),
      storyNodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}story_node_id']),
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

  /// Added in schema v3 for Adventure results. All nullable, because every row
  /// the older games already wrote has none of them.
  final int? maxScore;
  final int? starsEarned;
  final int? durationSeconds;

  /// Joins a score back to the story beat it served, when it came from one.
  final String? storyNodeId;
  const GameScore(
      {required this.id,
      required this.profileId,
      required this.gameKey,
      required this.score,
      this.level,
      required this.playedAt,
      this.maxScore,
      this.starsEarned,
      this.durationSeconds,
      this.storyNodeId});
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
    if (!nullToAbsent || maxScore != null) {
      map['max_score'] = Variable<int>(maxScore);
    }
    if (!nullToAbsent || starsEarned != null) {
      map['stars_earned'] = Variable<int>(starsEarned);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || storyNodeId != null) {
      map['story_node_id'] = Variable<String>(storyNodeId);
    }
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
      maxScore: maxScore == null && nullToAbsent
          ? const Value.absent()
          : Value(maxScore),
      starsEarned: starsEarned == null && nullToAbsent
          ? const Value.absent()
          : Value(starsEarned),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      storyNodeId: storyNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storyNodeId),
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
      maxScore: serializer.fromJson<int?>(json['maxScore']),
      starsEarned: serializer.fromJson<int?>(json['starsEarned']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      storyNodeId: serializer.fromJson<String?>(json['storyNodeId']),
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
      'maxScore': serializer.toJson<int?>(maxScore),
      'starsEarned': serializer.toJson<int?>(starsEarned),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'storyNodeId': serializer.toJson<String?>(storyNodeId),
    };
  }

  GameScore copyWith(
          {int? id,
          int? profileId,
          String? gameKey,
          int? score,
          Value<int?> level = const Value.absent(),
          DateTime? playedAt,
          Value<int?> maxScore = const Value.absent(),
          Value<int?> starsEarned = const Value.absent(),
          Value<int?> durationSeconds = const Value.absent(),
          Value<String?> storyNodeId = const Value.absent()}) =>
      GameScore(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        gameKey: gameKey ?? this.gameKey,
        score: score ?? this.score,
        level: level.present ? level.value : this.level,
        playedAt: playedAt ?? this.playedAt,
        maxScore: maxScore.present ? maxScore.value : this.maxScore,
        starsEarned: starsEarned.present ? starsEarned.value : this.starsEarned,
        durationSeconds: durationSeconds.present
            ? durationSeconds.value
            : this.durationSeconds,
        storyNodeId: storyNodeId.present ? storyNodeId.value : this.storyNodeId,
      );
  GameScore copyWithCompanion(GameScoresCompanion data) {
    return GameScore(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      gameKey: data.gameKey.present ? data.gameKey.value : this.gameKey,
      score: data.score.present ? data.score.value : this.score,
      level: data.level.present ? data.level.value : this.level,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      maxScore: data.maxScore.present ? data.maxScore.value : this.maxScore,
      starsEarned:
          data.starsEarned.present ? data.starsEarned.value : this.starsEarned,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      storyNodeId:
          data.storyNodeId.present ? data.storyNodeId.value : this.storyNodeId,
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
          ..write('playedAt: $playedAt, ')
          ..write('maxScore: $maxScore, ')
          ..write('starsEarned: $starsEarned, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('storyNodeId: $storyNodeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, gameKey, score, level,
      playedAt, maxScore, starsEarned, durationSeconds, storyNodeId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameScore &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.gameKey == this.gameKey &&
          other.score == this.score &&
          other.level == this.level &&
          other.playedAt == this.playedAt &&
          other.maxScore == this.maxScore &&
          other.starsEarned == this.starsEarned &&
          other.durationSeconds == this.durationSeconds &&
          other.storyNodeId == this.storyNodeId);
}

class GameScoresCompanion extends UpdateCompanion<GameScore> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> gameKey;
  final Value<int> score;
  final Value<int?> level;
  final Value<DateTime> playedAt;
  final Value<int?> maxScore;
  final Value<int?> starsEarned;
  final Value<int?> durationSeconds;
  final Value<String?> storyNodeId;
  const GameScoresCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.gameKey = const Value.absent(),
    this.score = const Value.absent(),
    this.level = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.starsEarned = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.storyNodeId = const Value.absent(),
  });
  GameScoresCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String gameKey,
    required int score,
    this.level = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.starsEarned = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.storyNodeId = const Value.absent(),
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
    Expression<int>? maxScore,
    Expression<int>? starsEarned,
    Expression<int>? durationSeconds,
    Expression<String>? storyNodeId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (gameKey != null) 'game_key': gameKey,
      if (score != null) 'score': score,
      if (level != null) 'level': level,
      if (playedAt != null) 'played_at': playedAt,
      if (maxScore != null) 'max_score': maxScore,
      if (starsEarned != null) 'stars_earned': starsEarned,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (storyNodeId != null) 'story_node_id': storyNodeId,
    });
  }

  GameScoresCompanion copyWith(
      {Value<int>? id,
      Value<int>? profileId,
      Value<String>? gameKey,
      Value<int>? score,
      Value<int?>? level,
      Value<DateTime>? playedAt,
      Value<int?>? maxScore,
      Value<int?>? starsEarned,
      Value<int?>? durationSeconds,
      Value<String?>? storyNodeId}) {
    return GameScoresCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      gameKey: gameKey ?? this.gameKey,
      score: score ?? this.score,
      level: level ?? this.level,
      playedAt: playedAt ?? this.playedAt,
      maxScore: maxScore ?? this.maxScore,
      starsEarned: starsEarned ?? this.starsEarned,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      storyNodeId: storyNodeId ?? this.storyNodeId,
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
    if (maxScore.present) {
      map['max_score'] = Variable<int>(maxScore.value);
    }
    if (starsEarned.present) {
      map['stars_earned'] = Variable<int>(starsEarned.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (storyNodeId.present) {
      map['story_node_id'] = Variable<String>(storyNodeId.value);
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
          ..write('playedAt: $playedAt, ')
          ..write('maxScore: $maxScore, ')
          ..write('starsEarned: $starsEarned, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('storyNodeId: $storyNodeId')
          ..write(')'))
        .toString();
  }
}

class $StoryNodeProgressTable extends StoryNodeProgress
    with TableInfo<$StoryNodeProgressTable, StoryNodeProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryNodeProgressTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _adventureIdMeta =
      const VerificationMeta('adventureId');
  @override
  late final GeneratedColumn<String> adventureId = GeneratedColumn<String>(
      'adventure_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
      'node_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completionMeta =
      const VerificationMeta('completion');
  @override
  late final GeneratedColumn<String> completion = GeneratedColumn<String>(
      'completion', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('completed'));
  static const VerificationMeta _stepsTotalMeta =
      const VerificationMeta('stepsTotal');
  @override
  late final GeneratedColumn<int> stepsTotal = GeneratedColumn<int>(
      'steps_total', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _stepsIndependentMeta =
      const VerificationMeta('stepsIndependent');
  @override
  late final GeneratedColumn<int> stepsIndependent = GeneratedColumn<int>(
      'steps_independent', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _hintsUsedMeta =
      const VerificationMeta('hintsUsed');
  @override
  late final GeneratedColumn<int> hintsUsed = GeneratedColumn<int>(
      'hints_used', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
      'score', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        adventureId,
        nodeId,
        completion,
        stepsTotal,
        stepsIndependent,
        hintsUsed,
        score,
        durationSeconds,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_node_progress';
  @override
  VerificationContext validateIntegrity(
      Insertable<StoryNodeProgressData> instance,
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
    if (data.containsKey('adventure_id')) {
      context.handle(
          _adventureIdMeta,
          adventureId.isAcceptableOrUnknown(
              data['adventure_id']!, _adventureIdMeta));
    } else if (isInserting) {
      context.missing(_adventureIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(_nodeIdMeta,
          nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta));
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('completion')) {
      context.handle(
          _completionMeta,
          completion.isAcceptableOrUnknown(
              data['completion']!, _completionMeta));
    }
    if (data.containsKey('steps_total')) {
      context.handle(
          _stepsTotalMeta,
          stepsTotal.isAcceptableOrUnknown(
              data['steps_total']!, _stepsTotalMeta));
    }
    if (data.containsKey('steps_independent')) {
      context.handle(
          _stepsIndependentMeta,
          stepsIndependent.isAcceptableOrUnknown(
              data['steps_independent']!, _stepsIndependentMeta));
    }
    if (data.containsKey('hints_used')) {
      context.handle(_hintsUsedMeta,
          hintsUsed.isAcceptableOrUnknown(data['hints_used']!, _hintsUsedMeta));
    }
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {profileId, nodeId},
      ];
  @override
  StoryNodeProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryNodeProgressData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id'])!,
      adventureId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}adventure_id'])!,
      nodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}node_id'])!,
      completion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}completion'])!,
      stepsTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}steps_total'])!,
      stepsIndependent: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}steps_independent'])!,
      hintsUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hints_used'])!,
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}score'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $StoryNodeProgressTable createAlias(String alias) {
    return $StoryNodeProgressTable(attachedDatabase, alias);
  }
}

class StoryNodeProgressData extends DataClass
    implements Insertable<StoryNodeProgressData> {
  final int id;
  final int profileId;
  final String adventureId;
  final String nodeId;

  /// `inProgress`, `completed` or `abandoned`.
  ///
  /// There is deliberately no `failed`. Every child who reaches the last step
  /// of an activity completes it, so the story can never stall on performance.
  final String completion;

  /// Mastery signals. They feed the parent report and the adaptive nudge, and
  /// they **never** branch the narrative.
  final int stepsTotal;
  final int stepsIndependent;
  final int hintsUsed;
  final int score;
  final int durationSeconds;
  final DateTime updatedAt;
  const StoryNodeProgressData(
      {required this.id,
      required this.profileId,
      required this.adventureId,
      required this.nodeId,
      required this.completion,
      required this.stepsTotal,
      required this.stepsIndependent,
      required this.hintsUsed,
      required this.score,
      required this.durationSeconds,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['adventure_id'] = Variable<String>(adventureId);
    map['node_id'] = Variable<String>(nodeId);
    map['completion'] = Variable<String>(completion);
    map['steps_total'] = Variable<int>(stepsTotal);
    map['steps_independent'] = Variable<int>(stepsIndependent);
    map['hints_used'] = Variable<int>(hintsUsed);
    map['score'] = Variable<int>(score);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoryNodeProgressCompanion toCompanion(bool nullToAbsent) {
    return StoryNodeProgressCompanion(
      id: Value(id),
      profileId: Value(profileId),
      adventureId: Value(adventureId),
      nodeId: Value(nodeId),
      completion: Value(completion),
      stepsTotal: Value(stepsTotal),
      stepsIndependent: Value(stepsIndependent),
      hintsUsed: Value(hintsUsed),
      score: Value(score),
      durationSeconds: Value(durationSeconds),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoryNodeProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryNodeProgressData(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      adventureId: serializer.fromJson<String>(json['adventureId']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      completion: serializer.fromJson<String>(json['completion']),
      stepsTotal: serializer.fromJson<int>(json['stepsTotal']),
      stepsIndependent: serializer.fromJson<int>(json['stepsIndependent']),
      hintsUsed: serializer.fromJson<int>(json['hintsUsed']),
      score: serializer.fromJson<int>(json['score']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'adventureId': serializer.toJson<String>(adventureId),
      'nodeId': serializer.toJson<String>(nodeId),
      'completion': serializer.toJson<String>(completion),
      'stepsTotal': serializer.toJson<int>(stepsTotal),
      'stepsIndependent': serializer.toJson<int>(stepsIndependent),
      'hintsUsed': serializer.toJson<int>(hintsUsed),
      'score': serializer.toJson<int>(score),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoryNodeProgressData copyWith(
          {int? id,
          int? profileId,
          String? adventureId,
          String? nodeId,
          String? completion,
          int? stepsTotal,
          int? stepsIndependent,
          int? hintsUsed,
          int? score,
          int? durationSeconds,
          DateTime? updatedAt}) =>
      StoryNodeProgressData(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        adventureId: adventureId ?? this.adventureId,
        nodeId: nodeId ?? this.nodeId,
        completion: completion ?? this.completion,
        stepsTotal: stepsTotal ?? this.stepsTotal,
        stepsIndependent: stepsIndependent ?? this.stepsIndependent,
        hintsUsed: hintsUsed ?? this.hintsUsed,
        score: score ?? this.score,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  StoryNodeProgressData copyWithCompanion(StoryNodeProgressCompanion data) {
    return StoryNodeProgressData(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      adventureId:
          data.adventureId.present ? data.adventureId.value : this.adventureId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      completion:
          data.completion.present ? data.completion.value : this.completion,
      stepsTotal:
          data.stepsTotal.present ? data.stepsTotal.value : this.stepsTotal,
      stepsIndependent: data.stepsIndependent.present
          ? data.stepsIndependent.value
          : this.stepsIndependent,
      hintsUsed: data.hintsUsed.present ? data.hintsUsed.value : this.hintsUsed,
      score: data.score.present ? data.score.value : this.score,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryNodeProgressData(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('adventureId: $adventureId, ')
          ..write('nodeId: $nodeId, ')
          ..write('completion: $completion, ')
          ..write('stepsTotal: $stepsTotal, ')
          ..write('stepsIndependent: $stepsIndependent, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('score: $score, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profileId,
      adventureId,
      nodeId,
      completion,
      stepsTotal,
      stepsIndependent,
      hintsUsed,
      score,
      durationSeconds,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryNodeProgressData &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.adventureId == this.adventureId &&
          other.nodeId == this.nodeId &&
          other.completion == this.completion &&
          other.stepsTotal == this.stepsTotal &&
          other.stepsIndependent == this.stepsIndependent &&
          other.hintsUsed == this.hintsUsed &&
          other.score == this.score &&
          other.durationSeconds == this.durationSeconds &&
          other.updatedAt == this.updatedAt);
}

class StoryNodeProgressCompanion
    extends UpdateCompanion<StoryNodeProgressData> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> adventureId;
  final Value<String> nodeId;
  final Value<String> completion;
  final Value<int> stepsTotal;
  final Value<int> stepsIndependent;
  final Value<int> hintsUsed;
  final Value<int> score;
  final Value<int> durationSeconds;
  final Value<DateTime> updatedAt;
  const StoryNodeProgressCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.adventureId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.completion = const Value.absent(),
    this.stepsTotal = const Value.absent(),
    this.stepsIndependent = const Value.absent(),
    this.hintsUsed = const Value.absent(),
    this.score = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StoryNodeProgressCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String adventureId,
    required String nodeId,
    this.completion = const Value.absent(),
    this.stepsTotal = const Value.absent(),
    this.stepsIndependent = const Value.absent(),
    this.hintsUsed = const Value.absent(),
    this.score = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : profileId = Value(profileId),
        adventureId = Value(adventureId),
        nodeId = Value(nodeId);
  static Insertable<StoryNodeProgressData> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? adventureId,
    Expression<String>? nodeId,
    Expression<String>? completion,
    Expression<int>? stepsTotal,
    Expression<int>? stepsIndependent,
    Expression<int>? hintsUsed,
    Expression<int>? score,
    Expression<int>? durationSeconds,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (adventureId != null) 'adventure_id': adventureId,
      if (nodeId != null) 'node_id': nodeId,
      if (completion != null) 'completion': completion,
      if (stepsTotal != null) 'steps_total': stepsTotal,
      if (stepsIndependent != null) 'steps_independent': stepsIndependent,
      if (hintsUsed != null) 'hints_used': hintsUsed,
      if (score != null) 'score': score,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StoryNodeProgressCompanion copyWith(
      {Value<int>? id,
      Value<int>? profileId,
      Value<String>? adventureId,
      Value<String>? nodeId,
      Value<String>? completion,
      Value<int>? stepsTotal,
      Value<int>? stepsIndependent,
      Value<int>? hintsUsed,
      Value<int>? score,
      Value<int>? durationSeconds,
      Value<DateTime>? updatedAt}) {
    return StoryNodeProgressCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      adventureId: adventureId ?? this.adventureId,
      nodeId: nodeId ?? this.nodeId,
      completion: completion ?? this.completion,
      stepsTotal: stepsTotal ?? this.stepsTotal,
      stepsIndependent: stepsIndependent ?? this.stepsIndependent,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      score: score ?? this.score,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (adventureId.present) {
      map['adventure_id'] = Variable<String>(adventureId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (completion.present) {
      map['completion'] = Variable<String>(completion.value);
    }
    if (stepsTotal.present) {
      map['steps_total'] = Variable<int>(stepsTotal.value);
    }
    if (stepsIndependent.present) {
      map['steps_independent'] = Variable<int>(stepsIndependent.value);
    }
    if (hintsUsed.present) {
      map['hints_used'] = Variable<int>(hintsUsed.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryNodeProgressCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('adventureId: $adventureId, ')
          ..write('nodeId: $nodeId, ')
          ..write('completion: $completion, ')
          ..write('stepsTotal: $stepsTotal, ')
          ..write('stepsIndependent: $stepsIndependent, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('score: $score, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StoryChapterProgressTable extends StoryChapterProgress
    with TableInfo<$StoryChapterProgressTable, StoryChapterProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryChapterProgressTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _adventureIdMeta =
      const VerificationMeta('adventureId');
  @override
  late final GeneratedColumn<String> adventureId = GeneratedColumn<String>(
      'adventure_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentNodeIdMeta =
      const VerificationMeta('currentNodeId');
  @override
  late final GeneratedColumn<String> currentNodeId = GeneratedColumn<String>(
      'current_node_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isUnlockedMeta =
      const VerificationMeta('isUnlocked');
  @override
  late final GeneratedColumn<bool> isUnlocked = GeneratedColumn<bool>(
      'is_unlocked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_unlocked" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastPlayedAtMeta =
      const VerificationMeta('lastPlayedAt');
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
      'last_played_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _currentBeatMeta =
      const VerificationMeta('currentBeat');
  @override
  late final GeneratedColumn<String> currentBeat = GeneratedColumn<String>(
      'current_beat', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activityCheckpointMeta =
      const VerificationMeta('activityCheckpoint');
  @override
  late final GeneratedColumn<String> activityCheckpoint =
      GeneratedColumn<String>('activity_checkpoint', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        adventureId,
        currentNodeId,
        isUnlocked,
        isCompleted,
        startedAt,
        completedAt,
        lastPlayedAt,
        currentBeat,
        activityCheckpoint
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_chapter_progress';
  @override
  VerificationContext validateIntegrity(
      Insertable<StoryChapterProgressData> instance,
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
    if (data.containsKey('adventure_id')) {
      context.handle(
          _adventureIdMeta,
          adventureId.isAcceptableOrUnknown(
              data['adventure_id']!, _adventureIdMeta));
    } else if (isInserting) {
      context.missing(_adventureIdMeta);
    }
    if (data.containsKey('current_node_id')) {
      context.handle(
          _currentNodeIdMeta,
          currentNodeId.isAcceptableOrUnknown(
              data['current_node_id']!, _currentNodeIdMeta));
    }
    if (data.containsKey('is_unlocked')) {
      context.handle(
          _isUnlockedMeta,
          isUnlocked.isAcceptableOrUnknown(
              data['is_unlocked']!, _isUnlockedMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
          _lastPlayedAtMeta,
          lastPlayedAt.isAcceptableOrUnknown(
              data['last_played_at']!, _lastPlayedAtMeta));
    }
    if (data.containsKey('current_beat')) {
      context.handle(
          _currentBeatMeta,
          currentBeat.isAcceptableOrUnknown(
              data['current_beat']!, _currentBeatMeta));
    }
    if (data.containsKey('activity_checkpoint')) {
      context.handle(
          _activityCheckpointMeta,
          activityCheckpoint.isAcceptableOrUnknown(
              data['activity_checkpoint']!, _activityCheckpointMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {profileId, adventureId},
      ];
  @override
  StoryChapterProgressData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryChapterProgressData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id'])!,
      adventureId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}adventure_id'])!,
      currentNodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}current_node_id']),
      isUnlocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_unlocked'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      lastPlayedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_played_at'])!,
      currentBeat: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}current_beat']),
      activityCheckpoint: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}activity_checkpoint']),
    );
  }

  @override
  $StoryChapterProgressTable createAlias(String alias) {
    return $StoryChapterProgressTable(attachedDatabase, alias);
  }
}

class StoryChapterProgressData extends DataClass
    implements Insertable<StoryChapterProgressData> {
  final int id;
  final int profileId;
  final String adventureId;

  /// The node to resume at. Null once the Adventure is finished.
  final String? currentNodeId;

  /// Carries a future entitlement check. Nothing reads it as a paywall today;
  /// Adventure boundaries are natural gates by construction, so the hook costs
  /// nothing now and would be expensive to add later.
  final bool isUnlocked;
  final bool isCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;

  /// Drives the "let's continue the story" reminder: a notification is only
  /// worth sending to a child who actually has a story in progress.
  final DateTime lastPlayedAt;

  /// The beat [currentNodeId] belongs to, stored alongside the id rather than
  /// derived from it.
  ///
  /// It is the drift handle. A node id is a content identifier, and content
  /// gets renamed, reordered and rewritten between releases; when the id a
  /// child was parked on no longer exists, the beat is enough to put them back
  /// in the right part of the story instead of at its first line.
  final String? currentBeat;

  /// The in-flight activity, as versioned JSON, or null when the child is on a
  /// narration beat or has finished the activity they were on.
  ///
  /// One opaque column rather than nine typed ones, and deliberately so. Its
  /// contents are a *cursor format*, not a schema the database has opinions
  /// about: it carries a version, and a cursor written by an older or newer
  /// build simply fails to parse and the current activity restarts. Spreading
  /// the same fields across nine columns would make every future change to the
  /// cursor a migration, for data whose entire lifetime is "until this child
  /// finishes this mini-game".
  ///
  /// What it holds is **logical** progress — which step, which seed, what has
  /// been earned so far. Never animation frames, drag coordinates or playback
  /// positions: those are how the screen looked, not where the child got to.
  final String? activityCheckpoint;
  const StoryChapterProgressData(
      {required this.id,
      required this.profileId,
      required this.adventureId,
      this.currentNodeId,
      required this.isUnlocked,
      required this.isCompleted,
      required this.startedAt,
      this.completedAt,
      required this.lastPlayedAt,
      this.currentBeat,
      this.activityCheckpoint});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['adventure_id'] = Variable<String>(adventureId);
    if (!nullToAbsent || currentNodeId != null) {
      map['current_node_id'] = Variable<String>(currentNodeId);
    }
    map['is_unlocked'] = Variable<bool>(isUnlocked);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    if (!nullToAbsent || currentBeat != null) {
      map['current_beat'] = Variable<String>(currentBeat);
    }
    if (!nullToAbsent || activityCheckpoint != null) {
      map['activity_checkpoint'] = Variable<String>(activityCheckpoint);
    }
    return map;
  }

  StoryChapterProgressCompanion toCompanion(bool nullToAbsent) {
    return StoryChapterProgressCompanion(
      id: Value(id),
      profileId: Value(profileId),
      adventureId: Value(adventureId),
      currentNodeId: currentNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentNodeId),
      isUnlocked: Value(isUnlocked),
      isCompleted: Value(isCompleted),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      lastPlayedAt: Value(lastPlayedAt),
      currentBeat: currentBeat == null && nullToAbsent
          ? const Value.absent()
          : Value(currentBeat),
      activityCheckpoint: activityCheckpoint == null && nullToAbsent
          ? const Value.absent()
          : Value(activityCheckpoint),
    );
  }

  factory StoryChapterProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryChapterProgressData(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      adventureId: serializer.fromJson<String>(json['adventureId']),
      currentNodeId: serializer.fromJson<String?>(json['currentNodeId']),
      isUnlocked: serializer.fromJson<bool>(json['isUnlocked']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      lastPlayedAt: serializer.fromJson<DateTime>(json['lastPlayedAt']),
      currentBeat: serializer.fromJson<String?>(json['currentBeat']),
      activityCheckpoint:
          serializer.fromJson<String?>(json['activityCheckpoint']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'adventureId': serializer.toJson<String>(adventureId),
      'currentNodeId': serializer.toJson<String?>(currentNodeId),
      'isUnlocked': serializer.toJson<bool>(isUnlocked),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'lastPlayedAt': serializer.toJson<DateTime>(lastPlayedAt),
      'currentBeat': serializer.toJson<String?>(currentBeat),
      'activityCheckpoint': serializer.toJson<String?>(activityCheckpoint),
    };
  }

  StoryChapterProgressData copyWith(
          {int? id,
          int? profileId,
          String? adventureId,
          Value<String?> currentNodeId = const Value.absent(),
          bool? isUnlocked,
          bool? isCompleted,
          DateTime? startedAt,
          Value<DateTime?> completedAt = const Value.absent(),
          DateTime? lastPlayedAt,
          Value<String?> currentBeat = const Value.absent(),
          Value<String?> activityCheckpoint = const Value.absent()}) =>
      StoryChapterProgressData(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        adventureId: adventureId ?? this.adventureId,
        currentNodeId:
            currentNodeId.present ? currentNodeId.value : this.currentNodeId,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        isCompleted: isCompleted ?? this.isCompleted,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
        currentBeat: currentBeat.present ? currentBeat.value : this.currentBeat,
        activityCheckpoint: activityCheckpoint.present
            ? activityCheckpoint.value
            : this.activityCheckpoint,
      );
  StoryChapterProgressData copyWithCompanion(
      StoryChapterProgressCompanion data) {
    return StoryChapterProgressData(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      adventureId:
          data.adventureId.present ? data.adventureId.value : this.adventureId,
      currentNodeId: data.currentNodeId.present
          ? data.currentNodeId.value
          : this.currentNodeId,
      isUnlocked:
          data.isUnlocked.present ? data.isUnlocked.value : this.isUnlocked,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      currentBeat:
          data.currentBeat.present ? data.currentBeat.value : this.currentBeat,
      activityCheckpoint: data.activityCheckpoint.present
          ? data.activityCheckpoint.value
          : this.activityCheckpoint,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryChapterProgressData(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('adventureId: $adventureId, ')
          ..write('currentNodeId: $currentNodeId, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('currentBeat: $currentBeat, ')
          ..write('activityCheckpoint: $activityCheckpoint')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profileId,
      adventureId,
      currentNodeId,
      isUnlocked,
      isCompleted,
      startedAt,
      completedAt,
      lastPlayedAt,
      currentBeat,
      activityCheckpoint);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryChapterProgressData &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.adventureId == this.adventureId &&
          other.currentNodeId == this.currentNodeId &&
          other.isUnlocked == this.isUnlocked &&
          other.isCompleted == this.isCompleted &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.currentBeat == this.currentBeat &&
          other.activityCheckpoint == this.activityCheckpoint);
}

class StoryChapterProgressCompanion
    extends UpdateCompanion<StoryChapterProgressData> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> adventureId;
  final Value<String?> currentNodeId;
  final Value<bool> isUnlocked;
  final Value<bool> isCompleted;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime> lastPlayedAt;
  final Value<String?> currentBeat;
  final Value<String?> activityCheckpoint;
  const StoryChapterProgressCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.adventureId = const Value.absent(),
    this.currentNodeId = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.currentBeat = const Value.absent(),
    this.activityCheckpoint = const Value.absent(),
  });
  StoryChapterProgressCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String adventureId,
    this.currentNodeId = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.currentBeat = const Value.absent(),
    this.activityCheckpoint = const Value.absent(),
  })  : profileId = Value(profileId),
        adventureId = Value(adventureId);
  static Insertable<StoryChapterProgressData> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? adventureId,
    Expression<String>? currentNodeId,
    Expression<bool>? isUnlocked,
    Expression<bool>? isCompleted,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? lastPlayedAt,
    Expression<String>? currentBeat,
    Expression<String>? activityCheckpoint,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (adventureId != null) 'adventure_id': adventureId,
      if (currentNodeId != null) 'current_node_id': currentNodeId,
      if (isUnlocked != null) 'is_unlocked': isUnlocked,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (currentBeat != null) 'current_beat': currentBeat,
      if (activityCheckpoint != null) 'activity_checkpoint': activityCheckpoint,
    });
  }

  StoryChapterProgressCompanion copyWith(
      {Value<int>? id,
      Value<int>? profileId,
      Value<String>? adventureId,
      Value<String?>? currentNodeId,
      Value<bool>? isUnlocked,
      Value<bool>? isCompleted,
      Value<DateTime>? startedAt,
      Value<DateTime?>? completedAt,
      Value<DateTime>? lastPlayedAt,
      Value<String?>? currentBeat,
      Value<String?>? activityCheckpoint}) {
    return StoryChapterProgressCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      adventureId: adventureId ?? this.adventureId,
      currentNodeId: currentNodeId ?? this.currentNodeId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      currentBeat: currentBeat ?? this.currentBeat,
      activityCheckpoint: activityCheckpoint ?? this.activityCheckpoint,
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
    if (adventureId.present) {
      map['adventure_id'] = Variable<String>(adventureId.value);
    }
    if (currentNodeId.present) {
      map['current_node_id'] = Variable<String>(currentNodeId.value);
    }
    if (isUnlocked.present) {
      map['is_unlocked'] = Variable<bool>(isUnlocked.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (currentBeat.present) {
      map['current_beat'] = Variable<String>(currentBeat.value);
    }
    if (activityCheckpoint.present) {
      map['activity_checkpoint'] = Variable<String>(activityCheckpoint.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryChapterProgressCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('adventureId: $adventureId, ')
          ..write('currentNodeId: $currentNodeId, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('currentBeat: $currentBeat, ')
          ..write('activityCheckpoint: $activityCheckpoint')
          ..write(')'))
        .toString();
  }
}

class $StoryRewardsTable extends StoryRewards
    with TableInfo<$StoryRewardsTable, StoryReward> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryRewardsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _rewardIdMeta =
      const VerificationMeta('rewardId');
  @override
  late final GeneratedColumn<String> rewardId = GeneratedColumn<String>(
      'reward_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _adventureIdMeta =
      const VerificationMeta('adventureId');
  @override
  late final GeneratedColumn<String> adventureId = GeneratedColumn<String>(
      'adventure_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _earnedAtMeta =
      const VerificationMeta('earnedAt');
  @override
  late final GeneratedColumn<DateTime> earnedAt = GeneratedColumn<DateTime>(
      'earned_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, profileId, rewardId, adventureId, earnedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_rewards';
  @override
  VerificationContext validateIntegrity(Insertable<StoryReward> instance,
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
    if (data.containsKey('reward_id')) {
      context.handle(_rewardIdMeta,
          rewardId.isAcceptableOrUnknown(data['reward_id']!, _rewardIdMeta));
    } else if (isInserting) {
      context.missing(_rewardIdMeta);
    }
    if (data.containsKey('adventure_id')) {
      context.handle(
          _adventureIdMeta,
          adventureId.isAcceptableOrUnknown(
              data['adventure_id']!, _adventureIdMeta));
    } else if (isInserting) {
      context.missing(_adventureIdMeta);
    }
    if (data.containsKey('earned_at')) {
      context.handle(_earnedAtMeta,
          earnedAt.isAcceptableOrUnknown(data['earned_at']!, _earnedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {profileId, rewardId},
      ];
  @override
  StoryReward map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryReward(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id'])!,
      rewardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reward_id'])!,
      adventureId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}adventure_id'])!,
      earnedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}earned_at'])!,
    );
  }

  @override
  $StoryRewardsTable createAlias(String alias) {
    return $StoryRewardsTable(attachedDatabase, alias);
  }
}

class StoryReward extends DataClass implements Insertable<StoryReward> {
  final int id;
  final int profileId;
  final String rewardId;
  final String adventureId;
  final DateTime earnedAt;
  const StoryReward(
      {required this.id,
      required this.profileId,
      required this.rewardId,
      required this.adventureId,
      required this.earnedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['reward_id'] = Variable<String>(rewardId);
    map['adventure_id'] = Variable<String>(adventureId);
    map['earned_at'] = Variable<DateTime>(earnedAt);
    return map;
  }

  StoryRewardsCompanion toCompanion(bool nullToAbsent) {
    return StoryRewardsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      rewardId: Value(rewardId),
      adventureId: Value(adventureId),
      earnedAt: Value(earnedAt),
    );
  }

  factory StoryReward.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryReward(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      rewardId: serializer.fromJson<String>(json['rewardId']),
      adventureId: serializer.fromJson<String>(json['adventureId']),
      earnedAt: serializer.fromJson<DateTime>(json['earnedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'rewardId': serializer.toJson<String>(rewardId),
      'adventureId': serializer.toJson<String>(adventureId),
      'earnedAt': serializer.toJson<DateTime>(earnedAt),
    };
  }

  StoryReward copyWith(
          {int? id,
          int? profileId,
          String? rewardId,
          String? adventureId,
          DateTime? earnedAt}) =>
      StoryReward(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        rewardId: rewardId ?? this.rewardId,
        adventureId: adventureId ?? this.adventureId,
        earnedAt: earnedAt ?? this.earnedAt,
      );
  StoryReward copyWithCompanion(StoryRewardsCompanion data) {
    return StoryReward(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      rewardId: data.rewardId.present ? data.rewardId.value : this.rewardId,
      adventureId:
          data.adventureId.present ? data.adventureId.value : this.adventureId,
      earnedAt: data.earnedAt.present ? data.earnedAt.value : this.earnedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryReward(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('rewardId: $rewardId, ')
          ..write('adventureId: $adventureId, ')
          ..write('earnedAt: $earnedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, rewardId, adventureId, earnedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryReward &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.rewardId == this.rewardId &&
          other.adventureId == this.adventureId &&
          other.earnedAt == this.earnedAt);
}

class StoryRewardsCompanion extends UpdateCompanion<StoryReward> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> rewardId;
  final Value<String> adventureId;
  final Value<DateTime> earnedAt;
  const StoryRewardsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rewardId = const Value.absent(),
    this.adventureId = const Value.absent(),
    this.earnedAt = const Value.absent(),
  });
  StoryRewardsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String rewardId,
    required String adventureId,
    this.earnedAt = const Value.absent(),
  })  : profileId = Value(profileId),
        rewardId = Value(rewardId),
        adventureId = Value(adventureId);
  static Insertable<StoryReward> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? rewardId,
    Expression<String>? adventureId,
    Expression<DateTime>? earnedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (rewardId != null) 'reward_id': rewardId,
      if (adventureId != null) 'adventure_id': adventureId,
      if (earnedAt != null) 'earned_at': earnedAt,
    });
  }

  StoryRewardsCompanion copyWith(
      {Value<int>? id,
      Value<int>? profileId,
      Value<String>? rewardId,
      Value<String>? adventureId,
      Value<DateTime>? earnedAt}) {
    return StoryRewardsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      rewardId: rewardId ?? this.rewardId,
      adventureId: adventureId ?? this.adventureId,
      earnedAt: earnedAt ?? this.earnedAt,
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
    if (rewardId.present) {
      map['reward_id'] = Variable<String>(rewardId.value);
    }
    if (adventureId.present) {
      map['adventure_id'] = Variable<String>(adventureId.value);
    }
    if (earnedAt.present) {
      map['earned_at'] = Variable<DateTime>(earnedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryRewardsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('rewardId: $rewardId, ')
          ..write('adventureId: $adventureId, ')
          ..write('earnedAt: $earnedAt')
          ..write(')'))
        .toString();
  }
}

class $ActivityAttemptLogsTable extends ActivityAttemptLogs
    with TableInfo<$ActivityAttemptLogsTable, ActivityAttemptLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityAttemptLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _activityIdMeta =
      const VerificationMeta('activityId');
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
      'activity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storyNodeIdMeta =
      const VerificationMeta('storyNodeId');
  @override
  late final GeneratedColumn<String> storyNodeId = GeneratedColumn<String>(
      'story_node_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stepIndexMeta =
      const VerificationMeta('stepIndex');
  @override
  late final GeneratedColumn<int> stepIndex = GeneratedColumn<int>(
      'step_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _attemptIndexMeta =
      const VerificationMeta('attemptIndex');
  @override
  late final GeneratedColumn<int> attemptIndex = GeneratedColumn<int>(
      'attempt_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _outcomeMeta =
      const VerificationMeta('outcome');
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
      'outcome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scaffoldLevelMeta =
      const VerificationMeta('scaffoldLevel');
  @override
  late final GeneratedColumn<String> scaffoldLevel = GeneratedColumn<String>(
      'scaffold_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _elapsedMillisecondsMeta =
      const VerificationMeta('elapsedMilliseconds');
  @override
  late final GeneratedColumn<int> elapsedMilliseconds = GeneratedColumn<int>(
      'elapsed_milliseconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        activityId,
        storyNodeId,
        stepIndex,
        attemptIndex,
        outcome,
        scaffoldLevel,
        elapsedMilliseconds,
        recordedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_attempt_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ActivityAttemptLog> instance,
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
    if (data.containsKey('activity_id')) {
      context.handle(
          _activityIdMeta,
          activityId.isAcceptableOrUnknown(
              data['activity_id']!, _activityIdMeta));
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('story_node_id')) {
      context.handle(
          _storyNodeIdMeta,
          storyNodeId.isAcceptableOrUnknown(
              data['story_node_id']!, _storyNodeIdMeta));
    }
    if (data.containsKey('step_index')) {
      context.handle(_stepIndexMeta,
          stepIndex.isAcceptableOrUnknown(data['step_index']!, _stepIndexMeta));
    } else if (isInserting) {
      context.missing(_stepIndexMeta);
    }
    if (data.containsKey('attempt_index')) {
      context.handle(
          _attemptIndexMeta,
          attemptIndex.isAcceptableOrUnknown(
              data['attempt_index']!, _attemptIndexMeta));
    } else if (isInserting) {
      context.missing(_attemptIndexMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(_outcomeMeta,
          outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta));
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('scaffold_level')) {
      context.handle(
          _scaffoldLevelMeta,
          scaffoldLevel.isAcceptableOrUnknown(
              data['scaffold_level']!, _scaffoldLevelMeta));
    } else if (isInserting) {
      context.missing(_scaffoldLevelMeta);
    }
    if (data.containsKey('elapsed_milliseconds')) {
      context.handle(
          _elapsedMillisecondsMeta,
          elapsedMilliseconds.isAcceptableOrUnknown(
              data['elapsed_milliseconds']!, _elapsedMillisecondsMeta));
    } else if (isInserting) {
      context.missing(_elapsedMillisecondsMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityAttemptLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityAttemptLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id'])!,
      activityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_id'])!,
      storyNodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}story_node_id']),
      stepIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}step_index'])!,
      attemptIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_index'])!,
      outcome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}outcome'])!,
      scaffoldLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scaffold_level'])!,
      elapsedMilliseconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}elapsed_milliseconds'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
    );
  }

  @override
  $ActivityAttemptLogsTable createAlias(String alias) {
    return $ActivityAttemptLogsTable(attachedDatabase, alias);
  }
}

class ActivityAttemptLog extends DataClass
    implements Insertable<ActivityAttemptLog> {
  final int id;
  final int profileId;
  final String activityId;
  final String? storyNodeId;
  final int stepIndex;
  final int attemptIndex;
  final String outcome;
  final String scaffoldLevel;
  final int elapsedMilliseconds;
  final DateTime recordedAt;
  const ActivityAttemptLog(
      {required this.id,
      required this.profileId,
      required this.activityId,
      this.storyNodeId,
      required this.stepIndex,
      required this.attemptIndex,
      required this.outcome,
      required this.scaffoldLevel,
      required this.elapsedMilliseconds,
      required this.recordedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['activity_id'] = Variable<String>(activityId);
    if (!nullToAbsent || storyNodeId != null) {
      map['story_node_id'] = Variable<String>(storyNodeId);
    }
    map['step_index'] = Variable<int>(stepIndex);
    map['attempt_index'] = Variable<int>(attemptIndex);
    map['outcome'] = Variable<String>(outcome);
    map['scaffold_level'] = Variable<String>(scaffoldLevel);
    map['elapsed_milliseconds'] = Variable<int>(elapsedMilliseconds);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  ActivityAttemptLogsCompanion toCompanion(bool nullToAbsent) {
    return ActivityAttemptLogsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      activityId: Value(activityId),
      storyNodeId: storyNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storyNodeId),
      stepIndex: Value(stepIndex),
      attemptIndex: Value(attemptIndex),
      outcome: Value(outcome),
      scaffoldLevel: Value(scaffoldLevel),
      elapsedMilliseconds: Value(elapsedMilliseconds),
      recordedAt: Value(recordedAt),
    );
  }

  factory ActivityAttemptLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityAttemptLog(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      activityId: serializer.fromJson<String>(json['activityId']),
      storyNodeId: serializer.fromJson<String?>(json['storyNodeId']),
      stepIndex: serializer.fromJson<int>(json['stepIndex']),
      attemptIndex: serializer.fromJson<int>(json['attemptIndex']),
      outcome: serializer.fromJson<String>(json['outcome']),
      scaffoldLevel: serializer.fromJson<String>(json['scaffoldLevel']),
      elapsedMilliseconds:
          serializer.fromJson<int>(json['elapsedMilliseconds']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'activityId': serializer.toJson<String>(activityId),
      'storyNodeId': serializer.toJson<String?>(storyNodeId),
      'stepIndex': serializer.toJson<int>(stepIndex),
      'attemptIndex': serializer.toJson<int>(attemptIndex),
      'outcome': serializer.toJson<String>(outcome),
      'scaffoldLevel': serializer.toJson<String>(scaffoldLevel),
      'elapsedMilliseconds': serializer.toJson<int>(elapsedMilliseconds),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  ActivityAttemptLog copyWith(
          {int? id,
          int? profileId,
          String? activityId,
          Value<String?> storyNodeId = const Value.absent(),
          int? stepIndex,
          int? attemptIndex,
          String? outcome,
          String? scaffoldLevel,
          int? elapsedMilliseconds,
          DateTime? recordedAt}) =>
      ActivityAttemptLog(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        activityId: activityId ?? this.activityId,
        storyNodeId: storyNodeId.present ? storyNodeId.value : this.storyNodeId,
        stepIndex: stepIndex ?? this.stepIndex,
        attemptIndex: attemptIndex ?? this.attemptIndex,
        outcome: outcome ?? this.outcome,
        scaffoldLevel: scaffoldLevel ?? this.scaffoldLevel,
        elapsedMilliseconds: elapsedMilliseconds ?? this.elapsedMilliseconds,
        recordedAt: recordedAt ?? this.recordedAt,
      );
  ActivityAttemptLog copyWithCompanion(ActivityAttemptLogsCompanion data) {
    return ActivityAttemptLog(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      activityId:
          data.activityId.present ? data.activityId.value : this.activityId,
      storyNodeId:
          data.storyNodeId.present ? data.storyNodeId.value : this.storyNodeId,
      stepIndex: data.stepIndex.present ? data.stepIndex.value : this.stepIndex,
      attemptIndex: data.attemptIndex.present
          ? data.attemptIndex.value
          : this.attemptIndex,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      scaffoldLevel: data.scaffoldLevel.present
          ? data.scaffoldLevel.value
          : this.scaffoldLevel,
      elapsedMilliseconds: data.elapsedMilliseconds.present
          ? data.elapsedMilliseconds.value
          : this.elapsedMilliseconds,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityAttemptLog(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('activityId: $activityId, ')
          ..write('storyNodeId: $storyNodeId, ')
          ..write('stepIndex: $stepIndex, ')
          ..write('attemptIndex: $attemptIndex, ')
          ..write('outcome: $outcome, ')
          ..write('scaffoldLevel: $scaffoldLevel, ')
          ..write('elapsedMilliseconds: $elapsedMilliseconds, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profileId,
      activityId,
      storyNodeId,
      stepIndex,
      attemptIndex,
      outcome,
      scaffoldLevel,
      elapsedMilliseconds,
      recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityAttemptLog &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.activityId == this.activityId &&
          other.storyNodeId == this.storyNodeId &&
          other.stepIndex == this.stepIndex &&
          other.attemptIndex == this.attemptIndex &&
          other.outcome == this.outcome &&
          other.scaffoldLevel == this.scaffoldLevel &&
          other.elapsedMilliseconds == this.elapsedMilliseconds &&
          other.recordedAt == this.recordedAt);
}

class ActivityAttemptLogsCompanion extends UpdateCompanion<ActivityAttemptLog> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> activityId;
  final Value<String?> storyNodeId;
  final Value<int> stepIndex;
  final Value<int> attemptIndex;
  final Value<String> outcome;
  final Value<String> scaffoldLevel;
  final Value<int> elapsedMilliseconds;
  final Value<DateTime> recordedAt;
  const ActivityAttemptLogsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.storyNodeId = const Value.absent(),
    this.stepIndex = const Value.absent(),
    this.attemptIndex = const Value.absent(),
    this.outcome = const Value.absent(),
    this.scaffoldLevel = const Value.absent(),
    this.elapsedMilliseconds = const Value.absent(),
    this.recordedAt = const Value.absent(),
  });
  ActivityAttemptLogsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String activityId,
    this.storyNodeId = const Value.absent(),
    required int stepIndex,
    required int attemptIndex,
    required String outcome,
    required String scaffoldLevel,
    required int elapsedMilliseconds,
    this.recordedAt = const Value.absent(),
  })  : profileId = Value(profileId),
        activityId = Value(activityId),
        stepIndex = Value(stepIndex),
        attemptIndex = Value(attemptIndex),
        outcome = Value(outcome),
        scaffoldLevel = Value(scaffoldLevel),
        elapsedMilliseconds = Value(elapsedMilliseconds);
  static Insertable<ActivityAttemptLog> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? activityId,
    Expression<String>? storyNodeId,
    Expression<int>? stepIndex,
    Expression<int>? attemptIndex,
    Expression<String>? outcome,
    Expression<String>? scaffoldLevel,
    Expression<int>? elapsedMilliseconds,
    Expression<DateTime>? recordedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (activityId != null) 'activity_id': activityId,
      if (storyNodeId != null) 'story_node_id': storyNodeId,
      if (stepIndex != null) 'step_index': stepIndex,
      if (attemptIndex != null) 'attempt_index': attemptIndex,
      if (outcome != null) 'outcome': outcome,
      if (scaffoldLevel != null) 'scaffold_level': scaffoldLevel,
      if (elapsedMilliseconds != null)
        'elapsed_milliseconds': elapsedMilliseconds,
      if (recordedAt != null) 'recorded_at': recordedAt,
    });
  }

  ActivityAttemptLogsCompanion copyWith(
      {Value<int>? id,
      Value<int>? profileId,
      Value<String>? activityId,
      Value<String?>? storyNodeId,
      Value<int>? stepIndex,
      Value<int>? attemptIndex,
      Value<String>? outcome,
      Value<String>? scaffoldLevel,
      Value<int>? elapsedMilliseconds,
      Value<DateTime>? recordedAt}) {
    return ActivityAttemptLogsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      activityId: activityId ?? this.activityId,
      storyNodeId: storyNodeId ?? this.storyNodeId,
      stepIndex: stepIndex ?? this.stepIndex,
      attemptIndex: attemptIndex ?? this.attemptIndex,
      outcome: outcome ?? this.outcome,
      scaffoldLevel: scaffoldLevel ?? this.scaffoldLevel,
      elapsedMilliseconds: elapsedMilliseconds ?? this.elapsedMilliseconds,
      recordedAt: recordedAt ?? this.recordedAt,
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
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (storyNodeId.present) {
      map['story_node_id'] = Variable<String>(storyNodeId.value);
    }
    if (stepIndex.present) {
      map['step_index'] = Variable<int>(stepIndex.value);
    }
    if (attemptIndex.present) {
      map['attempt_index'] = Variable<int>(attemptIndex.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (scaffoldLevel.present) {
      map['scaffold_level'] = Variable<String>(scaffoldLevel.value);
    }
    if (elapsedMilliseconds.present) {
      map['elapsed_milliseconds'] = Variable<int>(elapsedMilliseconds.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityAttemptLogsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('activityId: $activityId, ')
          ..write('storyNodeId: $storyNodeId, ')
          ..write('stepIndex: $stepIndex, ')
          ..write('attemptIndex: $attemptIndex, ')
          ..write('outcome: $outcome, ')
          ..write('scaffoldLevel: $scaffoldLevel, ')
          ..write('elapsedMilliseconds: $elapsedMilliseconds, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }
}

class $EarnedBadgesTable extends EarnedBadges
    with TableInfo<$EarnedBadgesTable, EarnedBadge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EarnedBadgesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _badgeIdMeta =
      const VerificationMeta('badgeId');
  @override
  late final GeneratedColumn<String> badgeId = GeneratedColumn<String>(
      'badge_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _earnedAtMeta =
      const VerificationMeta('earnedAt');
  @override
  late final GeneratedColumn<DateTime> earnedAt = GeneratedColumn<DateTime>(
      'earned_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, profileId, badgeId, earnedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'earned_badges';
  @override
  VerificationContext validateIntegrity(Insertable<EarnedBadge> instance,
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
    if (data.containsKey('badge_id')) {
      context.handle(_badgeIdMeta,
          badgeId.isAcceptableOrUnknown(data['badge_id']!, _badgeIdMeta));
    } else if (isInserting) {
      context.missing(_badgeIdMeta);
    }
    if (data.containsKey('earned_at')) {
      context.handle(_earnedAtMeta,
          earnedAt.isAcceptableOrUnknown(data['earned_at']!, _earnedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {profileId, badgeId},
      ];
  @override
  EarnedBadge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EarnedBadge(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id'])!,
      badgeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}badge_id'])!,
      earnedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}earned_at'])!,
    );
  }

  @override
  $EarnedBadgesTable createAlias(String alias) {
    return $EarnedBadgesTable(attachedDatabase, alias);
  }
}

class EarnedBadge extends DataClass implements Insertable<EarnedBadge> {
  final int id;
  final int profileId;
  final String badgeId;
  final DateTime earnedAt;
  const EarnedBadge(
      {required this.id,
      required this.profileId,
      required this.badgeId,
      required this.earnedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['badge_id'] = Variable<String>(badgeId);
    map['earned_at'] = Variable<DateTime>(earnedAt);
    return map;
  }

  EarnedBadgesCompanion toCompanion(bool nullToAbsent) {
    return EarnedBadgesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      badgeId: Value(badgeId),
      earnedAt: Value(earnedAt),
    );
  }

  factory EarnedBadge.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EarnedBadge(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      badgeId: serializer.fromJson<String>(json['badgeId']),
      earnedAt: serializer.fromJson<DateTime>(json['earnedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'badgeId': serializer.toJson<String>(badgeId),
      'earnedAt': serializer.toJson<DateTime>(earnedAt),
    };
  }

  EarnedBadge copyWith(
          {int? id, int? profileId, String? badgeId, DateTime? earnedAt}) =>
      EarnedBadge(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        badgeId: badgeId ?? this.badgeId,
        earnedAt: earnedAt ?? this.earnedAt,
      );
  EarnedBadge copyWithCompanion(EarnedBadgesCompanion data) {
    return EarnedBadge(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      badgeId: data.badgeId.present ? data.badgeId.value : this.badgeId,
      earnedAt: data.earnedAt.present ? data.earnedAt.value : this.earnedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EarnedBadge(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('badgeId: $badgeId, ')
          ..write('earnedAt: $earnedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, badgeId, earnedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EarnedBadge &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.badgeId == this.badgeId &&
          other.earnedAt == this.earnedAt);
}

class EarnedBadgesCompanion extends UpdateCompanion<EarnedBadge> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> badgeId;
  final Value<DateTime> earnedAt;
  const EarnedBadgesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.badgeId = const Value.absent(),
    this.earnedAt = const Value.absent(),
  });
  EarnedBadgesCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String badgeId,
    this.earnedAt = const Value.absent(),
  })  : profileId = Value(profileId),
        badgeId = Value(badgeId);
  static Insertable<EarnedBadge> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? badgeId,
    Expression<DateTime>? earnedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (badgeId != null) 'badge_id': badgeId,
      if (earnedAt != null) 'earned_at': earnedAt,
    });
  }

  EarnedBadgesCompanion copyWith(
      {Value<int>? id,
      Value<int>? profileId,
      Value<String>? badgeId,
      Value<DateTime>? earnedAt}) {
    return EarnedBadgesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      badgeId: badgeId ?? this.badgeId,
      earnedAt: earnedAt ?? this.earnedAt,
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
    if (badgeId.present) {
      map['badge_id'] = Variable<String>(badgeId.value);
    }
    if (earnedAt.present) {
      map['earned_at'] = Variable<DateTime>(earnedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EarnedBadgesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('badgeId: $badgeId, ')
          ..write('earnedAt: $earnedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $GameScoresTable gameScores = $GameScoresTable(this);
  late final $StoryNodeProgressTable storyNodeProgress =
      $StoryNodeProgressTable(this);
  late final $StoryChapterProgressTable storyChapterProgress =
      $StoryChapterProgressTable(this);
  late final $StoryRewardsTable storyRewards = $StoryRewardsTable(this);
  late final $ActivityAttemptLogsTable activityAttemptLogs =
      $ActivityAttemptLogsTable(this);
  late final $EarnedBadgesTable earnedBadges = $EarnedBadgesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        profiles,
        gameScores,
        storyNodeProgress,
        storyChapterProgress,
        storyRewards,
        activityAttemptLogs,
        earnedBadges
      ];
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

  static MultiTypedResultKey<$StoryNodeProgressTable,
      List<StoryNodeProgressData>> _storyNodeProgressRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.storyNodeProgress,
          aliasName: 'profiles__id__story_node_progress__profile_id');

  $$StoryNodeProgressTableProcessedTableManager get storyNodeProgressRefs {
    final manager =
        $$StoryNodeProgressTableTableManager($_db, $_db.storyNodeProgress)
            .filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_storyNodeProgressRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StoryChapterProgressTable,
      List<StoryChapterProgressData>> _storyChapterProgressRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.storyChapterProgress,
          aliasName: 'profiles__id__story_chapter_progress__profile_id');

  $$StoryChapterProgressTableProcessedTableManager
      get storyChapterProgressRefs {
    final manager =
        $$StoryChapterProgressTableTableManager($_db, $_db.storyChapterProgress)
            .filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_storyChapterProgressRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StoryRewardsTable, List<StoryReward>>
      _storyRewardsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.storyRewards,
              aliasName: 'profiles__id__story_rewards__profile_id');

  $$StoryRewardsTableProcessedTableManager get storyRewardsRefs {
    final manager = $$StoryRewardsTableTableManager($_db, $_db.storyRewards)
        .filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_storyRewardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ActivityAttemptLogsTable,
      List<ActivityAttemptLog>> _activityAttemptLogsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.activityAttemptLogs,
          aliasName: 'profiles__id__activity_attempt_logs__profile_id');

  $$ActivityAttemptLogsTableProcessedTableManager get activityAttemptLogsRefs {
    final manager =
        $$ActivityAttemptLogsTableTableManager($_db, $_db.activityAttemptLogs)
            .filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_activityAttemptLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EarnedBadgesTable, List<EarnedBadge>>
      _earnedBadgesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.earnedBadges,
              aliasName: 'profiles__id__earned_badges__profile_id');

  $$EarnedBadgesTableProcessedTableManager get earnedBadgesRefs {
    final manager = $$EarnedBadgesTableTableManager($_db, $_db.earnedBadges)
        .filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_earnedBadgesRefsTable($_db));
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

  Expression<bool> storyNodeProgressRefs(
      Expression<bool> Function($$StoryNodeProgressTableFilterComposer f) f) {
    final $$StoryNodeProgressTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.storyNodeProgress,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoryNodeProgressTableFilterComposer(
              $db: $db,
              $table: $db.storyNodeProgress,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> storyChapterProgressRefs(
      Expression<bool> Function($$StoryChapterProgressTableFilterComposer f)
          f) {
    final $$StoryChapterProgressTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.storyChapterProgress,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoryChapterProgressTableFilterComposer(
              $db: $db,
              $table: $db.storyChapterProgress,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> storyRewardsRefs(
      Expression<bool> Function($$StoryRewardsTableFilterComposer f) f) {
    final $$StoryRewardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.storyRewards,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoryRewardsTableFilterComposer(
              $db: $db,
              $table: $db.storyRewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> activityAttemptLogsRefs(
      Expression<bool> Function($$ActivityAttemptLogsTableFilterComposer f) f) {
    final $$ActivityAttemptLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.activityAttemptLogs,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActivityAttemptLogsTableFilterComposer(
              $db: $db,
              $table: $db.activityAttemptLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> earnedBadgesRefs(
      Expression<bool> Function($$EarnedBadgesTableFilterComposer f) f) {
    final $$EarnedBadgesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.earnedBadges,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EarnedBadgesTableFilterComposer(
              $db: $db,
              $table: $db.earnedBadges,
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

  Expression<T> storyNodeProgressRefs<T extends Object>(
      Expression<T> Function($$StoryNodeProgressTableAnnotationComposer a) f) {
    final $$StoryNodeProgressTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.storyNodeProgress,
            getReferencedColumn: (t) => t.profileId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$StoryNodeProgressTableAnnotationComposer(
                  $db: $db,
                  $table: $db.storyNodeProgress,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> storyChapterProgressRefs<T extends Object>(
      Expression<T> Function($$StoryChapterProgressTableAnnotationComposer a)
          f) {
    final $$StoryChapterProgressTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.storyChapterProgress,
            getReferencedColumn: (t) => t.profileId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$StoryChapterProgressTableAnnotationComposer(
                  $db: $db,
                  $table: $db.storyChapterProgress,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> storyRewardsRefs<T extends Object>(
      Expression<T> Function($$StoryRewardsTableAnnotationComposer a) f) {
    final $$StoryRewardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.storyRewards,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoryRewardsTableAnnotationComposer(
              $db: $db,
              $table: $db.storyRewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> activityAttemptLogsRefs<T extends Object>(
      Expression<T> Function($$ActivityAttemptLogsTableAnnotationComposer a)
          f) {
    final $$ActivityAttemptLogsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.activityAttemptLogs,
            getReferencedColumn: (t) => t.profileId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ActivityAttemptLogsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.activityAttemptLogs,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> earnedBadgesRefs<T extends Object>(
      Expression<T> Function($$EarnedBadgesTableAnnotationComposer a) f) {
    final $$EarnedBadgesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.earnedBadges,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EarnedBadgesTableAnnotationComposer(
              $db: $db,
              $table: $db.earnedBadges,
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
    PrefetchHooks Function(
        {bool gameScoresRefs,
        bool storyNodeProgressRefs,
        bool storyChapterProgressRefs,
        bool storyRewardsRefs,
        bool activityAttemptLogsRefs,
        bool earnedBadgesRefs})> {
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
          prefetchHooksCallback: (
              {gameScoresRefs = false,
              storyNodeProgressRefs = false,
              storyChapterProgressRefs = false,
              storyRewardsRefs = false,
              activityAttemptLogsRefs = false,
              earnedBadgesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (gameScoresRefs) db.gameScores,
                if (storyNodeProgressRefs) db.storyNodeProgress,
                if (storyChapterProgressRefs) db.storyChapterProgress,
                if (storyRewardsRefs) db.storyRewards,
                if (activityAttemptLogsRefs) db.activityAttemptLogs,
                if (earnedBadgesRefs) db.earnedBadges
              ],
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
                        typedResults: items),
                  if (storyNodeProgressRefs)
                    await $_getPrefetchedData<Profile, $ProfilesTable,
                            StoryNodeProgressData>(
                        currentTable: table,
                        referencedTable: $$ProfilesTableReferences
                            ._storyNodeProgressRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProfilesTableReferences(db, table, p0)
                                .storyNodeProgressRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.profileId == item.id),
                        typedResults: items),
                  if (storyChapterProgressRefs)
                    await $_getPrefetchedData<Profile, $ProfilesTable, StoryChapterProgressData>(
                        currentTable: table,
                        referencedTable: $$ProfilesTableReferences
                            ._storyChapterProgressRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProfilesTableReferences(db, table, p0)
                                .storyChapterProgressRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.profileId == item.id),
                        typedResults: items),
                  if (storyRewardsRefs)
                    await $_getPrefetchedData<Profile, $ProfilesTable,
                            StoryReward>(
                        currentTable: table,
                        referencedTable: $$ProfilesTableReferences
                            ._storyRewardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProfilesTableReferences(db, table, p0)
                                .storyRewardsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.profileId == item.id),
                        typedResults: items),
                  if (activityAttemptLogsRefs)
                    await $_getPrefetchedData<Profile, $ProfilesTable,
                            ActivityAttemptLog>(
                        currentTable: table,
                        referencedTable: $$ProfilesTableReferences
                            ._activityAttemptLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProfilesTableReferences(db, table, p0)
                                .activityAttemptLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.profileId == item.id),
                        typedResults: items),
                  if (earnedBadgesRefs)
                    await $_getPrefetchedData<Profile, $ProfilesTable,
                            EarnedBadge>(
                        currentTable: table,
                        referencedTable: $$ProfilesTableReferences
                            ._earnedBadgesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProfilesTableReferences(db, table, p0)
                                .earnedBadgesRefs,
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
    PrefetchHooks Function(
        {bool gameScoresRefs,
        bool storyNodeProgressRefs,
        bool storyChapterProgressRefs,
        bool storyRewardsRefs,
        bool activityAttemptLogsRefs,
        bool earnedBadgesRefs})>;
typedef $$GameScoresTableCreateCompanionBuilder = GameScoresCompanion Function({
  Value<int> id,
  required int profileId,
  required String gameKey,
  required int score,
  Value<int?> level,
  Value<DateTime> playedAt,
  Value<int?> maxScore,
  Value<int?> starsEarned,
  Value<int?> durationSeconds,
  Value<String?> storyNodeId,
});
typedef $$GameScoresTableUpdateCompanionBuilder = GameScoresCompanion Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> gameKey,
  Value<int> score,
  Value<int?> level,
  Value<DateTime> playedAt,
  Value<int?> maxScore,
  Value<int?> starsEarned,
  Value<int?> durationSeconds,
  Value<String?> storyNodeId,
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

  ColumnFilters<int> get maxScore => $composableBuilder(
      column: $table.maxScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get starsEarned => $composableBuilder(
      column: $table.starsEarned, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storyNodeId => $composableBuilder(
      column: $table.storyNodeId, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get maxScore => $composableBuilder(
      column: $table.maxScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get starsEarned => $composableBuilder(
      column: $table.starsEarned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storyNodeId => $composableBuilder(
      column: $table.storyNodeId, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get maxScore =>
      $composableBuilder(column: $table.maxScore, builder: (column) => column);

  GeneratedColumn<int> get starsEarned => $composableBuilder(
      column: $table.starsEarned, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<String> get storyNodeId => $composableBuilder(
      column: $table.storyNodeId, builder: (column) => column);

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
            Value<int?> maxScore = const Value.absent(),
            Value<int?> starsEarned = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            Value<String?> storyNodeId = const Value.absent(),
          }) =>
              GameScoresCompanion(
            id: id,
            profileId: profileId,
            gameKey: gameKey,
            score: score,
            level: level,
            playedAt: playedAt,
            maxScore: maxScore,
            starsEarned: starsEarned,
            durationSeconds: durationSeconds,
            storyNodeId: storyNodeId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int profileId,
            required String gameKey,
            required int score,
            Value<int?> level = const Value.absent(),
            Value<DateTime> playedAt = const Value.absent(),
            Value<int?> maxScore = const Value.absent(),
            Value<int?> starsEarned = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            Value<String?> storyNodeId = const Value.absent(),
          }) =>
              GameScoresCompanion.insert(
            id: id,
            profileId: profileId,
            gameKey: gameKey,
            score: score,
            level: level,
            playedAt: playedAt,
            maxScore: maxScore,
            starsEarned: starsEarned,
            durationSeconds: durationSeconds,
            storyNodeId: storyNodeId,
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
typedef $$StoryNodeProgressTableCreateCompanionBuilder
    = StoryNodeProgressCompanion Function({
  Value<int> id,
  required int profileId,
  required String adventureId,
  required String nodeId,
  Value<String> completion,
  Value<int> stepsTotal,
  Value<int> stepsIndependent,
  Value<int> hintsUsed,
  Value<int> score,
  Value<int> durationSeconds,
  Value<DateTime> updatedAt,
});
typedef $$StoryNodeProgressTableUpdateCompanionBuilder
    = StoryNodeProgressCompanion Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> adventureId,
  Value<String> nodeId,
  Value<String> completion,
  Value<int> stepsTotal,
  Value<int> stepsIndependent,
  Value<int> hintsUsed,
  Value<int> score,
  Value<int> durationSeconds,
  Value<DateTime> updatedAt,
});

final class $$StoryNodeProgressTableReferences extends BaseReferences<
    _$AppDatabase, $StoryNodeProgressTable, StoryNodeProgressData> {
  $$StoryNodeProgressTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('story_node_progress__profile_id__profiles__id');

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

class $$StoryNodeProgressTableFilterComposer
    extends Composer<_$AppDatabase, $StoryNodeProgressTable> {
  $$StoryNodeProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get adventureId => $composableBuilder(
      column: $table.adventureId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nodeId => $composableBuilder(
      column: $table.nodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completion => $composableBuilder(
      column: $table.completion, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stepsTotal => $composableBuilder(
      column: $table.stepsTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stepsIndependent => $composableBuilder(
      column: $table.stepsIndependent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hintsUsed => $composableBuilder(
      column: $table.hintsUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

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

class $$StoryNodeProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryNodeProgressTable> {
  $$StoryNodeProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get adventureId => $composableBuilder(
      column: $table.adventureId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nodeId => $composableBuilder(
      column: $table.nodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completion => $composableBuilder(
      column: $table.completion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stepsTotal => $composableBuilder(
      column: $table.stepsTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stepsIndependent => $composableBuilder(
      column: $table.stepsIndependent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hintsUsed => $composableBuilder(
      column: $table.hintsUsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

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

class $$StoryNodeProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryNodeProgressTable> {
  $$StoryNodeProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get adventureId => $composableBuilder(
      column: $table.adventureId, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get completion => $composableBuilder(
      column: $table.completion, builder: (column) => column);

  GeneratedColumn<int> get stepsTotal => $composableBuilder(
      column: $table.stepsTotal, builder: (column) => column);

  GeneratedColumn<int> get stepsIndependent => $composableBuilder(
      column: $table.stepsIndependent, builder: (column) => column);

  GeneratedColumn<int> get hintsUsed =>
      $composableBuilder(column: $table.hintsUsed, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

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

class $$StoryNodeProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoryNodeProgressTable,
    StoryNodeProgressData,
    $$StoryNodeProgressTableFilterComposer,
    $$StoryNodeProgressTableOrderingComposer,
    $$StoryNodeProgressTableAnnotationComposer,
    $$StoryNodeProgressTableCreateCompanionBuilder,
    $$StoryNodeProgressTableUpdateCompanionBuilder,
    (StoryNodeProgressData, $$StoryNodeProgressTableReferences),
    StoryNodeProgressData,
    PrefetchHooks Function({bool profileId})> {
  $$StoryNodeProgressTableTableManager(
      _$AppDatabase db, $StoryNodeProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryNodeProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryNodeProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryNodeProgressTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> profileId = const Value.absent(),
            Value<String> adventureId = const Value.absent(),
            Value<String> nodeId = const Value.absent(),
            Value<String> completion = const Value.absent(),
            Value<int> stepsTotal = const Value.absent(),
            Value<int> stepsIndependent = const Value.absent(),
            Value<int> hintsUsed = const Value.absent(),
            Value<int> score = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              StoryNodeProgressCompanion(
            id: id,
            profileId: profileId,
            adventureId: adventureId,
            nodeId: nodeId,
            completion: completion,
            stepsTotal: stepsTotal,
            stepsIndependent: stepsIndependent,
            hintsUsed: hintsUsed,
            score: score,
            durationSeconds: durationSeconds,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int profileId,
            required String adventureId,
            required String nodeId,
            Value<String> completion = const Value.absent(),
            Value<int> stepsTotal = const Value.absent(),
            Value<int> stepsIndependent = const Value.absent(),
            Value<int> hintsUsed = const Value.absent(),
            Value<int> score = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              StoryNodeProgressCompanion.insert(
            id: id,
            profileId: profileId,
            adventureId: adventureId,
            nodeId: nodeId,
            completion: completion,
            stepsTotal: stepsTotal,
            stepsIndependent: stepsIndependent,
            hintsUsed: hintsUsed,
            score: score,
            durationSeconds: durationSeconds,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StoryNodeProgressTableReferences(db, table, e)
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
                        $$StoryNodeProgressTableReferences._profileIdTable(db),
                    referencedColumn: $$StoryNodeProgressTableReferences
                        ._profileIdTable(db)
                        .id,
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

typedef $$StoryNodeProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StoryNodeProgressTable,
    StoryNodeProgressData,
    $$StoryNodeProgressTableFilterComposer,
    $$StoryNodeProgressTableOrderingComposer,
    $$StoryNodeProgressTableAnnotationComposer,
    $$StoryNodeProgressTableCreateCompanionBuilder,
    $$StoryNodeProgressTableUpdateCompanionBuilder,
    (StoryNodeProgressData, $$StoryNodeProgressTableReferences),
    StoryNodeProgressData,
    PrefetchHooks Function({bool profileId})>;
typedef $$StoryChapterProgressTableCreateCompanionBuilder
    = StoryChapterProgressCompanion Function({
  Value<int> id,
  required int profileId,
  required String adventureId,
  Value<String?> currentNodeId,
  Value<bool> isUnlocked,
  Value<bool> isCompleted,
  Value<DateTime> startedAt,
  Value<DateTime?> completedAt,
  Value<DateTime> lastPlayedAt,
  Value<String?> currentBeat,
  Value<String?> activityCheckpoint,
});
typedef $$StoryChapterProgressTableUpdateCompanionBuilder
    = StoryChapterProgressCompanion Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> adventureId,
  Value<String?> currentNodeId,
  Value<bool> isUnlocked,
  Value<bool> isCompleted,
  Value<DateTime> startedAt,
  Value<DateTime?> completedAt,
  Value<DateTime> lastPlayedAt,
  Value<String?> currentBeat,
  Value<String?> activityCheckpoint,
});

final class $$StoryChapterProgressTableReferences extends BaseReferences<
    _$AppDatabase, $StoryChapterProgressTable, StoryChapterProgressData> {
  $$StoryChapterProgressTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) => db.profiles
      .createAlias('story_chapter_progress__profile_id__profiles__id');

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

class $$StoryChapterProgressTableFilterComposer
    extends Composer<_$AppDatabase, $StoryChapterProgressTable> {
  $$StoryChapterProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get adventureId => $composableBuilder(
      column: $table.adventureId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentNodeId => $composableBuilder(
      column: $table.currentNodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isUnlocked => $composableBuilder(
      column: $table.isUnlocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentBeat => $composableBuilder(
      column: $table.currentBeat, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityCheckpoint => $composableBuilder(
      column: $table.activityCheckpoint,
      builder: (column) => ColumnFilters(column));

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

class $$StoryChapterProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryChapterProgressTable> {
  $$StoryChapterProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get adventureId => $composableBuilder(
      column: $table.adventureId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentNodeId => $composableBuilder(
      column: $table.currentNodeId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isUnlocked => $composableBuilder(
      column: $table.isUnlocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentBeat => $composableBuilder(
      column: $table.currentBeat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityCheckpoint => $composableBuilder(
      column: $table.activityCheckpoint,
      builder: (column) => ColumnOrderings(column));

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

class $$StoryChapterProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryChapterProgressTable> {
  $$StoryChapterProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get adventureId => $composableBuilder(
      column: $table.adventureId, builder: (column) => column);

  GeneratedColumn<String> get currentNodeId => $composableBuilder(
      column: $table.currentNodeId, builder: (column) => column);

  GeneratedColumn<bool> get isUnlocked => $composableBuilder(
      column: $table.isUnlocked, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => column);

  GeneratedColumn<String> get currentBeat => $composableBuilder(
      column: $table.currentBeat, builder: (column) => column);

  GeneratedColumn<String> get activityCheckpoint => $composableBuilder(
      column: $table.activityCheckpoint, builder: (column) => column);

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

class $$StoryChapterProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoryChapterProgressTable,
    StoryChapterProgressData,
    $$StoryChapterProgressTableFilterComposer,
    $$StoryChapterProgressTableOrderingComposer,
    $$StoryChapterProgressTableAnnotationComposer,
    $$StoryChapterProgressTableCreateCompanionBuilder,
    $$StoryChapterProgressTableUpdateCompanionBuilder,
    (StoryChapterProgressData, $$StoryChapterProgressTableReferences),
    StoryChapterProgressData,
    PrefetchHooks Function({bool profileId})> {
  $$StoryChapterProgressTableTableManager(
      _$AppDatabase db, $StoryChapterProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryChapterProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryChapterProgressTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryChapterProgressTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> profileId = const Value.absent(),
            Value<String> adventureId = const Value.absent(),
            Value<String?> currentNodeId = const Value.absent(),
            Value<bool> isUnlocked = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<DateTime> lastPlayedAt = const Value.absent(),
            Value<String?> currentBeat = const Value.absent(),
            Value<String?> activityCheckpoint = const Value.absent(),
          }) =>
              StoryChapterProgressCompanion(
            id: id,
            profileId: profileId,
            adventureId: adventureId,
            currentNodeId: currentNodeId,
            isUnlocked: isUnlocked,
            isCompleted: isCompleted,
            startedAt: startedAt,
            completedAt: completedAt,
            lastPlayedAt: lastPlayedAt,
            currentBeat: currentBeat,
            activityCheckpoint: activityCheckpoint,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int profileId,
            required String adventureId,
            Value<String?> currentNodeId = const Value.absent(),
            Value<bool> isUnlocked = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<DateTime> lastPlayedAt = const Value.absent(),
            Value<String?> currentBeat = const Value.absent(),
            Value<String?> activityCheckpoint = const Value.absent(),
          }) =>
              StoryChapterProgressCompanion.insert(
            id: id,
            profileId: profileId,
            adventureId: adventureId,
            currentNodeId: currentNodeId,
            isUnlocked: isUnlocked,
            isCompleted: isCompleted,
            startedAt: startedAt,
            completedAt: completedAt,
            lastPlayedAt: lastPlayedAt,
            currentBeat: currentBeat,
            activityCheckpoint: activityCheckpoint,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StoryChapterProgressTableReferences(db, table, e)
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
                    referencedTable: $$StoryChapterProgressTableReferences
                        ._profileIdTable(db),
                    referencedColumn: $$StoryChapterProgressTableReferences
                        ._profileIdTable(db)
                        .id,
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

typedef $$StoryChapterProgressTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $StoryChapterProgressTable,
        StoryChapterProgressData,
        $$StoryChapterProgressTableFilterComposer,
        $$StoryChapterProgressTableOrderingComposer,
        $$StoryChapterProgressTableAnnotationComposer,
        $$StoryChapterProgressTableCreateCompanionBuilder,
        $$StoryChapterProgressTableUpdateCompanionBuilder,
        (StoryChapterProgressData, $$StoryChapterProgressTableReferences),
        StoryChapterProgressData,
        PrefetchHooks Function({bool profileId})>;
typedef $$StoryRewardsTableCreateCompanionBuilder = StoryRewardsCompanion
    Function({
  Value<int> id,
  required int profileId,
  required String rewardId,
  required String adventureId,
  Value<DateTime> earnedAt,
});
typedef $$StoryRewardsTableUpdateCompanionBuilder = StoryRewardsCompanion
    Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> rewardId,
  Value<String> adventureId,
  Value<DateTime> earnedAt,
});

final class $$StoryRewardsTableReferences
    extends BaseReferences<_$AppDatabase, $StoryRewardsTable, StoryReward> {
  $$StoryRewardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('story_rewards__profile_id__profiles__id');

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

class $$StoryRewardsTableFilterComposer
    extends Composer<_$AppDatabase, $StoryRewardsTable> {
  $$StoryRewardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rewardId => $composableBuilder(
      column: $table.rewardId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get adventureId => $composableBuilder(
      column: $table.adventureId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get earnedAt => $composableBuilder(
      column: $table.earnedAt, builder: (column) => ColumnFilters(column));

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

class $$StoryRewardsTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryRewardsTable> {
  $$StoryRewardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rewardId => $composableBuilder(
      column: $table.rewardId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get adventureId => $composableBuilder(
      column: $table.adventureId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get earnedAt => $composableBuilder(
      column: $table.earnedAt, builder: (column) => ColumnOrderings(column));

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

class $$StoryRewardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryRewardsTable> {
  $$StoryRewardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rewardId =>
      $composableBuilder(column: $table.rewardId, builder: (column) => column);

  GeneratedColumn<String> get adventureId => $composableBuilder(
      column: $table.adventureId, builder: (column) => column);

  GeneratedColumn<DateTime> get earnedAt =>
      $composableBuilder(column: $table.earnedAt, builder: (column) => column);

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

class $$StoryRewardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoryRewardsTable,
    StoryReward,
    $$StoryRewardsTableFilterComposer,
    $$StoryRewardsTableOrderingComposer,
    $$StoryRewardsTableAnnotationComposer,
    $$StoryRewardsTableCreateCompanionBuilder,
    $$StoryRewardsTableUpdateCompanionBuilder,
    (StoryReward, $$StoryRewardsTableReferences),
    StoryReward,
    PrefetchHooks Function({bool profileId})> {
  $$StoryRewardsTableTableManager(_$AppDatabase db, $StoryRewardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryRewardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryRewardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryRewardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> profileId = const Value.absent(),
            Value<String> rewardId = const Value.absent(),
            Value<String> adventureId = const Value.absent(),
            Value<DateTime> earnedAt = const Value.absent(),
          }) =>
              StoryRewardsCompanion(
            id: id,
            profileId: profileId,
            rewardId: rewardId,
            adventureId: adventureId,
            earnedAt: earnedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int profileId,
            required String rewardId,
            required String adventureId,
            Value<DateTime> earnedAt = const Value.absent(),
          }) =>
              StoryRewardsCompanion.insert(
            id: id,
            profileId: profileId,
            rewardId: rewardId,
            adventureId: adventureId,
            earnedAt: earnedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StoryRewardsTableReferences(db, table, e)
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
                        $$StoryRewardsTableReferences._profileIdTable(db),
                    referencedColumn:
                        $$StoryRewardsTableReferences._profileIdTable(db).id,
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

typedef $$StoryRewardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StoryRewardsTable,
    StoryReward,
    $$StoryRewardsTableFilterComposer,
    $$StoryRewardsTableOrderingComposer,
    $$StoryRewardsTableAnnotationComposer,
    $$StoryRewardsTableCreateCompanionBuilder,
    $$StoryRewardsTableUpdateCompanionBuilder,
    (StoryReward, $$StoryRewardsTableReferences),
    StoryReward,
    PrefetchHooks Function({bool profileId})>;
typedef $$ActivityAttemptLogsTableCreateCompanionBuilder
    = ActivityAttemptLogsCompanion Function({
  Value<int> id,
  required int profileId,
  required String activityId,
  Value<String?> storyNodeId,
  required int stepIndex,
  required int attemptIndex,
  required String outcome,
  required String scaffoldLevel,
  required int elapsedMilliseconds,
  Value<DateTime> recordedAt,
});
typedef $$ActivityAttemptLogsTableUpdateCompanionBuilder
    = ActivityAttemptLogsCompanion Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> activityId,
  Value<String?> storyNodeId,
  Value<int> stepIndex,
  Value<int> attemptIndex,
  Value<String> outcome,
  Value<String> scaffoldLevel,
  Value<int> elapsedMilliseconds,
  Value<DateTime> recordedAt,
});

final class $$ActivityAttemptLogsTableReferences extends BaseReferences<
    _$AppDatabase, $ActivityAttemptLogsTable, ActivityAttemptLog> {
  $$ActivityAttemptLogsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) => db.profiles
      .createAlias('activity_attempt_logs__profile_id__profiles__id');

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

class $$ActivityAttemptLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityAttemptLogsTable> {
  $$ActivityAttemptLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storyNodeId => $composableBuilder(
      column: $table.storyNodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stepIndex => $composableBuilder(
      column: $table.stepIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptIndex => $composableBuilder(
      column: $table.attemptIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get outcome => $composableBuilder(
      column: $table.outcome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scaffoldLevel => $composableBuilder(
      column: $table.scaffoldLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedMilliseconds => $composableBuilder(
      column: $table.elapsedMilliseconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

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

class $$ActivityAttemptLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityAttemptLogsTable> {
  $$ActivityAttemptLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storyNodeId => $composableBuilder(
      column: $table.storyNodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stepIndex => $composableBuilder(
      column: $table.stepIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptIndex => $composableBuilder(
      column: $table.attemptIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outcome => $composableBuilder(
      column: $table.outcome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scaffoldLevel => $composableBuilder(
      column: $table.scaffoldLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedMilliseconds => $composableBuilder(
      column: $table.elapsedMilliseconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

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

class $$ActivityAttemptLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityAttemptLogsTable> {
  $$ActivityAttemptLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => column);

  GeneratedColumn<String> get storyNodeId => $composableBuilder(
      column: $table.storyNodeId, builder: (column) => column);

  GeneratedColumn<int> get stepIndex =>
      $composableBuilder(column: $table.stepIndex, builder: (column) => column);

  GeneratedColumn<int> get attemptIndex => $composableBuilder(
      column: $table.attemptIndex, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get scaffoldLevel => $composableBuilder(
      column: $table.scaffoldLevel, builder: (column) => column);

  GeneratedColumn<int> get elapsedMilliseconds => $composableBuilder(
      column: $table.elapsedMilliseconds, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

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

class $$ActivityAttemptLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActivityAttemptLogsTable,
    ActivityAttemptLog,
    $$ActivityAttemptLogsTableFilterComposer,
    $$ActivityAttemptLogsTableOrderingComposer,
    $$ActivityAttemptLogsTableAnnotationComposer,
    $$ActivityAttemptLogsTableCreateCompanionBuilder,
    $$ActivityAttemptLogsTableUpdateCompanionBuilder,
    (ActivityAttemptLog, $$ActivityAttemptLogsTableReferences),
    ActivityAttemptLog,
    PrefetchHooks Function({bool profileId})> {
  $$ActivityAttemptLogsTableTableManager(
      _$AppDatabase db, $ActivityAttemptLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityAttemptLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityAttemptLogsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityAttemptLogsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> profileId = const Value.absent(),
            Value<String> activityId = const Value.absent(),
            Value<String?> storyNodeId = const Value.absent(),
            Value<int> stepIndex = const Value.absent(),
            Value<int> attemptIndex = const Value.absent(),
            Value<String> outcome = const Value.absent(),
            Value<String> scaffoldLevel = const Value.absent(),
            Value<int> elapsedMilliseconds = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
          }) =>
              ActivityAttemptLogsCompanion(
            id: id,
            profileId: profileId,
            activityId: activityId,
            storyNodeId: storyNodeId,
            stepIndex: stepIndex,
            attemptIndex: attemptIndex,
            outcome: outcome,
            scaffoldLevel: scaffoldLevel,
            elapsedMilliseconds: elapsedMilliseconds,
            recordedAt: recordedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int profileId,
            required String activityId,
            Value<String?> storyNodeId = const Value.absent(),
            required int stepIndex,
            required int attemptIndex,
            required String outcome,
            required String scaffoldLevel,
            required int elapsedMilliseconds,
            Value<DateTime> recordedAt = const Value.absent(),
          }) =>
              ActivityAttemptLogsCompanion.insert(
            id: id,
            profileId: profileId,
            activityId: activityId,
            storyNodeId: storyNodeId,
            stepIndex: stepIndex,
            attemptIndex: attemptIndex,
            outcome: outcome,
            scaffoldLevel: scaffoldLevel,
            elapsedMilliseconds: elapsedMilliseconds,
            recordedAt: recordedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ActivityAttemptLogsTableReferences(db, table, e)
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
                    referencedTable: $$ActivityAttemptLogsTableReferences
                        ._profileIdTable(db),
                    referencedColumn: $$ActivityAttemptLogsTableReferences
                        ._profileIdTable(db)
                        .id,
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

typedef $$ActivityAttemptLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActivityAttemptLogsTable,
    ActivityAttemptLog,
    $$ActivityAttemptLogsTableFilterComposer,
    $$ActivityAttemptLogsTableOrderingComposer,
    $$ActivityAttemptLogsTableAnnotationComposer,
    $$ActivityAttemptLogsTableCreateCompanionBuilder,
    $$ActivityAttemptLogsTableUpdateCompanionBuilder,
    (ActivityAttemptLog, $$ActivityAttemptLogsTableReferences),
    ActivityAttemptLog,
    PrefetchHooks Function({bool profileId})>;
typedef $$EarnedBadgesTableCreateCompanionBuilder = EarnedBadgesCompanion
    Function({
  Value<int> id,
  required int profileId,
  required String badgeId,
  Value<DateTime> earnedAt,
});
typedef $$EarnedBadgesTableUpdateCompanionBuilder = EarnedBadgesCompanion
    Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> badgeId,
  Value<DateTime> earnedAt,
});

final class $$EarnedBadgesTableReferences
    extends BaseReferences<_$AppDatabase, $EarnedBadgesTable, EarnedBadge> {
  $$EarnedBadgesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('earned_badges__profile_id__profiles__id');

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

class $$EarnedBadgesTableFilterComposer
    extends Composer<_$AppDatabase, $EarnedBadgesTable> {
  $$EarnedBadgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get badgeId => $composableBuilder(
      column: $table.badgeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get earnedAt => $composableBuilder(
      column: $table.earnedAt, builder: (column) => ColumnFilters(column));

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

class $$EarnedBadgesTableOrderingComposer
    extends Composer<_$AppDatabase, $EarnedBadgesTable> {
  $$EarnedBadgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get badgeId => $composableBuilder(
      column: $table.badgeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get earnedAt => $composableBuilder(
      column: $table.earnedAt, builder: (column) => ColumnOrderings(column));

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

class $$EarnedBadgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EarnedBadgesTable> {
  $$EarnedBadgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get badgeId =>
      $composableBuilder(column: $table.badgeId, builder: (column) => column);

  GeneratedColumn<DateTime> get earnedAt =>
      $composableBuilder(column: $table.earnedAt, builder: (column) => column);

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

class $$EarnedBadgesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EarnedBadgesTable,
    EarnedBadge,
    $$EarnedBadgesTableFilterComposer,
    $$EarnedBadgesTableOrderingComposer,
    $$EarnedBadgesTableAnnotationComposer,
    $$EarnedBadgesTableCreateCompanionBuilder,
    $$EarnedBadgesTableUpdateCompanionBuilder,
    (EarnedBadge, $$EarnedBadgesTableReferences),
    EarnedBadge,
    PrefetchHooks Function({bool profileId})> {
  $$EarnedBadgesTableTableManager(_$AppDatabase db, $EarnedBadgesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EarnedBadgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EarnedBadgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EarnedBadgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> profileId = const Value.absent(),
            Value<String> badgeId = const Value.absent(),
            Value<DateTime> earnedAt = const Value.absent(),
          }) =>
              EarnedBadgesCompanion(
            id: id,
            profileId: profileId,
            badgeId: badgeId,
            earnedAt: earnedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int profileId,
            required String badgeId,
            Value<DateTime> earnedAt = const Value.absent(),
          }) =>
              EarnedBadgesCompanion.insert(
            id: id,
            profileId: profileId,
            badgeId: badgeId,
            earnedAt: earnedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EarnedBadgesTableReferences(db, table, e)
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
                        $$EarnedBadgesTableReferences._profileIdTable(db),
                    referencedColumn:
                        $$EarnedBadgesTableReferences._profileIdTable(db).id,
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

typedef $$EarnedBadgesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EarnedBadgesTable,
    EarnedBadge,
    $$EarnedBadgesTableFilterComposer,
    $$EarnedBadgesTableOrderingComposer,
    $$EarnedBadgesTableAnnotationComposer,
    $$EarnedBadgesTableCreateCompanionBuilder,
    $$EarnedBadgesTableUpdateCompanionBuilder,
    (EarnedBadge, $$EarnedBadgesTableReferences),
    EarnedBadge,
    PrefetchHooks Function({bool profileId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$GameScoresTableTableManager get gameScores =>
      $$GameScoresTableTableManager(_db, _db.gameScores);
  $$StoryNodeProgressTableTableManager get storyNodeProgress =>
      $$StoryNodeProgressTableTableManager(_db, _db.storyNodeProgress);
  $$StoryChapterProgressTableTableManager get storyChapterProgress =>
      $$StoryChapterProgressTableTableManager(_db, _db.storyChapterProgress);
  $$StoryRewardsTableTableManager get storyRewards =>
      $$StoryRewardsTableTableManager(_db, _db.storyRewards);
  $$ActivityAttemptLogsTableTableManager get activityAttemptLogs =>
      $$ActivityAttemptLogsTableTableManager(_db, _db.activityAttemptLogs);
  $$EarnedBadgesTableTableManager get earnedBadges =>
      $$EarnedBadgesTableTableManager(_db, _db.earnedBadges);
}
