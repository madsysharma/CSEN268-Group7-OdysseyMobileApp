part of 'locations_bloc.dart';

@immutable
sealed class LocationsEvent {}

class FetchLocations extends LocationsEvent {
  final String? searchQuery; 
  final int? proximity; 
  final String? category; 

  FetchLocations({
    this.searchQuery,
    this.proximity,
    this.category
  });
}
