import 'package:flutter/material.dart';
import 'package:kidzoo/models/shape_model.dart';
import 'package:kidzoo/shared/tts_helper.dart';

class ShapeDisplay extends StatelessWidget {
  final List<ShapeModel> shapes;
  const ShapeDisplay({super.key, required this.shapes});

  @override
  Widget build(BuildContext context) {
    final TtsHelper ttsHelper = TtsHelper();
    final screenWidth = MediaQuery.of(context).size.width;
    int selectionCrossAxisCount = screenWidth < 600
        ? 1
        : screenWidth < 900
            ? 2
            : 3;
    double selectionChildAspectRatio = screenWidth < 600 ? 1.6 : 1.5;

    return Container(
      height: MediaQuery.of(context).size.height / 1,
      width: MediaQuery.of(context).size.width / 3,
      color: Colors.white,
      child: Container(
        alignment: Alignment.center,
        color: Colors.white,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: selectionCrossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: selectionChildAspectRatio,
          ),
          itemCount: shapes.length,
          itemBuilder: (context, index) {
            final shape = shapes[index];
            return GestureDetector(
              onTap: () => ttsHelper.speak(shape.shape),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Draggable<ShapeModel>(
                  data: shape,
                  feedback: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.asset(shape.imagePath),
                  ),
                  childWhenDragging: Image.asset(
                    shape.imagePath,
                    color: Colors.grey[300],
                  ),
                  child: Image.asset(shape.imagePath),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
