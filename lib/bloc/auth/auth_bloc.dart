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

Future<void> _handleLogInEvent(LogInEvent event, Emitter<AuthState> emit) async {
  emit(Logging());
  try {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: event.email,
      password: event.password,
    );

    final user = userCredential.user;
    if (user == null) {
      emit(LoggingError(error: 'An unknown error occurred. Please try again.'));
      return;
    }

    emit(LoggedIn(
      user: User(
        name: user.displayName ?? 'Unknown',
        email: user.email ?? 'Unknown',
      ),
    ));
  } on firebase_auth.FirebaseAuthException catch (e) {
    // Log the error code and message for debugging
    print('FirebaseAuthException caught: ${e.code} - ${e.message}');
    emit(LoggingError(error: _getFirebaseAuthErrorMessage(e.code)));
  } catch (e, stackTrace) {
    // Log the generic error for debugging
    print('Unexpected error: $e');
    print('Stack trace: $stackTrace');
    emit(LoggingError(error: 'An unexpected error occurred. Please try again.'));
  }
}


  Future<void> _handleLogOutEvent(LogOutEvent event, Emitter<AuthState> emit) async {
    try {
      await _firebaseAuth.signOut();
      emit(LoggedOut());
    } catch (e) {
      emit(LoggingError(error: 'Failed to log out. Please try again.'));
    }
  }

String _getFirebaseAuthErrorMessage(String errorCode) {
  if (errorCode == 'user-not-found') {
    return 'No account found with this email.';
  } else if (errorCode == 'wrong-password') {
    return 'The password you entered is incorrect.';
  } else if (errorCode == 'invalid-email') {
    return 'The email address format is invalid.';
  }
  return 'An unknown error occurred. Please try again.';
}


}
