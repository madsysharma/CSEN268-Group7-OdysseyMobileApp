part of 'auth_bloc.dart';

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {} // Initial state
class AuthSplash extends AuthState {}  // Splash state
class LoggedOut extends AuthState {}   // Logged-out state
class Logging extends AuthState {}     // Logging-in state
class LoggedIn extends AuthState {     // Logged-in state
  final User user;

  LoggedIn({required this.user});
}
class LoggingError extends AuthState {
  final String error;

  LoggingError({required this.error});
}
