import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';

class LocationRatingPage extends StatefulWidget {
  @override
  _LocationRatingPageState createState() => _LocationRatingPageState();
}

class _LocationRatingPageState extends State<LocationRatingPage> {
  bool isLoading = true;  //track page loading state
  GoogleMapController? mapController;
  double rating = 0;
  double? lat;
  double? lon;
  Set<Marker> markers = {};
  double? averageRating;
  String? city;
  bool hasRatings = false;
  String? userId;
  String? userRatingId;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _getUserLocation() async {
    Position position = await getUserLocation();
    setState(() {
      lat = position.latitude;
      lon = position.longitude;
      markers.add(Marker(
        markerId: MarkerId('currentLocation'),
        position: LatLng(lat!, lon!),
      ));
    });

    await fetchCityFromCoordinates(lat!, lon!);
    if (city != null && userId != null) {
      fetchAverageRating(city!);
      checkUserRating(city!);
      // Fetch reports of the city
      fetchCityReports(city!);
    }
  }

  Future<Position> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> fetchCityFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        setState(() {
          city = placemarks[0].locality; 
        });
      }
      setState(() {
      // Set loading to false after all data is fetched
      isLoading = false;
    });
    } catch (e) {
      print('Error getting city from coordinates: $e');
    }
  }

  // Fetch average rating for the location
  Future<void> fetchAverageRating(String city) async {
    var ratingsQuery = await FirebaseFirestore.instance
        .collection('Rate')
        .doc(city)
        .collection('ratings')
        .get();

    if (ratingsQuery.docs.isNotEmpty) {
      double totalRating = 0;
      int count = ratingsQuery.docs.length;
      
      for (var doc in ratingsQuery.docs) {
        totalRating += doc['rating'];
      }

      setState(() {
        averageRating = totalRating / count;
        hasRatings = true;
      });
    } else {
      setState(() {
        hasRatings = false;
      });
    }
  }

  // Fetch reports for the city and add markers
  Future<void> fetchCityReports(String city) async {
    var reportsQuery = await FirebaseFirestore.instance
        .collection('Rate')
        .doc(city)
        .collection('reports')
        .get();

    for (var doc in reportsQuery.docs) {
      double latitude = doc['latitude'].toDouble();
      double longitude = doc['longitude'].toDouble();
      setState(() {
        markers.add(Marker(
          markerId: MarkerId('report_${doc.id}'),
          position: LatLng(latitude, longitude),
          // Red flag icon
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), 
        ));
      });
    }
  }

  // check if the user has already rated the location
  Future<void> checkUserRating(String city) async {
    if (userId != null) {
      var userRatingDoc = await FirebaseFirestore.instance
          .collection('Rate')
          .doc(city)
          .collection('ratings')
          .where('userId', isEqualTo: userId)
          .get();

      if (userRatingDoc.docs.isNotEmpty) {
        setState(() {
          rating = userRatingDoc.docs[0]['rating'];
          userRatingId = userRatingDoc.docs[0].id;
        });
      }
    }
  }

  // save or update the rating for the user
  void saveRating(double rating, String city) async {
    final rateCollection = FirebaseFirestore.instance.collection('Rate');
    if (userRatingId == null) {
      await rateCollection.doc(city).collection('ratings').add({
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
      }).then((value) {
        _showDialog('Success', 'Your rating has been saved.');
      }).catchError((error) {
        _showDialog('Error', 'There was an error saving your rating: $error');
      });
    } else {
      await rateCollection.doc(city).collection('ratings').doc(userRatingId).update({
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      }).then((value) {
        _showDialog('Success', 'Your rating has been updated.');
      }).catchError((error) {
        _showDialog('Error', 'There was an error updating your rating: $error');
      });
    }
  }

  // report security problems
  // add current location to reports collection
  void reportSecurityProblems(String city) async {
    if (lat != null && lon != null && city != null) {
      await FirebaseFirestore.instance.collection('Rate').doc(city).collection('reports').add({
        'latitude': lat,
        'longitude': lon,
        'timestamp': FieldValue.serverTimestamp(),
      }).then((value) {
        _showDialog('Success', 'Your report has been submitted.');
        // fetch the markers after reporting
        fetchCityReports(city); 
      }).catchError((error) {
        _showDialog('Error', 'There was an error submitting your report: $error');
      });
    }
  }

  // Function to show dialog
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildRatingField() {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      itemSize: 40,
      direction: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, _) => Icon(
        Icons.star,
        color: Colors.amber,
      ),
      onRatingUpdate: (rating) {
        setState(() {
          this.rating = rating;
        });
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 189, 220, 204),
        title: const Text("Security Rating"),
        centerTitle: true,
      ),
    body: isLoading
      ? Center(  // Show loading screen when isLoading is true
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Loading spinner
              CircularProgressIndicator(), 
              SizedBox(height: 20),
              Text('Page Loading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      : Column(
      children: [
        // Explain the page
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'View Security Ratings around your location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        
        // Map section
        SizedBox(
          height: MediaQuery.of(context).size.height / 2,
          child: lat != null && lon != null
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(lat!, lon!),
                    zoom: 14.0,
                  ),
                  markers: markers,
                  onMapCreated: (controller) => mapController = controller,
                )
              : Center(child: CircularProgressIndicator()),
        ),
        
        // SingleChildScrollView for other elements
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10),
                Text(
                  'You are currently in: ${city}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: hasRatings
                      ? Text(
                          'Average Safety Rating: ${averageRating!.toStringAsFixed(1)} ★',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        )
                      : Text(
                          'No safety rating now, need your contributions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: buildRatingField(),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (city != null) {
                      saveRating(rating, city!);
                    }
                  },
                  child: Text(userRatingId == null ? 'Submit Rating' : 'Update Rating', style: TextStyle(fontSize: 15)),
                ),
                // Report security problems button
                ElevatedButton(
                  onPressed: () {
                    if (city != null) {
                      reportSecurityProblems(city!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Color.fromARGB(255, 255, 255, 255),
                  ),
                  child: Text('Report Security Issues', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

}

