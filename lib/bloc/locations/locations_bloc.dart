import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:odyssey/api/get_locations.dart';
import 'package:odyssey/model/location.dart';

part 'locations_event.dart';
part 'locations_state.dart';

class LocationsBloc extends Bloc<LocationsEvent, LocationsState> {
  LocationsBloc() : super(LocationsSuccess([])) {
    on<FetchLocations>((event, emit) async {
      emit(LocationsLoading());
      try {
        final locations = await fetchLocationsFromFirestore();
        emit(LocationsSuccess(locations));
      } catch (e) {
        emit(LocationsError(e.toString()));
      }
    });
  }
}
