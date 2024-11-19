import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
import 'package:odyssey/components/navigation/shell_bottom_nav_bar.dart';
import 'package:odyssey/model/location.dart';
import 'package:odyssey/pages/profile/download_network.dart';
import 'package:odyssey/pages/profile/edit_profile.dart';
import 'package:odyssey/pages/home.dart';
import 'package:odyssey/pages/location_details.dart';
import 'package:odyssey/pages/map_page.dart';
import 'package:odyssey/pages/profile.dart';
import 'package:odyssey/pages/profile/forgot_password.dart';
import 'package:odyssey/pages/profile/login.dart';
import 'package:odyssey/pages/profile/manage_membership.dart';
import 'package:odyssey/pages/profile/profile_page.dart';
import 'package:odyssey/pages/profile/saved_locations.dart';
import 'package:odyssey/pages/profile/signup.dart';
import 'package:odyssey/pages/safety.dart';
import 'package:odyssey/pages/safety_checkin.dart';
import 'package:odyssey/pages/safety_emer.dart';
import 'package:odyssey/pages/safety_tips.dart';
import 'package:odyssey/pages/connect.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase before the app runs
  // await Firebase.initializeApp();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        initialLocation: Paths.loginPage,
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
                builder: (context, state) => Connect(),
                routes: [
                  GoRoute(
                    path: 'local',
                    builder: (context, state) => Connect(tab: 'local',)
                  ),
                  GoRoute(
                    path: 'friends',
                    builder: (context, state) => Connect(tab: 'friends',)
                  ),
                  GoRoute(
                    path: 'you',
                    builder: (context, state) => Connect(tab: 'you',)
                  ),
                ]
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
              GoRoute(
                path: Paths.profilePage,
                builder: (context, state) => ProfilePage(),
              ),
              GoRoute(
                path: Paths.editProfile,
                builder: (context, state) => EditProfilePage(),
              ),
              GoRoute(
                path: Paths.savedLocations,
                builder: (context, state) => SavedLocations(),
              ),
              GoRoute(
                path: Paths.downloadNetwork,
                builder: (context, state) => DownloadNetworkPage(),
              ),
              GoRoute(
                path: Paths.manageMembership,
                builder: (context, state) => ManageMembership(),
              ),
              GoRoute(
                path: Paths.signupPage,
                builder: (context, state) => SignUpPage(),
              ),
              GoRoute(
                path: Paths.forgotPassword,
                builder: (context, state) => ForgotPasswordPage(),
              ),
            ],
          ),
          GoRoute(
              path: Paths.locationDetails,
              builder: (context, state) {
                var location = state.extra as LocationDetails;
                return LocationDetailsPage(location: location);
              }),
          GoRoute(
            path: Paths.loginPage,
            builder: (context, state) => LoginPage(),
          ),
        ],
        redirect: (context, state) {
          var loggedIn = context.read<AuthBloc>().state is LoggedIn;
          var tryingToLogin = state.fullPath == Paths.loginPage;
          var tryingToSignup = state.fullPath == Paths.signupPage;
          var tryingToUpdatePassword = state.fullPath == Paths.forgotPassword;

          if (loggedIn && (tryingToLogin || tryingToSignup || tryingToUpdatePassword)) {
            // Redirect logged-in users away from login/signup pages to the home page
            return Paths.home;
          }

          if (!loggedIn && !(tryingToLogin || tryingToSignup || tryingToUpdatePassword)) {
            // Redirect unauthenticated users to login if they are accessing a protected page
            return Paths.loginPage;
          }

          // No redirect needed
          return null;
        });

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state is LoggedIn) {
          router.go(Paths.home);
        } else if (state is LoggedOut) {
          router.go(Paths.loginPage);
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
