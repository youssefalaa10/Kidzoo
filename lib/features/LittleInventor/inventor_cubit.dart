import 'package:flutter_bloc/flutter_bloc.dart';

enum BridgeFeedback { building, gap, noRoom, success }

class BridgePiece {
  const BridgePiece(this.id, this.length, {this.height = 1});
  final int id, length, height;
  String get sprite => ['red', 'blue', 'yellow', 'wedge', 'stone', 'crate'][id];
}

class InventorState {
  InventorState(
      {this.challenge = 0,
      Map<int, int> placements = const {},
      this.selected,
      this.feedback = BridgeFeedback.building,
      this.hint = false})
      : placements = Map.unmodifiable(placements);
  final int challenge;
  final Map<int, int> placements;
  final int? selected;
  final BridgeFeedback feedback;
  final bool hint;
  int get width => challenge == 0 ? 4 : 5;
  Set<int> get targetCells => switch (challenge) {
        0 => {0, 1, 2, 3, 4, 7},
        1 => {1, 2, 3, 5, 6, 7, 8, 9},
        _ => {3, 4, 6, 7, 8, 9, 10, 11},
      };
  int? get rampCell => challenge == 0
      ? null
      : challenge == 1
          ? 1
          : 8;
  List<BridgePiece> get availablePieces => pieces
      .where((p) => challenge != 0 || [0, 1, 4, 5].contains(p.id))
      .toList();
  String get missionKey =>
      ['inventor_flat', 'inventor_arch', 'inventor_ramp'][challenge];
  List<BridgePiece> get pieces => const [
        BridgePiece(0, 2),
        BridgePiece(1, 2),
        BridgePiece(2, 1),
        BridgePiece(3, 1),
        BridgePiece(4, 1),
        BridgePiece(5, 1)
      ];
  int? pieceAt(int cell) {
    final x = cell % width, y = cell ~/ width;
    for (final entry in placements.entries) {
      final p = pieces[entry.key],
          px = entry.value % width,
          py = entry.value ~/ width;
      if (x >= px && x < px + p.length && y >= py && y < py + p.height) {
        return p.id;
      }
    }
    return null;
  }
}

class InventorCubit extends Cubit<InventorState> {
  InventorCubit() : super(InventorState());
  void _update(
          {Map<int, int>? placements,
          int? selected,
          BridgeFeedback feedback = BridgeFeedback.building,
          bool? hint}) =>
      emit(InventorState(
          challenge: state.challenge,
          placements: placements ?? state.placements,
          selected: selected,
          feedback: feedback,
          hint: hint ?? state.hint));
  void select(int id) {
    if (state.feedback != BridgeFeedback.success &&
        !state.placements.containsKey(id)) {
      _update(selected: id);
    }
  }

