import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kidzoo/models/number_model.dart';
import 'package:kidzoo/modules/Numbers/bloc/number_bloc.dart';
import 'package:kidzoo/modules/Numbers/bloc/number_state.dart';

class NumberDisplay extends StatelessWidget {
  const NumberDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NumberBloc, NumberState>(
      builder: (context, state) {
        if (state is NumberInitialState) {
          return const Center(child: Text('Select a number',style: TextStyle(fontSize: 20,color: Colors.grey),));
        } else if (state is NumberLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is NumberLoadedState) {
          final numberModel = NumberModel.numbers.firstWhere(
            (model) => model.num == state.number,
            orElse: () => NumberModel(num: '', imagePath: '', example: ''),
          );

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
       
              if (numberModel.imagePath.isNotEmpty)
                SvgPicture.asset(
                  numberModel.imagePath,
                  width: 200,
                  height: 200,
                ),
              const SizedBox(height: 20),
              Text(
                '${state.number} = ${state.example}',
                style: const TextStyle(fontSize: 24),
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
