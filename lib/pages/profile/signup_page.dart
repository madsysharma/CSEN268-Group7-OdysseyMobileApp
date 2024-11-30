import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/components/forms/input.dart';
import 'package:odyssey/components/forms/password_input.dart';
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
  // ignore: unused_field
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
      final emailQuery = await FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: email)
          .get();

      final phoneQuery = await FirebaseFirestore.instance
          .collection('User')
          .where('phonenumber', isEqualTo: phoneNumber)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        throw Exception('An account with this email already exists.');
      }

      if (phoneQuery.docs.isNotEmpty) {
        throw Exception('An account with this phone number already exists.');
      }

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('User').doc(userId).set({
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        'phonenumber': phoneNumber,
        'homelocation': location,
        'membertype': 'Standard',
        'interests': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
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

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    String formattedValue = value.startsWith('+1') ? value : '+1$value';

    String digitsOnly = formattedValue.replaceAll(RegExp(r'\D'), '');

    if (!digitsOnly.startsWith('1') || digitsOnly.length != 11) {
      return 'Enter a valid 10-digit USA phone number';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: pagePadding,
        child: SafeArea(
          child: Column(
            children: [
              Form(
                key: formKey,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Create Your Account",
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            "Already have an account?",
                          ),
                          smallHorizontal,
                          TextButton(
                              onPressed: () {
                                GoRouter.of(context).go(Paths.loginPage);
                              },
                              child: Text("Login Here"))
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
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
                    mediumVertical,
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
                    mediumVertical,
                    Focus(
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
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(
                            fontSize: 16,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.shadow),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        validator: validatePhoneNumber,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(locationFocus);
                        },
                      ),
                    ),
                    mediumVertical,
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
                    mediumVertical,
                    PasswordTextField(
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
                    mediumVertical,
                    PasswordTextField(
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
              largeVertical,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: ElevatedButton(
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
                            GoRouter.of(context).go(Paths.home);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e is Exception
                                    ? e
                                        .toString()
                                        .replaceAll('Exception: ', '')
                                    : "An unknown error occurred"),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text("Create Account"),
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
