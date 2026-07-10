import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? suffixText;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.suffixText,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[700]),
        labelStyle: const TextStyle(color: Colors.grey),
        suffix: suffix,
        suffixText: suffixText,
        suffixStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[900],
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[800]!),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
