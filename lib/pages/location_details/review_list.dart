import 'package:flutter/material.dart';
import 'package:odyssey/model/location.dart';

class ReviewsList extends StatelessWidget {
  final Reviews reviews;
  const ReviewsList({super.key, required this.reviews});

 @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (var i = 0; i < reviews.reviews.length; i++) ...[
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
                            reviews.reviews[i].userEmail,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            'Rating: ${reviews.reviews[i].rating} / 5',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            reviews.reviews[i].review,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                  ),
                ],
              ),
            ),
            if (i != reviews.reviews.length - 1) Divider(), // Separator line
          ],
        ],
      ),
    );
  }
}