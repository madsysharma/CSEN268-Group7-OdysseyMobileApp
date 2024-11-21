import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/utils/paths.dart';
class ConnectYou extends StatelessWidget{
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  const ConnectYou({super.key, required this.auth, required this.firestore});

  Future<DocumentSnapshot?> _load(String? uid) async{
    final DocumentSnapshot? snap = await this.firestore.collection('Review').doc(uid).get();
    return snap;
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = this.auth.currentUser?.uid;
    return FutureBuilder(
      future: _load(userId),
      builder: (context, snap) {
        if(!snap.hasData || snap.data == null){
          return Padding(
            padding: const EdgeInsets.only(left: 46.0, right: 46.0, top: 155.0, bottom: 155.0),
            child: Center(
              child: Column(
                children: [
                  Image(image: AssetImage("assets/icons8-passport-100.png"),),
                  SizedBox(height: 20.0,),
                  Text("Looks like you haven't posted anything yet. Your travelogue awaits!", style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 20.0,),
                  ElevatedButton(
                    onPressed: (){
                      context.go(Paths.post);
                    },
                    child: Text("Create new post", style: Theme.of(context).textTheme.headlineSmall))
                ],
              ),
            ),
          );
        }
        else{
          
          return Container();
        }
      }
    );
  }
}