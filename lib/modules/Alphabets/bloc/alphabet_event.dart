import 'package:equatable/equatable.dart';

// Alphabet Event and State (same as provided earlier)
abstract class AlphabetEvent extends Equatable {
  const AlphabetEvent();
}

class SelectAlphabetEvent extends AlphabetEvent {
  final String alphabet;
  const SelectAlphabetEvent(this.alphabet);

  @override
  List<Object> get props => [alphabet];
}

