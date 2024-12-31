import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/models/shape_model.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_cubit.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_states.dart';
import 'package:kidzoo/shared/tts_helper.dart';

class ShapeSelection extends StatelessWidget {
  const ShapeSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final TtsHelper ttsHelper = TtsHelper();

    final List<ShapeModel> shapes = ShapeModel.shapes;

    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = screenWidth < 600
        ? 1
        : screenWidth < 900
            ? 2
            : 3;

    double childAspectRatio = screenWidth < 600 ? 1.6 : 1.5;

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: shapes.length,
      itemBuilder: (context, index) {
        final shape = shapes[index];
        return BlocConsumer<ShapeCubit, ShapeStates>(
          listener: (context, state) {},
          builder: (context, state) {
            return GestureDetector(
            onTap: () {
              // BlocProvider.of<ShapeBloc>(context)
              //     .add(SelectShapeEvent(shape.shape, shape.temp));
               ttsHelper.speak(shape.shape);
              ttsHelper.getVoices();
            },
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Draggable<ShapeModel>(
                  feedback: Container(
                      width: 80,
                      height: 80,
                      child: Image.asset(shape.imagePath)),
              child: Image.asset(shape.imagePath),
                childWhenDragging: Image.asset(shape.imagePath, color: Colors.grey[300],),
                onDragCompleted: (){

                 //   BlocProvider.of<ShapeBloc>(context)
                 // .add(SelectShapeEvent(shape.shape, shape.temp));
                },
              ),
            ),
          );
          },
        );
      },
    );
  }
}
