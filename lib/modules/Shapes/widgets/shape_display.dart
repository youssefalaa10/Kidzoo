import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kidzoo/models/shape_model.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_bloc.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_state.dart';

class ShapeDisplay extends StatelessWidget {
  const ShapeDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShapeBloc, ShapeState>(
      builder: (context, state) {
        if (state is ShapeInitialState) {
          return const Padding(
            padding: EdgeInsets.only(left: 30.0),
            child: Text('Select a shape',style: TextStyle(fontSize: 20,color: Colors.grey),),
          );
        } else if (state is ShapeLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ShapeLoadedState) {
          final shapeModel = ShapeModel.shapes.firstWhere(
            (model) => model.shape == state.shape,
            orElse: () => ShapeModel(shape: '', imagePath: '', example: ''),
          );

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (shapeModel.imagePath.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: SvgPicture.asset(
                    shapeModel.imagePath,
                    width: 200,
                    height: 200,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                state.shape, //= ${state.example}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ],
          );
        } else if (state is ShapeErrorState) {
          return Center(child: Text(state.errorMessage));
        }
        return Container();
      },
    );
  }
}
