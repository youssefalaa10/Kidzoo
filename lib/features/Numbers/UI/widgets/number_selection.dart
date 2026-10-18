import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/helpers/tts_helper.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';
import 'package:kidzo/features/Numbers/bloc/number_bloc.dart';
import 'package:kidzo/features/Numbers/bloc/number_event.dart';
import 'package:kidzo/features/Numbers/data/model/number_model.dart';

class NumberSelection extends StatefulWidget {
  const NumberSelection({super.key});

  @override
  State<NumberSelection> createState() => _NumberSelectionState();
}

class _NumberSelectionState extends State<NumberSelection> {
  TtsHelper? _ttsHelper;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ttsHelper == null) {
      final musicCubit = context.read<MusicCubit>();
      final languageCode = Localizations.localeOf(context).languageCode;
      _ttsHelper = TtsHelper(
        musicCubit: musicCubit,
        languageCode: languageCode,
      );
    }
  }

  @override
  void dispose() {
    _ttsHelper?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            _ttsHelper?.speak(number.getLocalizedName(context));
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
