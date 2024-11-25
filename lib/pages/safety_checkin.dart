import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odyssey/components/cards/location_card.dart';

class SafetyCheckin extends StatefulWidget {
  const SafetyCheckin({super.key});

  @override
  _SafetyCheckinState createState() => _SafetyCheckinState();
}

class _SafetyCheckinState extends State<SafetyCheckin> {
  late Future<List<Map<String, dynamic>>> locationsFuture;

  @override
  void initState() {
    super.initState();
    locationsFuture = fetchLocations();
  }


  // fetch location list from user's database
  Future<List<Map<String, dynamic>>> fetchLocations() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user logged in.");
    }

    final locationsSnapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .collection('savedLocations')
        .orderBy('createdAt', descending: true)
        .get();

    final locations = locationsSnapshot.docs.map((doc) {
      final data = doc.data();
      print("Fetched location data: $data");

      return {
        'id': doc.id,
        'imageUrl': (data['images'] != null && data['images'].isNotEmpty)
            ? data['images'][0]
            : 'https://img.freepik.com/free-vector/illustration-gallery-icon_53876-27002.jpg', // Use first image or default one
        'title': data['name'] ?? 'Untitled', // Map 'name' to 'title'
        'subtitle': data['description'] ?? 'No description', // Map 'description' to 'subtitle'
        'isChecked': false, // Default checked state
      };
    }).toList();

    return locations;
  } catch (e) {
    print("Error fetching locations: $e");
    throw Exception("Failed to fetch locations: $e");
  }
}



  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 189, 220, 204),
      title: const Text("Location Check-in"),
      centerTitle: true,
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: locationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Display message when there are no locations
          return const Center(
            child: Text(
              'No locations for checking now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        } else {
          final locations = snapshot.data!;
          return ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return LocationCard(
                imageUrl: location['imageUrl'],
                title: location['title'],
                subtitle: location['subtitle'],
                isChecked: location['isChecked'],
                onChecked: (checked) {
                  setState(() {
                    locations[index]['isChecked'] = checked;
                  });
                },
              );
            },
          );
        }
      },
    ),
  );
}
}