import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  const MyTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.obscureText = false,
    this.focusNode,
    this.nextFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      focusNode: focusNode ?? FocusNode(), // Ensure focus node is provided
      onFieldSubmitted: (_) => nextFocusNode?.requestFocus(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const UnderlineInputBorder(), // Single bottom line
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      validator: validator,
    );
  }
}
