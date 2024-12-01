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
  List<String> tags;

  LocationDetails(
      {this.id,
      required this.name,
      required this.city,
      required this.images,
      required this.description,
      required this.coordinates,
      required this.tags});

  static LocationDetails fromJson(Map<String, dynamic> json) =>
      _$LocationDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$LocationDetailsToJson(this);
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
