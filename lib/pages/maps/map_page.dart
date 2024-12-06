
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:odyssey/utils/spaces.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import '../config/config.dart';
import 'search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/manage_membership.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  // Map Controller and Search
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  // Location and Map State
  final Set<Marker> _markers = {};
  final Set<Marker> _userMarkers = {};
  LatLng? _currentLocation;
  bool _showNearbyUsers = false;
  Timer? _locationUpdateTimer;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 10,
  );

  // Speech Recognition
  late SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Live Location Sharing
  bool _isSharingLiveLocation = false;
  Timer? _shareTimer;
  String? _memberType;

  // Animation Controllers and Variables
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _searchBarAnimation; 
late AnimationController _iconPulseController;
late AnimationController _iconRotateController;
late Animation<double> _pulseAnimation;
late Animation<double> _rotateAnimation;
bool _isSearchBarExpanded = false;
bool _isConnecting = false;
  // Constants
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;
  static const double defaultZoomLevel = 15.0;
  static const double tiltedViewAngle = 45.0;
  static const double rotationAngle = 30.0;
  static const double searchBarHeight = 60.0;
  static const double searchBarPadding = 8.0;
  static const double searchBarBorderRadius = 25.0;
  static const double searchBarBorderWidth = 2.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpeech();
    _checkLocationPermission();
    _fetchMembershipDetails();
    _startLocationUpdates();
  }

  // Initialization Methods
  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        if (_currentLocation != null) {
          _updateUserLocation();
          if (_showNearbyUsers) {
            _fetchNearbyUsers();
          }
        }
      },
    );
  }

  void _initializeAnimations() {
     _fabAnimationController = AnimationController(
    vsync: this,
    duration: animationDuration,
  );

  _fabScaleAnimation = Tween<double>(
    begin: 1.0,
    end: 1.2,
  ).animate(CurvedAnimation(
    parent: _fabAnimationController,
    curve: animationCurve,
  ));

  _searchBarAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _fabAnimationController,
    curve: animationCurve,
  ));
    _iconPulseController = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  );

  _iconRotateController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );

  _pulseAnimation = Tween<double>(
    begin: 1.0,
    end: 1.2,
  ).animate(CurvedAnimation(
    parent: _iconPulseController,
    curve: Curves.easeInOut,
  ));

  _rotateAnimation = Tween<double>(
    begin: 0.0,
    end: 2 * 3.14159,
  ).animate(CurvedAnimation(
    parent: _iconRotateController,
    curve: Curves.easeInOut,
  ));

  // Start continuous pulse animation
  _iconPulseController.repeat(reverse: true);
}
  Future<void> _initializeSpeech() async {
    _speech = SpeechToText();
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') setState(() => _isListening = false);
      },
      onError: (errorNotification) {
        setState(() => _isListening = false);
        _showErrorSnackBar('Speech recognition error: ${errorNotification.errorMsg}');
      },
    );
  }

  // Location Methods
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar('Please enable location services');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateCurrentLocationMarker();
      });

      await _animateCameraToPosition(_currentLocation!);
      await _updateUserLocation();
      if (_showNearbyUsers) {
        await _fetchNearbyUsers();
      }
    } catch (e) {
      _showErrorSnackBar('Error getting location: $e');
    }
  }

  void _updateCurrentLocationMarker() {
    if (_currentLocation == null) return;

    _markers.removeWhere((marker) => marker.markerId.value == 'currentLocation');
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: _currentLocation!,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  Future<void> _updateUserLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _currentLocation == null) return;

      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .update({
            'location': GeoPoint(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
            ),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  // Nearby Users Methods
Future<void> _fetchNearbyUsers() async {
  if (_currentLocation == null) {
    print('Current location is not available');
    return;
  }

  try {
    // First check if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('No user is logged in');
      return;
    }

    print('Fetching nearby users...');

    // Get all users except current user
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('User')
        .where('location', isNull: false)  // Only get users with location
        .get();

    if (usersSnapshot.docs.isEmpty) {
      print('No users found with location data');
      return;
    }

    print('Found ${usersSnapshot.docs.length} users with location data');

    setState(() {
      // Clear existing user markers
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('user_'));

      for (var doc in usersSnapshot.docs) {
        // Skip current user
        if (doc.id == currentUser.uid) {
          continue;
        }

        try {
          final userData = doc.data();
          final GeoPoint? location = userData['location'] as GeoPoint?;
          final String username = userData['username'] ?? 'Unknown User';

          if (location != null) {
            final userLocation = LatLng(location.latitude, location.longitude);
            
            // Calculate distance
            double distance = Geolocator.distanceBetween(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              location.latitude,
              location.longitude,
            );

            // Only show users within 5km
            if (distance <= 5000) {
              print('Adding marker for user: $username at distance: ${(distance/1000).toStringAsFixed(1)}km');
              
              final marker = Marker(
                markerId: MarkerId('user_${doc.id}'),
                position: userLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                infoWindow: InfoWindow(
                  title: username,
                  snippet: '${(distance / 1000).toStringAsFixed(1)}km away',
                  onTap: () => _showUserDetails(doc),
                ),
              );

              _markers.add(marker);
            }
          }
        } catch (e) {
          print('Error processing user document ${doc.id}: $e');
        }
      }
    });

    print('Successfully updated nearby user markers');

  } catch (e) {
    print('Error fetching nearby users: $e');
    _showErrorSnackBar('Unable to fetch nearby users. Please try again.');
  }
}


