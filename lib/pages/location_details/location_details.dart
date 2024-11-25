import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odyssey/bloc/locationDetails/location_details_bloc.dart';
import 'package:odyssey/pages/location_details/reviews_list.dart';
import 'package:odyssey/pages/location_details/reviews_overview_widget.dart';

class LocationDetailsPage extends StatefulWidget {
  final String locationId;
  const LocationDetailsPage({super.key, required this.locationId});

  @override
  State<LocationDetailsPage> createState() => _LocationDetailsPageState();
}

class _LocationDetailsPageState extends State<LocationDetailsPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<LocationDetailsBloc>()
        .add(FetchLocationDetails(widget.locationId));
  }

  Future<void> saveLocationToFavorites({
    required String name,
    required String description,
    required List<String> images,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in.");
      }

      // Reference to the user's savedLocations
      final savedLocationsRef = FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .collection('savedLocations');

      // Check if the location already exists
      final querySnapshot =
          await savedLocationsRef.where('name', isEqualTo: name).get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location is already saved!")),
        );
        return;
      }

      // Add the location
      await savedLocationsRef.add({
        'name': name,
        'description': description,
        'images': images,
        'createdAt': FieldValue.serverTimestamp(),
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

  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
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
                    Image.network(
                      state.location.images.first,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    Text(
                      state.location.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                    SizedBox(height: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical:16, horizontal:24),
                        child: ListView(
                          scrollDirection: Axis.vertical,
                          children: [
                            Text(
                              state.location.description,
                              style: theme.textTheme.bodyLarge,
                            ),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: isSaving
                                  ? null // Disable button while saving
                                  : () async {
                                      setState(() {
                                        isSaving = true;
                                      });
                                      await saveLocationToFavorites(
                                        name: state.location.name,
                                        description: state.location.description,
                                        images: state.location.images,
                                      );
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
                                  : Icon(Icons.favorite),
                              label: Text(
                                  isSaving ? "Saving..." : "Save Location"),
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            )
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
