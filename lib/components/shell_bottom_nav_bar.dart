import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/utils/paths.dart';

class ShellBottomNavBar extends StatefulWidget {
  final Widget child;
  const ShellBottomNavBar({super.key, required this.child});

  @override
  State<ShellBottomNavBar> createState() => _ShellBottomNavBarState();
}

class _ShellBottomNavBarState extends State<ShellBottomNavBar> {
  var selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Connect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Maps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Safety',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      onTap: (value) {
        setState(() {
          selectedIndex = value;
        });
        switch (value) {
          case 0:
            context.go(Paths.home);
            break;
          case 1:
            context.go(Paths.connect);
            break;
          case 2:
            context.go(Paths.maps);
            break;
          case 3:
            context.go(Paths.safety);
            break;
          case 4:
            context.go(Paths.profile);
            break;
        }
      },
      )
    );
  }
}