  bool validCell(int x, int y) =>
      x >= 0 &&
      x < state.width &&
      y >= 0 &&
      state.targetCells.contains(y * state.width + x);
  bool _fits(int id, int cell, Map<int, int> placed) {
    final piece = state.pieces[id],
        x = cell % state.width,
        y = cell ~/ state.width;
    if (!state.availablePieces.any((p) => p.id == id) ||
        placed.containsKey(id) ||
        cell < 0) {
      return false;
    }
    if (id == 3 && cell != state.rampCell) return false;
    for (var dy = 0; dy < piece.height; dy++) {
      for (var dx = 0; dx < piece.length; dx++) {
        final cx = x + dx, cy = y + dy, target = cy * state.width + cx;
        if (!validCell(cx, cy) || (id != 3 && target == state.rampCell)) {
          return false;
        }
        for (final other in placed.entries) {
          final p = state.pieces[other.key],
              ox = other.value % state.width,
              oy = other.value ~/ state.width;
          if (cx >= ox &&
              cx < ox + p.length &&
              cy >= oy &&
              cy < oy + p.height) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool _solvable(Map<int, int> placed) {
    final occupied = <int>{};
    for (final entry in placed.entries) {
      final p = state.pieces[entry.key];
      for (var dy = 0; dy < p.height; dy++) {
        for (var dx = 0; dx < p.length; dx++) {
          occupied.add(entry.value + dy * state.width + dx);
        }
      }
    }
    final empty = state.targetCells.difference(occupied);
    if (empty.isEmpty) return true;
    final cell = empty.reduce((a, b) => a < b ? a : b);
    for (final p
        in state.availablePieces.where((p) => !placed.containsKey(p.id))) {
      for (var dx = 0; dx < p.length; dx++) {
        final anchor = cell - dx;
        if (_fits(p.id, anchor, placed) &&
            _solvable({...placed, p.id: anchor})) {
          return true;
        }
      }
    }
    return false;
  }

  List<int> viableAnchors(int id) => state.targetCells
      .where((cell) =>
          _fits(id, cell, state.placements) &&
          _solvable({...state.placements, id: cell}))
      .toList();

  /// A finger usually lands at a plank's centre, rather than its left edge.
  /// Snap nearby drops to a footprint that leaves the puzzle solvable.
  void drop(int id, int touchedCell) {
    if (state.feedback == BridgeFeedback.success ||
        id < 0 ||
        id >= state.pieces.length) {
      return;
    }
    final candidates = viableAnchors(id)
        .where((cell) =>
            (cell ~/ state.width - touchedCell ~/ state.width).abs() <= 1)
        .toList();
    double distance(int cell) {
      final p = state.pieces[id];
      final dx = (cell % state.width + (p.length - 1) / 2) -
          (touchedCell % state.width);
      final dy = (cell ~/ state.width) - (touchedCell ~/ state.width);
      return dx * dx + dy * dy * 4;
    }

    candidates.sort((a, b) {
      final comparison = distance(a).compareTo(distance(b));
      if (comparison != 0) return comparison;
      if (a == touchedCell) return -1;
      if (b == touchedCell) return 1;
      return a.compareTo(b);
    });
    if (candidates.isEmpty) {
      _update(selected: id, feedback: BridgeFeedback.noRoom);
      return;
    }
    place(id, candidates.first);
  }

  void place(int id, int cell) {
    if (state.feedback == BridgeFeedback.success ||
        state.placements.containsKey(id) ||
        id < 0 ||
        id >= state.pieces.length) {
      return;
    }
    final p = state.pieces[id], x = cell % state.width, y = cell ~/ state.width;
    final cells = [
      for (var dy = 0; dy < p.height; dy++)
        for (var dx = 0; dx < p.length; dx++) (x + dx, y + dy)
    ];
    if (cell < 0 ||
        (id == 3 && cell != state.rampCell) ||
        (id != 3 &&
            cells.any((c) => c.$2 * state.width + c.$1 == state.rampCell)) ||
        cells.any((c) =>
            c.$1 >= state.width ||
            !validCell(c.$1, c.$2) ||
            state.pieceAt(c.$2 * state.width + c.$1) != null)) {
      _update(selected: id, feedback: BridgeFeedback.noRoom);
      return;
    }
    _update(placements: {...state.placements, id: cell});
  }

  void tapCell(int cell) {
    if (state.feedback == BridgeFeedback.success) return;
    if (state.selected != null) {
      drop(state.selected!, cell);
      return;
    }
    final id = state.pieceAt(cell);
    if (id != null) {
      _update(placements: {...state.placements}..remove(id));
    } else if (state.selected != null) {
      drop(state.selected!, cell);
    }
  }

  void testBridge() {
    final complete =
        state.targetCells.every((cell) => state.pieceAt(cell) != null);
    _update(feedback: complete ? BridgeFeedback.success : BridgeFeedback.gap);
  }

  void showHint() => _update(selected: state.selected, hint: !state.hint);
  void reset() => emit(InventorState(challenge: state.challenge));
  void next() {
    if (state.feedback == BridgeFeedback.success) {
      emit(InventorState(challenge: (state.challenge + 1) % 3));
    }
  }
}
