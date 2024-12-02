import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import '../config/config.dart'; 
import 'search_page.dart'; 
import '../profile/profile_page.dart'; 

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  bool _isListening = false;
  String _searchQuery = '';
  late SpeechToText _speech;
  bool _isSharingLiveLocation = false;
  Timer? _shareTimer;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _speech = SpeechToText();
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Map'),
      backgroundColor: Colors.teal,
      actions: [
        IconButton(
          icon: Icon(Icons.my_location),
          onPressed: _goToCurrentLocation,
        ),
        IconButton(
          icon: Icon(Icons.directions),
          onPressed: _goToSearchPage,
        ),
        IconButton(
          icon: Icon(Icons.share_location),
          onPressed: _shareLiveLocationOptions,
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                     labelText: 'Search Location',
                     border: OutlineInputBorder(),
                     suffixIcon: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         IconButton(
                           icon: Icon(
                             _isListening ? Icons.mic_off : Icons.mic,
                             color: _isListening ? Colors.red : Colors.blue,
                           ),
                           onPressed: _toggleSpeechToText,
                         ),
                         if (_searchQuery.isNotEmpty)
                           IconButton(
                             icon: Icon(Icons.clear),
                             onPressed: () {
                               setState(() {
                                 _searchQuery = '';
                               });
                             },
                           ),
                       ],
                     ),
                   ),
                 ),
               ),
               IconButton(
                icon: Icon(Icons.search),
                onPressed: _searchLocation,
              
               ),
             ],
           ),
         ),

               
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? LatLng(0.0, 0.0),
                zoom: 10.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (_currentLocation != null) {
                  _goToCurrentLocation();
                }
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      if (_mapController != null && _currentLocation != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 17.0),
        );
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId('CurrentLocation'),
            position: _currentLocation!,
            infoWindow: InfoWindow(title: 'You are here'),
          ),
        );
      }
    } catch (e) {
      print('Error fetching current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location')),
      );
    }
  }

  void _goToCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 17.0),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Current location not available')),
      );
    }
  }

  Future<void> _shareLiveLocationOptions() async {
    final isPaid = await _isPaidUser();
    if (!isPaid) {
      // Showing a prompt and redirect to profile page
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Premium Feature'),
            content: Text(
                'Live location sharing is available only for paid users. Upgrade your plan to access this feature.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _redirectToProfilePage();
                },
                child: Text('Go to Profile'),
              ),
            ],
          );
        },
      );
      return;
    }

    // If the user is paid, show the live sharing options
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.group),
              title: Text('Share with Friends'),
              onTap: _shareWithFriends,
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share via Other Apps'),
              onTap: _shareWithApps,
            ),
            if (_isSharingLiveLocation)
              ListTile(
                leading: Icon(Icons.stop),
                title: Text('Stop Live Sharing'),
                onTap: _stopLiveSharing,
              ),
          ],
        );
      },
    );
  }

 Future<bool> _isPaidUser() async {
  bool isPaid = false; // Default value for unpaid user

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Premium Feature'),
        content: Text('Are you a paid user?'),
        actions: [
          TextButton(
            onPressed: () {
              isPaid = false;
              Navigator.pop(context);
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              isPaid = true;
              Navigator.pop(context);
            },
            child: Text('Yes'),
          ),
        ],
      );
    },
  );

  return isPaid;
}


  void _redirectToProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()), 
    );
  }

  void _shareWithFriends() {
    Navigator.pop(context); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Live location shared with friends')),
    );
  }

  void _shareWithApps() {
    Navigator.pop(context); 
    if (_currentLocation != null) {
      final locationUrl =
          'https://www.google.com/maps?q=${_currentLocation!.latitude},${_currentLocation!.longitude}';
      Share.share('Check out my live location: $locationUrl');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to fetch location')),
      );
    }
  }

  void _stopLiveSharing() {
    _shareTimer?.cancel();
    setState(() {
      _isSharingLiveLocation = false;
    });
    Navigator.pop(context); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Live location sharing stopped')),
    );
  }

  Future<void> _goToSearchPage() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage()),
    );

    if (result != null) {
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('SearchedLocation'),
            position: result,
            infoWindow: InfoWindow(title: 'Searched Location'),
          ),
        );
      });

      _mapController.animateCamera(CameraUpdate.newLatLngZoom(result, 15.0));
    }
  }

  Future<void> _toggleSpeechToText() async {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      bool available = await _speech.initialize();
      if (available) {
        _speech.listen(onResult: (result) {
          setState(() {
            _searchQuery = result.recognizedWords;
          });
        });
        setState(() {
          _isListening = true;
        });
      }
    }
  }

  



Future<void> _searchLocation() async {
  if (_searchQuery.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter a search query')),
    );
    return;
  }




  try {
    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$_searchQuery&key=${Config.googleApiKey}',
      ),
    );




    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        final formattedAddress = data['results'][0]['formatted_address'];
        final LatLng searchedLocation =
            LatLng(location['lat'], location['lng']);




        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId('SearchLocation'),
              position: searchedLocation,
              infoWindow: InfoWindow(title: formattedAddress),
            ),
          );
        });




        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(searchedLocation, 15.0),
        );




        // Showing  overlay with location details
        _showLocationDetailsOverlay(formattedAddress);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No results found')),
        );
      }
    } else {
      throw Exception('Failed to fetch location data');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error searching location: $e')),
    );
  }
}




void _showLocationDetailsOverlay(String address) {
 showModalBottomSheet(
   context: context,
   builder: (context) {
     return Container(
       padding: EdgeInsets.all(16.0),
       child: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             'Location Details',
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
           ),
           SizedBox(height: 8.0),
           Text('Address: $address'),
           SizedBox(height: 8.0),
           Row(
             children: [
               ElevatedButton(
                 onPressed: () => Navigator.pop(context),
                 child: Text('Close'),
               ),
               SizedBox(width: 8.0),
               ElevatedButton(
                 onPressed: () {
                   
                   _goToSearchPage();
                   
                 },
                 child: Text('Get Directions'),
               ),
             ],
           ),
         ],
       ),
     );
   },
 );
}






@override
void dispose() {
  _speech.stop();
  _shareTimer?.cancel();
  super.dispose();
}
}


