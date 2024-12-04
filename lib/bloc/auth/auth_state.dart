part of 'auth_bloc.dart';

@immutable
abstract class AuthState {}

class LoggedOut extends AuthState {}

class Logging extends AuthState {}

class LoggingError extends AuthState {
  final String error;

  LoggingError({required this.error});
}

class LoggedIn extends AuthState {
  final User user;

  LoggedIn({required this.user});
}
