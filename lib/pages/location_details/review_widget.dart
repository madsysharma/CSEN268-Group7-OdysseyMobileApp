import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/api/review.dart';
import 'package:odyssey/model/location.dart';
import 'package:odyssey/model/review.dart';
import 'package:odyssey/pages/location_details/reviews_overview_widget.dart';
import 'package:odyssey/utils/paths.dart';
import 'review_list.dart';

class ReviewsWidget extends StatefulWidget {
  final LocationDetails locationDetails;
  const ReviewsWidget({super.key, required this.locationDetails});

  @override
  State<ReviewsWidget> createState() => _ReviewsWidgetState();
}

class _ReviewsWidgetState extends State<ReviewsWidget> {
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
  future: fetchReviews(locationId: widget.locationDetails.id!),
  builder: (BuildContext context, AsyncSnapshot<List<LocationReview>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20.0),
            Text("Loading..."),
          ],
        ),
      );
    } else if (snapshot.hasError) {
      print('Error fetching reviews: ${snapshot.error}');
      return Center(
        child: Text("Something went wrong. Please try again."),
      );
    } else if (!snapshot.hasData) {
      return Center(
        child: Text("No reviews available."),
      );
    }

    final reviews = snapshot.data!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            context.push('/connect/you${Paths.post}', extra: widget.locationDetails);
          },
          child: Text("Write a Review"),
        ),
        SizedBox(height: 8),
        ReviewsOverViewWidget(reviews: reviews),
        SizedBox(height: 8),
        ReviewList(reviews: reviews),
      ],
    );
  },
);

  }
}
