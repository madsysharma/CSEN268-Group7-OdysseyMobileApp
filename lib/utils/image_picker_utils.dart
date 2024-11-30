import 'dart:io';
import 'package:flutter/material.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:odyssey/pages/profile/edit_profile.dart';
import 'package:odyssey/pages/connect/upload_post.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async{
  await Permission.camera.request();
  await Permission.photos.request();
  await Permission.storage.request();
}

Future<File?> pickImage(BuildContext context, ImageSource source) async{
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);
  if (pickedFile != null){
    print("Picked file path: ${pickedFile.path}");
    File tempImage = File(pickedFile.path);
    final savedImage = await saveImage(context, tempImage);
    return savedImage;
  } else {
    return null;
  }
}

Future<File> saveImage(BuildContext context, File image) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/profile_image.png';
    final savedImage = await image.copy(imagePath);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', imagePath);
    if(context == EditProfilePage){
      showMessageSnackBar(context, "New profile picture set");
    } else if (context == UploadPost) {
      showMessageSnackBar(context, "Review photo uploaded");
    }
    return savedImage;
  } catch (e) {
    showMessageSnackBar(context, "Error saving image");
    rethrow;
  }
}