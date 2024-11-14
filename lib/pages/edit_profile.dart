import 'package:flutter/material.dart';
import 'package:odyssey/components/forms/input.dart';
import 'package:odyssey/components/navigation/app_bar.dart';
import 'package:odyssey/components/navigation/bottom_bar.dart';
import 'package:odyssey/utils/spaces.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode firstNameFocus = FocusNode();
  final FocusNode lastNameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode numberFocus = FocusNode();
  final FocusNode locationFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(firstNameFocus);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    numberFocus.dispose();
    locationFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: MyAppBar(title: "Profile"),
        body: SingleChildScrollView(
          child: Column(
            children: [
              largeVertical,
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50.0,
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
                    Container(
                      width: 100.0,
                      height: 100.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              largeVertical,
              Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      MyTextField(
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
                      MyTextField(
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
                      MyTextField(
                        label: 'Email',
                        controller: _emailController,
                        focusNode: emailFocus,
                        nextFocusNode: numberFocus,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          return null;
                        },
                      ),
                      MyTextField(
                        label: 'Phone Number',
                        controller: _numberController,
                        focusNode: numberFocus,
                        nextFocusNode: locationFocus,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
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
                      MyTextField(
                        label: 'Password',
                        controller: _passwordController,
                        focusNode: passwordFocus,
                        nextFocusNode: null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                    ],
                    
                  )),
                  smallVertical,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton.extended(
                        onPressed: () {
                          final isValid = _formKey.currentState!.validate();
                          if (isValid == true) {
                            
                          }
                        },
                        label: const Text("Save"),
                      ),
                      mediumHorizontal
                    ],
                  ),
                  smallVertical
            ],
          ),
        ),
        bottomNavigationBar: MyBottomAppBar());
  }
}
