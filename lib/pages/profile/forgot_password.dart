import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final emailFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    emailFocus.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      // Send a password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );

      // Optionally navigate to login page
      GoRouter.of(context).go(Paths.loginPage);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found for this email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred. Please try again.')),
      );
    }
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
              const Text("Reset Your Password"),
              smallVertical,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(child: Text("Don't have an account?")),
                  Flexible(
                    child: TextButton(
                      onPressed: () {
                        GoRouter.of(context).go(Paths.signupPage);
                      },
                      child: const Text("Sign Up Here"),
                    ),
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
                    TextFormField(
                      controller: _emailController,
                      focusNode: emailFocus,
                      decoration: const InputDecoration(labelText: 'Email'),
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
                        if (formKey.currentState!.validate()) {
                          final email = _emailController.text.trim();
                          _sendPasswordResetEmail(email);
                        }
                      },
                      label: const Text("Send Reset Email"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
