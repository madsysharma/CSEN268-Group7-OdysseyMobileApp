import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:meta/meta.dart';
import 'package:odyssey/model/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  AuthBloc() : super(LoggedOut()) {
    on<LogInEvent>((event, emit) async {
      emit(Logging());

      try {
        // Attempt to sign in using the provided email and password
        final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        // Emit the LoggedIn state with the user's details
        emit(LoggedIn(user: User(name: userCredential.user!.displayName ?? 'Unknown', email: userCredential.user!.email ?? '')));
      } catch (e) {
        // Handle errors (e.g., invalid credentials)
        emit(LoggingError(error: e.toString()));
      }
    });

    on<LogOutEvent>((event, emit) {
      _firebaseAuth.signOut();
      emit(LoggedOut());
    });
  }
}
