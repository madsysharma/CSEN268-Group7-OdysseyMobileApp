import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';  // Import geolocator package
import '../config/config.dart'; 
import 'package:path_provider/path_provider.dart';  // Add this import
import 'dart:io';// Replace with your Google Maps API key configuration.


class SearchPage extends StatefulWidget {
 @override
 _SearchPageState createState() => _SearchPageState();
}


class _SearchPageState extends State<SearchPage> {
 String _startLocationQuery = '';
 String _endLocationQuery = '';
 bool _isLoading = false;
 LatLng? _startLocation;
 LatLng? _endLocation;
 Set<Marker> _markers = Set();
 Set<Polyline> _polylines = Set();
 GoogleMapController? _mapController;
 List<Map<String, dynamic>> _searchHistory = [];

 TextEditingController _startLocationController = TextEditingController();
 TextEditingController _endLocationController = TextEditingController();


 String _drivingTime = '';
 String _walkingTime = '';
 String _cyclingTime = '';
 String _transitTime = '';
 String _flightTime = '';


@override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadSearchHistory();  // Add this line
  }

  // Add this method to load search history
  Future<void> _loadSearchHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/search_history.json');
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        setState(() {
          _searchHistory = List<Map<String, dynamic>>.from(
            json.decode(contents),
          );
        });
      }
    } catch (e) {
      print('Error loading search history: $e');
    }
  }

  // Add this method to save search history
  Future<void> _saveSearch() async {
    if (_startLocation == null || _endLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Both locations must be set to save the search')),
      );
      return;
    }

    final searchData = {
      'timestamp': DateTime.now().toIso8601String(),
      'startLocation': {
        'address': _startLocationController.text,
        'lat': _startLocation!.latitude,
        'lng': _startLocation!.longitude,
      },
      'endLocation': {
        'address': _endLocationController.text,
        'lat': _endLocation!.latitude,
        'lng': _endLocation!.longitude,
      },
      'travelTimes': {
        'driving': _drivingTime,
        'walking': _walkingTime,
        'cycling': _cyclingTime,
        'transit': _transitTime,
        'flight': _flightTime,
      },
    };

    setState(() {
      _searchHistory.add(searchData);
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/search_history.json');
      await file.writeAsString(json.encode(_searchHistory));

      // Export as CSV
      final csv = await _exportAsCSV();
      final csvFile = File('${directory.path}/search_history.csv');
      await csvFile.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search history saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving search history: $e')),
      );
    }
  }

  // Add this method to export data as CSV
  Future<String> _exportAsCSV() async {
    final StringBuffer csv = StringBuffer();
    
    // Add headers
    csv.writeln('Timestamp,Start Location,Start Latitude,Start Longitude,'
        'End Location,End Latitude,End Longitude,'
        'Driving Time,Walking Time,Cycling Time,Transit Time,Flight Time');
    
    // Add data rows
    for (var search in _searchHistory) {
      csv.writeln(
        '${search['timestamp']},'
        '"${search['startLocation']['address']}",'
        '${search['startLocation']['lat']},'
        '${search['startLocation']['lng']},'
        '"${search['endLocation']['address']}",'
        '${search['endLocation']['lat']},'
        '${search['endLocation']['lng']},'
        '${search['travelTimes']['driving']},'
        '${search['travelTimes']['walking']},'
        '${search['travelTimes']['cycling']},'
        '${search['travelTimes']['transit']},'
        '${search['travelTimes']['flight']}'
      );
    }
    
    return csv.toString();
  }

  // Add this method to share the search history
  Future<void> _shareSearchHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final jsonFile = File('${directory.path}/search_history.json');
      final csvFile = File('${directory.path}/search_history.csv');

      if (!await jsonFile.exists() || !await csvFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No search history available to share')),
        );
        return;
      }

      // Show dialog to let user choose format
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Choose Export Format'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.file_present),
                  title: Text('JSON'),
                  onTap: () async {
                    Navigator.pop(context);
                    // Add your file sharing logic here for JSON
                    // You might want to use a file sharing plugin
                  },
                ),
                ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('CSV'),
                  onTap: () async {
                    Navigator.pop(context);
                    // Add your file sharing logic here for CSV
                    // You might want to use a file sharing plugin
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing search history: $e')),
      );
    }
  }

 // Function to get current location and update start location
 Future<void> _getCurrentLocation() async {
   setState(() {
     _isLoading = true;
   });


   try {
     // Check for location permission
     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
     LocationPermission permission = await Geolocator.checkPermission();


     if (!serviceEnabled || permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Location permissions are denied')),
       );
       return;
     }


     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
     LatLng currentLatLng = LatLng(position.latitude, position.longitude);


     setState(() {
       _startLocation = currentLatLng;
       _markers.add(Marker(
         markerId: MarkerId('start'),
         position: currentLatLng,
         infoWindow: InfoWindow(title: 'Current Location'),
       ));
     });


     // Move camera to the current location
     _moveCameraToLocation(currentLatLng);


     // Reverse geocode the current location to get an address and update the start location text
     _getAddressFromCoordinates(currentLatLng);
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Error fetching current location: $e')),
     );
   } finally {
     setState(() {
       _isLoading = false;
     });
   }
 }


 // Function to reverse geocode and get the address from coordinates
 Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
   try {
     final response = await http.get(
       Uri.parse(
         'https://maps.googleapis.com/maps/api/geocode/json?latlng=${coordinates.latitude},${coordinates.longitude}&key=${Config.googleApiKey}',
       ),
     );


     if (response.statusCode == 200) {
       final data = json.decode(response.body);
       if (data['results'].isNotEmpty) {
         final address = data['results'][0]['formatted_address'];
         setState(() {
           _startLocationController.text = address ?? 'Current Location';
         });
       } else {
         setState(() {
           _startLocationController.text = 'Current Location';
         });
       }
     } else {
       setState(() {
         _startLocationController.text = 'Error fetching address';
       });
     }
   } catch (e) {
     setState(() {
       _startLocationController.text = 'Error fetching address';
     });
   }
 }


 // Function to get directions and travel times
 Future<void> _getDirections() async {
   if (_startLocation == null || _endLocation == null) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Both start and end locations are required to get directions')),
     );
     return;
   }


   setState(() {
     _isLoading = true;
   });


   try {
     final response = await http.get(
       Uri.parse(
         'https://maps.googleapis.com/maps/api/directions/json?origin=${_startLocation!.latitude},${_startLocation!.longitude}&destination=${_endLocation!.latitude},${_endLocation!.longitude}&key=${Config.googleApiKey}&mode=driving',
       ),
     );


     if (response.statusCode == 200) {
       final data = json.decode(response.body);
       if (data['routes'].isNotEmpty) {
         final route = data['routes'][0]['overview_polyline']['points'];
         final polylinePoints = _decodePolyline(route);
         setState(() {
           _polylines.add(Polyline(
             polylineId: PolylineId('route'),
             points: polylinePoints,
             color: Colors.blue,
             width: 6,
           ));
         });


         // Display the time taken for different modes
         _displayTravelTimes(data);


         // Move camera to the starting point
         _moveCameraToLocation(_startLocation!);
       } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('No route found')),
         );
       }
     } else {
       throw Exception('Failed to fetch directions');
     }
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Error fetching directions: $e')),
     );
   } finally {
     setState(() {
       _isLoading = false;
     });
   }
 }


 // Function to display the travel times for various modes of transport
