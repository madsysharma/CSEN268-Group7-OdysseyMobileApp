import 'package:flutter/material.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:odyssey/components/cards/favorite_locations.dart';
import 'package:odyssey/components/navigation/app_bar.dart';

class SavedLocations extends StatefulWidget {
  const SavedLocations({super.key});

  @override
  State<SavedLocations> createState() => SavedLocationsState();
}

class SavedLocationsState extends State<SavedLocations> {
  List<Map<String, dynamic>> favoriteLocations = [
    {
      'imageUrl': 'https://example.com/image1.jpg',
      'title': 'Lake Tahoe',
      'subtitle': 'Tahoe, California',
    },
    {
      'imageUrl': 'https://example.com/image2.jpg',
      'title': 'Yosemite',
      'subtitle': 'California, USA',
    },
    {
      'imageUrl': 'https://example.com/image3.jpg',
      'title': 'Napa Valley',
      'subtitle': 'California, USA',
    },
    {
      'imageUrl': 'https://example.com/image4.jpg',
      'title': 'San Francisco',
      'subtitle': 'California, USA',
    },
  ];

  void removeLocation(int index) {
    setState(() {
      favoriteLocations.removeAt(index);
    });
    showMessageSnackBar(
        context, "Location has been removed from saved locations.");
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: MyAppBar(
        title: 'Saved Locations',
      ),
      body: favoriteLocations.isEmpty
          ? const Center(
              child: Text('No favorite locations'),
            )
          : ListView.builder(
            padding: EdgeInsets.only(top: 10),
              itemCount: favoriteLocations.length,
              itemBuilder: (context, index) {
                final location = favoriteLocations[index];
                return Dismissible(
                  key: ValueKey(location['title']),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    removeLocation(index);
                  },
                  background: Container(
                      color: colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: Text("Remove Location",
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: colorScheme.onError, // Change the color to red
                              ))),
                  child: FavoriteLocations(
                    imageUrl: location['imageUrl'],
                    title: location['title'],
                    subtitle: location['subtitle'],
                    fallbackBackgroundColor: colorScheme.surfaceContainer,
                  ),
                );
              },
            ),
    );
  }
}
