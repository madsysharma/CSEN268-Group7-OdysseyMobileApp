import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
import 'package:odyssey/components/shell_bottom_nav_bar.dart';
import 'package:odyssey/pages/login.dart';
import 'package:odyssey/pages/map_page.dart';
import 'package:odyssey/pages/profile.dart';
import 'package:odyssey/pages/safety.dart';
import 'package:odyssey/pages/safety_checkin.dart';
import 'package:odyssey/pages/safety_emer.dart';
import 'package:odyssey/pages/safety_tips.dart';
import 'package:odyssey/paths.dart';
import 'package:odyssey/pages/connect.dart';

void main() {
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(create: (context) => AuthBloc()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: Paths.login,
      routes: [
        ShellRoute(
          builder: (context, state, child) => ShellBottomNavBar(child: child),
          routes: [
            GoRoute(
              path: Paths.home,
              builder: (context, state) => Center(child: const Text("Home")),
            ),
            GoRoute(
              path: Paths.connect,
              builder: (context, state) => Connect(),
            ),
            GoRoute(
              path: Paths.maps,
              builder: (context, state) => MapPage(),
            ),
            GoRoute(
              path: Paths.safety,
              builder: (context, state) => Safety(),
              routes: [
                GoRoute(
                  path: 'location-checkin',
                  builder: (context, state) => SafetyCheckin(),
                ),
                GoRoute(
                  path: 'emergency-contact',
                  builder: (context, state) => ContactsPage(),
                ),
                GoRoute(
                  path: 'travel-tips',
                  builder: (context, state) => SafetyTips(),
                ),
                
              ],
            ),
            GoRoute(
              path: Paths.profile,
              builder: (context, state) => ProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: Paths.login,
          builder: (context, state) => LoginScreen(),
        ),
      ],
      redirect: (context, state) {
        var loggedIn = context.read<AuthBloc>().state is LoggedIn;
        var tryingToLogin = state.fullPath == Paths.login;
        if (loggedIn && tryingToLogin) {
          return Paths.home;
        }
        if (!loggedIn && !tryingToLogin) {
          return Paths.login;
        }
        if (state.fullPath == "/") {
          return Paths.home;
        }
        return null;
      },
    );

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state is LoggedIn) {
          router.go(Paths.home);
        } else if (state is LoggedOut) {
          router.go(Paths.login);
        }
      },
      child: MaterialApp.router(
        title: 'Odyssey',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF006A68)),
          fontFamily: GoogleFonts.lato().fontFamily,
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