void _displayTravelTimes(Map<String, dynamic> data) {
 final leg = data['routes'][0]['legs'][0];
 final drivingTime = leg['duration']['text'] ?? 'N/A';


 // Fetch walking, cycling, and transit times based on separate API requests
 // Placeholder distances for walking, cycling, and transit speeds
 final distanceInKm = leg['distance']['value'] / 1000; // Distance in kilometers


 // Approximate speeds in km/h
 const double walkingSpeed = 5;   // 5 km/h
 const double cyclingSpeed = 15; // 15 km/h
 const double transitSpeed = 40; // 40 km/h (approximation for public transport)


 // Calculate times in seconds
 final walkingTimeSeconds = (distanceInKm / walkingSpeed) * 3600;
 final cyclingTimeSeconds = (distanceInKm / cyclingSpeed) * 3600;
 final transitTimeSeconds = (distanceInKm / transitSpeed) * 3600;


 setState(() {
   _drivingTime = drivingTime;
   _walkingTime = _formatDuration(walkingTimeSeconds);
   _cyclingTime = _formatDuration(cyclingTimeSeconds);
   _transitTime = _formatDuration(transitTimeSeconds);


   // Calculate flight time based on straight-line distance
   _flightTime = _formatDuration((distanceInKm / 800) * 3600); // 800 km/h speed
 });
}


