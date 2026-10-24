import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum BalloonMode { free, colors, numbers, english, arabic, challenge }

enum BalloonPhase { ready, playing, complete }

enum PopResult { ignored, playful, correct, guidance, complete }

const balloonColors = <Color>[
  Color(0xFFFF637D),
  Color(0xFF39BCE8),
  Color(0xFFFFCD45),
  Color(0xFF9A77EF),
  Color(0xFF4EC99C),
  Color(0xFFEF83D0),
];
const balloonColorNames = ['red', 'blue', 'yellow', 'purple', 'green', 'pink'];
const balloonArabicColors = [
  'الأحمر',
  'الأزرق',
  'الأصفر',
  'البنفسجي',
  'الأخضر',
  'الوردي'
];
const balloonArabicLetters = ['أ', 'ب', 'ت', 'ث', 'ج', 'ح'];

@immutable
class FloatingBalloon {
  const FloatingBalloon(
      {required this.id,
      required this.color,
      required this.value,
      required this.x,
      required this.age,
      required this.duration,
      required this.size,
      required this.sway,
      required this.phase});
  final int id, color, value;
  final double x, age, duration, size, sway, phase;
  double get progress => age / duration;
  double get horizontal => (x + sin(age * 1.6 + phase) * sway).clamp(.07, .93);
  FloatingBalloon advance(double dt) => FloatingBalloon(
      id: id,
      color: color,
      value: value,
      x: x,
      age: age + dt,
      duration: duration,
      size: size,
      sway: sway,
      phase: phase);
  String label(BalloonMode mode) => switch (mode) {
        BalloonMode.numbers => '${value + 1}',
        BalloonMode.english => String.fromCharCode(65 + value),
        BalloonMode.arabic => balloonArabicLetters[value],
        _ => '',
      };
}

@immutable
class BalloonBurst {
  const BalloonBurst(this.id, this.x, this.y, this.color, {this.age = 0});
  final int id, color;
  final double x, y, age;
  BalloonBurst advance(double dt) =>
      BalloonBurst(id, x, y, color, age: age + dt);
}

@immutable
class BalloonState {
  const BalloonState(
      {this.mode = BalloonMode.free,
      this.phase = BalloonPhase.ready,
      this.balloons = const [],
      this.bursts = const [],
      this.score = 0,
      this.target = 0,
      this.elapsed = 0,
      this.pops = 0,
      this.streak = 0,
      this.comboRemaining = 0,
      this.paused = false});
  final BalloonMode mode;
  final BalloonPhase phase;
  final List<FloatingBalloon> balloons;
  final List<BalloonBurst> bursts;
  final int score, target;
  final int pops, streak;
  final double comboRemaining;
  final double elapsed;
  final bool paused;
  bool get challenge => mode == BalloonMode.challenge;
  bool get educational => mode != BalloonMode.free && !challenge;
  int get wave => challenge ? 1 + min(pops ~/ 12, 7) : 1;
  int get multiplier => challenge ? min(1 + streak ~/ 5, 5) : 1;
  int get goal => educational ? 8 : 20;
  BalloonState copy(
          {BalloonPhase? phase,
          List<FloatingBalloon>? balloons,
          List<BalloonBurst>? bursts,
          int? score,
          int? target,
          double? elapsed,
          int? pops,
          int? streak,
          double? comboRemaining,
          bool? paused}) =>
      BalloonState(
          mode: mode,
          phase: phase ?? this.phase,
          balloons: List.unmodifiable(balloons ?? this.balloons),
          bursts: List.unmodifiable(bursts ?? this.bursts),
          score: score ?? this.score,
          target: target ?? this.target,
          elapsed: elapsed ?? this.elapsed,
          pops: pops ?? this.pops,
          streak: streak ?? this.streak,
          comboRemaining: comboRemaining ?? this.comboRemaining,
          paused: paused ?? this.paused);
}

/// Time-driven simulation: no background timers, widget dependencies, or static game state.
class BalloonCubit extends Cubit<BalloonState> {
  BalloonCubit({Random? random})
      : _random = random ?? Random(),
        super(const BalloonState());
  final Random _random;
  int _nextId = 0;
  double _untilSpawn = 0;

