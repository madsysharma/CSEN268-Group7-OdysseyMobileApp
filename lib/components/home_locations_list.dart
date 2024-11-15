import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/mockdata/locations.dart';
import 'package:odyssey/model/location.dart';
import 'package:odyssey/utils/paths.dart';

class HomeLocationsList extends StatelessWidget {
  const HomeLocationsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          return LocationCard(location: location);
        },
      ),
    );
  }
}

class LocationCard extends StatelessWidget {
  final LocationDetails location;

  const LocationCard({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          context.push(Paths.locationDetails, extra: location);
        },
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    location.img,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image, size: 100, color: Colors.grey),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  location.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 4),
                Text(
                  location.city,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ));
  }
}
