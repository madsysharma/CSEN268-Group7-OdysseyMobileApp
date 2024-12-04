import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/api/review.dart';
import 'package:odyssey/model/location.dart';
import 'package:odyssey/model/review.dart';
import 'package:odyssey/pages/location_details/reviews_overview_widget.dart';
import 'package:odyssey/utils/paths.dart';

class ReviewsWidget extends StatelessWidget {
  final LocationDetails locationDetails;
  const ReviewsWidget({super.key, required this.locationDetails});

 @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchReviews(locationId: locationDetails.id!),
      builder: (BuildContext context, AsyncSnapshot<List<LocationReview>> snapshot) { 
        if(snapshot.connectionState == ConnectionState.waiting){
          return Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20.0,),
                Text("Loading...")
              ],
            )
          );
        }
        else if(snapshot.hasError){
          print('Error: ${snapshot.error}');
          return Center(
            child: Text("Something went wrong. Please try again."),
            );
        }
      var reviews = snapshot.data!;
      return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
         ElevatedButton(onPressed: () {
            context.push('/connect/you' + Paths.post, extra: locationDetails);
         }, child: Text("Write a Review")),
         SizedBox(height: 8),   
         ReviewsOverViewWidget(reviews: reviews),
         SizedBox(height: 8),
        _ReviewList(reviews: reviews)],
      );
    });
  }
}

class _ReviewList extends StatelessWidget {
  final List<LocationReview> reviews;
  
  const _ReviewList({required this.reviews});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
          children: [
            for (var i = 0; i < reviews.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      child:
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reviews[i].email ?? "",
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              'Rating: ${reviews[i].rating} / 5',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              reviews[i].reviewText ?? "",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                    ),
                  ],
                ),
              ),
              if (i != reviews.length - 1) Divider(), // Separator line
            ],
          ],
        ),
      );
  }
}