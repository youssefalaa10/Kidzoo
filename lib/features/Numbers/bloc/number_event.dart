import 'package:equatable/equatable.dart';

abstract class NumberEvent extends Equatable {
  const NumberEvent();
}

class SelectNumberEvent extends NumberEvent {
  const SelectNumberEvent(this.number);
  final String number;

  @override
  List<Object> get props => [number];
}
