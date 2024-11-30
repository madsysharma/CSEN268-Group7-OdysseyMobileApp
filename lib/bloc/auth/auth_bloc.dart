import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:meta/meta.dart';
import 'package:odyssey/model/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  AuthBloc({firebase_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        super(LoggedOut()) {
    on<LogInEvent>(_handleLogInEvent);
    on<LogOutEvent>(_handleLogOutEvent);
  }

  Future<void> _handleLogInEvent(
      LogInEvent event, Emitter<AuthState> emit) async {
    emit(Logging());
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      final user = userCredential.user;
      if (user == null) {
        emit(LoggingError(error: 'Login failed. Please try again.'));
        return;
      }

      emit(LoggedIn(
        user: User(
          name: user.displayName ?? 'Unknown',
          email: user.email ?? 'Unknown',
        ),
      ));
    } catch (e) {
      emit(LoggingError(error: 'Login failed. Please check your credentials.'));
    }
  }

  Future<void> _handleLogOutEvent(
      LogOutEvent event, Emitter<AuthState> emit) async {
    try {
      await _firebaseAuth.signOut();
      emit(LoggedOut());
    } catch (e) {
      emit(LoggingError(error: 'Failed to log out. Please try again.'));
    }
  }
}
