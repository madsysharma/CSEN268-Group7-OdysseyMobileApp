import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odyssey/model/location.dart';
import 'package:odyssey/utils/user_location.dart';
import 'package:geolocator/geolocator.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

Future<List<LocationDetails>> fetchLocationsFromFirestore({
  String? searchQuery,
  int? proximity,
  String? tag
}) async {
  try {
    Query<Map<String, dynamic>> collectionReference = firestore.collection('locations');
    // if(searchQuery != null) {
    //   collectionReference = collectionReference.where(
    //         'name',
    //         isGreaterThanOrEqualTo: searchQuery,
    //       ).where(
    //         'name',
    //         isLessThan: searchQuery + '\uf8ff', // Ensures prefix matches
    //       );
    // }

    // Fetch all location documents
    QuerySnapshot snapshot = await collectionReference.get();

    var filteredResults = snapshot.docs;
    if(searchQuery != null) {
      String lowerCaseQuery = searchQuery.toLowerCase();
      filteredResults = filteredResults.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final String docName = data['name'];

        // Check if the name contains the search query (case-insensitive)
        return docName.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    if(proximity != null) {
      Position userLocation = await getUserLocation();
      // Filter by proximity on the client-side
      filteredResults = filteredResults
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          GeoPoint geoPoint = data['coordinates'] as GeoPoint;

          // Calculate distance using the Haversine formula
          double distance = _calculateDistance(userLocation.latitude, userLocation.longitude, geoPoint.latitude, geoPoint.longitude);
          return distance <= (proximity); // Check if within the proximity
        })
        .toList();
    }

    if (tag != null) {
       filteredResults = filteredResults
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final tags = data['tags'] is List ? List<String>.from(data['tags']) : [];
          return tags.contains(tag);
        })
        .toList();
    }
    
    List<LocationDetails> locations = [];
    for (var doc in filteredResults) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      GeoPoint geoPoint = data['coordinates'] as GeoPoint;
      data['coordinates'] = GeoCoordinates(
        latitude: geoPoint.latitude,
        longitude: geoPoint.longitude,
      ).toJson();
      data['id'] = doc.id;
      locations.add(LocationDetails.fromJson(data));
    }
    return locations;
  } catch (e) {
    throw Exception("Error fetching locations: $e");
  }
}

Future<LocationDetails> fetchLocationDetailsFromFirestore(String id) async {
  try {
    DocumentSnapshot snapshot =
        await firestore.collection('locations').doc(id).get();
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    data['id'] = snapshot.id;
    GeoPoint geoPoint = data['coordinates'] as GeoPoint;
    data['coordinates'] = GeoCoordinates(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
    ).toJson();
    LocationDetails locationDetails = LocationDetails.fromJson(data);
    return locationDetails;
  } catch (e) {
    throw Exception("Error fetching location: $e");
  }
}

// Haversine formula to calculate the distance between two points
double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
  const double piDiv180 = pi / 180.0;
  const double earthRadiusInMiles = 3958.8; // Earth's radius in miles

  double dLat = (lat2 - lat1) * piDiv180;
  double dLng = (lng2 - lng1) * piDiv180;

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * piDiv180) * cos(lat2 * piDiv180) * sin(dLng / 2) * sin(dLng / 2);

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusInMiles * c; // Distance in miles
}