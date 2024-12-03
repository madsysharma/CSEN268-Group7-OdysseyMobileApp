import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/components/cards/contact_item.dart';
import 'package:odyssey/model/contact.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:odyssey/utils/image_picker_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = digits;

    if (digits.length >= 4 && digits.length <= 6) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else if (digits.length > 6) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ContactsPageState extends State<ContactsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Contact> contacts = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await _firestore
        .collection('User')
        .doc(userId)
        .collection('Contacts')
        .get();

    setState(() {
      contacts = snapshot.docs
          .map((doc) => Contact(
                id: doc.id,
                name: doc['name'],
                number: doc['number'],
                avatarUrl: doc['avatarUrl'],
              ))
          .toList();
    });
  }

  Future<void> _addContact(Contact newContact, {File? imageFile}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    String avatarUrl = newContact.avatarUrl;


    if (imageFile != null) {
      avatarUrl = await uploadImageToFirebase(imageFile) ?? '';
    }


    final contactData = newContact.copyWith(avatarUrl: avatarUrl).toMap();
    final docRef = await _firestore
        .collection('User')
        .doc(userId)
        .collection('Contacts')
        .add(contactData);

    setState(() {
      contacts.add(newContact.copyWith(id: docRef.id, avatarUrl: avatarUrl));
    });
  }

  Future<void> _editContact(Contact updatedContact, {File? imageFile}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || updatedContact.id == null) return;

    String avatarUrl = updatedContact.avatarUrl;


    if (imageFile != null) {
      avatarUrl = await uploadImageToFirebase(imageFile) ?? avatarUrl;
    }


    final contactData = updatedContact.copyWith(avatarUrl: avatarUrl).toMap();
    await _firestore
        .collection('User')
        .doc(userId)
        .collection('Contacts')
        .doc(updatedContact.id)
        .update(contactData);

    setState(() {
      final index =
          contacts.indexWhere((contact) => contact.id == updatedContact.id);
      if (index != -1) {
        contacts[index] = updatedContact.copyWith(avatarUrl: avatarUrl);
      }
    });
  }

  Future<void> _deleteContact(Contact contactToDelete) async {
  final userId = _auth.currentUser?.uid;
  if (userId == null || contactToDelete.id == null) return;

  // confirm before deleting
  final bool? shouldDelete = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete Contact'),
        content: Text('Are you sure you want to delete this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      );
    },
  );


  if (shouldDelete == true) {
    await _firestore
        .collection('User')
        .doc(userId)
        .collection('Contacts')
        .doc(contactToDelete.id)
        .delete();

    setState(() {
      contacts.removeWhere((contact) => contact.id == contactToDelete.id);
    });
  }
}


  Future<String?> uploadImageToFirebase(File imageFile) async {
    try {
      final storageRef = _storage.ref().child('contacts/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  void _showContactDialog({Contact? contact}) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final numberController = TextEditingController(
      text: contact?.number.replaceAll(RegExp(r'[\D]'), '') ?? '',
    );

    File? selectedImage;
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact == null ? 'Add Contact' : 'Edit Contact'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name Input
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name cannot be empty';
                  }
                  return null;
                },
              ),
              // Phone Number Input
              TextFormField(
              controller: numberController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number cannot be empty';
                }
                if (value.length != 10) {
                  return 'Please enter US phone number';
                }
                return null;
              },
            ),
              // Image Picker
              GestureDetector(
                onTap: () async {
                  final image = await pickImage(context, ImageSource.gallery);
                  setState(() {
                    selectedImage = image;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(50),
                    image: selectedImage != null
                        ? DecorationImage(
                            image: FileImage(selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: selectedImage == null
                      ? Icon(Icons.camera_alt, color: Colors.grey[700])
                      : null,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final name = nameController.text;
                final rawNumber = numberController.text;
                // Format number to "+1 xxx-xxx-xxxx"
                final formattedNumber =
                  '+1 ${rawNumber.substring(0, 3)}-${rawNumber.substring(3, 6)}-${rawNumber.substring(6)}';

                final newContact = Contact(
                  name: name,
                  number: formattedNumber,
                  avatarUrl: contact?.avatarUrl ?? '',
                );

                if (contact == null) {
                  await _addContact(newContact, imageFile: selectedImage);
                } else {
                  await _editContact(
                    newContact.copyWith(id: contact.id),
                    imageFile: selectedImage,
                  );
                }

                Navigator.of(context).pop();
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _callContact(String phoneNumber) async {
  final Uri callUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );

  if (await canLaunchUrl(callUri)) {
    await launchUrl(callUri);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not launch the dialer for $phoneNumber')),
    );
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Color.fromARGB(255, 189, 220, 204),
      title: Text("Emergency Contact"),
      centerTitle: true,
    ),
    body: ListView.separated(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        return ContactItem(
          contact: contacts[index],
          onEdit: () => _showContactDialog(contact: contacts[index]),
          onDelete: () => _deleteContact(contacts[index]),
          onCall: () => _callContact(contacts[index].number), 
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showContactDialog(),
      child: Icon(Icons.add),
    ),
  );
}
}

