import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/model/location.dart';
import 'package:odyssey/utils/paths.dart';

class ConnectFriends extends StatelessWidget{
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  const ConnectFriends({super.key, required this.auth, required this.firestore});

  Future<List<ReviewCard>> _loadFriendReviews(String? uid) async{
    final snap = await this.firestore.collection('User').doc(uid).get();
    final friendlist;
    List<ReviewCard> reviews = [];
    if(snap.exists){
      friendlist = snap.data()?['friends'];

    } else {
      friendlist = [];
    }
    for(String f in friendlist){
      Query<Map<String, dynamic>> friendsQuery = await this.firestore.collection('Review').where('username'.toLowerCase(),isEqualTo: f.toLowerCase());
      QuerySnapshot<Map<String, dynamic>> querySnap = await friendsQuery.get();
      for(var doc in querySnap.docs){
        reviews.add(ReviewCard(pageName: "ConnectFriends",imgUrls: doc.data()?['images']));
      }
    }
    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    String uid = this.auth.currentUser!.uid;
    return FutureBuilder(
      future: _loadFriendReviews(uid),
      builder: (context, snap){
        if(!snap.hasData || snap.data == null){
          return Center(
            child: Column(
              children: [
                Image(image: AssetImage("assets/icons8-friends-100.png"),),
                SizedBox(height: 20.0,),
                Text("Your friend list is empty. Make new friends and be a part of their adventures!", style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 20.0,),
              ],
            )
          );
        } else {
          return Container(
            constraints: BoxConstraints(maxHeight: double.infinity),
            child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Expanded(
              child: ListView.separated(
                itemBuilder: (context, index){
                  return snap.data![index];
                },
                separatorBuilder: (context, index) => Divider(indent: 16.0, endIndent: 16.0, thickness: 2.0,),
                itemCount: snap.data!.length),
              )
            )
          );
        }
      }
    );
  }
}