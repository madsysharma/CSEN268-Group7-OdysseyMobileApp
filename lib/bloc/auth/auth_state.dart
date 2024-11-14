part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class LoggedOut extends AuthState {}

final class Logging extends AuthState {}

final class LoggedIn extends AuthState {
  final User user;

  LoggedIn({required this.user});
}

final class LoggingError extends AuthState {
  final String error;
  LoggingError({required this.error});
}