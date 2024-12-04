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
import 'package:odyssey/pages/connect/expired_request.dart';
import 'package:odyssey/pages/profile/download_network.dart';
import 'package:odyssey/pages/profile/edit_profile.dart';
import 'package:odyssey/pages/home.dart';
//import 'package:odyssey/pages/locc3
import 'package:odyssey/pages/maps/map_page.dart';
import 'package:odyssey/pages/location_details/location_details.dart';
import 'package:odyssey/pages/profile/forgotpass_page.dart';
import 'package:odyssey/pages/profile/main_page.dart';
import 'package:odyssey/pages/profile/login_page.dart';
import 'package:odyssey/pages/profile/manage_membership.dart';
import 'package:odyssey/pages/profile/profile_page.dart';
import 'package:odyssey/pages/profile/saved_locations.dart';
import 'package:odyssey/pages/profile/signup_page.dart';
import 'package:odyssey/pages/safety/safety.dart';
import 'package:odyssey/pages/safety/safety_checkin.dart';
import 'package:odyssey/pages/safety/safety_emer.dart';
import 'package:odyssey/pages/safety/safety_sharing.dart';
import 'package:odyssey/pages/safety/safety_tips.dart';
import 'package:odyssey/pages/connect/connect.dart';
import 'package:odyssey/pages/connect/friend_request.dart';
import 'package:odyssey/pages/connect/notifications.dart';
import 'package:odyssey/pages/connect/accept_request.dart';
import 'package:odyssey/utils/custom_gallery.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:odyssey/pages/connect/upload_post.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug
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
  final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine initial location based on authentication state
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final initialLocation = isLoggedIn ? Paths.home : Paths.mainPage;

    // Set up GoRouter
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
                  builder: (context, state) => Connect(tab: 'local'),
                  routes: [
                    GoRoute(
                        path: 'local',
                        builder: (context, state) => Connect(
                              tab: 'local',
                            ),
                        routes: [
                          GoRoute(
                            path: Paths.friendReq,
                            builder: (context, state) => FriendRequest(),
                          ),
                        ]),
                    GoRoute(
                        path: 'friends',
                        builder: (context, state) => Connect(
                              tab: 'friends',
                            ),
                        routes: [
                          GoRoute(
                            path: Paths.friendReq,
                            builder: (context, state) => FriendRequest(),
                          ),
                        ]),
                    GoRoute(
                        path: 'you',
                        builder: (context, state) => Connect(
                              tab: 'you',
                            ),
                        routes: [
                          GoRoute(
                            path: Paths.post,
                            builder: (context, state) {
                              LocationDetails? location = state.extra as LocationDetails?;
                              return UploadPostInitial(location: location);
                            },
                          ),
                          GoRoute(
                            path: Paths.friendReq,
                            builder: (context, state) => FriendRequest(),
                          ),
                        ]),
                  ]),
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
                path: Paths.profile,
                builder: (context, state) => ProfilePage(),
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
                var location = state.extra as String;
                return LocationDetailsPage(locationId: location);
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

        // Redirect logic based on authentication
        if (loggedIn &&
            (tryingToLogin || tryingToSignup || tryingToUpdatePassword)) {
          return Paths.home;
        }

        if (!loggedIn &&
            !(tryingToLogin || tryingToSignup || tryingToUpdatePassword)) {
          return Paths.mainPage;
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
          router.go(Paths.mainPage);
        }
      },
      child: MaterialApp.router(
        title: 'Odyssey',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A68)),
          fontFamily: GoogleFonts.lato().fontFamily,
          useMaterial3: true,
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF006A68),
            foregroundColor: const Color(0xFFFFFFFF),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                const Color(0xFF006A68),
              ),
              foregroundColor: WidgetStateProperty.all(
                const Color(0xFFFFFFFF),
              ),
              padding: WidgetStateProperty.all<EdgeInsets>(
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              minimumSize: WidgetStateProperty.all<Size>(
                const Size(130, 50),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(const Color(0xFF006A68)),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            ),
          )),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFF3F4948),
            actionTextColor: const Color(0xFFF4FBF9),
            contentTextStyle: const TextStyle(
              color: Color(0xFFF4FBF9),
            ),
            elevation: 4,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
