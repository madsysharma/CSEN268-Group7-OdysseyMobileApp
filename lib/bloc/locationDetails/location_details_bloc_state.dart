part of 'location_details_bloc.dart';

@immutable
sealed class LocationDetailsBlocState {}

final class LocationDetailsBlocInitial extends LocationDetailsBlocState {}

final class LocationDetailsLoading extends LocationDetailsBlocState {}

final class LocationDetailsSuccess extends LocationDetailsBlocState {
  final LocationDetails location;

  LocationDetailsSuccess(this.location);
}

final class LocationDetailsError extends LocationDetailsBlocState {
  final String error;
  LocationDetailsError(this.error);
}
