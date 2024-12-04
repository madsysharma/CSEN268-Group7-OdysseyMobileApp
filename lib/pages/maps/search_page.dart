import 'dart:async';
import 'dart:math';
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


// Membership Handler Class
class MembershipHandler {
  static const Map<String, int> _mapLimits = {
    'BASIC': 3,
    'PREMIUM': 5,
    'ELITE': -1, // Unlimited
  };

  static Future<DownloadPermissionResult> checkDownloadPermission({
    required String memberType,
    required int currentMapCount,
    required BuildContext context,
  }) async {
    final effectiveMemberType = memberType.toUpperCase();
    final limit = _mapLimits[effectiveMemberType] ?? _mapLimits['BASIC']!;
    
    if (limit == -1) {
      return DownloadPermissionResult(
        canDownload: true,
        message: 'Download permitted - Elite membership',
      );
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

      return DownloadPermissionResult(
        canDownload: false,
        message: 'Save limit reached for $effectiveMemberType membership ($currentMapCount/$limit)',
      );
    }

    return DownloadPermissionResult(
      canDownload: true,
      message: 'Save permitted ($currentMapCount/$limit maps used)',
    );
  }

  static int getMembershipLimit(String memberType) {
    return _mapLimits[memberType.toUpperCase()] ?? _mapLimits['BASIC']!;
  }

  static String formatLimitDisplay(String memberType, int currentCount) {
    final limit = getMembershipLimit(memberType);
    return '$currentCount/${limit == -1 ? '∞' : limit}';
  }
}

class DownloadPermissionResult {
  final bool canDownload;
  final String message;

  DownloadPermissionResult({
    required this.canDownload,
    required this.message,
  });
}

// Direction Step Model
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

// Offline Map Model
class OfflineMap {
  final String id;
  final String startLocation;
  final String endLocation;
  final List<DirectionStep> steps;
  final DateTime createdAt;

  OfflineMap({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.steps,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'steps': steps.map((step) => step.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
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
    );
  }
}

// Main Search Page Widget
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
  bool _isListening = false;
  TextEditingController? _activeController;
  Timer? _debounceTimer;
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
  BitmapDescriptor? _carIcon;

  // Car Animation
  Marker? _carMarker;
  Timer? _carAnimationTimer;
  int _carAnimationIndex = 0;
  double _carRotation = 0.0;

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
    _createCarIcon();
    _loadCarIcon();
    _initializeAnimationControllers();
    _setupAnimations();
    _startInitialAnimations();
    _initializeComponents();
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

