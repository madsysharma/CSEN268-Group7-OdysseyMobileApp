import 'dart:async';
import 'dart:math' show asin, cos, sqrt, pi, max,min, sin, atan2;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/manage_membership.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

// Models
class NearbyUser {
  final String id;
  final String name;
  final LatLng location;
  final double distance;
  final DateTime lastUpdated;

  NearbyUser({
    required this.id,
    required this.name,
    required this.location,
    required this.distance,
    required this.lastUpdated,
  });

  factory NearbyUser.fromFirestore(DocumentSnapshot doc, LatLng currentLocation) {
    final data = doc.data() as Map<String, dynamic>;
    final GeoPoint geoPoint = data['location'];
    final userLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
    
    return NearbyUser(
      id: doc.id,
      name: data['name'] ?? 'Unknown User',
      location: userLocation,
      distance: _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        geoPoint.latitude,
        geoPoint.longitude,
      ),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; 
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }
}

class DirectionStep {
  final String instructions;
  final String distance;
  final String duration;

  DirectionStep({
    required this.instructions,
    required this.distance,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'instructions': instructions,
      'distance': distance,
      'duration': duration,
    };
  }

  static DirectionStep fromMap(Map<String, dynamic> map) {
    return DirectionStep(
      instructions: map['instructions'],
      distance: map['distance'],
      duration: map['duration'],
    );
  }
}

class OfflineMap {
  final String id;
  final String startLocation;
  final String endLocation;
  final List<DirectionStep> steps;
  final DateTime createdAt;
  final List<LatLng> routePoints;

