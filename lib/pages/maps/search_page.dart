import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform, File, Directory;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../profile/manage_membership.dart';

class OfflineMap {
  final String id;
  final String startLocation;
  final String endLocation;
  final String filePath;
  final DateTime createdAt;

  OfflineMap({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.filePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static OfflineMap fromMap(Map<String, dynamic> map) {
    return OfflineMap(
      id: map['id'],
      startLocation: map['startLocation'],
      endLocation: map['endLocation'],
      filePath: map['filePath'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

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
  List<dynamic> _searchResults = [];
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
    _loadOfflineMaps();
  }

  // Membership methods
  int getOfflineMapsLimit(String memberType) {
    switch (memberType.toUpperCase()) {
      case 'BASIC':
        return 3;
      case 'PREMIUM':
        return 5;
      case 'ELITE':
        return -1; // Unlimited
      default:
        return 0;
    }
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

  Future<bool> _canDownloadOfflineMap() async {
    if (_memberType == null) return false;
    final limit = getOfflineMapsLimit(_memberType!);
    if (limit == -1) return true;
    return _offlineMapsCount < limit;
  }

  Future<void> _incrementOfflineMapCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user logged in");

      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .update({'offline_maps_count': _offlineMapsCount + 1});

      setState(() => _offlineMapsCount++);
    } catch (e) {
      print('Error updating offline maps count: $e');
      throw e;
    }
  }

  // Location and navigation methods
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }
      
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

  // Directions and route methods
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
    double x0 = list[0].latitude, x1 = list[0].latitude;
    double y0 = list[0].longitude, y1 = list[0].longitude;
    
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

  // Offline maps methods
  Future<void> _loadOfflineMaps() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final offlineMapsDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .collection('offline_maps')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _offlineMaps = offlineMapsDoc.docs
            .map((doc) => OfflineMap.fromMap(doc.data()))
            .toList();
      });
    } catch (e) {
      print('Error loading offline maps: $e');
    }
  }

  Future<void> _downloadDirections() async {
    if (_directions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No directions to download')),
      );
      return;
    }

    try {
      final canDownload = await _canDownloadOfflineMap();
      if (!canDownload) {
        final limit = getOfflineMapsLimit(_memberType ?? 'BASIC');
        String message = limit == -1 
            ? 'Error checking download permissions' 
            : 'You have reached your offline maps limit ($limit maps). Upgrade your membership to download more maps.';
        
        ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
  content: Text(message),
  action: SnackBarAction(
    label: 'Upgrade',
    onPressed: () {
      // Replace Navigator.pushNamed with direct navigation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManageMembership(),
        ),
      );
    },
  ),
),
        );
        return;
      }

      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Storage permission required')),
          );
          return;
        }
      }

      final directionsText = StringBuffer();
      directionsText.writeln('Directions from ${_startController.text} to ${_endController.text}\n');
      
      for (int i = 0; i < _directions.length; i++) {
        final step = _directions[i];
        directionsText.writeln('${i + 1}. ${_stripHtmlTags(step['html_instructions'])}');
        directionsText.writeln('   Distance: ${step['distance']['text']}');
        directionsText.writeln('   Duration: ${step['duration']['text']}\n');
      }

      final directory = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();

      if (directory == null) {
        throw Exception('Could not get storage directory');
      }

      final mapsDirectory = Directory('${directory.path}/offline_maps');
      if (!await mapsDirectory.exists()) {
        await mapsDirectory.create(recursive: true);
      }

      final mapId = DateTime.now().millisecondsSinceEpoch.toString();
      final file = File('${mapsDirectory.path}/directions_$mapId.txt');
      await file.writeAsString(directionsText.toString());

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final offlineMap = OfflineMap(
          id: mapId,
          startLocation: _startController.text,
          endLocation: _endController.text,
          filePath: file.path,
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('User')
            .doc(user.uid)
            .collection('offline_maps')
            .doc(mapId)
            .set(offlineMap.toMap());

        await _incrementOfflineMapCount();
        await _loadOfflineMaps();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Map saved for offline use'),
                Text(
                  'Maps used: $_offlineMapsCount/${getOfflineMapsLimit(_memberType ?? 'BASIC') == -1 ? '∞' : getOfflineMapsLimit(_memberType ?? 'BASIC')}',
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
        SnackBar(content: Text('Error saving offline map: $e')),
      );
    }
  }

  Future<void> _deleteOfflineMap(OfflineMap map) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final file = File(map.filePath);
      if (await file.exists()) {
        await file.delete();
      }

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
      await _loadOfflineMaps();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offline map deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting offline map: $e')),
      );
    }
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
                  'Maps: $_offlineMapsCount/${getOfflineMapsLimit(_memberType ?? 'BASIC') == -1 ? '∞' : getOfflineMapsLimit(_memberType ?? 'BASIC')}',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          if (_directions.isNotEmpty)
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _downloadDirections,
              tooltip: 'Save for Offline Use',
            ),
          IconButton(
            icon: Icon(Icons.storage),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildOfflineMapsSheet(),
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

  Widget _buildSearchInputs() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
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

  Widget _buildOfflineMapsSheet() {
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
            'Saved Offline Maps',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Using $_offlineMapsCount of ${getOfflineMapsLimit(_memberType ?? 'BASIC') == -1 ? '∞' : getOfflineMapsLimit(_memberType ?? 'BASIC')} maps',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),
          Expanded(
            child: _offlineMaps.isEmpty
                ? Center(
                    child: Text('No offline maps saved'),
                  )
                : ListView.builder(
                    itemCount: _offlineMaps.length,
                    itemBuilder: (context, index) {
                      final map = _offlineMaps[index];
                      return Card(
                        child: ListTile(
                          title: Text('${map.startLocation} to ${map.endLocation}'),
                          subtitle: Text('Saved on ${map.createdAt.toString().split('.')[0]}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteOfflineMap(map),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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