import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:odyssey/utils/spaces.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(LogOutEvent());
    
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF9CF1EE),
                  Color(0xFF006A68),
                ],
              ),
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/bridge.png',
                  height: 450,
                  fit: BoxFit.contain,
                ),
                mediumVertical,
                const Text(
                  'Welcome to Odyssey',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                smallVertical,
                const Text(
                  'Enjoy the Bay, Your Way.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      GoRouter.of(context).go(Paths.loginPage);
                    },
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      GoRouter.of(context).go(Paths.signupPage);
                    },
                    child: const Text('Sign Up'),
                  ),
                ],
              ))
        ],
      ),
    );
  }
}
