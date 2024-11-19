// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationDetails _$LocationDetailsFromJson(Map<String, dynamic> json) =>
    LocationDetails(
      id: json['id'] as String?,
      name: json['name'] as String,
      city: json['city'] as String,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      description: json['description'] as String,
      reviews: json['reviews'] == null
          ? null
          : Reviews.fromJson(json['reviews'] as Map<String, dynamic>),
      coordinates:
          GeoCoordinates.fromJson(json['coordinates'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LocationDetailsToJson(LocationDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city': instance.city,
      'images': instance.images,
      'coordinates': instance.coordinates,
      'description': instance.description,
      'reviews': instance.reviews,
    };

Reviews _$ReviewsFromJson(Map<String, dynamic> json) => Reviews(
      overview: json['overview'] == null
          ? null
          : RatingsOverview.fromJson(json['overview'] as Map<String, dynamic>),
      reviews: (json['reviews'] as List<dynamic>)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReviewsToJson(Reviews instance) => <String, dynamic>{
      'overview': instance.overview,
      'reviews': instance.reviews,
    };

RatingsOverview _$RatingsOverviewFromJson(Map<String, dynamic> json) =>
    RatingsOverview(
      oneStar: (json['oneStar'] as num).toInt(),
      twoStar: (json['twoStar'] as num).toInt(),
      threeStar: (json['threeStar'] as num).toInt(),
      fourStar: (json['fourStar'] as num).toInt(),
      fiveStar: (json['fiveStar'] as num).toInt(),
    );

Map<String, dynamic> _$RatingsOverviewToJson(RatingsOverview instance) =>
    <String, dynamic>{
      'oneStar': instance.oneStar,
      'twoStar': instance.twoStar,
      'threeStar': instance.threeStar,
      'fourStar': instance.fourStar,
      'fiveStar': instance.fiveStar,
    };

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
      id: json['id'] as String?,
      userEmail: json['userEmail'] as String,
      review: json['review'] as String,
      rating: (json['rating'] as num).toInt(),
    );

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
      'id': instance.id,
      'userEmail': instance.userEmail,
      'review': instance.review,
      'rating': instance.rating,
    };

GeoCoordinates _$GeoCoordinatesFromJson(Map<String, dynamic> json) =>
    GeoCoordinates(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$GeoCoordinatesToJson(GeoCoordinates instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
