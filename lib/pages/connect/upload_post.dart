import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:odyssey/utils/image_picker_utils.dart';
import 'dart:io';
import 'package:odyssey/model/location.dart';
import 'package:odyssey/mockdata/locations.dart';

class UploadPost extends StatefulWidget{
  const UploadPost({super.key});

  @override
  State<UploadPost> createState() => _UploadPostState();

}

class _UploadPostState extends State<UploadPost> with AutomaticKeepAliveClientMixin{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static List<String> filterSetOne = ["Arts", "Culture", "Food"];
  static List<String> filterSetTwo = ["History", "Nature", "Safe Spot"];
  static List<String> filterSetThree = ["Hidden Gem", "Pet-Friendly", "Avoid"];
  List<String>? labels =[];
  String? reviewText = "";
  String? locationName = "";
  List<File?> images = [];
  double starRating = 0.0;
  final List<Map<String, dynamic>> _filtersSelected = [
    {"Arts": false},
    {"Culture": false},
    {"Food": false},
    {"History": false},
    {"Nature": false},
    {"Safe Spot": false},
    {"Hidden Gem": false},
    {"Pet-Friendly": false},
    {"Avoid": false},
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    //GlobalKey<LocationListBarState>? listBarKey = GlobalKey<LocationListBarState>();
    return Scaffold(
      appBar: AppBar(title: Text("New Post"),),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 44.0, horizontal: 37.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Location search section
            DropdownMenu(
              label: const Text("Select location"),
              initialSelection: locations[0].name,
              dropdownMenuEntries: locations.map<DropdownMenuEntry<String>>((LocationDetails l){
                return DropdownMenuEntry<String>(value: l.name, label: l.name);
              }).toList(),
              onSelected: (String? selected){
                setState((){
                  locationName = selected;
                });
              },
            ),
            SizedBox(height: 28.0,),
            //Photo upload section
            Column(
              children: [
                Text("Photo (allowed formats are JPG, JPEG and PNG):", style: Theme.of(context).textTheme.bodyMedium),
                SizedBox(height: 25.0,),
                ElevatedButton(
                  onPressed: (){
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(Icons.camera_alt),
                                title: Text("Take Photo"),
                                onTap: () async{
                                  Navigator.of(context).pop();
                                  try {
                                    File? image = await pickImage(context, ImageSource.camera);
                                    if(image == null){
                                      showMessageSnackBar(context, "No image was selected");
                                    } else {
                                      setState(() {
                                        images.add(image);
                                      });
                                    }
                                  } catch (e) {
                                    showMessageSnackBar(context, "Error loading image");
                                  }
                                }
                              ),
                              ListTile(
                                leading: Icon(Icons.photo_library),
                                title: Text("Choose Photo from Gallery"),
                                onTap: () async{
                                  Navigator.of(context).pop();
                                  try {
                                    File? image = await pickImage(context, ImageSource.gallery);
                                    if(image == null){
                                      showMessageSnackBar(context, "No image was selected");
                                    } else {
                                      setState(() {
                                        images.add(image);
                                      });
                                    }
                                  } catch (e) {
                                    showMessageSnackBar(context, "Error loading image");
                                  }
                                },
                              ),
                            ],
                          )
                        ],
                      )
                    );
                  },
                  child: Text("Upload photo", style: Theme.of(context).textTheme.bodyMedium,)
                )
              ],
            ),
            SizedBox(height: 13.0,),
            Column(
              children: images.length!=0 ? images.map((i) => OutlinedButton.icon(icon: Icon(Icons.delete), onPressed: (){setState(() {images.remove(i);});}, label: Text(i?.path.split('/').last ?? ""))).toList():[],
            ),
            SizedBox(height: 28.0,),
            Text("Select one or more tags:", style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 28.0,),
            //Tag selection section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Ensures equal spacing
              children: filterSetOne.map((item) {
              return Expanded(
                child: FilterChip(
                  label: Text(item, style: Theme.of(context).textTheme.labelSmall),
                  avatar: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] == false ? Icon(Icons.add) : null,
                  selected: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item],
                  onSelected: (selected) {
                    setState(() {
                      var updatedResults = _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: () => {item:false});
                      if (!updatedResults.containsKey(item)) {
                        _filtersSelected.add({item: selected}); // Add a new map if not found
                      } else {
                        updatedResults[item] = selected; // Update the existing entry
                      }
                      selected == true ? labels?.add(item) : labels?.removeWhere((name) => name==item);
                    });
                  },
                ),
              );
              }).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Ensures equal spacing
              children: filterSetTwo.map((item) {
              return Expanded(
                child: FilterChip(
                  label: Text(item, style: Theme.of(context).textTheme.labelSmall),
                  avatar: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] == false ? Icon(Icons.add) : null,
                  selected: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item],
                  onSelected: (selected){
                    setState(() {
                      var updatedResults = _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: () => {item:false});
                      if (!updatedResults.containsKey(item)) {
                        _filtersSelected.add({item: selected}); // Add a new map if not found
                      } else {
                        updatedResults[item] = selected; // Update the existing entry
                      }
                      selected == true ? labels?.add(item) : labels?.removeWhere((name) => name==item);
                    });
                  },
                ),
              );
              }).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Ensures equal spacing
              children: filterSetThree.map((item) {
              return Expanded(
                child: FilterChip(
                  label: Text(item, style: Theme.of(context).textTheme.labelSmall),
                  avatar: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] == false ? Icon(Icons.add) : null,
                  selected: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item],
                  onSelected: (selected) {
                    setState(() {
                      var updatedResults = _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: () => {item:false});
                      if (!updatedResults.containsKey(item)) {
                        _filtersSelected.add({item: selected}); // Add a new map if not found
                      } else {
                        updatedResults[item] = selected; // Update the existing entry
                      }
                      selected == true ? labels?.add(item) : labels?.removeWhere((name) => name==item);
                    });
                  },
                ),
              );
              }).toList(),
            ),
            SizedBox(height: 28.0),
            //Star rating section
            Center(
              child: Text("Rate this location:", style: Theme.of(context).textTheme.bodyMedium)
            ),
            Center(
              child: StarRating(
                allowHalfRating: false,
                rating: starRating,
                onRatingChanged: (rating){
                  setState(() {
                    starRating = rating;
                  });
                },
              ),
            ),
            SizedBox(height: 28.0,),
            //Review field section
            Text("Review: ", style: Theme.of(context).textTheme.bodyMedium,),
            SizedBox(height: 24.0,),
            TextField(
              enabled: true,
              onChanged: (value){
                setState(() {
                  reviewText = value;
                });
              },
            ),
            SizedBox(height: 28.0,),
            ElevatedButton(
              onPressed: (){
                showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text("Good to go?", style: Theme.of(context).textTheme.headlineSmall),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 0.0),
                        child: Text("If you want to continue editing your post, click \"No\"; otherwise click \"Yes\" and spread the word!", style: Theme.of(context).textTheme.bodyMedium)
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 24.0, top: 24.0, bottom: 24.0),
                            child: Row(
                              children: [
                                SimpleDialogOption(
                                  onPressed: () async{
                                    try {
                                      String uid = this.auth.currentUser!.uid;
                                      final docSnap = await this.firestore.collection('User').doc(uid).get();
                                      final uname;
                                      if (docSnap.exists){
                                        uname = docSnap.data()?['firstname'];
                                      } else {
                                        uname = "";
                                      }
                                      final docRef = await this.firestore.collection('Review').doc(uid).set({
                                        'email': this.auth.currentUser!.email,
                                        'images': images,
                                        'locationname': locationName,
                                        'rating': starRating,
                                        'reviewtext': reviewText,
                                        'tags': labels,
                                        'username': uname,
                                      });
                                      Navigator.of(context).pop();
                                      showMessageSnackBar(context, "Success! Your post is now uploaded.");
                                    } catch (e) {
                                      showMessageSnackBar(context, "Failed to upload post. Please try again.");
                                    }
                                  },
                                  child: Text("Yes", style: Theme.of(context).textTheme.labelLarge),
                                ),
                                SizedBox(width: 8.0,),
                                SimpleDialogOption(
                                  onPressed: (){
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("No", style: Theme.of(context).textTheme.labelLarge)
                                )
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                );
              },
              child: Text("Upload your post", style: Theme.of(context).textTheme.bodyMedium)
            )
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}