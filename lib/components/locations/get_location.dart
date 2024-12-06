import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc; 
import 'package:geocoding/geocoding.dart'; 

class LocationWidget extends StatefulWidget {
  const LocationWidget({Key? key}) : super(key: key);

  @override
  _LocationWidgetState createState() => _LocationWidgetState();
}

class LocationHelper {
  static final loc.Location _location = loc.Location();

  static Future<loc.LocationData?> getCurrentCoordinates() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return null;
      }

      loc.PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return null;
      }

      return await _location.getLocation();
    } catch (e) {
      print("Error fetching location: $e");
      return null;
    }
  }
}

class _LocationWidgetState extends State<LocationWidget> {
  loc.Location location = loc.Location(); 
  String? _currentLocation;
  String? _currentAddress;
  bool _isFetching = false;

  Future<void> _getLocation() async {
    setState(() {
      _isFetching = true;
    });

    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _currentLocation = "Location services are disabled.";
            _isFetching = false;
          });
          return;
        }
      }

      loc.PermissionStatus permissionGranted = await location.hasPermission(); 
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          setState(() {
            _currentLocation = "Location permission denied.";
            _isFetching = false;
          });
          return;
        }
      }

      final locData = await location.getLocation();
      setState(() {
        _currentLocation =
            "Latitude: ${locData.latitude}, Longitude: ${locData.longitude}";
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
        locData.latitude!,
        locData.longitude!,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentAddress =
              "${place.locality}, ${place.administrativeArea}, ${place.country}";
        });
      }

      setState(() {
        _isFetching = false;
      });
    } catch (e) {
      setState(() {
        _currentLocation = "Failed to get location: $e";
        _isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _isFetching ? null : _getLocation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF006A68),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(_isFetching ? "Fetching..." : "Get Location"),
        ),
        SizedBox(height: 10),
        if (_currentLocation != null)
          Text(
            _currentLocation!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        if (_currentAddress != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "Address: $_currentAddress",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
      ],
    );
  }
}
