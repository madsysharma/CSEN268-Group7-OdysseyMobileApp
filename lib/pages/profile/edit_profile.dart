import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:odyssey/components/alerts/alert_dialog.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:odyssey/components/forms/input.dart';
import 'package:odyssey/components/navigation/app_bar.dart';
import 'package:odyssey/utils/spaces.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(firstNameFocus);
    });
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/profile_image.png';

    final savedImage = File(imagePath);

    if (await savedImage.exists()) {
      setState(() {
        _image = savedImage;
      });
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

  File? _image;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        print("Picked file path: ${pickedFile.path}");
        File tempImage = File(pickedFile.path);
        final savedImage = await _saveImage(tempImage);

        setState(() {
          _image = savedImage;
          avatarKey = UniqueKey();
        });

        PaintingBinding.instance.imageCache.clear();
      } else {
        showMessageSnackBar(context, "No image was selected");
      }
    } catch (e) {
      showMessageSnackBar(context, "Error loading image");
    }
  }

  Future<File> _saveImage(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_image.png';
      final savedImage = await image.copy(imagePath);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', imagePath);
      showMessageSnackBar(context, "New profile picture set");
      return savedImage;
    } catch (e) {
      showMessageSnackBar(context, "Error saving image");
      rethrow;
    }
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
                      backgroundImage: _image != null
                          ? FileImage(_image!) as ImageProvider
                          : null,
                      child: _image == null
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
                          if (EmailValidator.validate(_emailController.text) ==
                              false) {
                            return "Invalid email address";
                          }
                          return null;
                        },
                      ),
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
                    backgroundColor: colorScheme.primary,
                    onPressed: () {
                      final isValid = _formKey.currentState!.validate();
                      if (isValid == true) {}
                    },
                    label: Text("Save",
                        style: TextStyle(color: colorScheme.onPrimary)),
                  ),
                  mediumHorizontal
                ],
              ),
              smallVertical
            ],
          ),
        ));
  }
}
