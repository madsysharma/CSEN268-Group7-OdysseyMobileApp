import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:odyssey/model/contact.dart';

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
          radius: 25, 
          backgroundImage: contact.avatarUrl.isNotEmpty
              ? (Uri.parse(contact.avatarUrl).isAbsolute
                  ? NetworkImage(contact.avatarUrl) 
                  : FileImage(File(contact.avatarUrl))) 
              : null,
          child: contact.avatarUrl.isEmpty
              ? Icon(Icons.person, size: 30, color: Colors.grey)
              : null, 
        ),
        title: Text(
          contact.name,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          contact.number,
          style: TextStyle(color: Colors.black87),
        ),
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
