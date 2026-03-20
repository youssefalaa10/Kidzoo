import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/core/localization/app_localizations.dart';
import 'package:kidzoo/features/Numbers/bloc/number_bloc.dart';
import 'package:kidzoo/features/Numbers/bloc/number_state.dart';
import 'package:kidzoo/features/Numbers/data/model/number_model.dart';

class NumberDisplay extends StatelessWidget {
  const NumberDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<NumberBloc, NumberState>(
      builder: (context, state) {
        if (state is NumberInitialState) {
          return Center(
              child: Text(
            l10n.selectANumber,
            style: const TextStyle(fontSize: 20, color: Colors.grey),
          ));
        } else if (state is NumberLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is NumberLoadedState) {
          final numberModel = NumberModel.numbers.firstWhere(
            (model) => model.num == state.number,
            orElse: () => NumberModel(num: '', imagePath: '', example: '', exampleKey: ''),
          );

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (numberModel.imagePath.isNotEmpty)
                Image.asset(
                  numberModel.imagePath,
                  width: 300,
                  height: 300,
                ),
              const SizedBox(height: 20),
              Text(
                '${state.number} = ${numberModel.getLocalizedName(context)}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent),
              ),
            ],
          );
        } else if (state is NumberErrorState) {
          return Center(child: Text(state.errorMessage));
        }
        return Container();
      },
    );
  }
}