  OfflineMap({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.steps,
    required this.createdAt,
    required this.routePoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'steps': steps.map((step) => step.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'routePoints': routePoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
    };
  }


  static OfflineMap fromMap(Map<String, dynamic> map) {
    return OfflineMap(
      id: map['id'],
      startLocation: map['startLocation'],
      endLocation: map['endLocation'],
      steps: (map['steps'] as List)
          .map((step) => DirectionStep.fromMap(step as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
      routePoints: (map['routePoints'] as List).map((point) => 
        LatLng(point['latitude'] as double, point['longitude'] as double)
      ).toList(),
    );
  }
}

class MembershipHandler {
  static const Map<String, int> _mapLimits = {
    'BASIC': 3,
    'PREMIUM': 5,
    'ELITE': -1, // Unlimited
  };

  static Future<bool> checkDownloadPermission({
    required String memberType,
    required int currentMapCount,
    required BuildContext context,
  }) async {
    final effectiveMemberType = memberType.toUpperCase();
    final limit = _mapLimits[effectiveMemberType] ?? _mapLimits['BASIC']!;
    
    if (limit == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download permitted - Elite membership')),
      );
      return true;
    }

    if (currentMapCount >= limit) {
      final shouldUpgrade = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Map Download Limit Reached'),
          content: Text(
            'You have reached your limit of $limit saved maps for your '
            '$effectiveMemberType membership.\n\n'
            'Would you like to upgrade your membership to save more maps?'
          ),
          actions: [
            TextButton(
              child: const Text('Not Now'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Upgrade Membership'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ) ?? false;

      if (shouldUpgrade) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ManageMembership(),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save limit reached for $effectiveMemberType membership ($currentMapCount/$limit)'),
        ),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Save permitted ($currentMapCount/$limit maps used)'),
      ),
    );
    return true;
  }

  static int getMembershipLimit(String memberType) {
    return _mapLimits[memberType.toUpperCase()] ?? _mapLimits['BASIC']!;
  }

  static String formatLimitDisplay(String memberType, int currentCount) {
    final limit = getMembershipLimit(memberType);
    return '$currentCount/${limit == -1 ? '∞' : limit}';
  }

}

class SearchPage extends StatefulWidget {
  final LatLng? endLocation;

  const SearchPage({Key? key, this.endLocation}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  late GoogleMapController _mapController;
  
  // Animation Controllers
  late AnimationController _mapExpandController;
  late AnimationController _directionsListController;
  late AnimationController _searchBarController;
  late AnimationController _markerAnimationController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _routeController;
  
  // Animations
  late Animation<double> _mapHeightAnimation;
  late Animation<double> _directionsOpacity;
  late Animation<Offset> _searchBarSlideAnimation;
  late Animation<double> _markerScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _routeProgress;

  // State Variables
  String? _memberType;
  int _offlineMapsCount = 0;
  bool _isLoadingMembership = true;
  List<OfflineMap> _offlineMaps = [];
  List<dynamic> _directions = [];
  Set<Polyline> _polylines = {};
  final List<Circle> _rippleEffects = [];
  List<Polyline> _animatedRoute = [];
  List<LatLng> _routePoints = [];
  bool _isNavigating = false;
  bool _isListening = false;
  TextEditingController? _activeController;
  Timer? _debounceTimer;
  
  // Car Animation
  BitmapDescriptor? _carIcon;
  Marker? _carMarker;
  Timer? _carAnimationTimer;
  int _carAnimationIndex = 0;
  double _carRotation = 0.0;
  
  // Nearby Users
  List<NearbyUser> _nearbyUsers = [];
  StreamSubscription<QuerySnapshot>? _nearbyUsersSubscription;
  final double _searchRadius = 5.0; // 5km radius
  BitmapDescriptor? _userMarkerIcon;
  bool _showNearbyUsers = true;
  Timer? _locationUpdateTimer;
  
  // Location Variables
  LatLng? _startLocation;
  LatLng? _endLocation;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 10,
  );

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _createCarIcon();
    _createUserMarkerIcon();
    _initializeAnimationControllers();
    _setupAnimations();
    _startInitialAnimations();
    _startLocationUpdates();
  }

  void _initializeComponents() {
    if (widget.endLocation != null) {
      _endLocation = widget.endLocation;
      _fetchAddressForLocation(_endLocation!, isStart: false);
    }
    _getCurrentLocation();
    _fetchMembershipDetails();
    _loadSavedMaps();
  }

  void _initializeAnimationControllers() {
    _mapExpandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _directionsListController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _searchBarController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _routeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

void _setupAnimations() {
  _mapHeightAnimation = Tween<double>(
    begin: 0.6,
    end: 0.4,
  ).animate(CurvedAnimation(
    parent: _mapExpandController,
    curve: Curves.easeInOut,
  ));
  
  _directionsOpacity = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _directionsListController,
    curve: Curves.easeIn,
  ));
  
  _searchBarSlideAnimation = Tween<Offset>(
    begin: const Offset(-1.0, 0.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _searchBarController,
    curve: Curves.easeOutBack,
  ));
  
  // Ensure marker scale animation stays between 0.0 and 1.0
  _markerScaleAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _markerAnimationController,
    curve: Curves.elasticOut,
  ));


    _pulseAnimation = Tween<double>(
      begin: 30,
      end: 50,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
    
    _routeProgress = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _routeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation.addListener(_updateRippleEffect);
    _routeProgress.addListener(_updateRouteAnimation);
  }

  void _startInitialAnimations() {
    _searchBarController.forward();
  }

  Future<void> _createCarIcon() async {
    const double size = 50;
    
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = Colors.blue;
    
    // Draw a simple car icon
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size, size * 0.6),
        const Radius.circular(8),
      ),
      paint,
    );
    
    paint.color = Colors.black;
    canvas.drawCircle(Offset(size * 0.25, size * 0.6), size * 0.1, paint);
    canvas.drawCircle(Offset(size * 0.75, size * 0.6), size * 0.1, paint);
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (bytes != null) {
      setState(() {
        _carIcon = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
      });
    }
  }

  

  Future<void> _createUserMarkerIcon() async {
    const double size = 40;
    
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    final bgPaint = Paint()..color = Colors.purple;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      bgPaint,
    );
   
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(
      Offset(size / 2, size * 0.3),
      size * 0.15,
      paint,
    );
    
    final bodyPath = Path()
      ..moveTo(size / 2, size * 0.45)
      ..lineTo(size / 2, size * 0.7);
    canvas.drawPath(bodyPath, paint);
    
    canvas.drawLine(
      Offset(size * 0.3, size * 0.55),
      Offset(size * 0.7, size * 0.55),
      paint,
    );
  
    canvas.drawLine(
      Offset(size / 2, size * 0.7),
      Offset(size * 0.3, size * 0.85),
      paint,
    );
    canvas.drawLine(
      Offset(size / 2, size * 0.7),
      Offset(size * 0.7, size * 0.85),
      paint,
    );
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (bytes != null) {
      setState(() {
        _userMarkerIcon = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
      });
    }
  }
  Future<void> _updateUserLocation() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get current location
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );
    
    // Update location in Firestore
    await FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .update({
      'location': GeoPoint(position.latitude, position.longitude),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    // Update local state if this is the first location update
    if (_startLocation == null) {
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _startLocation = newLocation;
      });

      // Update map camera position
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newLocation,
            zoom: 15,
          ),
        ),
      );

      // Get address for the location
      await _fetchAddressForLocation(newLocation, isStart: true);
    }

    // Update nearby users
    _startNearbyUsersListener();

  } catch (e) {
    debugPrint('Error updating location: $e');
  }
}

