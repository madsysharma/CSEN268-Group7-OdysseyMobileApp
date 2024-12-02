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
import 'package:odyssey/pages/profile.dart';
import 'package:odyssey/pages/profile/forgot_password.dart';
import 'package:odyssey/pages/profile/login.dart';
import 'package:odyssey/pages/profile/manage_membership.dart';
import 'package:odyssey/pages/profile/profile_page.dart';
import 'package:odyssey/pages/profile/saved_locations.dart';
import 'package:odyssey/pages/profile/signup.dart';
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
      BlocProvider(create: (context) => AuthBloc()),
      BlocProvider(create: (context) => LocationsBloc()),
      BlocProvider(create: (context) => LocationDetailsBloc())
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
        initialLocation: Paths.loginPage,
        navigatorKey: rootNavigatorKey,
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
              }),
              GoRoute(
                path: Paths.connect,
                builder: (context, state) => Connect(tab: 'local'),
                routes: [
                  GoRoute(
                    path: 'local',
                    builder: (context, state) => Connect(tab: 'local',),
                    routes: [
                      GoRoute(
                        path: Paths.friendReq,
                        builder: (context, state) => FriendRequest(),
                      ),
                      GoRoute(
                        path: Paths.notifs,
                        builder: (context, state) => Notifications(fromScreen: 'local',),
                        routes: [
                          GoRoute(
                            path: Paths.acceptReq,
                            builder: (context, state){
                              final query = state.uri.queryParameters['q'];
                              return AcceptRequest(requesterName: query);
                            },
                          ),
                          GoRoute(
                            path: Paths.expiredReq,
                            builder: (context, state) => ExpiredRequest()
                          ),
                        ],
                      ),
                    ]
                  ),
                  GoRoute(
                    path: 'friends',
                    builder: (context, state) => Connect(tab: 'friends',),
                    routes: [
                      GoRoute(
                        path: Paths.friendReq,
                        builder: (context, state) => FriendRequest(),
                      ),
                      GoRoute(
                        path: Paths.notifs,
                        builder: (context, state) => Notifications(fromScreen: 'friends',),
                        routes: [
                          GoRoute(
                            path: Paths.acceptReq,
                            builder: (context, state){
                              final query = state.uri.queryParameters['q'];
                              return AcceptRequest(requesterName: query);
                            }
                          ),
                          GoRoute(
                            path: Paths.expiredReq,
                            builder: (context, state) => ExpiredRequest()
                          ),
                        ],
                      ),
                    ]
                  ),
                  GoRoute(
                    path: 'you',
                    builder: (context, state) => Connect(tab: 'you',),
                    routes: [
                      GoRoute(
                        path: Paths.post,
                        // parentNavigatorKey: rootNavigatorKey, // open it not in the inner Navigator, but in a root Navigator
                        builder: (context, state) {
                          LocationDetails? location = state.extra as LocationDetails?;
                          return UploadPost(location: location);
                        },
                        routes: [
                          GoRoute(
                            path: Paths.customGallery,
                            builder: (context, state) => CustomGallery(imgPaths: state.extra as List<String>),
                          ),
                        ]
                      ),
                      GoRoute(
                        path: Paths.friendReq,
                        builder: (context, state) => FriendRequest(),
                      ),
                      GoRoute(
                        path: Paths.notifs,
                        builder: (context, state) => Notifications(fromScreen: 'you',),
                        routes: [
                          GoRoute(
                            path: Paths.acceptReq,
                            builder: (context, state){
                              final query = state.uri.queryParameters['q'];
                              return AcceptRequest(requesterName: query);
                            },
                          ),
                          GoRoute(
                            path: Paths.expiredReq,
                            builder: (context, state) => ExpiredRequest()
                          ),
                        ],
                      ),
                    ]
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
                  GoRoute(
                    path: 'sharing',
                    builder: (context, state) => SharingPage(),
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
            path: Paths.loginPage,
            builder: (context, state) => LoginPage(),
          ),
        ],
        redirect: (context, state) {
          var loggedIn = context.read<AuthBloc>().state is LoggedIn;
          var tryingToLogin = state.fullPath == Paths.loginPage;
          var tryingToSignup = state.fullPath == Paths.signupPage;
          var tryingToUpdatePassword = state.fullPath == Paths.forgotPassword;

          if (loggedIn &&
              (tryingToLogin || tryingToSignup || tryingToUpdatePassword)) {
            return Paths.home;
          }

          if (!loggedIn &&
              !(tryingToLogin || tryingToSignup || tryingToUpdatePassword)) {
            return Paths.loginPage;
          }
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
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF006A68),
              foregroundColor: Color(0xFFFFFFFF),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
                style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(Color(0xFF006A68)),
              textStyle: WidgetStateProperty.all(
                TextStyle(
                  fontSize: 16,
                ),
              ),
              padding: WidgetStateProperty.all(
                EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              ),
            ))),
        routerConfig: router,
      ),
    );
  }
}
