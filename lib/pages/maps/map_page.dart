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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/manage_membership.dart'; 

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Controllers
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  // Location and Map state
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 10,
  );

  // Speech recognition
  late SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Live location sharing
  bool _isSharingLiveLocation = false;
  Timer? _shareTimer;
  String? _memberType;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _checkLocationPermission();
    _fetchMembershipDetails();
  }

  Future<void> _initializeSpeech() async {
    _speech = SpeechToText();
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (errorNotification) {
        print('Speech recognition error: $errorNotification');
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: ${errorNotification.errorMsg}')),
        );
      },
    );
  }

  Future<void> _fetchMembershipDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _memberType = userDoc.data()?['membertype'] ?? 'BASIC';
        });
      }
    } catch (e) {
      print('Error fetching membership: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
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
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _initialCameraPosition = CameraPosition(
          target: _currentLocation!,
          zoom: 15,
        );
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: _currentLocation!,
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      });

      if (_mapController != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _toggleSpeechToText() async {
    try {
      if (_isListening) {
        await _speech.stop();
        setState(() => _isListening = false);
      } else {
        setState(() {
          _isListening = true;
          _searchController.text = '';
          _searchQuery = '';
        });

        await _speech.listen(
          onResult: (result) {
            setState(() {
              _searchQuery = result.recognizedWords;
              _searchController.text = result.recognizedWords;
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: _searchController.text.length),
              );
            });

            if (result.finalResult) {
              setState(() => _isListening = false);
              if (_searchQuery.isNotEmpty) {
                _searchLocation();
              }
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: 'en_US',
          onSoundLevelChange: (level) => print('Sound level: $level'),
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        );
      }
    } catch (e) {
      print('Speech recognition error: $e');
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition error: $e')),
      );
    }
  }

  Future<void> _searchLocation() async {
    if (_searchQuery.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$_searchQuery&key=${Config.googleApiKey}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final LatLng searchLocation = LatLng(location['lat'], location['lng']);
          final address = data['results'][0]['formatted_address'];
          
          setState(() {
            _markers.add(
              Marker(
                markerId: const MarkerId('searchLocation'),
                position: searchLocation,
                infoWindow: InfoWindow(
                  title: data['results'][0]['name'],
                  snippet: address,
                ),
              ),
            );
          });

          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(searchLocation, 15),
          );

          _showLocationDetailsOverlay(address);
        }
      }
    } catch (e) {
      print('Error searching location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching location: $e')),
      );
    }
  }

  Future<void> _shareLiveLocationOptions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to use this feature')),
        );
        return;
      }

      if (_memberType == 'BASIC') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Premium Feature'),
            content: const Text(
              'Live location sharing is only available for Premium and Elite members. '
              'Would you like to upgrade your membership?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageMembership()),
                  );
                },
                child: const Text('Upgrade'),
              ),
            ],
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Share with Friends'),
              onTap: _shareWithFriends,
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share via Other Apps'),
              onTap: _shareWithApps,
            ),
            if (_isSharingLiveLocation)
              ListTile(
                leading: const Icon(Icons.stop),
                title: const Text('Stop Live Sharing'),
                onTap: _stopLiveSharing,
              ),
          ],
        ),
      );
    } catch (e) {
      print('Error with location sharing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error with location sharing: $e')),
      );
    }
  }

  Future<void> _shareWithFriends() async {
    try {
      if (_currentLocation == null) {
        throw Exception('Current location not available');
      }

      setState(() => _isSharingLiveLocation = true);

      _shareTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
        final position = await Geolocator.getCurrentPosition();
        final user = FirebaseAuth.instance.currentUser;
        
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('User')
              .doc(user.uid)
              .collection('shared_locations')
              .add({
                'latitude': position.latitude,
                'longitude': position.longitude,
                'timestamp': DateTime.now(),
              });
        }
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live location sharing started')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing location: $e')),
      );
    }
  }

  void _shareWithApps() {
    Navigator.pop(context);
    if (_currentLocation != null) {
      final locationUrl = 
          'https://www.google.com/maps?q=${_currentLocation!.latitude},${_currentLocation!.longitude}';
      Share.share('Check out my location: $locationUrl');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
    }
  }

  void _stopLiveSharing() {
    _shareTimer?.cancel();
    setState(() => _isSharingLiveLocation = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live location sharing stopped')),
    );
  }

  void _showLocationDetailsOverlay(String address) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Address: $address'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
                ElevatedButton(
                  onPressed: () {
                    final searchLocationMarker = _markers.firstWhere(
                      (marker) => marker.markerId.value == 'searchLocation',
                      orElse: () => _markers.first,
                    );
                    
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchPage(
                          endLocation: searchLocationMarker.position,
                        ),
                      ),
                    );
                  },
                  child: const Text('Get Directions'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.share_location),
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
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Location',
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                              color: _isListening ? Colors.red : Colors.grey,
                            ),
                            onPressed: _toggleSpeechToText,
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchLocation,
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: true,
              onTap: (latLng) {
                // Clear search when map is tapped
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isSharingLiveLocation)
            FloatingActionButton.extended(
              onPressed: _stopLiveSharing,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Sharing'),
              backgroundColor: Colors.red,
              heroTag: 'stopSharing',
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
              
              if (result != null && result is LatLng) {
                setState(() {
                  _markers.add(
                    Marker(
                      markerId: const MarkerId('destination'),
                      position: result,
                      infoWindow: const InfoWindow(title: 'Destination'),
                    ),
                  );
                });
                
                _mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(result, 15),
                );
              }
            },
            child: const Icon(Icons.directions),
            backgroundColor: Colors.teal,
            heroTag: 'directions',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _shareTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

// Extension for handling permission messages
extension PermissionMessages on LocationPermission {
  String get message {
    switch (this) {
      case LocationPermission.denied:
        return 'Location permissions are denied';
      case LocationPermission.deniedForever:
        return 'Location permissions are permanently denied';
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return 'Location permissions granted';
      default:
        return 'Unknown permission status';
    }
  }
}