void _startNearbyUsersListener() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Cancel existing subscription if any
  _nearbyUsersSubscription?.cancel();

  // Start listening for nearby users
  _nearbyUsersSubscription = FirebaseFirestore.instance
      .collection('User')
      .where('lastUpdated', 
          isGreaterThan: DateTime.now().subtract(const Duration(minutes: 5)))
      .snapshots()
      .listen((snapshot) {
        if (!mounted || _startLocation == null) return;

        setState(() {
          _nearbyUsers = snapshot.docs
              .where((doc) => doc.id != user.uid) // Exclude current user
              .map((doc) => NearbyUser.fromFirestore(doc, _startLocation!))
              .where((user) => user.distance <= _searchRadius)
              .toList();
        });
      });
}

  Future<void> _startLocationUpdates() async {
    // Request location permission
    final permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always && 
        permission != LocationPermission.whileInUse) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
      }
      return;
    }

    // Get current location
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _startLocation = LatLng(position.latitude, position.longitude);
        _initialCameraPosition = CameraPosition(
          target: _startLocation!,
          zoom: 15,
        );
      });

      // Start periodic location updates
      _locationUpdateTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _updateUserLocation(),
      );

      // Listen for nearby users
      _startNearbyUsersListener();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _updateRippleEffect() {
    if (!mounted || _routePoints.isEmpty) return;
    
    setState(() {
      _rippleEffects.clear();
      
      // Adding ripple effect for start location
      if (_startLocation != null) {
        _rippleEffects.add(
          Circle(
            circleId: const CircleId('start_ripple'),
            center: _startLocation!,
            radius: _pulseAnimation.value,
            strokeWidth: 2,
            strokeColor: Colors.blue.withOpacity(0.5),
            fillColor: Colors.blue.withOpacity(0.2),
          ),
        );
      }
      
      // Adding ripple effect for end location
      if (_endLocation != null) {
        _rippleEffects.add(
          Circle(
            circleId: const CircleId('end_ripple'),
            center: _endLocation!,
            radius: _pulseAnimation.value,
            strokeWidth: 2,
            strokeColor: Colors.red.withOpacity(0.5),
            fillColor: Colors.red.withOpacity(0.2),
          ),
        );
      }
    });
  }

  void _updateRouteAnimation() {
    if (!mounted || _routePoints.isEmpty) return;
    
    final currentIndex = (_routeProgress.value * _routePoints.length).floor();
    final animatedPoints = _routePoints.sublist(0, max(currentIndex, 1));
    
    setState(() {
      _animatedRoute = [
        Polyline(
          polylineId: const PolylineId('animated_route'),
          color: Colors.blue,
          width: 5,
          points: animatedPoints,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
          geodesic: true,
        ),
      ];
    });
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for speech input')),
        );
      }
      return;
    }

    try {
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
        onError: (errorNotification) => debugPrint('Speech recognition error: $errorNotification'),
      );

      if (mounted) {
        if (!available) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition is not available on this device')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing speech recognition: $e')),
        );
      }
    }
  }

  Set<Marker> _buildAnimatedMarkers() {
  Set<Marker> markers = {};
  
  // Add start location marker if available
  if (_startLocation != null) {
    
    final alpha = _markerScaleAnimation.value.clamp(0.0, 1.0);
    
    markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: _startLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Start Location'),
        alpha: alpha,
      ),
    );
  }

  // Add end location marker if available
  if (_endLocation != null) {
   
    final alpha = _markerScaleAnimation.value.clamp(0.0, 1.0);
    

    markers.add(
      Marker(
        markerId: const MarkerId('end'),
        position: _endLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'End Location'),
        alpha: alpha,
      ),

    );
  }

  if (_carMarker != null) {
    markers.add(_carMarker!);
  }

  // Add nearby user markers if enabled
  if (_showNearbyUsers) {
    for (var user in _nearbyUsers) {
      markers.add(
        Marker(
          markerId: MarkerId('user_${user.id}'),
          position: user.location,
          icon: _userMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: user.name,
            snippet: 'Distance: ${user.distance.toStringAsFixed(1)} km',
          ),
          alpha: 1.0,  
        ),
      );
    }
  }

  return markers;
}

