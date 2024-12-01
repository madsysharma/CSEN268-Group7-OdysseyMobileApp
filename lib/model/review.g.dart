// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationReview _$LocationReviewFromJson(Map<String, dynamic> json) =>
    LocationReview(
      userId: json['userId'] as String,
      email: json['email'] as String,
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      locationName: json['locationName'] as String,
      locationId: json['locationId'] as String,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewText: json['reviewText'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      username: json['username'] as String,
      postedOn:
          LocationReview._timestampToDateTime(json['postedOn'] as Timestamp?),
    );

Map<String, dynamic> _$LocationReviewToJson(LocationReview instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'username': instance.username,
      'images': instance.images,
      'locationName': instance.locationName,
      'locationId': instance.locationId,
      'rating': instance.rating,
      'reviewText': instance.reviewText,
      'tags': instance.tags,
      'postedOn': LocationReview._dateTimeToTimestamp(instance.postedOn),
    };
