import 'package:flutter/material.dart';
import 'package:odyssey/utils/spaces.dart';

void showActionSnackBar(
    BuildContext context, String message, SnackBarAction action) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    padding: mediumPadding,
    behavior: SnackBarBehavior.floating,
    action: action,
  ));
}

void showMessageSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    padding: mediumPadding,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 5),
  ));
}