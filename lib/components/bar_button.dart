import 'package:flutter/material.dart';

class BarButton extends StatelessWidget {
  final Icon icon;
  final String text;
  final VoidCallback onPressed;

  const BarButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 80,
      height: 80,
      child: Column(
        children: [
          IconButton(
            icon: icon,
            color: colorScheme.onSecondaryContainer,
            onPressed: onPressed,
          ),
          Text(
            text,
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
            ),
          )
        ],
      ),
    );
  }
}
