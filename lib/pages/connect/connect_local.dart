import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/utils/paths.dart';

class ConnectLocal extends StatelessWidget{
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  const ConnectLocal({super.key, required this.auth, required this.firestore});

  Future<List<ReviewCard>> _loadLocalUserReviews(String? uid) async{
    final snap = await this.firestore.collection('User').doc(uid).get();
    final homeloc;
    if(snap.exists){
      homeloc = snap.data()?['homelocation'];
    } else {
      homeloc = "";
    }
    final localUserQuery = await this.firestore.collection('User').where('homelocation',isEqualTo: homeloc);
    final querySnap = await localUserQuery.get();
    List<String> names = [];
    List<ReviewCard> reviews = [];
    for(var doc in querySnap.docs){
      names.add(doc.data()?['firstname']+" "+doc.data()?['lastname']);
    }
    for(String n in names){
      final localReviewQuerySnap = await this.firestore.collection('Review').where('username'.toLowerCase(),isEqualTo: n.toLowerCase()).get();
      for(var doc in localReviewQuerySnap.docs){
        var images = doc['images'];
        reviews.add(ReviewCard(pageName: "ConnectLocal", imgUrls: images));
      }
    }
    return reviews;
  }

  @override
  Widget build(BuildContext context){
    String uid = this.auth.currentUser!.uid;
    return FutureBuilder<List<ReviewCard>>(
      future: _loadLocalUserReviews(uid),
      builder: (context, snap){
        if(!snap.hasData || snap.data == null){
          return Center(
            child: Column(
              children: [
                Image(image: AssetImage("assets/icons8-friends-100.png"),),
                SizedBox(height: 20.0,),
                Text("Follow travelers in your area to get the latest updates!", style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 20.0,),
              ],
            ),
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
      },
    );
  }
}