Future<void> _fetchMembershipDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user logged in");

      final userDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        setState(() {
          _memberType = userDoc.data()?['membertype'] ?? 'BASIC';
          _offlineMapsCount = userDoc.data()?['offline_maps_count'] ?? 0;
          _isLoadingMembership = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching membership: $e');
      if (mounted) {
        setState(() => _isLoadingMembership = false);
      }
    }
  }

  Future<void> _loadSavedMaps() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final savedMapsDoc = await FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .collection('offline_maps')
        .orderBy('createdAt', descending: true)
        .get();

    if (!mounted) return;

    final maps = savedMapsDoc.docs
        .map((doc) => OfflineMap.fromMap(doc.data()))
        .toList();

    setState(() {
      _offlineMaps = maps;
      _offlineMapsCount = maps.length; 
    });

    // Update Firestore count to match actual number of maps
    await FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .update({'offline_maps_count': maps.length});
        
  } catch (e) {
    debugPrint('Error loading saved maps: $e');
    if (mounted && _offlineMaps.isNotEmpty) {
      setState(() {
        _offlineMapsCount = _offlineMaps.length;
      });
    }
  }
}
 Future<void> _saveMap() async {
  if (_directions.isEmpty || _routePoints.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No directions to save')),
    );
    return;
  }

  try {
    final canDownload = await MembershipHandler.checkDownloadPermission(
      memberType: _memberType ?? 'BASIC',
      currentMapCount: _offlineMaps.length,
      context: context,
    );

    if (!canDownload) return;

    final steps = _directions.map((step) => DirectionStep(
      instructions: _stripHtmlTags(step['html_instructions']),
      distance: step['distance']['text'],
      duration: step['duration']['text'],
    )).toList();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final mapId = DateTime.now().millisecondsSinceEpoch.toString();
      final offlineMap = OfflineMap(
        id: mapId,
        startLocation: _startController.text,
        endLocation: _endController.text,
        steps: steps,
        createdAt: DateTime.now(),
        routePoints: _routePoints,
      );

      await _directionsListController.reverse();
      
      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .collection('offline_maps')
          .doc(mapId)
          .set(offlineMap.toMap());

      setState(() {
        _offlineMaps.add(offlineMap);
        _offlineMapsCount = _offlineMaps.length;
      });

      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .update({'offline_maps_count': _offlineMaps.length});
      
      await _directionsListController.forward();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Map saved successfully'),
              Text(
                MembershipHandler.formatLimitDisplay(_memberType ?? 'BASIC', _offlineMaps.length),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving map: $e')),
    );
  }
}
  Future<void> _deleteMap(OfflineMap map) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Animate out
    await _directionsListController.reverse();

    await FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .collection('offline_maps')
        .doc(map.id)
        .delete();

    // Removed the map from local list first
    setState(() {
      _offlineMaps.removeWhere((m) => m.id == map.id);
      _offlineMapsCount = _offlineMaps.length;
    });
    
    // Update Firestore with new count
    await FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .update({'offline_maps_count': _offlineMaps.length});

    // Animate back in
    await _directionsListController.forward();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map deleted successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error deleting map: $e')),
    );
  }
}

  Future<void> _getCurrentLocation() async {
  try {
    final permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always && 
        permission != LocationPermission.whileInUse) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    final newLocation = LatLng(position.latitude, position.longitude);

    setState(() {
      _startLocation = newLocation;
      _initialCameraPosition = CameraPosition(
        target: newLocation,
        zoom: 15,
      );
    });

    // Update map camera
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(_initialCameraPosition),
    );

    // Get and set the address
    await _fetchAddressForLocation(newLocation, isStart: true);

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting current location: $e')),
      );
    }
  }
}

