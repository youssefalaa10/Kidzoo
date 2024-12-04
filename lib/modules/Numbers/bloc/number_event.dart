import 'package:equatable/equatable.dart';


abstract class NumberEvent extends Equatable {
  const NumberEvent();
}

class SelectNumberEvent extends NumberEvent {
  final String number;
  const SelectNumberEvent(this.number);

  @override
  List<Object> get props => [number];
}

