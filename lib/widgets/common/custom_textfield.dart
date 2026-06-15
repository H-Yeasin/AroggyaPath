import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget {
  const CustomTextfield({
    super.key,
    this.suffixIcon,
    this.textInputType,
    this.width,
    required this.prefixIcon,
    required this.controller,
    required this.hintText,
    required this.obsecureText,
  });

  final TextEditingController controller;
  final Icon prefixIcon;
  final IconButton? suffixIcon;
  final TextInputType? textInputType;
  final String hintText;
  final bool obsecureText;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width?? double.infinity,
      child: TextField(
        controller: controller,
        obscureText: obsecureText,
        decoration: InputDecoration(
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: const Color.fromARGB(255, 240, 239, 236),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(15.0)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            hintText: hintText,
            hintStyle: const TextStyle(color:Color.fromARGB(255, 153, 161, 83),
            fontWeight: FontWeight.w400),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
      ),
    );
  }
}
