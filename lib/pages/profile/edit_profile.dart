import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:odyssey/components/alerts/alert_dialog.dart';
import 'package:odyssey/components/forms/input.dart';
import 'package:odyssey/components/navigation/app_bar.dart';
import 'package:odyssey/utils/spaces.dart';
import 'package:odyssey/utils/image_picker_utils.dart';
import 'package:path_provider/path_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  // ignore: unused_field
  PhoneNumber? _phoneNumber;

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
  Key avatarKey = UniqueKey();
  String? getCurrentUserId() {
    final User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Future<void> _checkAndSaveProfile() async {
    try {
      final email = _emailController.text.trim();
      final phoneNumber = _numberController.text.trim();

      // Get current user ID
      final userId = getCurrentUserId();
      if (userId == null) {
        _showSnackBar("User not logged in. Please log in again.");
        return;
      }

      // Query Firestore for existing email
      final emailQuery = await FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: email)
          .get();

      // Query Firestore for existing phone number
      final phoneQuery = await FirebaseFirestore.instance
          .collection('User')
          .where('phonenumber', isEqualTo: phoneNumber)
          .get();

      // Check for duplicate email
      if (emailQuery.docs.isNotEmpty && emailQuery.docs.first.id != userId) {
        _showSnackBar("Email is already in use by another account.");
        return;
      }

      // Check for duplicate phone number
      if (phoneQuery.docs.isNotEmpty && phoneQuery.docs.first.id != userId) {
        _showSnackBar("Phone number is already in use by another account.");
        return;
      }

      // If no duplicates, save the profile
      await _saveProfile(userId);
    } catch (e) {
      _showSnackBar("An error occurred: ${e.toString()}");
    }
  }

  Future<void> _saveProfile(String userId) async {
    // Save updated profile information to Firestore
    await FirebaseFirestore.instance.collection('User').doc(userId).update({
      'firstname': _firstNameController.text.trim(),
      'lastname': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phonenumber': _numberController.text.trim(),
      'location': _locationController.text.trim(),
    });

    _showSnackBar("Profile updated successfully!");
  }

  Future<String?> _uploadImage(File imageFile, String userId) async {
    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('profile_images/$userId.png');
      final uploadTask = await storageRef.putFile(imageFile);

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _showSnackBar("Failed to upload image: $e");
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(firstNameFocus);
    });
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    final docSnapshot =
        await FirebaseFirestore.instance.collection('User').doc(userId).get();
    if (docSnapshot.exists && docSnapshot.data() != null) {
      final data = docSnapshot.data()!;
      final imageUrl = data['imageUrl'] as String?;

      if (imageUrl != null) {
        setState(() {
          image = File(imageUrl);
        });
      }
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
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    numberFocus.dispose();
    locationFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  File? image;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final File? imageSaved = await pickImage(context, source);

      if (imageSaved != null) {
        setState(() {
          image = imageSaved;
          avatarKey = UniqueKey();
        });

        final userId = getCurrentUserId();
        if (userId == null) {
          _showSnackBar("User not logged in. Please log in again.");
          return;
        }

        final imageUrl = await _uploadImage(imageSaved, userId);
        if (imageUrl != null) {
          final userRef =
              FirebaseFirestore.instance.collection('User').doc(userId);
          final docSnapshot = await userRef.get();

          if (docSnapshot.exists) {
            // Update existing document
            await updateImageUrl(userId, imageUrl);
          } else {
            // Create a new document
            await createUserWithImage(userId, imageUrl);
          }

          _showSnackBar("Profile image saved successfully!");
        }
      } else {
        _showSnackBar("No image was selected.");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  Future<void> createUserWithImage(String userId, String imageUrl) async {
  final userRef = FirebaseFirestore.instance.collection('User').doc(userId);

  // Create a new document with the `imageUrl` field and other required fields
  await userRef.set({
    'firstname': '', // You can include other default fields
    'lastname': '',
    'email': '',
    'phonenumber': '',
    'homelocation': '',
    'imageUrl': imageUrl, // Add the imageUrl
    'interests': ['', '', ''], // Add default interests or remove if unnecessary
    'membertype': '',
    'password': '',
  });
}

Future<void> updateImageUrl(String userId, String imageUrl) async {
  final userRef = FirebaseFirestore.instance.collection('User').doc(userId);

  // Update the `imageUrl` field in the existing document
  await userRef.update({
    'imageUrl': imageUrl, // Add or update the imageUrl field
  });
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

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => MyAlertDialog(
        title: 'Pick an Option',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Photo Library'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: MyAppBar(title: "Profile"),
        body: SingleChildScrollView(
          padding: pagePadding,
          child: Column(
            children: [
              largeVertical,
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      key: avatarKey,
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: image != null
                          ? FileImage(image!) as ImageProvider
                          : null,
                      child: image == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Container(
                      width: 100.0,
                      height: 100.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        shape: BoxShape.circle,
                      ),
                      child: TextButton(
                        onPressed: _showImageSourceDialog,
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                      mediumVertical,
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
                          if (EmailValidator.validate(_emailController.text) ==
                              false) {
                            return "Invalid email address";
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
                    ],
                  )),
              largeVertical,
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () async {
                    final isValid = _formKey.currentState!.validate();
                    if (isValid == true) {
                      await _checkAndSaveProfile();
                    }
                  },
                  child: Text("Save",
                      style: TextStyle(color: colorScheme.onPrimary)),
                ),
              ),
              mediumHorizontal,
              smallVertical
            ],
          ),
        ));
  }
}
