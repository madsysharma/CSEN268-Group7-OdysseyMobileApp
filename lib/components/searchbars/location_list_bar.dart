import 'package:flutter/material.dart';
import 'package:odyssey/mockdata/locations.dart';
import 'package:odyssey/model/location.dart';
class LocationListBar extends StatefulWidget{
  final GlobalKey<LocationListBarState> key;
  LocationListBar({required this.key}): super(key:key);

  @override
  LocationListBarState createState() => LocationListBarState();
}

class LocationListBarState extends State<LocationListBar> {
  List<LocationDetails> searchResults = [];
  String selectedLoc = "";
  void onQueryChange(String q){
    setState(() {
      if(q.isEmpty){
        searchResults = locations;
      } else {
        searchResults = locations.where((e) => e.name.toLowerCase().contains(q.toLowerCase())).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchBar(
            leading: Icon(Icons.search),
            hintText: "Search for location to review",
            onChanged: onQueryChange,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index){
                return ListTile(
                  title: searchResults.length>0 ? Text(searchResults[index].name) : Text("No locations found"),
                  onTap: (){
                    if(searchResults.length>0){
                      setState(() {
                        selectedLoc = searchResults[index].name;
                      });
                    }
                  },
                );
              }
            )
          )
        ],
      ),
    );
  }
}