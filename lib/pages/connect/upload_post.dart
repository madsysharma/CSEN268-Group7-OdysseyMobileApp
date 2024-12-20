import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odyssey/api/get_locations.dart';
import 'package:odyssey/api/review.dart';
import 'package:odyssey/api/upload_file.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:odyssey/model/review.dart';
import 'package:odyssey/utils/image_picker_utils.dart';
import 'package:odyssey/utils/img_paths.dart';
import 'package:odyssey/utils/paths.dart';
import 'dart:io';
import 'package:odyssey/model/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tuple/tuple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadPostInitial extends StatefulWidget {
  final LocationDetails? location;
  const UploadPostInitial({super.key, this.location});

  @override
  State<UploadPostInitial> createState() => UploadPostInitialState();
}

class UploadPostInitialState extends State<UploadPostInitial> with AutomaticKeepAliveClientMixin{
  late Future<List<LocationDetails>> _locationsFuture;

  @override
  void initState() {
    super.initState();
    _locationsFuture = widget.location != null ? Future.value([widget.location!]) : fetchLocationsFromFirestore();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<LocationDetails>>(
      future: _locationsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<LocationDetails>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5, // Adjust the count based on your needs
        itemBuilder: (context, index) {
          return ListTile(
            title: Container(
              height: 20,
              width: 200,
              color: Colors.white,
            ),
          );
        },
      ),
    ));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return UploadPost(locations: snapshot.data!);
      },
    );
  }
}

class UploadPost extends StatefulWidget{
  final List<LocationDetails> locations;
  const UploadPost({super.key, required this.locations});

  @override
  State<UploadPost> createState() => UploadPostState();

}

