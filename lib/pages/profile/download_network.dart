import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:odyssey/components/navigation/app_bar.dart';
import 'package:odyssey/utils/spaces.dart';

class DownloadNetworkPage extends StatefulWidget {
  const DownloadNetworkPage({super.key});

  @override
  State<DownloadNetworkPage> createState() => DownloadNetworkPageState();
}

class DownloadNetworkPageState extends State<DownloadNetworkPage> {
  String? selectedOption = ''; 

  @override
  void initState() {
    super.initState();
    _fetchNetworkPreference();
  }

  Future<String?> getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid; 
  }

  Future<void> _fetchNetworkPreference() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception("User not logged in.");
      }

      final docSnapshot =
          await FirebaseFirestore.instance.collection('User').doc(userId).get();

      if (docSnapshot.exists) {
        setState(() {
          selectedOption = docSnapshot.data()?['networkPref'] ?? 'Wi-Fi';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching network preference: $e')),
      );
    }
  }

  Future<void> saveNetworkPreference() async {
    try {
      final userId = await getCurrentUserId();
      debugPrint("User ID: $userId"); 
      if (userId == null) {
        throw Exception("User not logged in.");
      }

      await FirebaseFirestore.instance
          .collection('User')
          .doc(userId)
          .update({'networkPref': selectedOption});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network preference saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preference: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: "Maps Download Network"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: smallPadding,
              child: Text(
                "How would you like to download your data?",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            RadioListTile<String>(
              title: Text('Wi-Fi'),
              value: 'Wi-Fi',
              groupValue: selectedOption,
              onChanged: (value) {
                setState(() {
                  selectedOption = value;
                });
              },
            ),
            RadioListTile<String>(
              title: Text('Cellular'),
              value: 'Cellular',
              groupValue: selectedOption,
              onChanged: (value) {
                setState(() {
                  selectedOption = value;
                });
              },
            ),
            RadioListTile<String>(
              title: Text('Both'),
              value: 'Both',
              groupValue: selectedOption,
              onChanged: (value) {
                setState(() {
                  selectedOption = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveNetworkPreference,
              child: Text('Save Preference'),
            ),
          ],
        ),
      ),
    );
  }
}
