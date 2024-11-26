import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    context
        .read<LocationDetailsBloc>()
        .add(FetchLocationDetails(widget.locationId));
    super.initState();
  }

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
                            ReviewsOverViewWidget(reviews: state.location.reviews!),
                            SizedBox(height: 8),
                            ElevatedButton(onPressed: () {}, child: Text("Write a Review"), style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.primary),
                              foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.onPrimary),
                            )),
                            SizedBox(height: 8),
                            ReviewsList(reviews: state.location.reviews!)
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
