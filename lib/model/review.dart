import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

@JsonSerializable()
class LocationReview {
  String? reviewId;
  String? userId;
  String? email;
  String? username;
  List<String>? images;
  String? locationName;
  String? locationId;
  double? rating;
  String? reviewText;
  List<String>? tags;
  List<String>? tokens;
  
  @JsonKey(fromJson: _timestampToDateTime, toJson: _dateTimeToTimestamp)
  final DateTime? postedOn;

  // Constructor
  LocationReview({
    required this.userId,
    required this.email,
    this.images,
    required this.locationName,
    required this.locationId,
    this.rating,
    this.reviewText,
    this.tags,
    this.tokens,
    required this.username,
    this.postedOn,
    this.reviewId
  });

  // Connect the generated `fromJson` and `toJson` methods
  factory LocationReview.fromJson(Map<String, dynamic> json) => _$LocationReviewFromJson(json);
  Map<String, dynamic> toJson() => _$LocationReviewToJson(this);

    // Custom methods for conversion
  static DateTime? _timestampToDateTime(Timestamp? timestamp) {
    return timestamp?.toDate();
  }

  static Timestamp? _dateTimeToTimestamp(DateTime? dateTime) {
    return dateTime != null ? Timestamp.fromDate(dateTime) : null;
  }
}


class RatingsOverview {
  int oneStar;
  int twoStar;
  int threeStar;
  int fourStar;
  int fiveStar;

  RatingsOverview({
    required this.oneStar,
    required this.twoStar,
    required this.threeStar,
    required this.fourStar,
    required this.fiveStar,
  });

  static RatingsOverview fromReviews(List<LocationReview> reviews) {
    int oneStar = 0, twoStar = 0, threeStar = 0, fourStar = 0, fiveStar = 0;

  for (var review in reviews) {
    switch (review.rating) {
      case 1:
        oneStar++;
        break;
      case 2:
        twoStar++;
        break;
      case 3:
        threeStar++;
        break;
      case 4:
        fourStar++;
        break;
      case 5:
        fiveStar++;
        break;
    }
  }
  return RatingsOverview(
      oneStar: oneStar,
      twoStar: twoStar,
      threeStar: threeStar,
      fourStar: fourStar,
      fiveStar: fiveStar);
  }
}