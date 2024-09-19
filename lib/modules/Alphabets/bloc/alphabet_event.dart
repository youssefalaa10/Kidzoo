import 'package:equatable/equatable.dart';


abstract class AlphabetEvent extends Equatable {
  const AlphabetEvent();
}

class SelectAlphabetEvent extends AlphabetEvent {
  final String alphabet;
  const SelectAlphabetEvent(this.alphabet);

  @override
  List<Object> get props => [alphabet];
}

