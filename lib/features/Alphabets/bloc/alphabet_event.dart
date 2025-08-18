import 'package:equatable/equatable.dart';

abstract class AlphabetEvent extends Equatable {
  const AlphabetEvent();
}

class SelectAlphabetEvent extends AlphabetEvent {
  const SelectAlphabetEvent(this.alphabet);
  final String alphabet;

  @override
  List<Object> get props => [alphabet];
}