    // Add animation listeners
    _pulseAnimation.addListener(_updateRippleEffect);
    _routeProgress.addListener(_updateRouteAnimation);
  }

  void _startInitialAnimations() {
    _searchBarController.forward();
  }

  void _initializeComponents() {
    if (widget.endLocation != null) {
      _endLocation = widget.endLocation;
      _fetchAddressForLocation(_endLocation!, isEnd: true);
    }
    _getCurrentLocation();
    _fetchMembershipDetails();
    _loadSavedMaps();
  }

  void _updateRippleEffect() {
    if (!mounted || _startLocation == null) return;
    
    setState(() {
      _rippleEffects.clear();
      _rippleEffects.add(
        Circle(
          circleId: const CircleId('ripple'),
          center: _startLocation!,
          radius: _pulseAnimation.value,
          strokeWidth: 2,
          strokeColor: Colors.blue.withOpacity(0.5),
          fillColor: Colors.blue.withOpacity(0.2),
        ),
      );
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
  Future<void> _initSpeech() async {
    await _requestPermission();
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => debugPrint('Error: $error'),
    );
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }
  }


  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (!mounted) return;

      setState(() {
        _startLocation = LatLng(position.latitude, position.longitude);
        _initialCameraPosition = CameraPosition(
          target: _startLocation!,
          zoom: 12,
        );
      });
      
      _fetchAddressForLocation(_startLocation!, isEnd: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting current location: $e')),
        );
      }
    }
  }

  Future<void> _fetchAddressForLocation(LatLng location, {required bool isEnd}) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=${Config.googleApiKey}',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final address = _formatAddress(data['results'][0]);
          
          setState(() {
            if (isEnd) {
              _endController.text = address;
              _endLocation = location;
            } else {
              _startController.text = address;
              _startLocation = location;
            }
          });
        } else {
          _handleGeocodeError('No address found for this location');
        }
      } else {
        _handleGeocodeError('Failed to fetch address: ${response.statusCode}');
      }
    } catch (e) {
      _handleGeocodeError('Error fetching address: $e');
    }
  }

  String _formatAddress(Map<String, dynamic> result) {
    final List<dynamic> components = result['address_components'];
    String formattedAddress = result['formatted_address'];
    
    try {
      final streetNumber = _getAddressComponent(components, 'street_number');
      final route = _getAddressComponent(components, 'route');
      final locality = _getAddressComponent(components, 'locality');
      final area = _getAddressComponent(components, 'administrative_area_level_1');
      
      if (streetNumber.isNotEmpty && route.isNotEmpty) {
        formattedAddress = '$streetNumber $route';
        if (locality.isNotEmpty) {
          formattedAddress += ', $locality';
        }
        if (area.isNotEmpty) {
          formattedAddress += ', $area';
        }
      }
    } catch (e) {
      debugPrint('Error formatting address: $e');
      // Fall back to full formatted address if there's an error
    }
    
    return formattedAddress;
  }

  String _getAddressComponent(List<dynamic> components, String type) {
    try {
      return components
          .firstWhere(
            (component) => component['types'].contains(type),
            orElse: () => {'long_name': ''},
          )['long_name'];
    } catch (e) {
      return '';
    }
  }

  void _handleGeocodeError(String message) {
    if (!mounted) return;
    debugPrint(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _activeController?.text = result.recognizedWords;
            if (!result.hasConfidenceRating || result.confidence > 0) {
              _performSearch(result.recognizedWords, _activeController == _startController);
            }
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  Future<void> _searchDirections() async {
    if (_startLocation == null || _endLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end locations')),
      );
      return;
    }

    _stopCarAnimation();
    _pulseController.reset();
    _bounceController.reset();
    _routeController.reset();

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${_startLocation!.latitude},${_startLocation!.longitude}&destination=${_endLocation!.latitude},${_endLocation!.longitude}&key=${Config.googleApiKey}',
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
          _startAnimations();

          if (!mounted) return;

          _mapController.animateCamera(
            CameraUpdate.newLatLngBounds(
              _boundsFromLatLngList(_getRouteLatLngs(data['routes'][0]['legs'][0]['steps'])),
              50,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding directions: $e')),
      );
    }
  }

  void _startAnimations() async {
    _isNavigating = true;
    _pulseController.repeat();
    _bounceController.repeat(reverse: true);
    _routeController.forward();
    _startCarAnimation();
    
    await _markerAnimationController.forward();
    await _mapExpandController.forward();
    await _directionsListController.forward();
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

Future<void> _createCarIcon() async {
  const double width = 30;  // Swapped width and height
  const double height = 60; // to orient car vertically
  
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()
    ..color = Colors.blue[600] ?? Colors.blue
    ..style = PaintingStyle.fill
    ..strokeWidth = 1.5;

  // Car body (rotated 90 degrees)
  final bodyPath = Path()
    ..moveTo(width * 0.25, height * 0.1)  // Start at top left
    ..lineTo(width * 0.75, height * 0.1)  // Top of car
    ..lineTo(width * 0.75, height * 0.9)  // Right side
    ..lineTo(width * 0.25, height * 0.9)  // Bottom
    ..close();  // Back to start

  // Draw shadow
  final shadowPath = Path()
    ..addPath(bodyPath, Offset(2, 2));
  canvas.drawPath(
    shadowPath,
    Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill
  );

  // Draw car body
  canvas.drawPath(bodyPath, paint);

  // Windows
  final windowPaint = Paint()
    ..color = Colors.white.withOpacity(0.9)
    ..style = PaintingStyle.fill;

  // Front windshield
  canvas.drawPath(
    Path()
      ..moveTo(width * 0.3, height * 0.15)
      ..lineTo(width * 0.7, height * 0.15)
      ..lineTo(width * 0.7, height * 0.3)
      ..lineTo(width * 0.3, height * 0.3)
      ..close(),
    windowPaint
  );

  // Back windshield
  canvas.drawPath(
    Path()
      ..moveTo(width * 0.3, height * 0.7)
      ..lineTo(width * 0.7, height * 0.7)
      ..lineTo(width * 0.7, height * 0.85)
      ..lineTo(width * 0.3, height * 0.85)
      ..close(),
    windowPaint
  );

  // Wheels
  final wheelPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill;

  // Left wheel
  canvas.drawCircle(
    Offset(width * 0.2, height * 0.35),
    width * 0.15,
    wheelPaint
  );
  canvas.drawCircle(
    Offset(width * 0.2, height * 0.35),
    width * 0.1,
    Paint()..color = Colors.grey[800]!
  );

  // Right wheel
  canvas.drawCircle(
    Offset(width * 0.2, height * 0.65),
    width * 0.15,
    wheelPaint
  );
  canvas.drawCircle(
    Offset(width * 0.2, height * 0.65),
    width * 0.1,
    Paint()..color = Colors.grey[800]!
  );

  // Left wheel
  canvas.drawCircle(
    Offset(width * 0.8, height * 0.35),
    width * 0.15,
    wheelPaint
  );
  canvas.drawCircle(
    Offset(width * 0.8, height * 0.35),
    width * 0.1,
    Paint()..color = Colors.grey[800]!
  );

  // Right wheel
  canvas.drawCircle(
    Offset(width * 0.8, height * 0.65),
    width * 0.15,
    wheelPaint
  );
  canvas.drawCircle(
    Offset(width * 0.8, height * 0.65),
    width * 0.1,
    Paint()..color = Colors.grey[800]!
  );

  // Headlights
  canvas.drawCircle(
    Offset(width * 0.3, height * 0.1),
    width * 0.08,
    Paint()..color = Colors.yellow.withOpacity(0.8)
  );
  canvas.drawCircle(
    Offset(width * 0.7, height * 0.1),
    width * 0.08,
    Paint()..color = Colors.yellow.withOpacity(0.8)
  );

  // Taillights
  canvas.drawCircle(
    Offset(width * 0.3, height * 0.9),
    width * 0.08,
    Paint()..color = Colors.red.withOpacity(0.8)
  );
  canvas.drawCircle(
    Offset(width * 0.7, height * 0.9),
    width * 0.08,
    Paint()..color = Colors.red.withOpacity(0.8)
  );

  // Convert to image
  final picture = pictureRecorder.endRecording();
  final img = await picture.toImage(width.toInt(), height.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  
  if (data != null) {
    setState(() {
      _carIcon = BitmapDescriptor.fromBytes(data.buffer.asUint8List());
    });
  }
}

// Update the marker creation to use a better anchor point
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
      anchor: const Offset(0.5, 0.5), // Center the icon
      alpha: 1.0,
      zIndex: 2,
    );
  });
}
  double _calculateRotation(LatLng from, LatLng to) {
  final double deltaLng = to.longitude - from.longitude;
  final double deltaLat = to.latitude - from.latitude;
  final double rotation = (atan2(deltaLng, deltaLat) * 180.0 / pi); // Removed the + 180
  return rotation;
}

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int result = 1;
      int shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63 - 1;
        result += b << shift;
        shift += 5;
      } while (b >= 0x1f);
      lat += (result & 1 != 0 ? ~(result >> 1) : (result >> 1));

      result = 1;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63 - 1;
        result += b << shift;
        shift += 5;
      } while (b >= 0x1f);
      lng += (result & 1 != 0 ? ~(result >> 1) : (result >> 1));

      points.add(LatLng(lat / 1e5, lng / 1e5));
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

    // Add padding to the bounds
    final latPadding = (maxLat! - minLat!) * 0.1;
    final lngPadding = (maxLng! - minLng!) * 0.1;
    
    return LatLngBounds(
      southwest: LatLng(minLat! - latPadding, minLng! - lngPadding),
      northeast: LatLng(maxLat! + latPadding, maxLng! + lngPadding),
    );
  }

  List<LatLng> _getRouteLatLngs(List<dynamic> steps) {
    final List<LatLng> points = [];
    
    for (final step in steps) {
      // Add start location of each step
      points.add(LatLng(
        step['start_location']['lat'],
        step['start_location']['lng'],
      ));
      
      // Add end location of each step
      points.add(LatLng(
        step['end_location']['lat'],
        step['end_location']['lng'],
      ));
      
      // If the step has a polyline, decode and add those points too
      if (step['polyline'] != null && step['polyline']['points'] != null) {
        points.addAll(_decodePolyline(step['polyline']['points']));
      }
    }
    
    return points;
  }

  Future<void> _performSearch(String query, bool isStart) async {
    if (query.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=${Config.googleApiKey}',
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
              _startController.text = address;
            } else {
              _endLocation = LatLng(location['lat'], location['lng']);
              _endController.text = address;
            }
          });

          _mapController.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(location['lat'], location['lng'])
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error searching locations: $e');
    }
  }

  String _stripHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }

  void _showSavedDirections(OfflineMap map) async {
  Navigator.pop(context);

  if (!mounted) return;

  // Reset animations
  _mapExpandController.reset();
  _directionsListController.reset();
  _markerAnimationController.reset();

  setState(() {
    _startController.text = map.startLocation;
    _endController.text = map.endLocation;
    _directions = map.steps.map((step) => {
      'html_instructions': step.instructions,
      'distance': {'text': step.distance},
      'duration': {'text': step.duration},
    }).toList();
  });

  if (!mounted) return;

  // Replay animations
  await _markerAnimationController.forward();
  await _mapExpandController.forward();
  await _directionsListController.forward();
}

