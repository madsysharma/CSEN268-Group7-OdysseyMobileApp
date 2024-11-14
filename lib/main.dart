import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
import 'package:odyssey/components/shell_bottom_nav_bar.dart';
import 'package:odyssey/mockdata/locations.dart';
import 'package:odyssey/model/location.dart';
import 'package:odyssey/pages/home.dart';
import 'package:odyssey/pages/location_details.dart';
import 'package:odyssey/pages/login.dart';
import 'package:odyssey/pages/profile.dart';
import 'package:odyssey/utils/paths.dart';

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
                builder: (context, state) => HomeScreen(),
              ),
              GoRoute(
                path: Paths.connect,
                builder: (context, state) =>
                    Center(child: const Text("connect")),
              ),
              GoRoute(
                path: Paths.maps,
                builder: (context, state) => Center(child: const Text('maps')),
              ),
              GoRoute(
                path: Paths.safety,
                builder: (context, state) =>
                    Center(child: const Text('safety')),
              ),
              GoRoute(
                path: Paths.profile,
                builder: (context, state) => ProfileScreen(),
              ),
              GoRoute(
                  path: Paths.locationDetails,
                  builder: (context, state) {
                    var location = state.extra as LocationDetails;
                    return LocationDetailsPage(location: location);
                  })
            ]),
        GoRoute(
          path: Paths.login,
          builder: (context, state) => LoginScreen(),
        )
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
        child: SafeArea(
          child: MaterialApp.router(
              title: 'Odyssey',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF006A68)),
                fontFamily: GoogleFonts.lato().fontFamily,
                useMaterial3: true,
              ),
              routerConfig: router),
        ));
  }
}