class UploadPostState extends State<UploadPost> with AutomaticKeepAliveClientMixin{
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  static List<String> filterSetOne = ["Arts", "Culture", "Food"];
  static List<String> filterSetTwo = ["History", "Nature", "Safe Spot"];
  static List<String> filterSetThree = ["Hidden Gem", "Pet-Friendly", "Avoid"];
  TextEditingController controller = TextEditingController();
  List<String>? labels =[];
  String? reviewText = "";
  String? locationName = "";
  String? locationId = "";
  List<File?> images = [];
  List<String> imageUrls = [];
  double starRating = 1.0;
  final List<Map<String, bool>> _filtersSelected = [
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
  void initState() {
    super.initState();
    this.controller.text = widget.locations.first.name;
    this.locationId = widget.locations.first.id;
    this.locationName = this.controller.text; //setNone in case of accessing Upload page via the You tab of Connect
  }

  @override
  void dispose(){
    controller.dispose();
    super.dispose();
  }

  Future<File> copyAssetToFile(String assetPath) async{
    try{
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${assetPath.split('/').last}');
      final byteData = await rootBundle.load(assetPath);

      await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      return tempFile;
    } catch(e){
      throw Exception("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    //GlobalKey<LocationListBarState>? listBarKey = GlobalKey<LocationListBarState>();

    return Scaffold(
      appBar: AppBar(title: Text("New Post"), backgroundColor: const Color.fromARGB(255, 189, 220, 204),),
      body: Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 44.0, horizontal: 37.0),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //Location search section
                  DropdownMenu(
                    label: const Text("Select location"),
                    controller: this.controller,
                    initialSelection: this.controller.text,
                    dropdownMenuEntries: widget.locations.map<DropdownMenuEntry<Tuple2<String, String>>>((LocationDetails l){
                      return DropdownMenuEntry<Tuple2<String, String>>(value: Tuple2(l.name, l.id!), label: l.name);
                    }).toList(),
                    onSelected: (Object? selected) {
                      // Cast selected to Tuple2<String, String>? and handle it
                      if (selected is Tuple2<String, String>?) {
                        setState(() {
                          this.controller.text = selected?.item1 ?? "";
                          this.locationName = this.controller.text;
                          this.locationId = selected?.item2;
                          print("Location name is now: ${this.locationName}");
                        });
                      }
                    }
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
                            builder: (dialogContext) => SimpleDialog(
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.camera_alt),
                                      title: Text("Take Photo"),
                                      onTap: () async{
                                        Navigator.of(dialogContext).pop();
                                        try {
                                          File? image = await pickImage(context, ImageSource.camera);
                                          if(image == null){
                                            if(mounted){
                                              showMessageSnackBar(context, "No image was selected");
                                            }
                                          } else {
                                            if(mounted){
                                              setState(() {
                                                images.add(image);
                                              });
                                            }
                                          }
                                        } catch (e) {
                                          if(mounted){
                                            showMessageSnackBar(context, "Error loading image");
                                          }
                                        }
                                      }
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.photo_library),
                                      title: Text("Choose Photo from Gallery"),
                                      onTap: () async{
                                        try {
                                          Navigator.of(dialogContext).pop();
                                          String result = await GoRouter.of(context).push("/connect/you/post"+Paths.customGallery, extra: ImgPaths.paths) as String;
                                          if(result.isNotEmpty){
                                            if(result.startsWith('assets/')){
                                              try{
                                                final file = await copyAssetToFile(result);
                                                if(file.existsSync()){
                                                  print("Selected image path: $result");
                                                  if(mounted){
                                                    setState(() {
                                                      images.add(file);
                                                    });
                                                  }
                                                }
                                                else{
                                                  if(mounted){
                                                    showMessageSnackBar(context, "The selected file doesn't exist");
                                                  }
                                                }
                                              } catch (e){
                                                if(mounted){
                                                  print("Exception: $e");
                                                  showMessageSnackBar(context, "Failed to resolve the file.");
                                                }
                                              }
                                            } else {
                                              try{
                                                final file = File(result);
                                                if(file.existsSync()){
                                                  print("Selected image path: $result");
                                                  if(mounted){
                                                    setState(() {
                                                      images.add(file);
                                                    });
                                                  }
                                                }
                                                else{
                                                  if(mounted){
                                                    showMessageSnackBar(context, "The selected file doesn't exist");
                                                  }
                                                }
                                              } catch (e){
                                                if(mounted){
                                                  print("Exception: $e");
                                                  showMessageSnackBar(context, "Failed to resolve the file.");
                                                }
                                              }
                                            }
                                          }
                                        } catch (e){
                                          throw Exception("Exception: $e");
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
                  SizedBox(
                    height: 40.0,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: filterSetOne.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: FilterChip(
                            padding: EdgeInsets.symmetric(vertical: 5.0),
                            label: Container(width: 300.0, child: Text(item, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center,)),
                            avatar: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] == false ? Icon(Icons.add) : null,
                            selected: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] ?? false,
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
                        ),
                      );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    height: 40.0,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: filterSetTwo.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: FilterChip(
                            padding: EdgeInsets.symmetric(vertical: 5.0),
                            label: Container(width: 300.0,child: Text(item, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center,)),
                            avatar: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] == false ? Icon(Icons.add) : null,
                            selected: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] ?? false,
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
                        ),
                      );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    height: 40.0,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: filterSetThree.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: FilterChip(
                            padding: EdgeInsets.symmetric(vertical: 5.0),
                            label: Container(width: 300.0, child: Text(item, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center,)),
                            avatar: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] == false ? Icon(Icons.add) : null,
                            selected: _filtersSelected.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] ?? false,
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
                        ),
                      );
                      }).toList(),
                    ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF006A68),
                      foregroundColor: Colors.white,
                      textStyle: Theme.of(context).textTheme.labelMedium,
                      side: BorderSide(
                        width: 0.3,
                      ),
                    ),
                    onPressed: (){
                      showDialog(
                        context: context,
                        builder: (dialogContext) => SimpleDialog(
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
                                            var ref = await firestore.collection('User').doc(this.auth.currentUser?.uid).get();
                                            String? fetchedUsername = ref.data()?['firstname']+" "+ref.data()?['lastname'];
                                            for(File? f in images){
                                              String url = await uploadFileToStorage(f!);
                                              imageUrls.add(url);
                                            }
                                            await addReview(LocationReview(
                                              userId: this.auth.currentUser?.uid,
                                              email: this.auth.currentUser?.email,
                                              images: imageUrls,
                                              locationName: locationName!,
                                              locationId: locationId!,
                                              rating: starRating,
                                              reviewText: reviewText,
                                              tags: labels,
                                              username: fetchedUsername,
                                              tokens: reviewText?.split(" "),
                                            ));
                                            context.pop();
                                            showMessageSnackBar(context, "Success! Your post is now uploaded.");
                                          } catch (e) {
                                            print("Error: $e");
                                            context.pop();
                                            showMessageSnackBar(context, "Failed to upload post. Please try again.");
                                          }
                                        },
                                        child: Text("Yes", style: Theme.of(context).textTheme.labelLarge),
                                      ),
                                      SizedBox(width: 8.0,),
                                      SimpleDialogOption(
                                        onPressed: (){
                                          Navigator.of(dialogContext).pop();
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
                    child: Text("Upload your post", style: TextStyle(color: Colors.white))
                  )
                ],
              ),
            ),
          ),
        )
    );
}

  @override
  bool get wantKeepAlive => true;
}