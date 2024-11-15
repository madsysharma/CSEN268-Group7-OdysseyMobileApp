import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'search_page.dart'; // Import the SearchPage for place search

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  LatLng _center = const LatLng(37.7749, -122.4194); // Default location (San Francisco)
  Location _location = Location();
  late BitmapDescriptor customMarkerIcon;
  final Set<Marker> _markers = {};
  bool isLoading = false;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _placePredictions = [];
  LatLng? _destination;
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _setCustomMarker();
    _getUserLocation();
  }

  // Set custom marker icon
  void _setCustomMarker() async {
    customMarkerIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/marker.png', // Set your marker image
    );
  }

  // Get the current user location
  void _getUserLocation() async {
    var locationData = await _location.getLocation();
    setState(() {
      _center = LatLng(locationData.latitude!, locationData.longitude!);
    });
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _center, zoom: 14),
      ),
    );
  }

  // Navigate to the search page
  void _navigateToSearchPage() async {
    final selectedPlace = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(
          onPlaceSelected: _setSelectedPlace,
        ),
      ),
    );
  }

  // Set selected place on the map
  Future<void> _setSelectedPlace(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=AIzaSyDGbl_R3u5F1A9hVlpzDxF6AVgQMHp4hwM';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final location = data['result']['geometry']['location'];
      final placeLatLng = LatLng(location['lat'], location['lng']);
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: placeLatLng, zoom: 14),
        ),
      );
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId(data['result']['name']),
            position: placeLatLng,
            infoWindow: InfoWindow(title: data['result']['name']),
            icon: customMarkerIcon,
          ),
        );
        _destination = placeLatLng; // Set destination when place is selected
      });
    }
  }

  // Get directions from current location to the selected destination
  Future<void> _getDirections() async {
    if (_destination == null) return;
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_center.latitude},${_center.longitude}&destination=${_destination!.latitude},${_destination!.longitude}&key=YOUR_GOOGLE_MAPS_API_KEY';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    if (data['status'] == 'OK') {
      final route = data['routes'][0]['legs'][0];
      final startLocation = route['start_location'];
      final endLocation = route['end_location'];
      final polyline = data['routes'][0]['overview_polyline']['points'];

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('start'),
            position: LatLng(startLocation['lat'], startLocation['lng']),
            infoWindow: InfoWindow(title: 'Start'),
            icon: customMarkerIcon,
          ),
        );
        _markers.add(
          Marker(
            markerId: MarkerId('end'),
            position: LatLng(endLocation['lat'], endLocation['lng']),
            infoWindow: InfoWindow(title: 'End'),
            icon: customMarkerIcon,
          ),
        );
      });
      _addPolyline(polyline);
    }
  }

  // Decode polyline and add it to the map
  void _addPolyline(String polyline) {
    final polylinePoints = _decodePolyline(polyline);
    final polylineOptions = Polyline(
      polylineId: PolylineId('route'),
      color: Colors.blue,
      width: 5,
      points: polylinePoints,
    );
    setState(() {
      _polylines.add(polylineOptions);
    });
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0;
    int len = polyline.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Interface'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 14),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true, // Enable location button
            zoomControlsEnabled: true, // Enable zoom controls
            zoomGesturesEnabled: true,
            compassEnabled: true, // Enable compass
            mapToolbarEnabled: true, // Enable map toolbar (like Google Maps)
          ),
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: GestureDetector(
              onTap: _navigateToSearchPage, // Trigger search page on tap
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Places...',
                      suffixIcon: Icon(Icons.search),
                    ),
                    readOnly: true, // Make the text field non-editable
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: FloatingActionButton(
              onPressed: _getDirections, // Get directions
              child: Icon(Icons.directions),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _getUserLocation();
  }
}
