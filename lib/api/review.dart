import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odyssey/model/review.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

Future<void> addReview(LocationReview review) {
  Map<String, dynamic> reviewMap = review.toJson();
  reviewMap["postedOn"] = FieldValue.serverTimestamp();
  return firestore.collection('Review').add(reviewMap);
}

Future<List<LocationReview>> fetchReviews({String? userEmail, String? locationId}) async {
  Query<Map<String, dynamic>> locationRef = firestore.collection('Review');

  if (userEmail != null) {
    locationRef = locationRef.where('email', isEqualTo: userEmail);
  }
  if (locationId != null) {
    locationRef = locationRef.where('locationId', isEqualTo: locationId);
  }

  locationRef = locationRef.orderBy('postedOn', descending: true);

  final querySnapshot = await locationRef.get();

  // Log documents properly
  for (var doc in querySnapshot.docs) {
    print('Document ID: ${doc.id}');
    print('Document Data: ${doc.data()}');
  }

  // Map documents to LocationReview objects
  return querySnapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id; // Add document ID to the data map
    return LocationReview.fromJson(data);
  }).toList();
}
