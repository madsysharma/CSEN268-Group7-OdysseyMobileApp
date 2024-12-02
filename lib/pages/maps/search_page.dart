import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform,File, Directory;

class SearchPage extends StatefulWidget {
  final LatLng? endLocation;

  const SearchPage({Key? key, this.endLocation}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  Timer? _debounceTimer;
  List<dynamic> _searchResults = [];
  
  LatLng? _startLocation;
  LatLng? _endLocation;
  
  List<dynamic> _directions = [];
  Set<Polyline> _polylines = {};
  
  late GoogleMapController _mapController;
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
  }

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

  Future<void> _searchLocation(bool isStart) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController searchController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isStart ? 'Search Start Location' : 'Search End Location'),
              content: Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter location',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  setDialogState(() {
                                    searchController.clear();
                                    _searchResults = [];
                                  });
                                },
                              ),
                            IconButton(
                              icon: Icon(Icons.search),
                              onPressed: () => _performSearch(searchController.text, setDialogState),
                            ),
                          ],
                        ),
                      ),
                      onChanged: (value) {
                        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                          _performSearch(value, setDialogState);
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: _searchResults.isEmpty
                          ? Center(
                              child: Text(
                                searchController.text.isEmpty
                                    ? 'Enter a location to search'
                                    : 'No results found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final result = _searchResults[index];
                                return ListTile(
                                  leading: Icon(Icons.location_on),
                                  title: Text(
                                    result['formatted_address'] ?? result['name'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    _selectLocation(result, isStart);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performSearch(String query, StateSetter setDialogState) async {
    if (query.isEmpty) {
      setDialogState(() => _searchResults = []);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=${Config.googleApiKey}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setDialogState(() {
          _searchResults = data['results'];
        });
      }
    } catch (e) {
      print('Error searching locations: $e');
      setDialogState(() => _searchResults = []);
    }
  }

  void _selectLocation(dynamic result, bool isStart) {
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No routes found')),
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
        LatLng(
          step['start_location']['lat'],
          step['start_location']['lng'],
        ),
        LatLng(
          step['end_location']['lat'],
          step['end_location']['lng'],
        )
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

  Future<void> _downloadDirections() async {
    if (_directions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No directions to download')),
      );
      return;
    }

    try {
      // Create a formatted text for directions
      final directionsText = StringBuffer();
      directionsText.writeln('Directions from ${_startController.text} to ${_endController.text}\n');
      
      for (int i = 0; i < _directions.length; i++) {
        final step = _directions[i];
        directionsText.writeln('${i + 1}. ${_stripHtmlTags(step['html_instructions'])}');
        directionsText.writeln('   Distance: ${step['distance']['text']}');
        directionsText.writeln('   Duration: ${step['duration']['text']}\n');
      }

      // Get the directory for saving the file
      final directory = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();

      if (directory == null) {
        throw Exception('Could not get storage directory');
      }

      // Create the file
      final file = File('${directory.path}/directions.txt');

      // Write the directions to the file
      await file.writeAsString(directionsText.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Directions downloaded to ${file.path}'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading directions: $e')),
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
          if (_directions.isNotEmpty)
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _downloadDirections,
              tooltip: 'Download Directions',
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
                    controller: _startController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Start Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_startController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _startLocation = null;
                                  _startController.clear();
                                  _polylines.clear();
                                  _directions = [];
                                });
                              },
                            ),
                          IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () => _searchLocation(true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.swap_vert),
                  onPressed: () {
                    final tempLocation = _startLocation;
                    final tempController = _startController.text;
                    
                    setState(() {
                      _startLocation = _endLocation;
                      _startController.text = _endController.text;
                      
                      _endLocation = tempLocation;
                      _endController.text = tempController;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _endController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'End Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_endController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _endLocation = null;
                                  _endController.clear();
                                  _polylines.clear();
                                  _directions = [];
                                });
                              },
                            ),
                          IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () => _searchLocation(false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
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
          ),
          Expanded(
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
          ),
          if (_directions.isNotEmpty)
            Expanded(
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