Future<void> _fetchAddressForLocation(LatLng location, {required bool isStart}) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${location.latitude},${location.longitude}'
        '&key=${Config.googleApiKey}',
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        final address = data['results'][0]['formatted_address'];
        setState(() {
          if (isStart) {
            _startController.text = address;
          } else {
            _endController.text = address;
          }
        });
      }
    }
  } catch (e) {
    debugPrint('Error fetching address: $e');
  }
}
Future<void> _searchDirections() async {
  if (_startLocation == null || _endLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select start and end locations')),
    );
    return;
  }

  // Reseting any existing animations
  _stopCarAnimation();
  _pulseController.reset();
  _bounceController.reset();
  _routeController.reset();

  try {
    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_startLocation!.latitude},${_startLocation!.longitude}'
        '&destination=${_endLocation!.latitude},${_endLocation!.longitude}'
        '&key=${Config.googleApiKey}',
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['routes'].isNotEmpty) {
        setState(() {
          _directions = data['routes'][0]['legs'][0]['steps'];
          _routePoints = _decodePolyline(data['routes'][0]['overview_polyline']['points']);
          
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: _routePoints,
              endCap: Cap.roundCap,
              startCap: Cap.roundCap,
              geodesic: true,
              patterns: [
                PatternItem.dash(20),
                PatternItem.gap(10),
              ],
            ),
          );
        });

        // Start animations
        await _startAnimations();

        // Adjust map bounds to show the entire route
        if (!mounted) return;
        _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            _boundsFromLatLngList(_getRouteLatLngs(data['routes'][0]['legs'][0]['steps'])),
            50, 
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No route found')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.statusCode}')),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error finding directions: $e')),
    );
  }
}

List<LatLng> _getRouteLatLngs(List<dynamic> steps) {
  final List<LatLng> points = [];
  
  for (final step in steps) {
    points.add(LatLng(
      step['start_location']['lat'],
      step['start_location']['lng'],
    ));
    
    points.add(LatLng(
      step['end_location']['lat'],
      step['end_location']['lng'],
    ));
    
    if (step['polyline'] != null && step['polyline']['points'] != null) {
      points.addAll(_decodePolyline(step['polyline']['points']));
    }
  }
  
  return points;
}

List<LatLng> _decodePolyline(String encoded) {
  List<LatLng> points = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    points.add(LatLng(lat * 1e-5, lng * 1e-5));
  }

  return points;
}

LatLngBounds _boundsFromLatLngList(List<LatLng> points) {
  double? minLat, maxLat, minLng, maxLng;
  
  for (final point in points) {
    if (minLat == null || point.latitude < minLat) {
      minLat = point.latitude;
    }
    if (maxLat == null || point.latitude > maxLat) {
      maxLat = point.latitude;
    }
    if (minLng == null || point.longitude < minLng) {
      minLng = point.longitude;
    }
    if (maxLng == null || point.longitude > maxLng) {
      maxLng = point.longitude;
    }
  }

  return LatLngBounds(
    southwest: LatLng(minLat! - 0.1, minLng! - 0.1),
    northeast: LatLng(maxLat! + 0.1, maxLng! + 0.1),
  );
}

