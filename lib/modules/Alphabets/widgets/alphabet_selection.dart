import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/alphabet_bloc.dart';
import '../bloc/alphabet_event.dart';


class AlphabetSelection extends StatelessWidget {
  const AlphabetSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(26, (index) {
          final alphabet = String.fromCharCode(65 + index);  // A-Z
          return GestureDetector(
            onTap: () {
              BlocProvider.of<AlphabetBloc>(context)
                  .add(SelectAlphabetEvent(alphabet));
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                radius: 30,
                child: Text(alphabet, style: const TextStyle(fontSize: 24)),
              ),
            ),
          );
        }),
      ),
    );
  }
}
