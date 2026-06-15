import 'package:flutter/material.dart';

class CustomIcon extends StatelessWidget {
  const CustomIcon({super.key, required this.icon,});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 20,
      ),
      decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(8),
       boxShadow:const [
        BoxShadow(
            color: Color.fromARGB(255, 172, 175, 163),
            spreadRadius: 3,
            blurRadius: 10,
            offset: Offset(0, 6))
      ]),
      child: Icon(icon),
    );
  }
}
