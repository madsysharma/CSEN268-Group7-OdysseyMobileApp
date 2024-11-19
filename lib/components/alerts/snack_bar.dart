import 'package:flutter/material.dart';
import 'package:odyssey/utils/spaces.dart';

void showActionSnackBar(
    BuildContext context, String message, SnackBarAction action) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content:
        Text(message, style: TextStyle(color: colorScheme.onInverseSurface)),
    padding: mediumPadding,
    behavior: SnackBarBehavior.floating,
    action: action,
  ));
}

void showMessageSnackBar(BuildContext context, String message) {
  final colorScheme = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content:
        Text(message, style: TextStyle(color: colorScheme.onInverseSurface)),
    padding: mediumPadding,
    backgroundColor: colorScheme.inverseSurface,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 5),
  ));
}
