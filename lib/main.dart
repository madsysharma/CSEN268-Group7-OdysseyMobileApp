import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
import 'package:odyssey/bloc/locationDetails/location_details_bloc.dart';
import 'package:odyssey/bloc/locations/locations_bloc.dart';
import 'package:odyssey/components/navigation/shell_bottom_nav_bar.dart';
import 'package:odyssey/model/location.dart';
import 'package:odyssey/pages/home.dart';
import 'package:odyssey/pages/maps/map_page.dart';
import 'package:odyssey/pages/location_details/location_details.dart';
import 'package:odyssey/pages/profile/forgotpass_page.dart';
import 'package:odyssey/pages/profile/login_page.dart';
import 'package:odyssey/pages/profile/profile_page.dart';
import 'package:odyssey/pages/profile/edit_profile.dart';
import 'package:odyssey/pages/profile/saved_locations.dart';
import 'package:odyssey/pages/profile/download_network.dart';
import 'package:odyssey/pages/profile/manage_membership.dart';
import 'package:odyssey/pages/connect/connect.dart';
import 'package:odyssey/pages/connect/friend_request.dart';
import 'package:odyssey/pages/connect/notifications.dart';
import 'package:odyssey/pages/connect/accept_request.dart';
import 'package:odyssey/pages/connect/expired_request.dart';
import 'package:odyssey/pages/connect/upload_post.dart';
import 'package:odyssey/pages/profile/signup_page.dart';
import 'package:odyssey/pages/splash/main_page.dart';
import 'package:odyssey/pages/splash/splash_screen.dart';
import 'package:odyssey/utils/custom_gallery.dart';
import 'package:odyssey/pages/safety/safety.dart';
import 'package:odyssey/pages/safety/safety_checkin.dart';
import 'package:odyssey/pages/safety/safety_emer.dart';
import 'package:odyssey/pages/safety/safety_sharing.dart';
import 'package:odyssey/pages/safety/safety_tips.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(create: (context) => AuthBloc()..add(CheckAuthEvent())),
      BlocProvider(create: (context) => LocationsBloc()),
      BlocProvider(create: (context) => LocationDetailsBloc()),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: Paths.splashScreen,
      routes: [
        ShellRoute(
          builder: (context, state, child) => ShellBottomNavBar(child: child),
          routes: [
            GoRoute(
              path: Paths.home,
              builder: (context, state) => HomeScreen(),
            ),
            GoRoute(
              path: Paths.locationDetails,
              builder: (context, state) {
                var location = state.extra as String;
                return LocationDetailsPage(locationId: location);
              },
            ),
            GoRoute(
              path: Paths.connect,
              builder: (context, state) => Connect(tab: 'local'),
              routes: [
                GoRoute(
                  path: 'local',
                  builder: (context, state) => Connect(tab: 'local'),
                  routes: [
                    GoRoute(
                      path: Paths.friendReq,
                      builder: (context, state) => FriendRequest(),
                    ),
                    GoRoute(
                      path: Paths.notifs,
                      builder: (context, state) =>
                          Notifications(fromScreen: 'local'),
                      routes: [
                        GoRoute(
                          path: Paths.acceptReq,
                          builder: (context, state) {
                            final query = state.uri.queryParameters['q'];
                            return AcceptRequest(requesterName: query);
                          },
                        ),
                        GoRoute(
                          path: Paths.expiredReq,
                          builder: (context, state) => ExpiredRequest(),
                        ),
                      ],
                    ),
                  ],
                ),
                GoRoute(
                  path: 'friends',
                  builder: (context, state) => Connect(tab: 'friends'),
                  routes: [
                    GoRoute(
                      path: Paths.friendReq,
                      builder: (context, state) => FriendRequest(),
                    ),
                    GoRoute(
                      path: Paths.notifs,
                      builder: (context, state) =>
                          Notifications(fromScreen: 'friends'),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'you',
                  builder: (context, state) => Connect(tab: 'you'),
                  routes: [
                    GoRoute(
                      path: Paths.friendReq,
                      builder: (context, state) => FriendRequest(),
                    ),
                    GoRoute(
                      path: Paths.notifs,
                      builder: (context, state) =>
                          Notifications(fromScreen: 'friends'),
                    ),
                    GoRoute(
                      path: Paths.post,
                      builder: (context, state) {
                        final location = state.extra as LocationDetails?;
                        return UploadPostInitial(location: location);
                      },
                      routes: [
                        GoRoute(
                          path: Paths.customGallery,
                          builder: (context, state) => CustomGallery(
                              imgPaths: state.extra as List<String>),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
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
                GoRoute(
                  path: 'sharing',
                  builder: (context, state) => SharingPage(),
                ),
              ],
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
          ],
        ),
        GoRoute(
          path: Paths.splashScreen,
          builder: (context, state) => SplashScreen(),
        ),
        GoRoute(
          path: Paths.mainPage,
          builder: (context, state) => MainPage(),
        ),
        GoRoute(
          path: Paths.loginPage,
          builder: (context, state) => LoginPage(),
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
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;

        // Handle AuthInitial (splash screen state)
        if (authState is AuthInitial) {
          return Paths.splashScreen; // Stay on splash during initialization
        }

        // Check if user is logged in
        final loggedIn = authState is LoggedIn;

        // Identify the current location
        final onSplash = state.matchedLocation == Paths.splashScreen;
        final tryingToLogin = state.matchedLocation == Paths.loginPage;
        final tryingToSignup = state.matchedLocation == Paths.signupPage;
        final tryingToUpdatePassword =
            state.matchedLocation == Paths.forgotPassword;

        // Redirect logged-in users away from authentication pages
        if (loggedIn &&
            (tryingToLogin || tryingToSignup || tryingToUpdatePassword)) {
          return Paths.home; // Redirect to home if logged in
        }

        // Redirect logged-out users to mainPage if they try to access restricted pages
        if (!loggedIn &&
            !(onSplash ||
                tryingToLogin ||
                tryingToSignup ||
                tryingToUpdatePassword)) {
          return Paths.mainPage; // Redirect to main page
        }

        // Allow navigation to proceed
        return null;
      },
    );

    return BlocListener<AuthBloc, AuthState>(
  listenWhen: (previous, current) => previous != current,
  listener: (context, state) {
    final currentLocation = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;

    if (state is AuthInitial) {
      // Navigate to splash screen during initialization
      if (currentLocation != Paths.splashScreen) {
        GoRouter.of(context).go(Paths.splashScreen);
      }
    } else if (state is LoggedIn) {
      // Navigate to home screen if authenticated
      if (currentLocation != Paths.home) {
        GoRouter.of(context).go(Paths.home);
      }
    } else if (state is LoggedOut) {
      // Navigate to main page if not authenticated
      if (currentLocation != Paths.mainPage) {
        GoRouter.of(context).go(Paths.mainPage);
      }
    }
  },
      child: MaterialApp.router(
        title: 'Odyssey',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A68)),
          fontFamily: GoogleFonts.lato().fontFamily,
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF006A68),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
