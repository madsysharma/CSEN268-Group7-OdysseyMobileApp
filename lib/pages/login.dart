import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Center(
          child: state is LoggedOut ? ElevatedButton(
            child: Text("Login"),
            onPressed: () {
              context.read<AuthBloc>().add(LogInEvent());
            },
          ) : state is Logging ? CircularProgressIndicator() :
          Text(""),
        );
      },
    );
  }
}
