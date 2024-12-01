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

  // Build query with optional filters using where clauses (chained if necessary)
  if (userEmail != null) {
    locationRef = locationRef.where('email', isEqualTo: userEmail);
  }
  if (locationId != null) {
    locationRef = locationRef.where('locationId', isEqualTo: locationId);
  }
  final querySnapshot = await locationRef.get();
  print(querySnapshot);
  return querySnapshot.docs.map((e) => LocationReview.fromJson(e.data())).toList();
}