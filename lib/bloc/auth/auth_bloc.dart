import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:odyssey/model/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(LoggedOut()) {
    on<LogInEvent>((event, emit) async {
      emit(Logging());
      await Future.delayed(const Duration(seconds: 1));
      emit(LoggedIn(user: User(name: "John Doe", email: "joe@example.com")));
    });

    on<LogOutEvent>((event, emit) {
      emit(LoggedOut());
    });
  }
}
