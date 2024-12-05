import 'package:flutter/material.dart';
import 'package:odyssey/components/get_location.dart';
import 'package:odyssey/model/contact.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SharingPage extends StatefulWidget {
  const SharingPage({super.key});

  @override
  _SharingPageState createState() => _SharingPageState();
}

class _SharingPageState extends State<SharingPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
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

  Future<void> _sendLocation(Contact contact) async {
    try {
      final locData = await LocationHelper.getCurrentCoordinates();
      if (locData == null || locData.latitude == null || locData.longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to fetch location.")),
        );
        return;
      }

      final message = "My current location is: https://maps.google.com/?q=${locData.latitude},${locData.longitude}";
      final smsUrl = Uri.parse("sms:${contact.number}?body=$message");

      if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send SMS.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showContactOverlay(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: contact.avatarUrl.isNotEmpty
                  ? NetworkImage(contact.avatarUrl)
                  : null,
              child: contact.avatarUrl.isEmpty
                // Default icon if no avatar
                  ? Icon(Icons.person, size: 40)
                  : null,
            ),
            SizedBox(height: 10),
            Text('Phone: ${contact.number}'),
            SizedBox(height: 10),
            Text('Share your location with this contact?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _sendLocation(contact);
            },
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
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
        title: Text("Live Sharing"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              // Add the location widget
              child: LocationWidget(),
            ),
            Divider(),
            contacts.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.all(16),
                            backgroundColor: Color.fromARGB(255, 189, 220, 204),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => _showContactOverlay(contact),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                contact.name,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                contact.number,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
