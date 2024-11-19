import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/components/forms/input.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:odyssey/utils/spaces.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final formKey = GlobalKey<FormState>();
  PhoneNumber? _phoneNumber;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();

  final firstNameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final emailFocus = FocusNode();
  final numberFocus = FocusNode();
  final locationFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmationFocus = FocusNode();

  Future<void> signUpUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String location,
  }) async {
    try {
      // Create a new user in Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the generated user ID
      String userId = userCredential.user!.uid;

      // Save user details in Firestore
      await FirebaseFirestore.instance.collection('User').doc(userId).set({
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        'phonenumber': phoneNumber,
        'homelocation': location,
        'membertype': 'Standard', // Default value, can be updated later
        'interests': [], // Default empty list
        'createdAt':
            FieldValue.serverTimestamp(), // Add a timestamp for tracking
      });

      print("User signed up and details saved successfully!");
    } on FirebaseAuthException catch (e) {
      print("Error: ${e.message}");
      throw Exception(
          e.message); // You can handle this with a UI-friendly message
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    numberFocus.dispose();
    locationFocus.dispose();
    passwordFocus.dispose();
    confirmationFocus.dispose();
    super.dispose();
  }

  final List<String> _bayAreaAreaCodes = ['408', '415', '510', '650', '925'];

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Prepend +1 if missing
    String formattedValue = value.startsWith('+1') ? value : '+1$value';

    // Remove all non-digit characters for validation
    String digitsOnly = formattedValue.replaceAll(RegExp(r'\D'), '');

    // Check for valid USA phone number length
    if (!digitsOnly.startsWith('1') || digitsOnly.length != 11) {
      return 'Enter a valid 10-digit USA phone number';
    }

    // Additional check for Bay Area area codes
    List<String> bayAreaAreaCodes = ['408', '415', '510', '650', '925', '669'];
    String areaCode = digitsOnly.substring(1, 4);
    if (!bayAreaAreaCodes.contains(areaCode)) {
      return 'Phone number must be from the Bay Area';
    }

    return null;
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
              const Text("Fill out the form below to join"),
              smallVertical,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text("Or, if you have an account"),
                  ),
                  Flexible(
                    child: TextButton(
                      onPressed: () {
                        GoRouter.of(context).go(Paths.loginPage);
                      },
                      child: const Text("Login Here"),
                    ),
                  ),
                ],
              ),
              extraLargeVertical,
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Sign Up"),
              ),
              mediumVertical,
              Form(
                key: formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: MyTextField(
                            label: 'First Name',
                            controller: _firstNameController,
                            focusNode: firstNameFocus,
                            nextFocusNode: lastNameFocus,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MyTextField(
                            label: 'Last Name',
                            controller: _lastNameController,
                            focusNode: lastNameFocus,
                            nextFocusNode: emailFocus,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    smallVertical,
                    MyTextField(
                      label: 'Email',
                      controller: _emailController,
                      focusNode: emailFocus,
                      nextFocusNode: numberFocus,
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
                    smallVertical,
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Focus(
                        focusNode: numberFocus,
                        child: InternationalPhoneNumberInput(
                          onInputChanged: (PhoneNumber number) {
                            setState(() {
                              _phoneNumber = number;
                            });
                          },
                          selectorConfig: const SelectorConfig(
                            selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                            showFlags: false,
                          ),
                          ignoreBlank: false,
                          autoValidateMode: AutovalidateMode.disabled,
                          initialValue:
                              PhoneNumber(isoCode: 'US', dialCode: '+1'),
                          countries: const ['US'],
                          textFieldController: _numberController,
                          formatInput: true,
                          inputDecoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: 'Enter phone number',
                            labelText: 'Phone Number',
                          ),
                          validator: validatePhoneNumber,
                          onFieldSubmitted: (_) {
                            // Move focus to the email field
                            FocusScope.of(context).requestFocus(locationFocus);
                          },
                        ),
                      ),
                    ),
                    smallVertical,
                    MyTextField(
                      label: 'Location',
                      controller: _locationController,
                      focusNode: locationFocus,
                      nextFocusNode: passwordFocus,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Location is required';
                        }
                        return null;
                      },
                    ),
                    smallVertical,
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
                ),
              ),
              mediumVertical,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FloatingActionButton.extended(
                      onPressed: () async {
                        final isValid = formKey.currentState!.validate();
                        if (isValid) {
                          try {
                            await signUpUser(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              firstName: _firstNameController.text.trim(),
                              lastName: _lastNameController.text.trim(),
                              phoneNumber: _numberController.text.trim(),
                              location: _locationController.text.trim(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Account created successfully!")),
                            );

                            // Navigate to another page after sign-up
                            GoRouter.of(context).go(Paths.home);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        }
                      },
                      label: const Text("Create Account"),
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
