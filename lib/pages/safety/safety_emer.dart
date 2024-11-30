import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/components/cards/contact_item.dart';
import 'package:odyssey/model/contact.dart';

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

  List<Contact> contacts = [];
  // Variable to hold error message
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

  Future<void> _addContact(Contact newContact) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final docRef = await _firestore
        .collection('User')
        .doc(userId)
        .collection('Contacts')
        .add(newContact.toMap());

    setState(() {
      contacts.add(newContact.copyWith(id: docRef.id));
    });
  }

  Future<void> _editContact(Contact updatedContact) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || updatedContact.id == null) return;

    await _firestore
        .collection('User')
        .doc(userId)
        .collection('Contacts')
        .doc(updatedContact.id)
        .update(updatedContact.toMap());

    setState(() {
      final index =
          contacts.indexWhere((contact) => contact.id == updatedContact.id);
      if (index != -1) {
        contacts[index] = updatedContact;
      }
    });
  }

  Future<void> _deleteContact(Contact contactToDelete) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || contactToDelete.id == null) return;

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

  

void _showContactDialog({Contact? contact}) {
  final nameController = TextEditingController(text: contact?.name ?? '');
  final numberController = TextEditingController(
    text: contact?.number.replaceAll(RegExp(r'[\D]'), '') ?? '',
  );

  final _formKey = GlobalKey<FormState>();

  setState(() {
    errorMessage = '';
  });

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(contact == null ? 'Add Contact' : 'Edit Contact'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name cannot be empty';
                }
                if (value.length > 15) {
                  return 'Name cannot be more than 15 characters';
                }
                return null;
              },
            ),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final name = nameController.text;
              final rawNumber = numberController.text;

              // Format number to "+1 xxx-xxx-xxxx"
              final formattedNumber =
                  '+1 ${rawNumber.substring(0, 3)}-${rawNumber.substring(3, 6)}-${rawNumber.substring(6)}';

              final newContact = Contact(
                id: contact?.id,
                name: name,
                number: formattedNumber,
                avatarUrl: contact?.avatarUrl ?? '',
              );

              if (contact == null) {
                _addContact(newContact);
              } else {
                _editContact(newContact);
              }

              Navigator.of(context).pop();
            } else {
              setState(() {
                errorMessage = 'Please fix the errors';
              });
            }
          },
          child: Text('Save'),
        ),
      ],
    ),
  );
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
          );
        },
        separatorBuilder: (context, index) =>
            const SizedBox(height: 10),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

