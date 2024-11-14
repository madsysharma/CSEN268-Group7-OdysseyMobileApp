import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MyPageState();
}

class _MyPageState extends State<MapPage> {
  Location _locationController = Location();

  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
  static const LatLng _pApplePark = LatLng(37.334, -122.0090);
  LatLng? _currentP;
  Map<PolylineId, Polyline> polylines ={};

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then(
      (_) => {
        getPolylinePoints().then((coordinates)=>{
          generatePolylineFromPoints(coordinates),
        }),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentP == null
          ? const Center(
              child: Text('Waiting for location updates...'),
            )
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) =>
                  _mapController.complete(controller),
              initialCameraPosition: CameraPosition(
                target: _pGooglePlex,
                zoom: 10,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId("_currentLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _currentP!,
                ),
                const Marker(
                  markerId: MarkerId("_sourceLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _pGooglePlex,
                ),
                const Marker(
                  markerId: MarkerId("_destinationLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _pApplePark,
                ),
              },
              polylines: Set<Polyline>.of(polylines.values),
          ),
              
              
             /* {
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: polylineCoordinates,
                  color: Colors.blue,
                  width: 5,
                ),
              },
            ),*/
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition newCameraPosition = CameraPosition(target: pos, zoom: 10);
    await controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentP = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _cameraToPosition(_currentP!);
        });
      }
    });
  }

  List<LatLng> polylineCoordinates = [];

  Future<List<LatLng>> getPolylinePoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

  
    PolylineRequest request = PolylineRequest(
      origin: PointLatLng(_pGooglePlex.latitude, _pGooglePlex.longitude),
      destination: PointLatLng(_pApplePark.latitude, _pApplePark.longitude),
      mode: TravelMode.driving,
    );

    
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: "AIzaSyDGbl_R3u5F1A9hVlpzDxF6AVgQMHp4hwM",  
      request: request,
    );

    if (result.points.isNotEmpty) {
      setState(() {
        polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      });
    }else {
      print(result.errorMessage);
  }
  return polylineCoordinates;
  }
  void generatePolylineFromPoints(List<LatLng> polylineCoordinates) async{
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, 
        color: Colors.blue,
        points: polylineCoordinates, 
        width: 8 );

    setState(() {
      polylines[id] = polyline;
    });
  }
}
