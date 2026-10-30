import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

enum FootballPhase { aiming, charging, flying, result, finished }

enum FootballMode { levels, openChallenge }

enum ShotOutcome { goal, saved, wide, weak }

class FootballState {
  const FootballState(
      {this.phase = FootballPhase.aiming,
      this.aim = .65,
      this.power = 0,
      this.clock = 0,
      this.flight = 0,
      this.keeper = 0,
      this.results = const [],
      this.outcome,
      this.mode = FootballMode.levels,
      this.level = 1,
      this.bankedScore = 0});
  final FootballMode mode;
  final int level, bankedScore;
  int get difficulty =>
      mode == FootballMode.openChallenge ? 1 + results.length ~/ 5 : level;
  double get greenStart => .30 + (difficulty - 1).clamp(0, 8) * .015;
  double get greenEnd => .80 - (difficulty - 1).clamp(0, 8) * .015;
  int get score =>
      bankedScore +
      results.fold<int>(
          0,
          (sum, r) =>
              sum +
              (r == ShotOutcome.goal
                  ? 100
                  : r == ShotOutcome.saved
                      ? 10
                      : 0));
  final FootballPhase phase;
  final double aim, power, clock, flight, keeper;
  final List<ShotOutcome> results;
  final ShotOutcome? outcome;
  int get goals => results.where((r) => r == ShotOutcome.goal).length;
}

class FootballCubit extends Cubit<FootballState> {
  FootballCubit({Random? random})
      : random = random ?? Random(),
        super(const FootballState());
  final Random random;
  void _set(
      {FootballPhase? phase,
      double? aim,
      double? power,
      double? clock,
      double? flight,
      double? keeper,
      List<ShotOutcome>? results,
      ShotOutcome? outcome}) {
    emit(FootballState(
        mode: state.mode,
        level: state.level,
        bankedScore: state.bankedScore,
        phase: phase ?? state.phase,
        aim: aim ?? state.aim,
        power: power ?? state.power,
        clock: clock ?? state.clock,
        flight: flight ?? state.flight,
        keeper: keeper ?? state.keeper,
        results: results ?? state.results,
        outcome: outcome ?? state.outcome));
  }

  void aim(double value) {
    if (state.phase == FootballPhase.aiming) _set(aim: value.clamp(-1, 1));
  }

  void confirmAim() {
    if (state.phase == FootballPhase.aiming) {
      _set(phase: FootballPhase.charging, clock: 0, power: 0);
    }
  }

  void tick(double seconds) {
    if (seconds <= 0) return;
    if (state.phase == FootballPhase.aiming ||
        state.phase == FootballPhase.charging) {
      final t = state.clock + seconds;
      _set(
          clock: t,
          keeper: sin(t * (1.4 + state.difficulty.clamp(1, 12) * .20)) * .75,
          power: state.phase == FootballPhase.charging
              ? (1 - cos(t * (2.7 + state.difficulty.clamp(1, 12) * .15))) / 2
              : 0);
    } else if (state.phase == FootballPhase.flying) {
      final progress = (state.flight + seconds / .85).clamp(0.0, 1.0);
      if (progress == 1) {
        _set(
            phase:
                state.mode == FootballMode.levels && state.results.length == 4
                    ? FootballPhase.finished
                    : FootballPhase.result,
            flight: 1,
            results: List.unmodifiable([...state.results, state.outcome]));
      } else {
        _set(flight: progress);
      }
    }
  }

  void shoot() {
    if (state.phase != FootballPhase.charging) return;
    final keeper = (state.keeper +
            (state.aim - state.keeper) *
                ((state.difficulty - 1) * .075).clamp(0, .65) +
            (random.nextDouble() - .5) * .22)
        .clamp(-.85, .85);
    final outcome = state.power < state.greenStart
        ? ShotOutcome.weak
        : state.power > state.greenEnd
            ? ShotOutcome.wide
            : (state.aim - keeper).abs() <
                    .20 + (state.difficulty * .018).clamp(0, .20)
                ? ShotOutcome.saved
                : ShotOutcome.goal;
    _set(
        phase: FootballPhase.flying,
        flight: 0,
        keeper: keeper,
        outcome: outcome);
  }

  void next() {
    if (state.phase != FootballPhase.result) return;
    emit(FootballState(
        mode: state.mode,
        level: state.level,
        bankedScore: state.bankedScore,
        phase: state.mode == FootballMode.levels && state.results.length == 5
            ? FootballPhase.finished
            : FootballPhase.aiming,
        results: state.results));
  }

  void restart() => emit(FootballState(mode: state.mode, level: state.level));
  void chooseMode(FootballMode mode) => emit(FootballState(mode: mode));
  void nextLevel() {
    if (state.phase == FootballPhase.finished) {
      emit(FootballState(
          mode: state.mode, level: state.level + 1, bankedScore: state.score));
    }
  }
}
