import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kidzoo/models/shape_model.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_cubit.dart';
import '../bloc/shape_states.dart';

class ShapeDisplay extends StatelessWidget {
  const ShapeDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    String? selectedShape;
    String? selectedTemp;
    final List<ShapeModel> shapes = ShapeModel.shapes;
    final List<String> temps = shapes.map((shape) => shape.temp).toList();
    temps.shuffle(Random());
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = screenWidth < 600
        ? 2
        : screenWidth < 900
            ? 2
            : 3;
    double childAspectRatio = screenWidth < 600 ? .9 : 1.5;
    return BlocConsumer<ShapeCubit, ShapeStates>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is ShapeInitialState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width / 1,
                height: MediaQuery.of(context).size.height / 1.3,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    //crossAxisSpacing: 0,
                    mainAxisSpacing: 10,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: temps.length,
                  itemBuilder: (context, index) {
                    final temp = temps[index];
                    return DragTarget<ShapeModel>(
                      onAcceptWithDetails: (val){
                        if(temp != '' &&val.data.temp == temp){
                          print(temp);
                          print(val);
                        }
                      },
                      builder: (context, candidateData, rejectedData) =>
                          Column(
                          children: [
                            if (index % 2 != 0)
                              SizedBox(
                                height: 40,
                              ),
                            Container(
                                height: 80, child: SvgPicture.asset(temp)),
                          ],
                        ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        else if (state is ShapeLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ShapeLoadedState) {
          selectedShape = state.shape;
          selectedTemp = state.temp;
          // final shapeModel = ShapeModel.shapes.firstWhere(
          //   (model) => model.shape == state.shape,
          //   orElse: () => ShapeModel(shape: '', imagePath: '', temp: ''),
          // );
          // return Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     if (shapeModel.imagePath.isNotEmpty)
          //       Padding(
          //         padding: const EdgeInsets.only(left: 10.0),
          //         child: SvgPicture.asset(
          //           shapeModel.imagePath,
          //           width: 200,
          //           height: 200,
          //         ),
          //       ),
          //     const SizedBox(height: 20),
          //     Text(
          //       state.shape,
          //       style: const TextStyle(
          //           fontSize: 24,
          //           fontWeight: FontWeight.bold,
          //           color: Colors.redAccent),
          //     ),
          //   ],
          // );
        } else if (state is ShapeErrorState) {
          return Center(child: Text(state.errorMessage));
        }
        return Container();
      },
    );
  }
}
