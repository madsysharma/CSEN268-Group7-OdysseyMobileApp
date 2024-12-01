import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odyssey/model/location.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

Future<List<LocationDetails>> fetchLocationsFromFirestore() async {
  try {
    // Fetch all location documents
    QuerySnapshot snapshot = await firestore.collection('locations').get();
    List<LocationDetails> locations = [];
    for (var doc in snapshot.docs) {
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