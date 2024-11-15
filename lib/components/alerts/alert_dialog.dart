import 'package:flutter/material.dart';
import 'package:odyssey/utils/spaces.dart';

class MyAlertDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const MyAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: mediumPadding,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: content,
      actions: actions,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}
