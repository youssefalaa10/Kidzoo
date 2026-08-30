import 'package:equatable/equatable.dart';

class Tile extends Equatable {
  const Tile({
    required this.value,
    required this.row,
    required this.col,
    this.merged = false,
    this.isNew = false,
    this.previousRow,
    this.previousCol,
  });

  final int value;
  final int row;
  final int col;
  final bool merged;
  final bool isNew;
  final int? previousRow;
  final int? previousCol;

  Tile copyWith({
    int? value,
    int? row,
    int? col,
    bool? merged,
    bool? isNew,
    Object? previousRow = _undefined,
    Object? previousCol = _undefined,
  }) {
    return Tile(
      value: value ?? this.value,
      row: row ?? this.row,
      col: col ?? this.col,
      merged: merged ?? this.merged,
      isNew: isNew ?? this.isNew,
      previousRow:
          previousRow == _undefined ? this.previousRow : previousRow as int?,
      previousCol:
          previousCol == _undefined ? this.previousCol : previousCol as int?,
    );
  }

  @override
  List<Object?> get props =>
      [value, row, col, merged, isNew, previousRow, previousCol];

  static const _undefined = Object();
}
