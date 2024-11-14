import 'package:flutter/material.dart';
import 'package:odyssey/model/contact.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> contacts = [
    Contact(name: 'John Doe', number: '123-456-7890', avatarUrl: ''),
    Contact(name: 'Jane Smith', number: '987-654-3210', avatarUrl: ''),
  ];

  void _addContact() {
    // Implement add contact functionality
  }

  void _editContact(Contact contact) {
    // Implement edit contact functionality
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
            onEdit: () => _editContact(contacts[index]),
          );
        },
        separatorBuilder: (context, index) => SizedBox(height: 10), // Adjust height for spacing
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        child: Icon(Icons.add),
      ),
    );
  }
}

class ContactItem extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;

  ContactItem({required this.contact, required this.onEdit});

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
        trailing: IconButton(
          icon: Icon(Icons.edit, color: Colors.black54),
          onPressed: onEdit,
        ),
      ),
    );
  }
}