  void select(BalloonMode mode) => emit(BalloonState(mode: mode));
  void start() {
    _untilSpawn = .3;
    final target = _random.nextInt(6);
    emit(BalloonState(
        mode: state.mode,
        phase: BalloonPhase.playing,
        target: target,
        balloons: List.unmodifiable([_spawn(firstTarget: target)])));
  }

  void setPaused(bool value) => emit(state.copy(paused: value));
  void menu() => emit(BalloonState(mode: state.mode));
  void finishChallenge() {
    if (state.challenge && state.phase == BalloonPhase.playing) {
      emit(state.copy(phase: BalloonPhase.complete));
    }
  }

  bool matches(FloatingBalloon b) =>
      (state.mode == BalloonMode.colors ? b.color : b.value) == state.target;

  FloatingBalloon _spawn({int? firstTarget}) {
    final wave = firstTarget == null ? state.wave : 1;
    // At least one target remains discoverable, even after the previous one escapes.
    final targetNeeded = firstTarget != null ||
        (state.educational && !state.balloons.any(matches));
    final value = targetNeeded || _random.nextDouble() < .42
        ? (firstTarget ?? state.target)
        : _random.nextInt(6);
    return FloatingBalloon(
        id: _nextId++,
        color: state.mode == BalloonMode.colors ? value : _random.nextInt(6),
        value: value,
        x: .13 + _random.nextDouble() * .74,
        age: 0,
        duration: state.challenge
            ? max(3.2, 7.5 - (wave - 1) * .6) + _random.nextDouble() * 2
            : 8 + _random.nextDouble() * 5,
        size: .86 + _random.nextDouble() * .22,
        sway: .025 + _random.nextDouble() * .065,
        phase: _random.nextDouble() * pi * 2);
  }

  void tick(double dt) {
    if (state.phase != BalloonPhase.playing || state.paused || dt <= 0) return;
    // Avoid teleporting after suspended frames; lifecycle pauses freeze elapsed time.
    dt = dt.clamp(0, .06);
    final balloons = state.balloons
        .map((b) => b.advance(dt))
        .where((b) => b.progress < 1.15)
        .toList();
    final escaped = balloons.length < state.balloons.length;
    final comboRemaining = max(0.0, state.comboRemaining - dt);
    final bursts = state.bursts
        .map((b) => b.advance(dt))
        .where((b) => b.age < .55)
        .toList();
    _untilSpawn -= dt;
    if (_untilSpawn <= 0 && balloons.length < 9) {
      balloons.add(_spawn());
      _untilSpawn = state.challenge
          ? max(.30, .85 - (state.wave - 1) * .07) + _random.nextDouble() * .3
          : .65 + _random.nextDouble() * .65;
    }
    final elapsed = state.elapsed + dt;
    emit(state.copy(
        balloons: balloons,
        bursts: bursts,
        elapsed: elapsed,
        streak: state.challenge && (escaped || comboRemaining == 0)
            ? 0
            : state.streak,
        comboRemaining: escaped ? 0 : comboRemaining,
        phase: state.mode == BalloonMode.free && elapsed >= 60
            ? BalloonPhase.complete
            : null));
  }

  PopResult pop(int id) {
    if (state.phase != BalloonPhase.playing || state.paused) {
      return PopResult.ignored;
    }
    final index = state.balloons.indexWhere((b) => b.id == id);
    if (index < 0) return PopResult.ignored;
    final balloon = state.balloons[index];
    final correct = !state.educational || matches(balloon);
    final streak = state.challenge ? state.streak + 1 : 0;
    final multiplier = min(1 + streak ~/ 5, 5);
    final score =
        state.score + (state.challenge ? 10 * multiplier : (correct ? 1 : 0));
    final complete = !state.challenge && score >= state.goal;
    final nextTarget = state.educational && correct
        ? (state.target + 1 + _random.nextInt(5)) % 6
        : state.target;
    emit(state.copy(
        balloons: state.balloons.where((b) => b.id != id).toList(),
        bursts: [
          ...state.bursts,
          BalloonBurst(
              balloon.id, balloon.horizontal, balloon.progress, balloon.color)
        ],
        score: score,
        pops: state.pops + 1,
        streak: streak,
        comboRemaining: state.challenge ? 2.5 : 0,
        target: nextTarget,
        phase: complete ? BalloonPhase.complete : null));
    return complete
        ? PopResult.complete
        : !correct
            ? PopResult.guidance
            : state.educational
                ? PopResult.correct
                : PopResult.playful;
  }
}