Future<void> _startAnimations() async {
  _isNavigating = true;
  _pulseController.repeat();
  _bounceController.repeat(reverse: true);
  _routeController.forward();
  _startCarAnimation();
  
  await _markerAnimationController.forward();
  await _mapExpandController.forward();
  await _directionsListController.forward();
}
void _stopCarAnimation() {
  _carAnimationTimer?.cancel();
  _carAnimationTimer = null;
  if (mounted) {
    setState(() {
      _carMarker = null;
      _carAnimationIndex = 0;
    });
  }
}

void _startCarAnimation() {
  _carAnimationIndex = 0;
  _updateCarMarker();
  
  _carAnimationTimer = Timer.periodic(
    const Duration(milliseconds: 100), 
    (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_carAnimationIndex < _routePoints.length - 1) {
        setState(() {
          _carAnimationIndex++;
          _updateCarMarker();
        });
      } else {
        _stopCarAnimation();
      }
    }
  );
}

void _updateCarMarker() {
  if (_carAnimationIndex >= _routePoints.length) return;
  
  final currentPoint = _routePoints[_carAnimationIndex];
  LatLng? nextPoint;
  
  if (_carAnimationIndex < _routePoints.length - 1) {
    nextPoint = _routePoints[_carAnimationIndex + 1];
    _carRotation = _calculateRotation(currentPoint, nextPoint);
  }

  setState(() {
    _carMarker = Marker(
      markerId: const MarkerId('car'),
      position: currentPoint,
      rotation: _carRotation,
      icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      flat: true,
      anchor: const Offset(0.5, 0.5),
      alpha: 1.0,  
      zIndex: 2,
    );
  });
}
double _calculateRotation(LatLng from, LatLng to) {
  final double deltaLng = to.longitude - from.longitude;
  final double deltaLat = to.latitude - from.latitude;
  return (atan2(deltaLng, deltaLat) * 180.0 / pi);
}
Future<void> _listen(TextEditingController controller) async {
  if (!_speech.isAvailable) {
    await _initSpeech();
  }

  if (!_isListening) {
    setState(() {
      _isListening = true;
      _activeController = controller;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _activeController?.text = result.recognizedWords;
            if (result.hasConfidenceRating && result.confidence > 0) {
              // Perform search when we have confident result
              _performSearch(
                result.recognizedWords, 
                _activeController == _startController
              );
            }
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting voice input: $e')),
        );
      }
    }
  } else {
    // Stop listening
    setState(() => _isListening = false);
    await _speech.stop();
  }
}

Future<void> _performSearch(String query, bool isStart) async {
  if (query.isEmpty) return;

  try {
    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=${Uri.encodeComponent(query)}'
        '&key=${Config.googleApiKey}'
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        final result = data['results'][0];
        final location = result['geometry']['location'];
        final address = result['formatted_address'] ?? result['name'] ?? '';
        
        setState(() {
          if (isStart) {
            _startLocation = LatLng(location['lat'], location['lng']);
            if (_startController.text != address) {
              _startController.text = address;
            }
          } else {
            _endLocation = LatLng(location['lat'], location['lng']);
            if (_endController.text != address) {
              _endController.text = address;
            }
          }
        });

        // Only animate camera if both locations aren't set yet
        if (_startLocation == null || _endLocation == null) {
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(location['lat'], location['lng']),
              15,
            ),
          );
        } else {
          // If both locations are set, show the full route
          LatLngBounds bounds = LatLngBounds(
            southwest: LatLng(
              min(_startLocation!.latitude, _endLocation!.latitude),
              min(_startLocation!.longitude, _endLocation!.longitude),
            ),
            northeast: LatLng(
              max(_startLocation!.latitude, _endLocation!.latitude),
              max(_startLocation!.longitude, _endLocation!.longitude),
            ),
          );
          
          _mapController.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }
      }
    }
  } catch (e) {
    debugPrint('Error searching location: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching location: $e')),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        backgroundColor: Colors.teal,
        actions: _buildAppBarActions(),
      ),
      body: Column(
        children: [
          _buildSearchInputs(),
          _buildDirectionsButton(),
          _buildMap(),
          if (_directions.isNotEmpty) _buildDirectionsList(),
        ],
      ),
    );
  }

