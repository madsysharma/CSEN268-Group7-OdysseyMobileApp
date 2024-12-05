import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:odyssey/utils/spaces.dart';

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

  bool _isObscured = true;
  @override
  void initState() {
    super.initState();
  }

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.primary
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/bridge.png',
                  height: 450,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 50),
                SingleChildScrollView(
                  padding: pagePadding,
                  child: Column(
                    children: [
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            SizedBox(height: screenHeight * 0.45),
                            mediumVertical,
                            TextFormField(
                              controller: _emailController,
                              focusNode: emailFocus,
                              onFieldSubmitted: (_) =>
                                  passwordFocus.requestFocus(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Email is required";
                                }
                                if (!EmailValidator.validate(value)) {
                                  return "Invalid email address";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    colorScheme.onSurface.withOpacity(0.875),
                                hintText: 'Email',
                                hintStyle: TextStyle(
                                  color: colorScheme.onPrimary.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: colorScheme.onPrimary
                                          .withOpacity(0.8)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: colorScheme.onPrimary),
                                ),
                              ),
                              style: TextStyle(
                                  color: colorScheme.onPrimary, fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              focusNode: passwordFocus,
                              obscureText: _isObscured,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Password is required";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    colorScheme.onSurface.withOpacity(0.875),
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  color: colorScheme.onPrimary.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: colorScheme.onPrimary
                                          .withOpacity(0.8)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: colorScheme.onPrimary),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscured
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color:
                                        colorScheme.onPrimary.withOpacity(0.8),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscured = !_isObscured;
                                    });
                                  },
                                ),
                              ),
                              style: TextStyle(
                                  color: colorScheme.onPrimary, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      mediumVertical,
                      ElevatedButton(
                        style: ButtonStyle(
                          minimumSize: WidgetStateProperty.all<Size>(
                            Size(screenWidth, 50),
                          ),
                        ),
                        onPressed: () {
                          final isValid = formKey.currentState!.validate();
                          if (isValid) {
                            final email = _emailController.text.trim();
                            final password = _passwordController.text.trim();
                            context.read<AuthBloc>().add(
                                LogInEvent(email: email, password: password));
                          }
                        },
                        child: const Text("Login"),
                      ),
                      SizedBox(height: screenHeight * 0.15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.all(
                                  colorScheme.onPrimary),
                            ),
                            onPressed: () {
                              GoRouter.of(context).go(Paths.signupPage);
                            },
                            child: Text("Create an Account"),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: colorScheme.onPrimary,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          TextButton(
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.all(
                                  colorScheme.onPrimary),
                            ),
                            onPressed: () {
                              GoRouter.of(context).go(Paths.forgotPassword);
                            },
                            child: Text("Forgot Password"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
