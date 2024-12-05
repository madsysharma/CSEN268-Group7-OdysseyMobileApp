import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:odyssey/utils/spaces.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';

class SplashScreen extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fadeContentController;
  late AnimationController _fadeText1Controller;
  late AnimationController _fadeText2Controller;
  late AnimationController _slideUpController;

  late Animation<double> _waveAnimation;
  late Animation<double> _fadeContentAnimation;
  late Animation<double> _fadeText1Animation;
  late Animation<double> _fadeText2Animation;
  late Animation<Offset> _slideUpAnimation;

  bool showButtons = false;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();

    _waveAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _fadeContentController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _fadeText1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeText2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _slideUpController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _slideUpAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -0.2),
    ).animate(
        CurvedAnimation(parent: _slideUpController, curve: Curves.easeInOut));

    _waveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _fadeContentController.forward().then((_) {
          _fadeText1Controller.forward().then((_) {
            _fadeText2Controller.forward().then((_) {
              _slideUpController.forward().then((_) {
                setState(() {
                  showButtons = true;

                  // Navigate after animations complete
                  if (mounted) {
                    context.read<AuthBloc>().add(CheckAuthEvent());
                  }
                });
              });
            });
          });
        });
      }
    });

    _fadeContentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeContentController, curve: Curves.easeIn),
    );

    _fadeText1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeText1Controller, curve: Curves.easeIn),
    );

    _fadeText2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeText2Controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeContentController.dispose();
    _fadeText1Controller.dispose();
    _fadeText2Controller.dispose();
    _slideUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return WaveWidget(
                config: CustomConfig(
                  gradients: [
                    [const Color(0xFF9CF1EE), const Color(0xFF4CACA9)],
                    [const Color(0xFF4CACA9), const Color(0xFF0268B89)],
                    [const Color(0xFF0268B89), const Color(0xFF006A68)],
                    [const Color(0xFF006A68), const Color(0xFF006A68)],
                  ],
                  durations: [3500, 3000, 2500, 4000],
                  heightPercentages: [
                    _waveAnimation.value,
                    _waveAnimation.value + 0.05,
                    _waveAnimation.value + 0.1,
                    _waveAnimation.value + 0.15,
                  ],
                  gradientBegin: Alignment.bottomCenter,
                  gradientEnd: Alignment.topCenter,
                ),
                size: const Size(double.infinity, double.infinity),
                waveAmplitude: 0,
                backgroundColor: Colors.white,
              );
            },
          ),
          FadeTransition(
            opacity: _fadeContentAnimation,
            child: SlideTransition(
              position: _slideUpAnimation,
              child: Container(
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/bridge.png',
                        height: 450,
                        fit: BoxFit.contain,
                      ),
                      mediumVertical,
                      FadeTransition(
                        opacity: _fadeText1Animation,
                        child: const Text(
                          'Welcome to Odyssey',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      smallVertical,
                      FadeTransition(
                        opacity: _fadeText2Animation,
                        child: const Text(
                          'Enjoy the Bay, Your Way.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showButtons)
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
              ),
            ),
        ],
      ),
    );
  }
}
