import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odyssey/bloc/locationDetails/location_details_bloc.dart';
import 'package:odyssey/pages/location_details/image_carousel.dart';
import 'package:odyssey/pages/location_details/review_list.dart';

class LocationDetailsPage extends StatefulWidget {
  final String locationId;
  const LocationDetailsPage({super.key, required this.locationId});

  @override
  State<LocationDetailsPage> createState() => _LocationDetailsPageState();
}

class _LocationDetailsPageState extends State<LocationDetailsPage> {
  bool isSaving = false;
  bool isSaved = false; // Track whether the location is already saved

  @override
  void initState() {
    super.initState();
    context
        .read<LocationDetailsBloc>()
        .add(FetchLocationDetails(widget.locationId));
    checkIfLocationIsSaved(); // Check if the location is saved on page load
  }

  Future<String?> getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Future<void> checkIfLocationIsSaved() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;

      final savedLocationsRef = FirebaseFirestore.instance
          .collection('User')
          .doc(userId)
          .collection('savedLocations');

      // Check if the location is already saved by matching the locationId
      final querySnapshot = await savedLocationsRef
          .where('locationId', isEqualTo: widget.locationId) // Match by ID
          .get();

      setState(() {
        isSaved = querySnapshot.docs.isNotEmpty;
      });
    } catch (e) {
      debugPrint("Error checking saved location: $e");
    }
  }

  Future<void> saveLocationToFavorites({
    required String locationId,
    required String name,
    required String description,
    required List<String> images,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception("No user logged in.");
      }

      final savedLocationsRef = FirebaseFirestore.instance
          .collection('User')
          .doc(userId)
          .collection('savedLocations');

      await savedLocationsRef.add({
        'locationId': locationId, // Unique identifier
        'name': name,
        'description': description,
        'images': images,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        isSaved = true; // Mark as saved
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location saved to favorites!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save location: $e")),
      );
    }
  }

  Future<void> removeLocationFromFavorites(String locationId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception("No user logged in.");
      }

      final savedLocationsRef = FirebaseFirestore.instance
          .collection('User')
          .doc(userId)
          .collection('savedLocations');

      final querySnapshot = await savedLocationsRef
          .where('locationId', isEqualTo: locationId)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        isSaved = false; // Mark as not saved
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location removed from favorites!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove location: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationDetailsBloc, LocationDetailsBlocState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: state is LocationDetailsSuccess
              ? Column(
                  children: [
                    // Image.network(
                    //   state.location.images.first,
                    //   height: 250,
                    //   width: double.infinity,
                    //   fit: BoxFit.cover,
                    //   errorBuilder: (context, error, stackTrace) =>
                    //       Icon(Icons.image, size: 100, color: Colors.grey),
                    // ),
                    ImageCarousel(imageUrls: state.location.images),
                    SizedBox(height: 8),
                    Text(
                      state.location.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView(
                          scrollDirection: Axis.vertical,
                          children: [
                            Text(
                              state.location.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: isSaving
                                  ? null // Disable button while saving
                                  : () async {
                                      setState(() {
                                        isSaving = true;
                                      });
                                      if (isSaved) {
                                        await removeLocationFromFavorites(
                                          widget.locationId,
                                        );
                                      } else {
                                        await saveLocationToFavorites(
                                          locationId: widget.locationId,
                                          name: state.location.name,
                                          description:
                                              state.location.description,
                                          images: state.location.images,
                                        );
                                      }
                                      setState(() {
                                        isSaving = false;
                                      });
                                    },
                              icon: isSaving
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    )
                                  : Icon(
                                      isSaved
                                          ? Icons.remove_circle
                                          : Icons.favorite,
                                    ),
                              label: Text(
                                isSaving
                                    ? "Processing..."
                                    : isSaved
                                        ? "Remove Location"
                                        : "Save Location",
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: 8),
                            ReviewsWidget(
                                locationDetails: state.location)
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : state is LocationDetailsLoading
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : state is LocationDetailsError
                      ? Center(
                          child: Text(state.error),
                        )
                      : Container(),
        );
      },
    );
  }
}

