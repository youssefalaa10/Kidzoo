import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String title;
  final Function() onPressed;
  final Color color;

  const CustomButton(
      {super.key,
      required this.title,
      required this.onPressed,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.width / 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
