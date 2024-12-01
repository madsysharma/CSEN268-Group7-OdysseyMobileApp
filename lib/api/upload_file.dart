import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

final FirebaseStorage storage = FirebaseStorage.instance;

Future<String> uploadFileToStorage(File f) async{
    try{
      final storageRef = storage.ref();
      final fileRef = storageRef.child("uploads/${DateTime.now().millisecondsSinceEpoch}_${f.path.split('/').last}");
      final uploadRef = fileRef.putFile(f);

      final snap = await uploadRef.whenComplete(()=> null);

      final downloadUrl = await snap.ref.getDownloadURL();

      return downloadUrl;
    } catch(e){
      print("Error uploading file");
      throw(e);
    }
}