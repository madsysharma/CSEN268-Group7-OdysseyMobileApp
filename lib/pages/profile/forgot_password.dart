import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/components/forms/input.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:odyssey/utils/spaces.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmationFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmationFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      padding: pagePadding,
      child: SafeArea(
        child: Column(
          children: [
            extraLargeVertical,
            const Text("Change your password below"),
            smallVertical,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: Text("If you're new"),
                ),
                Flexible(
                  child: TextButton(
                      onPressed: () {
                       GoRouter.of(context).go(Paths.signupPage);
                      },
                      child: const Text("Join Us Here")),
                ),
              ],
            ),
            extraLargeVertical,
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Forgot Password"),
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
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!EmailValidator.validate(value)) {
                          return 'Invalid email address';
                        }
                        return null;
                      },
                    ),
                     MyTextField(
                      label: 'Password',
                      controller: _passwordController,
                      focusNode: passwordFocus,
                      nextFocusNode: confirmationFocus,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    smallVertical,
                    MyTextField(
                      label: 'Confirm Password',
                      controller: _confirmationController,
                      focusNode: confirmationFocus,
                      nextFocusNode: null,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password confirmation is required';
                        }
                        if (value != _passwordController.text) {
                          return 'Password and confirmation must match';
                        }
                        return null;
                      },
                    ),
                  ],
                )),
            mediumVertical,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      final isValid = formKey.currentState!.validate();
                      if (isValid == true) {
                       //update password
                      }
                    },
                    label: const Text("Update Password"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}