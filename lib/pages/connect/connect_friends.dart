import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odyssey/utils/date_time_utils.dart';

class ConnectFriends extends StatefulWidget{
  ConnectFriends({super.key});

  @override
  State<ConnectFriends> createState() => _ConnectFriendsState();
}

class _ConnectFriendsState extends State<ConnectFriends> with AutomaticKeepAliveClientMixin{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<ReviewCard>> _loadFriendReviews(String? uid) async{
    final snap = await firestore.collection('User').doc(uid).get();
    if (!snap.exists || snap.data()?['friends'] == null) {
      print("No friends found for user: $uid");
      return [];
    }
    List<String> friendlist = List<String>.from(snap.data()?['friends']);
    print('Processed friend list: $friendlist');
    List<ReviewCard> reviews = [];
    for(String f in friendlist){
      print("Query name: ${f.toLowerCase().split(" ").first}");
      Query<Map<String, dynamic>> friendsQuery = await this.firestore.collection('Review').where('username',isEqualTo: f.split(" ").first);
      QuerySnapshot<Map<String, dynamic>> querySnap = await friendsQuery.get();
      for(var doc in querySnap.docs){
        final postedDate = doc.data()['postedOn'] ?? "";
        final dayDifference = getDayDifference(postedDate.toDate());
        final revText = doc.data()['reviewtext'] ?? "";
        print("Posted date: $postedDate, day difference: $dayDifference, review text: $revText");
        reviews.add(ReviewCard(pageName: "ConnectFriends",imgUrls: List<String>.from(doc.data()['images']), posterName: f.split(" ").first, dayDiff: dayDifference, reviewText: revText,));
      }
    }
    print("Reviews: $reviews");
    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String? uid = this.auth.currentUser?.uid;
    return FutureBuilder(
      future: _loadFriendReviews(uid),
      builder: (context, snap){
        if(snap.connectionState == ConnectionState.waiting){
          return Center(child: CircularProgressIndicator());
        }
        else if(snap.hasError){
          return Center(child: Text("An error occurred: ${snap.error}"));
        }
        else if(snap.data!.isEmpty || snap.data == null){
          return Center(
            child: Column(
              children: [
                Image(image: AssetImage("assets/icons8-friends-100.png"),),
                SizedBox(height: 20.0,),
                Text("Your friend list is empty. Make new friends and be a part of their adventures!", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 20.0,),
              ],
            )
          );
        } else {
          return Container(
            constraints: BoxConstraints(maxHeight: double.infinity),
            child: ListView.separated(
              shrinkWrap: true,
              itemBuilder: (context, index){
                return snap.data![index];
              },
              separatorBuilder: (context, index) => Divider(indent: 16.0, endIndent: 16.0, thickness: 2.0,),
              itemCount: snap.data!.length)
          );
        }
      }
    );
  }

  @override
  bool get wantKeepAlive => true;
}