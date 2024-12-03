import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/manage_membership.dart';

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
          title: Text('Map Download Limit Reached'),
          content: Text(
            'You have reached your limit of $limit saved maps for your '
            '$effectiveMemberType membership.\n\n'
            'Would you like to upgrade your membership to save more maps?'
          ),
          actions: [
            TextButton(
              child: Text('Not Now'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: Text('Upgrade Membership'),
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

class _SearchPageState extends State<SearchPage> {
  // Controllers
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  Timer? _debounceTimer;
  late GoogleMapController _mapController;

  // State variables
  String? _memberType;
  int _offlineMapsCount = 0;
  bool _isLoadingMembership = true;
  List<OfflineMap> _offlineMaps = [];
  List<dynamic> _directions = [];
  Set<Polyline> _polylines = {};
  
  LatLng? _startLocation;
  LatLng? _endLocation;
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(0, 0),
    zoom: 10,
  );

  @override
  void initState() {
    super.initState();
    if (widget.endLocation != null) {
      _endLocation = widget.endLocation;
      _fetchAddressForLocation(_endLocation!, isEnd: true);
    }
    _getCurrentLocation();
    _fetchMembershipDetails();
    _loadSavedMaps();
  }

  Future<void> _fetchMembershipDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user logged in");

      final userDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _memberType = userDoc.data()?['membertype'] ?? 'BASIC';
          _offlineMapsCount = userDoc.data()?['offline_maps_count'] ?? 0;
          _isLoadingMembership = false;
        });
      }
    } catch (e) {
      print('Error fetching membership: $e');
      setState(() => _isLoadingMembership = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      
      setState(() {
        _startLocation = LatLng(position.latitude, position.longitude);
        _initialCameraPosition = CameraPosition(
          target: _startLocation!,
          zoom: 12,
        );
      });
      
      _fetchAddressForLocation(_startLocation!, isEnd: false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting current location: $e')),
      );
    }
  }

  Future<void> _fetchAddressForLocation(LatLng location, {required bool isEnd}) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=${Config.googleApiKey}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'];
          setState(() {
            if (isEnd) {
              _endController.text = address;
            } else {
              _startController.text = address;
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  Future<void> _performSearch(String query, bool isStart) async {
    if (query.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=${Config.googleApiKey}',
        ),
      );

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
      print('Error searching locations: $e');
    }
  }

  Future<void> _searchDirections() async {
    if (_startLocation == null || _endLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select start and end locations')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${_startLocation!.latitude},${_startLocation!.longitude}&destination=${_endLocation!.latitude},${_endLocation!.longitude}&key=${Config.googleApiKey}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'].isNotEmpty) {
          setState(() {
            _directions = data['routes'][0]['legs'][0]['steps'];
            
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: PolylineId('route'),
                color: Colors.blue,
                width: 5,
                points: _decodePolyline(data['routes'][0]['overview_polyline']['points']),
              ),
            );
          });

          _mapController.animateCamera(
            CameraUpdate.newLatLngBounds(
              _boundsFromLatLngList(_getRouteLatLngs(data['routes'][0]['legs'][0]['steps'])),
              50,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding directions: $e')),
      );
    }
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

  List<LatLng> _getRouteLatLngs(List<dynamic> steps) {
    return steps.expand((step) {
      return [
        LatLng(step['start_location']['lat'], step['start_location']['lng']),
        LatLng(step['end_location']['lat'], step['end_location']['lng'])
      ];
    }).toList();
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list[0].latitude;
    double x1 = list[0].latitude;
    double y0 = list[0].longitude;
    double y1 = list[0].longitude;
    
    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    
    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
  }

  String _stripHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
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

      setState(() {
        _offlineMaps = savedMapsDoc.docs
            .map((doc) => OfflineMap.fromMap(doc.data()))
            .toList();
      });
    } catch (e) {
      print('Error loading saved maps: $e');
    }
  }

  Future<void> _saveMap() async {
    if (_directions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No directions to save')),
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

      // Convert directions to DirectionStep objects
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Map saved successfully'),
                Text(
                  MembershipHandler.formatLimitDisplay(_memberType ?? 'BASIC', _offlineMapsCount),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
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

      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .collection('offline_maps')
          .doc(map.id)
          .delete();

      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .update({'offline_maps_count': _offlineMapsCount - 1});

      setState(() => _offlineMapsCount--);
      await _loadSavedMaps();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Map deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting map: $e')),
      );
    }
  }

  void _showSavedDirections(OfflineMap map) {
    // Clear any existing route
    setState(() {
      _startController.text = map.startLocation;
      _endController.text = map.endLocation;
      
      // Convert saved steps back to directions format
      _directions = map.steps.map((step) => {
        'html_instructions': step.instructions,
        'distance': {'text': step.distance},
        'duration': {'text': step.duration},
      }).toList();
    });

    // Close the bottom sheet
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Directions'),
        backgroundColor: Colors.teal,
        actions: [
          if (!_isLoadingMembership) 
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  MembershipHandler.formatLimitDisplay(_memberType ?? 'BASIC', _offlineMapsCount),
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          if (_directions.isNotEmpty)
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _saveMap,
              tooltip: 'Save Map',
            ),
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildSavedMapsSheet(),
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              );
            },
            tooltip: 'Saved Maps',
          ),
        ],
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

  Widget _buildSavedMapsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved Maps',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Using ${MembershipHandler.formatLimitDisplay(_memberType ?? 'BASIC', _offlineMapsCount)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),
          Expanded(
            child: _offlineMaps.isEmpty
                ? Center(child: Text('No saved maps'))
                : ListView.builder(
                    itemCount: _offlineMaps.length,
                    itemBuilder: (context, index) {
                      final map = _offlineMaps[index];
                      return ExpansionTile(
                        title: Text('${map.startLocation} to ${map.endLocation}'),
                        subtitle: Text(
                          'Saved on ${map.createdAt.toString().split('.')[0]}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.directions),
                              onPressed: () => _showSavedDirections(map),
                              tooltip: 'Show Directions',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteMap(map),
                              tooltip: 'Delete Map',
                            ),
                          ],
                        ),
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: map.steps.length,
                            itemBuilder: (context, stepIndex) {
                              final step = map.steps[stepIndex];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal,
                                  child: Text(
                                    '${stepIndex + 1}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(step.instructions),
                                subtitle: Text(
                                  '${step.distance} - ${step.duration}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
Widget _buildSearchInputs() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Start Location TextField
          Expanded(
            child: TextField(
              controller: _startController,
              decoration: InputDecoration(
                labelText: 'Start Location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _startController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _startLocation = null;
                            _startController.clear();
                            _polylines.clear();
                            _directions = [];
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
                  _performSearch(value, true);
                });
              },
            ),
          ),
          // Swap Button
          IconButton(
            icon: Icon(Icons.swap_vert),
            onPressed: () {
              final tempLocation = _startLocation;
              final tempText = _startController.text;
              
              setState(() {
                _startLocation = _endLocation;
                _startController.text = _endController.text;
                
                _endLocation = tempLocation;
                _endController.text = tempText;
              });
            },
          ),
          // End Location TextField
          Expanded(
            child: TextField(
              controller: _endController,
              decoration: InputDecoration(
                labelText: 'End Location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _endController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _endLocation = null;
                            _endController.clear();
                            _polylines.clear();
                            _directions = [];
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
                  _performSearch(value, false);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: _searchDirections,
        icon: Icon(Icons.directions),
        label: Text('Get Directions'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        polylines: _polylines,
        markers: {
          if (_startLocation != null)
            Marker(
              markerId: MarkerId('start'),
              position: _startLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(title: 'Start Location'),
            ),
          if (_endLocation != null)
            Marker(
              markerId: MarkerId('end'),
              position: _endLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(title: 'End Location'),
            ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        zoomGesturesEnabled: true,
        mapToolbarEnabled: true,
      ),
    );
  }

  Widget _buildDirectionsList() {
    return Expanded(
      flex: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header for Directions List
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.directions, color: Colors.teal),
                  SizedBox(width: 8),
                  Text(
                    'Directions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // List of Direction Steps
            Expanded(
              child: ListView.builder(
                itemCount: _directions.length,
                itemBuilder: (context, index) {
                  final step = _directions[index];
                  return Card(
                    margin: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        _stripHtmlTags(step['html_instructions']),
                        style: TextStyle(fontSize: 14),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}