Future<void> _loadCarIcon() async {
    try {
      _carIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(64, 64)),
        'assets/car_icon.png', // Make sure to add this in pubspec.yaml
      );
      setState(() {}); // Trigger rebuild if needed
    } catch (e) {
      debugPrint('Error loading car icon: $e');
      // Fallback to default marker if loading fails
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
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

      setState(() {
        _offlineMaps = savedMapsDoc.docs
            .map((doc) => OfflineMap.fromMap(doc.data()))
            .toList();
      });

      if (_offlineMaps.isEmpty) {
        await FirebaseFirestore.instance
            .collection('User')
            .doc(user.uid)
            .update({'offline_maps_count': 0});
        
        setState(() {
          _offlineMapsCount = 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved maps: $e');
    }
  }

  Future<void> _saveMap() async {
    if (_directions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No directions to save')),
      );
      return;
    }

    try {
      final permissionResult = await MembershipHandler.checkDownloadPermission(
        memberType: _memberType ?? 'BASIC',
        currentMapCount: _offlineMapsCount,
        context: context,
      );

      if (!permissionResult.canDownload) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(permissionResult.message)),
        );
        return;
      }

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
        );

        // Save with animation
        await _directionsListController.reverse();
        
        await FirebaseFirestore.instance
            .collection('User')
            .doc(user.uid)
            .collection('offline_maps')
            .doc(mapId)
            .set(offlineMap.toMap());

        await FirebaseFirestore.instance
            .collection('User')
            .doc(user.uid)
            .update({'offline_maps_count': _offlineMapsCount + 1});

        setState(() => _offlineMapsCount++);
        await _loadSavedMaps();
        
        await _directionsListController.forward();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Map saved successfully'),
                Text(
                  MembershipHandler.formatLimitDisplay(_memberType ?? 'BASIC', _offlineMapsCount),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
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

      final newCount = _offlineMapsCount > 0 ? _offlineMapsCount - 1 : 0;
      
      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .update({'offline_maps_count': newCount});

      setState(() => _offlineMapsCount = newCount);
      await _loadSavedMaps();
      
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

  void _animatedSwapLocations() async {
    // Fade out
    await _searchBarController.reverse();
    
    final tempLocation = _startLocation;
    final tempText = _startController.text;
    
    setState(() {
      _startLocation = _endLocation;
      _startController.text = _endController.text;
      
      _endLocation = tempLocation;
      _endController.text = tempText;
    });
    
    // Fade back in
    await _searchBarController.forward();
  }

  Set<Marker> _buildAnimatedMarkers() {
    final markers = <Marker>{};
    final markerAlpha = _markerScaleAnimation.value.clamp(0.0, 1.0);
    final bounceOffset = _isNavigating ? _bounceAnimation.value : 0.0;
    
    if (_startLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: _startLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Start Location'),
        alpha: markerAlpha,
        anchor: Offset(0.5, 1.0 + bounceOffset / 100),
      ));
    }
    
    if (_endLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('end'),
        position: _endLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'End Location'),
        alpha: markerAlpha,
        anchor: Offset(0.5, 1.0 + bounceOffset / 100),
      ));
    }
    
    if (_carMarker != null) {
      markers.add(_carMarker!.copyWith(
        alphaParam: 1.0,
        anchorParam: Offset(0.5, 0.5 + bounceOffset / 100),
      ));
    }
    
    return markers;
  }

  void _showAnimatedBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildAnimatedSavedMapsSheet(),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Widget _buildAnimatedSavedMapsSheet() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(16),
              child: _buildSavedMapsContent(),
            ),
          ),
        );
      },
    );
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
            child: Center(
              child: Text(
                MembershipHandler.formatLimitDisplay(
                  _memberType ?? 'BASIC',
                  _offlineMapsCount,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      if (_directions.isNotEmpty)
        ScaleTransition(
          scale: _directionsOpacity,
          child: IconButton(
            icon: const Icon(Icons.download),
            onPressed: _saveMap,
            tooltip: 'Save Map',
          ),
        ),
      IconButton(
        icon: const Icon(Icons.map),
        onPressed: () => _showAnimatedBottomSheet(),
        tooltip: 'Saved Maps',
      ),
    ];
  }

  Widget _buildSearchInputs() {
    return SlideTransition(
      position: _searchBarSlideAnimation,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: _buildAnimatedTextField(
                controller: _startController,
                label: 'Start Location',
                isStart: true,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.swap_vert),
              onPressed: _animatedSwapLocations,
            ),
            Expanded(
              child: _buildAnimatedTextField(
                controller: _endController,
                label: 'End Location',
                isStart: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required bool isStart,
  }) {
    final bool isActiveController = controller == _activeController;
    
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    if (isStart) {
                      _startLocation = null;
                      _startController.clear();
                    } else {
                      _endLocation = null;
                      _endController.clear();
                    }
                    _polylines.clear();
                    _directions = [];
                  });
                },
              ),
            IconButton(
              icon: Icon(
                _isListening && isActiveController ? Icons.mic : Icons.mic_none,
                color: _isListening && isActiveController ? Colors.red : null,
              ),
              onPressed: () => _listen(controller),
            ),
          ],
        ),
      ),
      onChanged: (value) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(
          const Duration(milliseconds: 1000),
          () => _performSearch(value, isStart),
        );
      },
    );
  }

  Widget _buildDirectionsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: _searchDirections,
        icon: const Icon(Icons.directions),
        label: const Text('Get Directions'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return AnimatedBuilder(
      animation: _mapHeightAnimation,
      builder: (context, child) {
        return Expanded(
          flex: (_mapHeightAnimation.value * 10).round(),
          child: GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            polylines: {..._polylines, ..._animatedRoute},
            markers: _buildAnimatedMarkers(),
            circles: Set<Circle>.from(_rippleEffects),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            mapToolbarEnabled: true,
          ),
        );
      },
    );
  }

  Widget _buildDirectionsList() {
    return FadeTransition(
      opacity: _directionsOpacity,
      child: SizeTransition(
        sizeFactor: _directionsOpacity,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDirectionsHeader(),
              Expanded(
                child: _buildDirectionsStepsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionsHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Icon(Icons.directions, color: Colors.teal),
          const SizedBox(width: 8),
          const Text(
            'Directions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${_directions.length} steps',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionsStepsList() {
    return ListView.builder(
      itemCount: _directions.length,
      itemBuilder: (context, index) {
        final step = _directions[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + (index * 100)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildDirectionStep(step, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDirectionStep(dynamic step, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          _stripHtmlTags(step['html_instructions']),
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          '${step['distance']['text']} - ${step['duration']['text']}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedMapsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Maps',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Using ${MembershipHandler.formatLimitDisplay(_memberType ?? 'BASIC', _offlineMapsCount)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _offlineMaps.isEmpty
              ? _buildEmptySavedMaps()
              : _buildSavedMapsList(),
        ),
      ],
    );
  }

  Widget _buildEmptySavedMaps() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved maps',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedMapsList() {
    return ListView.builder(
      itemCount: _offlineMaps.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + (index * 100)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(100 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: _buildSavedMapItem(_offlineMaps[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedMapItem(OfflineMap map) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(
          '${map.startLocation} to ${map.endLocation}',
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          'Saved on ${DateFormat('MMM d, y HH:mm').format(map.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.directions, color: Colors.teal),
              onPressed: () => _showSavedDirections(map),
              tooltip: 'Show Directions',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[300]),
              onPressed: () => _deleteMap(map),
              tooltip: 'Delete Map',
            ),
          ],
        ),
        children: [
          _buildSavedMapSteps(map.steps),
        ],
      ),
    );
  }

  Widget _buildSavedMapSteps(List<DirectionStep> steps) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, stepIndex) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 150 + (stepIndex * 50)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    radius: 12,
                    child: Text(
                      '${stepIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  title: Text(
                    steps[stepIndex].instructions,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    '${steps[stepIndex].distance} - ${steps[stepIndex].duration}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  dense: true,
                ),
              ),
            );
          },
        );
      },
    );
  }

 @override
void dispose() {
  // Cancel all animation controllers
  _mapController.dispose();
  _mapExpandController.dispose();
  _directionsListController.dispose();
  _searchBarController.dispose();
  _markerAnimationController.dispose();
  _pulseController.dispose();
  _bounceController.dispose();
  _routeController.dispose();
   _speech.stop();
  
  // Cancel text controllers
  _startController.dispose();
  _endController.dispose();
  
  // Cancel timers and animations
  _debounceTimer?.cancel();
  _carAnimationTimer?.cancel();
  
  // Remove animation listeners
  _pulseAnimation.removeListener(_updateRippleEffect);
  _routeProgress.removeListener(_updateRouteAnimation);
  
  // Clear any pending animations
  _isNavigating = false;
  _carMarker = null;
  _carAnimationIndex = 0;
  
  super.dispose();
}



}