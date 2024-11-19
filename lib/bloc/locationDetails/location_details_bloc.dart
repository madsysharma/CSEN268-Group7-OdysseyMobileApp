import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:odyssey/api/get_locations.dart';
import 'package:odyssey/model/location.dart';

part 'location_details_bloc_event.dart';
part 'location_details_bloc_state.dart';

class LocationDetailsBloc
    extends Bloc<LocationDetailsBlocEvent, LocationDetailsBlocState> {
  LocationDetailsBloc() : super(LocationDetailsBlocInitial()) {
    on<FetchLocationDetails>((event, emit) async {
      emit(LocationDetailsLoading());
      try {
        final location =
            await fetchLocationDetailsFromFirestore(event.locationId);
        emit(LocationDetailsSuccess(location));
      } catch (e) {
        emit(LocationDetailsError(e.toString()));
      }
    });
  }
}
