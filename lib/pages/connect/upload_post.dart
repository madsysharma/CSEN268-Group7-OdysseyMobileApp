import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:odyssey/components/searchbars/location_list_bar.dart';
import 'package:odyssey/utils/image_picker_utils.dart';
import 'dart:io';

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
  static List<String> filterSetThree = ["Hidden Gem", "Pet-friendly", "Avoid"];
  List<String>? labels;
  String? reviewText = "";
  List<File?> images = [];
  int starRating = 0;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    GlobalKey<LocationListBarState>? listBarKey = GlobalKey<LocationListBarState>();
    late OverlayEntry beforeUploadOverlay;
    late OverlayEntry afterUploadOverlay;
    late OverlayEntry imageSourceOverlay;
    return Scaffold(
      appBar: AppBar(title: Text("New Post"),),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 44.0, horizontal: 37.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Location search section
            LocationListBar(key: listBarKey,),
            SizedBox(height: 28.0,),
            //Photo upload section
            Column(
              children: [
                Text("Photo (allowed formats are JPG, JPEG and PNG):", ),
                SizedBox(height: 25.0,),
                ElevatedButton(
                  onPressed: (){
                    imageSourceOverlay = OverlayEntry(
                      builder: (context) => SimpleDialog(
                        children: [
                          Expanded(
                            child: Column(
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
                            ),
                          )
                        ],
                      )
                    );
                    Overlay.of(context).insert(imageSourceOverlay);
                  },
                  child: Text("Upload photo", style: Theme.of(context).textTheme.headlineSmall,)
                )
              ],
            ),
            SizedBox(height: 13.0,),
            SizedBox(
              height: 100.0,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index){
                  return OutlinedButton.icon(
                    icon: Icon(Icons.delete),
                    onPressed: (){
                      setState(() {
                        images.remove(images[index]);
                      });
                    },
                    label: Text(images[index]?.path.split('/').last ?? "")
                  );
                }
              ),
            ),
            SizedBox(height: 28.0,),
            Text("Select one or more tags:", style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 28.0,),
            //Tag selection section
            Wrap(
              spacing: 15.0,
              runSpacing: 15.0,
              children:
                filterSetOne.map((item) {
                  return FilterChip(
                  label: Text(item),
                  onSelected: (selected) {
                    setState(() {
                      selected ? labels?.add(item) : labels?.remove(item);
                    });
                  },
                );
              }).toList(),
            ),
            Wrap(
              spacing: 15.0,
              runSpacing: 15.0,
              children:
                filterSetTwo.map((item) {
                  return FilterChip(
                  label: Text(item),
                  onSelected: (selected) {
                    setState(() {
                      selected ? labels?.add(item) : labels?.remove(item);
                    });
                  },
                );
              }).toList(),
            ),
            Wrap(
              spacing: 15.0,
              runSpacing: 15.0,
              children:
                filterSetThree.map((item) {
                  return FilterChip(
                  label: Text(item),
                  onSelected: (selected) {
                    setState(() {
                      selected ? labels?.add(item) : labels?.remove(item);
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 28.0),
            //Star rating section
            Center(
              child: Text("Rate this location:")
            ),
            Center(
              child: StarRating(
                allowHalfRating: false,
                onRatingChanged: (rating){
                  setState(() {
                    starRating = rating as int;
                  });
                },
              ),
            ),
            SizedBox(height: 28.0,),
            //Review field section
            Text("Review: ", style: Theme.of(context).textTheme.headlineSmall,),
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
                beforeUploadOverlay = OverlayEntry(
                  builder: (context) => SimpleDialog(
                    title: Text("Good to go?", style: Theme.of(context).textTheme.headlineSmall),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 0.0),
                        child: Text("If you want to continue editing your post, click \"No\"; otherwise click \"Yes\" and spread the word!", style: Theme.of(context).textTheme.bodyMedium)
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, right: 24.0, top: 24.0, bottom: 24.0),
                              child: Expanded(
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
                                            'locationname': listBarKey.currentState?.selectedLoc,
                                            'rating': starRating,
                                            'reviewtext': reviewText,
                                            'tags': labels,
                                            'username': uname,
                                          });
                                          afterUploadOverlay = OverlayEntry(
                                            builder: (context) => SimpleDialog(
                                              title: Text("Success!"),
                                              children: [
                                                Align(
                                                  alignment: Alignment.center,
                                                  child: Text("You have uploaded your post."),
                                                )
                                              ],
                                            )
                                          );
                                          Overlay.of(context).insert(afterUploadOverlay);
                                        } catch (e) {
                                          afterUploadOverlay = OverlayEntry(
                                            builder: (context) => SimpleDialog(
                                              title: Text("Upload failed."),
                                              children: [
                                                Align(
                                                  alignment: Alignment.center,
                                                  child: Text("Please try again."),
                                                )
                                              ],
                                            )
                                          );
                                          Overlay.of(context).insert(afterUploadOverlay);
                                        }
                                      },
                                      child: Text("Yes", style: Theme.of(context).textTheme.labelLarge),
                                    ),
                                    SizedBox(width: 8.0,),
                                    SimpleDialogOption(
                                      onPressed: (){
                                        beforeUploadOverlay.remove();
                                      },
                                      child: Text("No", style: Theme.of(context).textTheme.labelLarge)
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                );
                Overlay.of(context).insert(beforeUploadOverlay);
              },
              child: Text("Upload your post", style: Theme.of(context).textTheme.headlineSmall)
            )
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}