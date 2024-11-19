part of 'location_details_bloc.dart';

@immutable
sealed class LocationDetailsBlocEvent {}

class FetchLocationDetails extends LocationDetailsBlocEvent {
  final String locationId;

  FetchLocationDetails(this.locationId);
}
