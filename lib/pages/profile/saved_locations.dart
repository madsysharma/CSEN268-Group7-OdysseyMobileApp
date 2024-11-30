import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:odyssey/components/cards/favorite_locations.dart';
import 'package:odyssey/components/navigation/app_bar.dart';

class SavedLocations extends StatefulWidget {
  const SavedLocations({super.key});

  @override
  State<SavedLocations> createState() => _SavedLocationsState();
}

class _SavedLocationsState extends State<SavedLocations> {
  late Future<List<Map<String, dynamic>>> favoriteLocationsFuture;

  @override
  void initState() {
    super.initState();
    favoriteLocationsFuture = fetchSavedLocations();
  }

  // Fetch saved locations from Firestore
  Future<List<Map<String, dynamic>>> fetchSavedLocations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in.");
      }

      final savedLocationsSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .collection('savedLocations')
          .orderBy('createdAt', descending: true) // Order by most recent
          .get();

      return savedLocationsSnapshot.docs.map((doc) {
        final data = doc.data();
        final images = data['images'] as List<dynamic>?; // Array of image URLs
        final imageUrl = (images != null && images.isNotEmpty)
            ? images[0]
            : ''; // Get the first URL or empty
        return {
          'id': doc.id, // Document ID for deletion
          'imageUrl': imageUrl,
          'title': data['name'] ?? 'Untitled',
          'subtitle': data['description'] ?? '',
        };
      }).toList();
    } catch (e) {
      throw Exception("Failed to fetch saved locations: $e");
    }
  }

  // Remove a location from Firestore
  Future<void> removeLocation(String locationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in.");
      }

      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .collection('savedLocations')
          .doc(locationId)
          .delete();

      showMessageSnackBar(
          context, "Location has been removed from saved locations.");
      setState(() {
        favoriteLocationsFuture = fetchSavedLocations(); // Refresh the UI
      });
    } catch (e) {
      showMessageSnackBar(context, "Failed to remove location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: MyAppBar(
        title: 'Saved Locations',
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: favoriteLocationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: colorScheme.error),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorite locations'));
          } else {
            final favoriteLocations = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: favoriteLocations.length,
              itemBuilder: (context, index) {
                final location = favoriteLocations[index];
                return Dismissible(
                  key: ValueKey(location['id']),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => removeLocation(location['id']),
                  background: Container(
                    color: colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      "Remove Location",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.onError,
                          ),
                    ),
                  ),
                  child: FavoriteLocations(
                    imageUrl: location['imageUrl'],
                    title: location['title'],
                    subtitle: location['subtitle'],
                    fallbackBackgroundColor: colorScheme.surfaceContainer,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
