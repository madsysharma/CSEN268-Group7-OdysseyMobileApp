import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const MyAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.onPrimary,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: colorScheme.onPrimary,
        ),
        onPressed: () {
          
        },
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
