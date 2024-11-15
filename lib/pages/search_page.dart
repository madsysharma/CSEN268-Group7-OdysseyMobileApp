import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPage extends StatefulWidget {
  final Function(String) onPlaceSelected; // Callback to pass the selected place back

  SearchPage({required this.onPlaceSelected});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _placePredictions = [];
  bool _isSearching = false; // To show/hide loading indicator

  // Autocomplete search for places
  Future<void> _autocompleteSearch(String input) async {
    if (input.isEmpty) {
      setState(() {
        _placePredictions = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=AIzaSyDGbl_R3u5F1A9hVlpzDxF6AVgQMHp4hwMY';
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        setState(() {
          _placePredictions = data['predictions'];
        });
      } else {
        setState(() {
          _placePredictions = [];
        });
      }
    } catch (e) {
      print('Error fetching place predictions: $e');
      setState(() {
        _placePredictions = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Select a place and pass it back to the MapPage
  void _selectPlace(String placeId) {
    widget.onPlaceSelected(placeId);
    Navigator.pop(context); // Close the search page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Places'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Search Input Field
            TextField(
              controller: _searchController,
              onChanged: _autocompleteSearch,
              decoration: InputDecoration(
                hintText: 'Search for places...',
                suffixIcon: _isSearching
                    ? CircularProgressIndicator()
                    : Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            SizedBox(height: 10),
            
            // Predictions List
            Expanded(
              child: ListView.builder(
                itemCount: _placePredictions.length,
                itemBuilder: (context, index) {
                  final place = _placePredictions[index];
                  return ListTile(
                    title: Text(place['description']),
                    subtitle: Text(place['place_id']),
                    onTap: () => _selectPlace(place['place_id']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
