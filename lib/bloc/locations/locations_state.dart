part of 'locations_bloc.dart';

@immutable
sealed class LocationsState {}

final class LocationsLoading extends LocationsState {}

final class LocationsSuccess extends LocationsState {
  final List<LocationDetails> locations;

  LocationsSuccess(this.locations);
}

final class LocationsError extends LocationsState {
  final String error;

  LocationsError(this.error);
}
