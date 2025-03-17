import 'package:flutter/material.dart';
import 'package:kidzoo/modules/Shapes/widgets/custom_icon.dart';

class ShapeAppBar extends StatelessWidget {
  final String score;
  final Function() onTapGameOVer;
  const ShapeAppBar(
      {super.key, required this.score, required this.onTapGameOVer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CustomIcon(
            icon: Icons.arrow_back,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 5),
          CustomIcon(
            icon: Icons.refresh,
            onTap: onTapGameOVer,
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Score: ',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  TextSpan(
                    text: score,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.teal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
