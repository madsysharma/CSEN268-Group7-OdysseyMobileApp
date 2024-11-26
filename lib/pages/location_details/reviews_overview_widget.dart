import 'package:flutter/material.dart';
import 'package:odyssey/model/location.dart';

class ReviewsOverViewWidget extends StatelessWidget {
  final Reviews reviews;

  ReviewsOverViewWidget({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final totalReviews = reviews.reviews.length;
    final overview = reviews.overview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Reviews ($totalReviews)",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        if (overview != null) ...[
          _buildRatingRow(5, overview.fiveStar, totalReviews),
          _buildRatingRow(4, overview.fourStar, totalReviews),
          _buildRatingRow(3, overview.threeStar, totalReviews),
          _buildRatingRow(2, overview.twoStar, totalReviews),
          _buildRatingRow(1, overview.oneStar, totalReviews),
        ],
      ],
    );
  }

  Widget _buildRatingRow(int star, int count, int totalReviews) {
    final proportion = totalReviews > 0 ? count / totalReviews : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text("$star ★", style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: proportion,
              backgroundColor: Colors.white,
              color: Colors.grey[300],
            ),
          ),
          SizedBox(width: 8),
          Text("$count"),
        ],
      ),
    );
  }
}