import 'package:flutter/material.dart';

class CustomIcon extends StatelessWidget {
  const CustomIcon({required this.icon, required this.onTap, super.key});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Icon(
            icon,
            color: Colors.teal,
            size: 30,
          ),
        ));
  }
}
