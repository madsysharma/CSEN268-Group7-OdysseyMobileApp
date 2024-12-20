import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odyssey/mockdata/locations.dart';

Future<void> updateFirestoreFromMockData() async {
  // Get the Firestore instance
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Step 1: Clean existing data
    print("Cleaning existing data...");
    QuerySnapshot existingLocations =
        await firestore.collection('locations').get();

    for (QueryDocumentSnapshot doc in existingLocations.docs) {
      await doc.reference.delete();
    }

    QuerySnapshot existingReviews =
        await firestore.collection('Reviews').get();
    for (QueryDocumentSnapshot doc in existingReviews.docs) {
      await doc.reference.delete();
    }

    print("Existing data cleaned.");
  } catch (e) {
    print("Error cleaning existing data: $e");
  }

  try {
    // Iterate through the locations
    for (var location in locations) {
      // Prepare the location data
      Map<String, dynamic> locationData = {
        "name": location.name,
        "city": location.city,
        "coordinates": GeoPoint(
          location.coordinates.latitude,
          location.coordinates.longitude,
        ),
        "images": location.images,
        "description": location.description,
        "tags": location.tags
      };

      // Add the location to Firestore
      DocumentReference locationRef =
          await firestore.collection('locations').add(locationData);

      print("Added location: ${location.name}");
    }
  } catch (e) {
    print("Error updating Firestore: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Call the update function
  await updateFirestoreFromMockData();
}