// Modify your _showUserDetails method:
void _showUserDetails(DocumentSnapshot userDoc) {
  final userData = userDoc.data() as Map<String, dynamic>;
  final String username = userData['username'] ?? 'Unknown User';
  final bool isConnected = userData['connections']?.contains(FirebaseAuth.instance.currentUser?.uid) ?? false;

  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (userData['bio'] != null) ...[
            Text(
              userData['bio'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.person_add,
                label: isConnected ? 'Connected' : 'Connect',
                onPressed: isConnected ? null : () => _sendConnectionRequest(userDoc),
                isLoading: _isConnecting,
              ),
              _buildActionButton(
                icon: Icons.message,
                label: 'Message',
                onPressed: isConnected ? () => _openChat(userDoc) : null,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildActionButton({
  required IconData icon,
  required String label,
  VoidCallback? onPressed,
  bool isLoading = false,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: isLoading 
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
      : Icon(icon),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.teal,
      disabledBackgroundColor: Colors.grey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}

Future<void> _sendConnectionRequest(DocumentSnapshot userDoc) async {
  try {
    setState(() => _isConnecting = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to send connection requests');
    }

    // Create the connection request
    await FirebaseFirestore.instance
        .collection('ConnectionRequests')
        .add({
          'fromUserId': currentUser.uid,
          'toUserId': userDoc.id,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
          'fromUsername': (await FirebaseFirestore.instance
              .collection('User')
              .doc(currentUser.uid)
              .get())['username'],
          'toUsername': userDoc['username'],
        });

    // Show success message
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection request sent to ${userDoc['username']}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send connection request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isConnecting = false);
    }
  }
}

void _openChat(DocumentSnapshot userDoc) {
  Navigator.pop(context);
  // TODO: Implement chat functionality
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Chat feature coming soon!'),
    ),
  );
}

  void _sendMessage(DocumentSnapshot userDoc) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Messaging feature coming soon!'),
      ),
    );
  }

  void _toggleNearbyUsers() {
    setState(() {
      _showNearbyUsers = !_showNearbyUsers;
      if (_showNearbyUsers) {
        _fetchNearbyUsers();
      } else {
        _markers.removeWhere(
          (marker) => marker.markerId.value.startsWith('user_'),
        );
      }
    });
  }
  // Search and Speech Methods
