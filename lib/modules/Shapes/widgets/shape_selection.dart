import 'package:flutter/material.dart';

class ShapeSelection extends StatelessWidget {
  final bool isMatched;
  final String temp;
  final int index;
  const ShapeSelection(
      {super.key,
      required this.isMatched,
      required this.temp,
      required this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (index % 2 == 0)
          const SizedBox(
            height: 30,
          ),
        Container(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          margin: const EdgeInsets.all(8),
          //height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: isMatched
              ? Stack(
                  children: [
                    const Positioned(
                        left: 5,
                        top: 5,
                        bottom: 5,
                        right: 5,
                        child: Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 50,
                        )),
                    Image.asset(
                      temp,
                      color: Colors.green,
                    ),
                  ],
                )
              : Image.asset(temp),
        ),
        if (index % 2 != 0)
          const SizedBox(
            height: 30,
          ),
      ],
    );
  }
}
