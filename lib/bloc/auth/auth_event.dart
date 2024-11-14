part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class LogOutEvent extends AuthEvent {}
final class LogInEvent extends AuthEvent{}