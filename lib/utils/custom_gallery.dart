import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odyssey/utils/image_picker_utils.dart';
import 'package:go_router/go_router.dart';

class CustomGallery extends StatelessWidget{

  final List<String> imgPaths;

  CustomGallery({super.key, required this.imgPaths});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose an image"),
        actions: [
          IconButton(
            onPressed: () async{
              File? img = await pickImage(context, ImageSource.gallery);
              if(img!=null){
                context.pop(img.path);
              }
              else{
                context.pop("");
              }
            },
            icon: Icon(Icons.photo_library))
        ],
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: this.imgPaths.length,
        itemBuilder: (context, index){
          return GestureDetector(
            onTap: (){
              String selectedPath = imgPaths[index];
              print("Selected image: $selectedPath");
              context.pop(this.imgPaths[index]);
            },
            child: Image.asset(this.imgPaths[index], fit: BoxFit.cover,)
          );
        }
      )
    );
  }
}