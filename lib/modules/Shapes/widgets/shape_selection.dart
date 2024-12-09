import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kidzoo/models/shape_model.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_bloc.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_event.dart';
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

        return GestureDetector(
          onTap: () {
            BlocProvider.of<ShapeBloc>(context)
                .add(SelectShapeEvent(shape.shape));
            ttsHelper.speak(shape.shape);
            ttsHelper.getVoices();
          },
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: SvgPicture.asset(shape.imagePath),
          ),
        );
      },
    );
  }
}
