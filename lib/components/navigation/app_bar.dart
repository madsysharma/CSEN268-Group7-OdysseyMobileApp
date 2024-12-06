import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton; 

  const MyAppBar({
    super.key,
    required this.title,
    this.showBackButton = true, 
  });

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
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: colorScheme.onPrimary,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          : null, 
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
