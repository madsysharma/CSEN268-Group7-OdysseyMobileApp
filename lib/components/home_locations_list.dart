import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/locations/locations_bloc.dart';
import 'package:odyssey/model/location.dart';
import 'package:odyssey/utils/paths.dart';

class HomeLocationsList extends StatelessWidget {
  const HomeLocationsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationsBloc, LocationsState>(
      builder: (context, state) {
        return Expanded(
          child: state is LocationsSuccess
              ? (state.locations.length > 0 ? ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: state.locations.length,
                  itemBuilder: (context, index) {
                    final location = state.locations[index];
                    return LocationCard(location: location);
                  },
                ) :Center(
                      child: Text("No Locations Found"),
                ))
              : state is LocationsLoading
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : state is LocationsError
                      ? Center(
                          child: Text("Error fetching locations"),
                        )
                      : Container(),
        );
      },
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
          context.push(Paths.locationDetails, extra: location.id!);
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
                    location.images.first,
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
