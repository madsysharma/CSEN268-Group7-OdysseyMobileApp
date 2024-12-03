import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:odyssey/model/contact.dart';

class ContactItem extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCall; 

  const ContactItem({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    required this.onCall, 
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: contact.avatarUrl.isNotEmpty
            ? NetworkImage(contact.avatarUrl)
            : null,
        child: contact.avatarUrl.isEmpty ? Icon(Icons.person) : null,
      ),
      title: Text(contact.name),
      subtitle: Text(contact.number),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.phone),
            onPressed: onCall, 
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