List<Widget> _buildAppBarActions() {
  return [
    if (!_isLoadingMembership)
      FadeTransition(
        opacity: _searchBarController,
        child: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text(
            MembershipHandler.formatLimitDisplay(
              _memberType ?? 'BASIC',
              _offlineMapsCount,
            ),
          ),
        ),
      ),
    if (_directions.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.download),
        onPressed: _saveMap,
        tooltip: 'Save Map',
      ),
    IconButton(
      icon: Icon(_showNearbyUsers ? Icons.people : Icons.people_outline),
      onPressed: () {
        setState(() => _showNearbyUsers = !_showNearbyUsers);
      },
      tooltip: 'Toggle Nearby Users',
    ),
    IconButton(
      icon: const Icon(Icons.folder),
      onPressed: _showAnimatedBottomSheet,
      tooltip: 'View Saved Maps',
    ),
  ];
}

void _showAnimatedBottomSheet() {
  final limit = MembershipHandler._mapLimits[_memberType?.toUpperCase() ?? 'BASIC'] ?? 
                MembershipHandler._mapLimits['BASIC']!;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      OfflineMap? selectedMap;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          Widget buildDirectionsView(OfflineMap map) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => setModalState(() => selectedMap = null),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Route Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${map.startLocation} → ${map.endLocation}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Map Preview
                Builder(
                  builder: (context) {
                    final routePoints = map.routePoints;
                    if (routePoints == null || routePoints.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      height: 200,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: routePoints.first,
                            zoom: 12,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('start'),
                              position: routePoints.first,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                            ),
                            Marker(
                              markerId: const MarkerId('end'),
                              position: routePoints.last,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                            ),
                          },
                          polylines: {
                            Polyline(
                              polylineId: const PolylineId('route'),
                              points: routePoints,
                              color: Colors.blue,
                              width: 5,
                            ),
                          },
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationButtonEnabled: false,
                          scrollGesturesEnabled: false,
                        ),
                      ),
                    );
                  },
                ),
                 
                Expanded(
                  child: ListView.builder(
                    itemCount: map.steps.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final step = map.steps[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(step.instructions),
                          subtitle: Text('${step.distance} - ${step.duration}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return AnimatedPadding(
            padding: MediaQuery.of(context).viewInsets,
            duration: const Duration(milliseconds: 200),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: selectedMap == null 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Saved Maps',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${min(_offlineMapsCount, limit)}/${limit == -1 ? '∞' : limit}',
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Maps List
                      Expanded(
                        child: _offlineMaps.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No saved maps yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Search for directions and tap save to add maps',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _offlineMaps.length,
                              padding: const EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                final map = _offlineMaps[index];
                                final isAccessible = index < limit || limit == -1;

                                return Stack(
                                  children: [
                                    Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 8,
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: isAccessible ? Colors.teal : Colors.grey,
                                          child: const Icon(
                                            Icons.map,
                                            color: Colors.white,
                                          ),
                                        ),
                                        title: Text(
                                          '${map.startLocation} → ${map.endLocation}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          'Saved on ${DateFormat('MMM d, y').format(map.createdAt)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        onTap: isAccessible 
                                          ? () => setModalState(() => selectedMap = map)
                                          : () => _showUpgradeDialog(),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isAccessible) ...[
                                              IconButton(
                                                icon: const Icon(Icons.directions),
                                                color: Colors.teal,
                                                onPressed: () {
                                                  setState(() {
                                                    _startController.text = map.startLocation;
                                                    _endController.text = map.endLocation;
                                                  });
                                                  Navigator.pop(context);
                                                  _performSearch(map.startLocation, true);
                                                  _performSearch(map.endLocation, false);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline),
                                                color: Colors.red[400],
                                                onPressed: () => _deleteMap(map),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (!isAccessible)
                                      Positioned.fill(
                                        child: GestureDetector(
                                          onTap: () => _showUpgradeDialog(),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: BackdropFilter(
                                              filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                              child: Container(
                                                color: Colors.white.withOpacity(0.6),
                                                child: const Center(
                                                  child: Text(
                                                    'Upgrade membership to access',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                      ),
                    ],
                  )
                : buildDirectionsView(selectedMap!),
            ),
          );
        },
      );
    },
  );
}

Widget _buildDirectionsView(BuildContext context, OfflineMap map, Function(OfflineMap?) onUpdateMap) {
  return Column(
    children: [
      // Header
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => onUpdateMap(null),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Route Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${map.startLocation} → ${map.endLocation}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      Builder(
        builder: (context) {
          final routePoints = map.routePoints;
          if (routePoints == null || routePoints.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: routePoints.first,
                  zoom: 12,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('start'),
                    position: routePoints.first,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  ),
                  Marker(
                    markerId: const MarkerId('end'),
                    position: routePoints.last,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: routePoints,
                    color: Colors.blue,
                    width: 5,
                  ),
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                scrollGesturesEnabled: false,
              ),
            ),
          );
        },
      ),
     
      Expanded(
        child: ListView.builder(
          itemCount: map.steps.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final step = map.steps[index];
            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text('${index + 1}'),
                ),
                title: Text(step.instructions),
                subtitle: Text('${step.distance} - ${step.duration}'),
              ),
            );
          },
        ),
      ),
    ],
  );
}
void _showUpgradeDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Upgrade Membership'),
      content: Text(
        'Upgrade your membership to access more saved maps.\n\n'
        'Current plan: ${_memberType ?? "BASIC"}'
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Upgrade Now'),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageMembership(),
              ),
            );
          },
        ),
      ],
    ),
  );
}
  Widget _buildSearchInputs() {
  return SlideTransition(
    position: _searchBarSlideAnimation,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _startController,
            decoration: InputDecoration(
              labelText: 'Start Location',
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_startController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _startLocation = null;
                          _startController.clear();
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                  ),
                  IconButton(
                    icon: Icon(_isListening && _activeController == _startController 
                      ? Icons.mic : Icons.mic_none),
                    onPressed: () => _listen(_startController),
                  ),
                ],
              ),
            ),
            onChanged: (value) {
              if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
              _debounceTimer = Timer(
                const Duration(milliseconds: 1000),
                () => _performSearch(value, true),
              );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _endController,
            decoration: InputDecoration(
              labelText: 'End Location',
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _endLocation = null;
                          _endController.clear();
                        });
                      },
                    ),
                  IconButton(
                    icon: Icon(_isListening && _activeController == _endController 
                      ? Icons.mic : Icons.mic_none),
                    onPressed: () => _listen(_endController),
                  ),
                ],
              ),
            ),
            onChanged: (value) {
              if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
              _debounceTimer = Timer(
                const Duration(milliseconds: 1000),
                () => _performSearch(value, false),
              );
            },
          ),
        ],
      ),
    ),
  );
}
  Widget _buildDirectionsButton() {
    return ElevatedButton.icon(
      onPressed: _searchDirections,
      icon: const Icon(Icons.directions),
      label: const Text('Get Directions'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildMap() {
    return Expanded(
      child: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (controller) => _mapController = controller,
        markers: _buildAnimatedMarkers(),
        polylines: {..._polylines, ..._animatedRoute},
        circles: Set<Circle>.from(_rippleEffects),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      ),
    );
  }

  Widget _buildDirectionsList() {
    return FadeTransition(
      opacity: _directionsOpacity,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ListView.builder(
          itemCount: _directions.length,
          itemBuilder: (context, index) {
            final step = _directions[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                child: Text('${index + 1}'),
                
              ),
              title: Text(_stripHtmlTags(step['html_instructions'])),
              subtitle: Text(
                '${step['distance']['text']} - ${step['duration']['text']}',
              ),
            );
          },
        ),
      ),
    );
  }

  String _stripHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }

  @override
  void dispose() {
    _mapController.dispose();
    _mapExpandController.dispose();
    _directionsListController.dispose();
    _searchBarController.dispose();
    _markerAnimationController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    _routeController.dispose();
    _speech.stop();
    _startController.dispose();
    _endController.dispose();
    _debounceTimer?.cancel();
    _carAnimationTimer?.cancel();
    _nearbyUsersSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _pulseAnimation.removeListener(_updateRippleEffect);
    _routeProgress.removeListener(_updateRouteAnimation);
    super.dispose();
  }
}