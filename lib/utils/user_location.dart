import 'package:geolocator/geolocator.dart';

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled, return an error.
    throw Exception('Location services are disabled.');
  }

  // Check location permissions
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, return an error.
      throw Exception('Location permissions are denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are permanently denied, handle appropriately.
    throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // Define location settings with desired accuracy
  LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high, // Specify high accuracy
    distanceFilter: 10, // Minimum distance in meters before updates
  );

  // Get the current position with the specified settings
  return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
}

Future<Position> getUserLocation() {
  return _determinePosition();
}
