import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
import 'package:odyssey/components/forms/input.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:odyssey/utils/spaces.dart';
import 'package:odyssey/utils/string_extensions.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is LoggedIn) {
            // Navigate to HomeScreen when logged in
            GoRouter.of(context).go(Paths.home);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Logging) {
              // Show loading indicator during authentication
              return const Center(child: CircularProgressIndicator());
            } else if (state is LoggedOut) {
              // Show the login form if logged out
              return SingleChildScrollView(
                padding: pagePadding,
                child: SafeArea(
                  child: Column(
                    children: [
                      extraLargeVertical,
                      Text(
                        "Welcome to Odyssey Travel App",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      smallVertical,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              "Login below or",
                            ),
                          ),
                          Flexible(
                            child: TextButton(
                              onPressed: () {
                                GoRouter.of(context).go(Paths.signupPage);
                              },
                              child: const Text("Create an Account"),
                            ),
                          ),
                        ],
                      ),
                      largeVertical,
                      Text(
                        "Sign In",
                      ),
                      mediumVertical,
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            MyTextField(
                              label: 'Email',
                              controller: _emailController,
                              focusNode: emailFocus,
                              nextFocusNode: passwordFocus,
                              validator: (value) {
                                if (_emailController.text.isWhitespace()) {
                                  return "Email is required";
                                }
                                if (!EmailValidator.validate(
                                    _emailController.text)) {
                                  return "Invalid email address";
                                }
                                return null;
                              },
                            ),
                            smallVertical,
                            MyTextField(
                              label: 'Password',
                              controller: _passwordController,
                              focusNode: passwordFocus,
                              nextFocusNode: null,
                              validator: (value) {
                                if (_passwordController.text.isWhitespace()) {
                                  return "Password is required";
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      mediumVertical,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FloatingActionButton.extended(
                              onPressed: () {
                                // Validate the form
                                final isValid =
                                    formKey.currentState!.validate();
                                if (isValid) {
                                  // Pass email and password to the LogInEvent
                                  final email = _emailController.text.trim();
                                  final password =
                                      _passwordController.text.trim();
                                  context.read<AuthBloc>().add(LogInEvent(
                                      email: email, password: password));
                                }
                              },
                              label: const Text("Login"),
                            ),
                          ),
                          Flexible(
                            child: TextButton(
                              onPressed: () {
                                GoRouter.of(context).go(Paths.forgotPassword);
                              },
                              child: const Text("Forgot Password"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
            // unexpected state page
            return const Center(child: Text("Unexpected state of logging in"));
          },
        ),
      ),
    );
  }
}
