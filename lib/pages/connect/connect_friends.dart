import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:odyssey/components/shimmer_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odyssey/utils/date_time_utils.dart';

class ConnectFriends extends StatefulWidget{
  ConnectFriends({Key? key}): super(key:key);

  @override
  State<ConnectFriends> createState() => ConnectFriendsState();
}

class ConnectFriendsState extends State<ConnectFriends>{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Future<List<ReviewCard>> _futureCards;

  @override
  void initState() {
    super.initState();
    reloadFriendReviews();
  }

  void clearState(){
    setState(() {
      _futureCards = Future.value([]);
    });
  }

  void reloadFriendReviews({List<String>? locNames, List<String>? filters, List<double>? stars, String? search}){
    String? uid = this.auth.currentUser?.uid;
    setState(() {
      _futureCards = _loadFriendReviews(uid, locations: locNames, appliedFilters: filters, numStars: stars, searchText: search);
    });
  }

  Future<List<ReviewCard>> _loadFriendReviews(String? uid, {List<String>? locations, List<String>? appliedFilters, List<double>? numStars, String? searchText}) async{
    await Future.delayed(Duration(seconds: 1));
    final snap = await firestore.collection('User').doc(uid).get();
    if (!snap.exists || snap.data()?['friends'] == null) {
      print("No friends found for user: $uid");
      return [];
    }
    List<String> friendlist = List<String>.from((snap.data()?['friends'] ?? []).where((e) => e!=null));
    print('Processed friend list: $friendlist');
    List<ReviewCard> reviews = [];
    for(String f in friendlist){
      Query<Map<String, dynamic>> friendsQuery = await this.firestore.collection('Review').where('username',isEqualTo: f);
      QuerySnapshot<Map<String, dynamic>> querySnap = await friendsQuery.get();
      var filteredDocs = querySnap.docs;
      if(searchText != null && searchText.isNotEmpty){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return data['reviewText'].contains(searchText);
          }).toList();
        }
        if(locations != null){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return locations.contains(data['locationName']);
          }).toList();
        }
        if(appliedFilters != null){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return data['tags'].toSet().intersection(appliedFilters.toSet()).isNotEmpty;
          }).toList();
        }
        if(numStars != null){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return numStars.contains(data['rating'].toDouble());
          }).toList();
        }
      for(var doc in filteredDocs){
        final postedDate = doc.data()['postedOn'] ?? "";
        final dayDifference = getDayDifference(postedDate.toDate());
        final revText = doc.data()['reviewText'] ?? "";
        print("Posted date: $postedDate, day difference: $dayDifference, review text: $revText");
        reviews.add(ReviewCard(pageName: "ConnectFriends",imgUrls: List<String>.from(doc.data()['images']), posterName: f, locationName: doc.data()['locationName'], dayDiff: dayDifference, reviewText: revText,));
      }
    }
    print("Reviews: $reviews");
    return reviews;
  }

  @override
  void didUpdateWidget(covariant ConnectFriends oldWidget) {
    super.didUpdateWidget(oldWidget);
    reloadFriendReviews(); // Trigger reload on widget update
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _futureCards,
      builder: (context, snap){
        if(snap.connectionState == ConnectionState.waiting){
          return ShimmerList();
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
          return Column(
            children: [
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8.0),
                  shrinkWrap: true,
                  itemBuilder: (context, index){
                    return snap.data![index];
                  },
                  separatorBuilder: (context, index) => Divider(indent: 16.0, endIndent: 16.0, thickness: 2.0,),
                  itemCount: snap.data!.length),
              ),
              SizedBox(height: 20.0,),
            ],
          );
        }
      }
    );
  }
}