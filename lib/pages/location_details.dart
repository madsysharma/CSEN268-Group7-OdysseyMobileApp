import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odyssey/bloc/locationDetails/location_details_bloc.dart';

class LocationDetailsPage extends StatefulWidget {
  final String locationId;
  const LocationDetailsPage({super.key, required this.locationId});

  @override
  State<LocationDetailsPage> createState() => _LocationDetailsPageState();
}

class _LocationDetailsPageState extends State<LocationDetailsPage> {
  @override
  void initState() {
    context
        .read<LocationDetailsBloc>()
        .add(FetchLocationDetails(widget.locationId));
    super.initState();
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
                    Image.network(
                      state.location.images.first,
                      height: 400,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView(
                          scrollDirection: Axis.vertical,
                          children: [
                            Text(
                              state.location.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            SizedBox(height: 4),
                            Text(
                              state.location.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                      ),
                    )
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
