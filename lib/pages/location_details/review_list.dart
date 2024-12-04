import 'package:flutter/material.dart';
import 'package:odyssey/model/review.dart';

class ReviewList extends StatelessWidget {
  final List<LocationReview> reviews;

  const ReviewList({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Center(
        child: Text(
          "No reviews available.",
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true, // Adjust height for parent widgets
      physics: NeverScrollableScrollPhysics(), // Disable internal scrolling
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        child: Text(
                          review.email != null && review.email!.isNotEmpty
                              ? review.email!.substring(0, 1).toUpperCase()
                              : "?",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          review.email ?? "Anonymous",
                          style: Theme.of(context).textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Text(
                        'Rating: ${review.rating} / 5',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.0),
                  Text(
                    review.reviewText!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