Future<void> _toggleSpeechToText() async {
  try {
    if (_isListening) {
      await _speech.stop();
      if (mounted) { 
        setState(() => _isListening = false);
      }
    } else {
      if (mounted) {  
        setState(() {
          _isListening = true;
          _searchController.text = '';
          _searchQuery = '';
        });
      }

      await _speech.listen(
        onResult: _handleSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        onSoundLevelChange: null,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    }
  } catch (e) {
    if (mounted) {  
      _showErrorSnackBar('Speech recognition error: $e');
      setState(() => _isListening = false);
    }
  }
}

void _handleSpeechResult(SpeechRecognitionResult result) {
  if (!mounted) return; 

  setState(() {
    _searchQuery = result.recognizedWords;
    _searchController.text = result.recognizedWords;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
  });

  if (result.finalResult) {
    if (!mounted) return;  
    setState(() => _isListening = false);
    if (_searchQuery.isNotEmpty) {
      _searchLocation();
    }
  }
}



  
  Future<void> _searchLocation() async {
    if (_searchQuery.isEmpty) return;

    _fabAnimationController.forward();

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

          await _animateMarkerAddition(
            searchLocation,
            data['results'][0]['name'],
            address,
          );

          await _animateCameraToPosition(searchLocation);
          _showLocationDetailsOverlay(address, searchLocation);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error searching location: $e');
    } finally {
      _fabAnimationController.reverse();
    }
  }

  Future<void> _animateMarkerAddition(
    LatLng position,
    String title,
    String address,
  ) async {
    if (_markers.any((m) => m.markerId.value == 'searchLocation')) {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'searchLocation');
      });
      await Future.delayed(const Duration(milliseconds: 150));
    }

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('searchLocation'),
          position: position,
          infoWindow: InfoWindow(
            title: title,
            snippet: address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  Future<void> _animateCameraToPosition(LatLng target) async {
    final CameraPosition newPosition = CameraPosition(
      target: target,
      zoom: defaultZoomLevel,
      tilt: tiltedViewAngle,
      bearing: rotationAngle,
    );

    await _mapController.animateCamera(
      CameraUpdate.newCameraPosition(newPosition),
    );

    await Future.delayed(const Duration(milliseconds: 1000));
    
    await _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: defaultZoomLevel,
          tilt: 0.0,
          bearing: 0.0,
        ),
      ),
    );
  }

  // Location Sharing Methods
  Future<void> _shareLiveLocationOptions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Please log in to use this feature');
        return;
      }

      if (_memberType == 'BASIC') {
        _showPremiumFeatureDialog();
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
      _showErrorSnackBar('Error with location sharing: $e');
    }
  }

  void _showPremiumFeatureDialog() {
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
      _showErrorSnackBar('Error sharing location: $e');
    }
  }

void _shareWithApps() {
    Navigator.pop(context);
    if (_currentLocation != null) {
      final locationUrl = 
          'https://www.google.com/maps?q=${_currentLocation!.latitude},${_currentLocation!.longitude}';
      Share.share('Check out my location: $locationUrl');
    } else {
      _showErrorSnackBar('Location not available');
    }
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
    _showErrorSnackBar('Error fetching membership: $e');
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

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildAnimatedFABs(),
    );
  }

PreferredSizeWidget _buildAppBar() {
  return AppBar(
    title: const Text('Map'),
    backgroundColor: Colors.teal,
    actions: [
      // Nearby users icon with pulse animation
      ScaleTransition(
        scale: _pulseAnimation,
        child: IconButton(
          icon: Icon(
            _showNearbyUsers ? Icons.people : Icons.people_outline,
            color: _showNearbyUsers ? Colors.amber : Colors.white,
          ),
          onPressed: () {
            _toggleNearbyUsers();
            _iconPulseController.forward(from: 0.0);
          },
        ),
      ),
      
      RotationTransition(
        turns: _rotateAnimation,
        child: IconButton(
          icon: const Icon(
            Icons.my_location,
            color: Colors.white,
          ),
          onPressed: () {
            _getCurrentLocation();
            _iconRotateController.forward(from: 0.0);
          },
        ),
      ),
   
      AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isSharingLiveLocation ? _pulseAnimation.value : 1.0,
            child: IconButton(
              icon: Icon(
                _isSharingLiveLocation ? Icons.share_location : Icons.share,
                color: _isSharingLiveLocation ? Colors.amber : Colors.white,
              ),
              onPressed: _shareLiveLocationOptions,
            ),
          );
        },
      ),
    ],
  );
}
  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: Stack(
            children: [
              _buildMap(),
              if (_isSharingLiveLocation)
                _buildSharingIndicator(),
            ],
          ),
        ),
      ],
    );
  }
