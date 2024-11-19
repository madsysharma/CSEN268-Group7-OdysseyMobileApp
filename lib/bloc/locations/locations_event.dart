part of 'locations_bloc.dart';

@immutable
sealed class LocationsEvent {}

class FetchLocations extends LocationsEvent {}
