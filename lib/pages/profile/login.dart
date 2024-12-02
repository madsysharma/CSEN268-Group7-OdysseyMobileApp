import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:odyssey/components/forms/input.dart';
import 'package:odyssey/components/forms/password_input.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:odyssey/utils/spaces.dart';
import 'package:odyssey/utils/string_extensions.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final List<String> phrases = [
    "Plan Your Dream Trip",
    "Discover New Destinations",
    "Your Journey Starts Here",
  ];

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is LoggedIn) {
            GoRouter.of(context).go(Paths.home);
          } else if (state is LoggingError) {
            showMessageSnackBar(context, state.error);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Logging) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: pagePadding,
              child: SafeArea(
                child: Column(
                  children: [
                    extraLargeVertical,
                    Text(
                      "Welcome To Odyssey Travel App",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Stack(
                      children: [
                        // Background Gradient or Image
                        Container(
                          height: 300,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.teal, Colors.green],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        // Carousel Slider for Text
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: CarouselSlider(
                              items: phrases.map((phrase) {
                                return Text(
                                  phrase,
                                  style: GoogleFonts.lora(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              }).toList(),
                              options: CarouselOptions(
                                height: 80,
                                autoPlay: true,
                                autoPlayInterval: const Duration(seconds: 3),
                                autoPlayAnimationDuration:
                                    const Duration(milliseconds: 800),
                                enlargeCenterPage: true,
                                viewportFraction: 1.0,
                                scrollDirection: Axis.horizontal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    smallVertical,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text("Login below or",
                              style: Theme.of(context).textTheme.bodyLarge),
                        ),
                        smallHorizontal,
                        Flexible(
                          child: TextButton(
                            onPressed: () {
                              GoRouter.of(context).go(Paths.signupPage);
                            },
                            child: Text("Create an Account"),
                          ),
                        ),
                      ],
                    ),
                    largeVertical,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Sign In",
                          style: Theme.of(context).textTheme.displayMedium),
                    ),
                    Divider(),
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
                          PasswordTextField(
                            label: 'Password',
                            obscureText: true,
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
                              final isValid = formKey.currentState!.validate();
                              if (isValid) {
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
                            child: Text("Forgot Password"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
