import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

@JsonSerializable()
class LocationReview {
  String userId;
  String email;
  String username;
  List<String>? images;
  String locationName;
  String locationId;
  double? rating;
  String? reviewText;
  List<String>? tags;
  
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
    required this.username,
    this.postedOn,
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