Widget _buildSearchBar() {
  return Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onTap: () => setState(() => _isSearchBarExpanded = true),
                    onSubmitted: (_) => setState(() => _isSearchBarExpanded = false),
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(left: 16),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mic button
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                              color: _isListening ? Colors.red : Colors.grey[600],
                            ),
                            onPressed: _toggleSpeechToText,
                          ),
                          // Clear button
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[600]),
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
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchLocation,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSearchBarSuffixIcon() {
    if (_isListening) {
      return IconButton(
        key: const ValueKey('mic_active'),
        icon: const Icon(Icons.mic_off, color: Colors.red),
        onPressed: _toggleSpeechToText,
      );
    } else if (_searchQuery.isNotEmpty) {
      return IconButton(
        key: const ValueKey('clear'),
        icon: const Icon(Icons.clear),
        onPressed: () {
          setState(() {
            _searchQuery = '';
            _searchController.clear();
          });
        },
      );
    } else {
      return IconButton(
        key: const ValueKey('mic'),
        icon: const Icon(Icons.mic),
        onPressed: _toggleSpeechToText,
      );
    }
  }
Widget _buildMap() {
  return GoogleMap(
    initialCameraPosition: _initialCameraPosition,
    onMapCreated: (controller) => _mapController = controller,
    markers: _markers,
    myLocationEnabled: true,
    myLocationButtonEnabled: false,
    zoomControlsEnabled: true,
    mapToolbarEnabled: true,
    onTap: (latLng) async {
      // Clear search bar
      setState(() {
        _searchQuery = '';
        _searchController.clear();
        _isSearchBarExpanded = false;
        FocusScope.of(context).unfocus();
      });

      try {
        
        final response = await http.get(
          Uri.parse(
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=${Config.googleApiKey}',
          ),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['results'].isNotEmpty) {
            final address = data['results'][0]['formatted_address'];

            
            await _animateMarkerAddition(
              latLng,
              'Selected Location',
              address,
            );

            
            await _animateCameraToPosition(latLng);

           
            _showLocationDetailsOverlay(address, latLng);
          }
        }
      } catch (e) {
        _showErrorSnackBar('Error getting location details: $e');
      }
    },
  );
}

  Widget _buildSharingIndicator() {
    return Positioned(
      top: 16,
      left: 16,
      child: AnimatedContainer(
        duration: animationDuration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.share_location, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Sharing Location',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedFABs() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      if (_isSharingLiveLocation)
        ScaleTransition(
          scale: _pulseAnimation,
          child: FloatingActionButton.extended(
            onPressed: _stopLiveSharing,
            icon: const Icon(Icons.stop),
            label: const Text('Stop Sharing'),
            backgroundColor: Colors.red,
            heroTag: 'stopSharing',
          ),
        ),
      const SizedBox(height: 16),
      AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * 0.9 + 0.1,
            child: FloatingActionButton(
              onPressed: () async {
                _iconRotateController.forward(from: 0.0);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
                
                if (result != null && result is LatLng) {
                  await _animateMarkerAddition(
                    result,
                    'Destination',
                    '',
                  );
                  await _animateCameraToPosition(result);
                }
              },
              child: RotationTransition(
                turns: _rotateAnimation,
                child: const Icon(Icons.directions),
              ),
              backgroundColor: Colors.teal,
              heroTag: 'directions',
            ),
          );
        },
      ),
    ],
  );
}

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  void _showLocationDetailsOverlay(String address, LatLng position) {
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
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Close'),
                ),
              ),
              smallHorizontal,
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToSearch(position);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Get Directions'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> _navigateToSearch(LatLng position) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SearchPage(endLocation: position),
    ),
  );

  if (result != null && result is LatLng) {
    await _animateMarkerAddition(
      result,
      'Destination',
      '',
    );
    await _animateCameraToPosition(result);
  }
}

 @override
void dispose() {
  
  _locationUpdateTimer?.cancel();
  _fabAnimationController.dispose();
  _iconPulseController.dispose();
  _iconRotateController.dispose();
  _speech.stop();
  _shareTimer?.cancel();
  _debounceTimer?.cancel(); 
  _searchController.dispose();
  _mapController.dispose();
  
  if (_isListening) {
    _speech.stop();
  }

  super.dispose();
}
}