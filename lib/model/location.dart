import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

class Location {
  String name;
  String city;
  String img;

  Location({required this.name, required this.city, required this.img});

  getLocation() {}
}

@JsonSerializable()
class LocationDetails {
  String? id;
  String name;
  String city;
  List<String> images;
  GeoCoordinates coordinates;
  String description;
  // populated only in details
  Reviews? reviews;

  LocationDetails(
      {this.id,
      required this.name,
      required this.city,
      required this.images,
      required this.description,
      this.reviews,
      required this.coordinates});

  static LocationDetails fromJson(Map<String, dynamic> json) =>
      _$LocationDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$LocationDetailsToJson(this);
}

@JsonSerializable()
class Reviews {
  RatingsOverview? overview;
  List<Review> reviews;

  Reviews({this.overview, required this.reviews});

  static Reviews fromJson(Map<String, dynamic> json) => _$ReviewsFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewsToJson(this);
}

@JsonSerializable()
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

  static RatingsOverview fromJson(Map<String, dynamic> json) =>
      _$RatingsOverviewFromJson(json);

  Map<String, dynamic> toJson() => _$RatingsOverviewToJson(this);
}

@JsonSerializable()
class Review {
  String? id;
  String userEmail;
  String review;
  int rating;

  Review({
    this.id,
    required this.userEmail,
    required this.review,
    required this.rating,
  });

  static Review fromJson(Map<String, dynamic> json) {
    return _$ReviewFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}

@JsonSerializable()
class GeoCoordinates {
  final double latitude;
  final double longitude;

  GeoCoordinates({required this.latitude, required this.longitude});

  @override
  String toString() {
    return 'Latitude: $latitude, Longitude: $longitude';
  }

  static GeoCoordinates fromJson(Map<String, dynamic> json) =>
      _$GeoCoordinatesFromJson(json);

  Map<String, dynamic> toJson() => _$GeoCoordinatesToJson(this);
}
