import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/model/contact.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  _ContactsPageState createState() => _ContactsPageState();
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
  final numberController = TextEditingController(text: contact?.number ?? '');

  // Create a GlobalKey for the Form
  final _formKey = GlobalKey<FormState>();

  // Reset error message on dialog opening
  setState(() {
    errorMessage = '';
  });

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(contact == null ? 'Add Contact' : 'Edit Contact'),
      content: Form(
        // Use the Form key to validate
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
                return null; // No error
              },
            ),
            TextFormField(
              controller: numberController,
              decoration: InputDecoration(
                labelText: 'Number',
                // Display error message
                errorText: errorMessage.isEmpty ? null : errorMessage,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                // Only digits for input
                FilteringTextInputFormatter.digitsOnly, 
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Number cannot be empty';
                }
                if (value.length > 15) {
                  return 'Number cannot be more than 15 characters';
                }
                if (value.contains(' ')) {
                  return 'Number cannot contain spaces';
                }
                if (!RegExp(r'^\d+$').hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
                // No error
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
              final number = numberController.text;

              final newContact = Contact(
                id: contact?.id,
                name: name,
                number: number,
                avatarUrl: contact?.avatarUrl ?? '',
              );

              if (contact == null) {
                _addContact(newContact);
              } else {
                _editContact(newContact);
              }

              Navigator.of(context).pop();
            } else {
              // If the form is invalid, display the error message
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

class ContactItem extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ContactItem({
    super.key,
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 189, 220, 204),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: contact.avatarUrl.isNotEmpty
              ? NetworkImage(contact.avatarUrl)
              : null,
          child: contact.avatarUrl.isEmpty ? Icon(Icons.person) : null,
        ),
        title: Text(contact.name, style: TextStyle(color: Colors.black)),
        subtitle: Text(contact.number, style: TextStyle(color: Colors.black87)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.black54),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
