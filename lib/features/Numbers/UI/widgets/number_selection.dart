import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/core/helpers/tts_helper.dart';
import 'package:kidzoo/features/Numbers/bloc/number_bloc.dart';
import 'package:kidzoo/features/Numbers/bloc/number_event.dart';
import 'package:kidzoo/features/Numbers/data/model/number_model.dart';

class NumberSelection extends StatelessWidget {
  const NumberSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final TtsHelper ttsHelper = TtsHelper();

    final List<NumberModel> numbers = NumberModel.numbers;

    final screenWidth = MediaQuery.of(context).size.width;

    final int crossAxisCount = screenWidth < 600
        ? 5
        : screenWidth < 900
            ? 2
            : 3;

    final double childAspectRatio = screenWidth < 600 ? 1.2 : 1.5;

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: numbers.length,
      itemBuilder: (context, index) {
        final number = numbers[index];

        return GestureDetector(
          onTap: () {
            BlocProvider.of<NumberBloc>(context)
                .add(SelectNumberEvent(number.num));
            ttsHelper.speak(number.num);
          },
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Image.asset(number.imagePath),
          ),
        );
      },
    );
  }
}
