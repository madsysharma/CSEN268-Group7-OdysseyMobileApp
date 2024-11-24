part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class LogOutEvent extends AuthEvent {}

final class LogInEvent extends AuthEvent {
  final String email;
  final String password;

  // Constructor to accept email and password
  LogInEvent({required this.email, required this.password});
}
