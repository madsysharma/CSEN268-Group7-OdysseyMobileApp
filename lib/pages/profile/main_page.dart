import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:odyssey/utils/spaces.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final smallTop = screenHeight * 0.18;
    final smallLeft = screenWidth * 0.05;
    final smallRight = screenWidth * 0.05;

    final largeTop = screenHeight * 0.80;
    final largeLeft = screenWidth * 0.05;
    final largeRight = screenWidth * 0.05;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.30), colorScheme.primary],
                begin: Alignment.center,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: smallTop,
            left: smallLeft,
            right: smallRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome To",
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(color: colorScheme.onPrimary),
                ),
                Text(
                  "Odyssey",
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(color: colorScheme.onPrimary),
                ),
                extraSmallVertical,
                Text(
                  "Explore the bay, your way.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: colorScheme.onPrimary),
                ),
              ],
            ),
          ),
          Positioned(
            top: largeTop,
            left: largeLeft,
            right: largeRight,
            child: Column(
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all<Size>(
                      Size(screenWidth * 0.75, 50),
                    ),
                  ),
                  onPressed: () {
                    GoRouter.of(context).go(Paths.loginPage);
                  },
                  child: const Text('Sign In'),
                ),
                mediumVertical,
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      colorScheme.onPrimary,
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      colorScheme.primary,
                    ),
                    minimumSize: WidgetStateProperty.all<Size>(
                      Size(screenWidth * 0.75, 50),
                    ),
                  ),
                  onPressed: () {
                    GoRouter.of(context).go(Paths.signupPage);
                  },
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