String _formatDuration(double seconds) {
 final duration = Duration(seconds: seconds.round());
 final hours = duration.inHours;
 final minutes = duration.inMinutes.remainder(60);
 return hours > 0
     ? '${hours}h ${minutes}m'
     : '${minutes}m';
}




 // Format the duration into a readable string
 String _formatDurationInDays(double seconds) {
 final duration = Duration(seconds: seconds.round());
 final days = duration.inDays;
 final hours = duration.inHours.remainder(24);
 final minutes = duration.inMinutes.remainder(60);


 if (days > 0) {
   return '${days}d ${hours}h ${minutes}m';
 } else if (hours > 0) {
   return '${hours}h ${minutes}m';
 } else {
   return '${minutes}m';
 }
}




 // Function to decode the polyline
 List<LatLng> _decodePolyline(String encoded) {
   List<LatLng> points = [];
   int index = 0;
   int len = encoded.length;
   int lat = 0;
   int lng = 0;


   while (index < len) {
     int b;
     int shift = 0;
     int result = 0;
     do {
       b = encoded.codeUnitAt(index++) - 63;
       result |= (b & 0x1f) << shift;
       shift += 5;
     } while (b >= 0x20);
     lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);


     shift = 0;
     result = 0;
     do {
       b = encoded.codeUnitAt(index++) - 63;
       result |= (b & 0x1f) << shift;
       shift += 5;
     } while (b >= 0x20);
     lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);


     points.add(LatLng(lat / 1E5, lng / 1E5));
   }


   return points;
 }


 // Function to move the camera to a specific location
 void _moveCameraToLocation(LatLng location) {
   if (_mapController != null) {
     _mapController!.animateCamera(
       CameraUpdate.newCameraPosition(
         CameraPosition(
           target: location,
           zoom: 14.0, // Adjust zoom level here
         ),
       ),
     );
   }
 }


 // Search location and update map
 Future<void> _searchLocation(String query, bool isStartLocation) async {
   setState(() {
     _isLoading = true;
   });


   try {
     final response = await http.get(
       Uri.parse(
         'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=${Config.googleApiKey}',
       ),
     );


     if (response.statusCode == 200) {
       final data = json.decode(response.body);
       if (data['results'].isNotEmpty) {
         final location = data['results'][0]['geometry']['location'];
         final latLng = LatLng(location['lat'], location['lng']);


         setState(() {
           if (isStartLocation) {
             _startLocation = latLng;
             _startLocationController.text = query;
           } else {
             _endLocation = latLng;
             _endLocationController.text = query;
           }


           // Add markers
           _markers.clear();
           if (_startLocation != null) {
             _markers.add(Marker(
               markerId: MarkerId('start'),
               position: _startLocation!,
               infoWindow: InfoWindow(title: 'Start Location'),
             ));
           }
           if (_endLocation != null) {
             _markers.add(Marker(
               markerId: MarkerId('end'),
               position: _endLocation!,
               infoWindow: InfoWindow(title: 'End Location'),
             ));
           }
         });


         // Move camera to show the locations
         _moveCameraToLocation(latLng);
       }
     }
   } catch (e) {
     setState(() {
       // Handle error
     });
   } finally {
     setState(() {
       _isLoading = false;
     });
   }
 }


 @override
 Widget _buildTravelModeItem({
   required IconData icon,
   required String time,
   required Color color,
   required double iconSize,
   required double spacing,
 }) {
   return Container(
     padding: EdgeInsets.all(spacing / 2),
     decoration: BoxDecoration(
       color: color.withOpacity(0.1),
       borderRadius: BorderRadius.circular(8),
     ),
     child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         Icon(
           icon,
           color: color,
           size: iconSize,
         ),
         SizedBox(width: spacing),
         Text(
           time,
           style: TextStyle(
             fontSize: iconSize * 0.8,
             color: Colors.black87,
           ),
         ),
       ],
     ),
   );
 }

    

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: Text('Route Finder'),
       actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _saveSearch,
            tooltip: 'Save Search',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareSearchHistory,
            tooltip: 'Share History',
          ),
          IconButton(
            icon: Icon(Icons.directions),
            onPressed: _getDirections,
          ),
        ],
     ),
     body: Column(
       children: [
         Padding(
           padding: const EdgeInsets.all(8.0),
           child: TextField(
             controller: _startLocationController,
             decoration: InputDecoration(
               labelText: 'Start Location',
               prefixIcon: Icon(Icons.search),
               suffixIcon: _startLocationController.text.isNotEmpty
                   ? IconButton(
                       icon: Icon(Icons.clear),
                       onPressed: () {
                         setState(() {
                           _startLocationController.clear();
                         });
                       },
                     )
                   : null,
             ),
             onChanged: (value) => _searchLocation(value, true),
           ),
         ),
         Padding(
           padding: const EdgeInsets.all(8.0),
           child: TextField(
             controller: _endLocationController,
             decoration: InputDecoration(
               labelText: 'End Location',
               prefixIcon: Icon(Icons.search),
               suffixIcon: _endLocationController.text.isNotEmpty
                   ? IconButton(
                       icon: Icon(Icons.clear),
                       onPressed: () {
                         setState(() {
                           _endLocationController.clear();
                         });
                       },
                     )
                   : null,
             ),
             onChanged: (value) => _searchLocation(value, false),
           ),
         ),
         Expanded(
           child: GoogleMap(
             initialCameraPosition: CameraPosition(
               target: _startLocation ?? LatLng(37.7749, -122.4194),
               zoom: 14.0,
             ),
             markers: _markers,
             polylines: _polylines,
             onMapCreated: (controller) {
               _mapController = controller;
             },
           ),
         ),
         if (_isLoading)
           CircularProgressIndicator(),
         if (_drivingTime.isNotEmpty)
           Padding(
             padding: const EdgeInsets.all(8.0),
             child: LayoutBuilder(
               builder: (context, constraints) {
                 final screenWidth = MediaQuery.of(context).size.width;
                 final iconSize = screenWidth * 0.05; // 5% of screen width
                 final spacing = screenWidth * 0.02; // 2% of screen width


                 final travelModes = <Widget>[
                   if (_drivingTime.isNotEmpty)
                     _buildTravelModeItem(
                       icon: Icons.directions_car,
                       time: _drivingTime,
                       color: Colors.blue,
                       iconSize: iconSize,
                       spacing: spacing,
                     ),
                   if (_walkingTime.isNotEmpty)
                     _buildTravelModeItem(
                       icon: Icons.directions_walk,
                       time: _walkingTime,
                       color: Colors.green,
                       iconSize: iconSize,
                       spacing: spacing,
                     ),
                   if (_cyclingTime.isNotEmpty)
                     _buildTravelModeItem(
                       icon: Icons.directions_bike,
                       time: _cyclingTime,
                       color: Colors.orange,
                       iconSize: iconSize,
                       spacing: spacing,
                     ),
                   if (_transitTime.isNotEmpty)
                     _buildTravelModeItem(
                       icon: Icons.directions_bus,
                       time: _transitTime,
                       color: Colors.red,
                       iconSize: iconSize,
                       spacing: spacing,
                     ),
                   if (_flightTime.isNotEmpty)
                     _buildTravelModeItem(
                       icon: Icons.airplanemode_active,
                       time: _flightTime,
                       color: Colors.purple,
                       iconSize: iconSize,
                       spacing: spacing,
                     ),
                 ];


                 return Wrap(
                   spacing: spacing,
                   runSpacing: spacing,
                   alignment: WrapAlignment.center,
                   children: travelModes,
                 );
               },
             ),
           ),
       ],
     ),
   );
 }
}



