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

    // Fetch reviews for the location
    QuerySnapshot reviewSnapshot = await firestore
        .collection('locations')
        .doc(id)
        .collection('reviews')
        .get();
    List<Review> reviews = reviewSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Review.fromJson(data);
    }).toList();

    // Calculate ratings overview
    RatingsOverview ratingsOverview = _calculateRatingsOverview(reviews);

    locationDetails.reviews = Reviews(
      overview: ratingsOverview,
      reviews: reviews,
    );

    return locationDetails;
  } catch (e) {
    throw Exception("Error fetching location: $e");
  }
}

/// Helper function to calculate RatingsOverview from reviews
RatingsOverview _calculateRatingsOverview(List<Review> reviews) {
  int oneStar = 0, twoStar = 0, threeStar = 0, fourStar = 0, fiveStar = 0;

  for (var review in reviews) {
    switch (review.rating) {
      case 1:
        oneStar++;
        break;
      case 2:
        twoStar++;
        break;
      case 3:
        threeStar++;
        break;
      case 4:
        fourStar++;
        break;
      case 5:
        fiveStar++;
        break;
    }
  }
  return RatingsOverview(
      oneStar: oneStar,
      twoStar: twoStar,
      threeStar: threeStar,
      fourStar: fourStar,
      fiveStar: fiveStar);
}
