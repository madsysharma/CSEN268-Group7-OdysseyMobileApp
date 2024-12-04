import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:odyssey/components/shimmer_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odyssey/utils/date_time_utils.dart';

class ConnectLocal extends StatefulWidget{
  ConnectLocal({super.key});

  @override
  State<ConnectLocal> createState() => _ConnectLocalState();
}

class _ConnectLocalState extends State<ConnectLocal> with AutomaticKeepAliveClientMixin{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Future<List<ReviewCard>> _futureCards;

  @override
  void initState() {
    super.initState();
    reloadReviews();
  }

  void reloadReviews(){
    String? uid = this.auth.currentUser?.uid;
    setState(() {
      _futureCards = _loadLocalUserReviews(uid);
    });
  }

  Future<List<ReviewCard>> _loadLocalUserReviews(String? uid) async{
    await Future.delayed(Duration(seconds: 5));
    try {
      if(uid == null){
        print("UID is null!");
        return [];
      }
      final snap = await this.firestore.collection('User').doc(uid).get();
      if(!snap.exists){
        print("Error: document doesn't exist for uid");
        return [];
      }
      final homeloc = snap.data()?['homelocation'];
      if(homeloc.isEmpty){
        print("Home location is empty");
        return [];
      }
      final localUserQuery = await this.firestore.collection('User').where('homelocation',isEqualTo: homeloc);
      final querySnap = await localUserQuery.get();
      List<String> names = [];
      List<ReviewCard> reviews = [];
      for(var doc in querySnap.docs){
        final firstname = doc.data()['firstname'] ?? "";
        final lastname = doc.data()['lastname'] ?? "";
        names.add("$firstname $lastname");
      }
      for(String n in names){
        final localReviewQuerySnap = await this.firestore.collection('Review').where('username'.toLowerCase(),isEqualTo: n.toLowerCase().split(" ").first).get();
        for(var doc in localReviewQuerySnap.docs){
          final images = List<String>.from(doc.data()['images']) ?? [];
          final postedDate = doc.data()['postedOn'] ?? "";
          final dayDifference = getDayDifference(postedDate.toDate());
          final revText = doc.data()['reviewtext'] ?? "";
          reviews.add(ReviewCard(pageName: "ConnectLocal", imgUrls: images, posterName: n.split(" ").first, locationName: doc.data()['locationname'], dayDiff: dayDifference, reviewText: revText,));
        }
      }
      print('Loaded reviews: ${reviews.length}');
      return reviews;
    } catch (e, stackTrace) {
      print("Error loading local user reviews: $e");
      print(stackTrace);
      return [];
    }
  }

  @override
  Widget build(BuildContext context){
    super.build(context);
    return FutureBuilder<List<ReviewCard>>(
      future: _futureCards,
      builder: (context, snap){
        if(snap.connectionState == ConnectionState.waiting) {
          return ShimmerList();
        } else if (snap.hasError) {
          print("Error in FutureBuilder: ${snap.error}");
          return Center(child: Text("An error occurred: ${snap.error}"));
        } else if(!snap.hasData || snap.data == null || snap.data!.isEmpty){
          return Center(
            child: Column(
              children: [
                Image(image: AssetImage("assets/icons8-friends-100.png"),),
                SizedBox(height: 20.0,),
                Align(
                  alignment: Alignment.center,
                  child: Text("Follow travelers in your area to get the latest updates!", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall)),
                SizedBox(height: 20.0,),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemBuilder: (context, index){
                  return snap.data![index];
                },
                separatorBuilder: (context, index) => Divider(indent: 16.0, endIndent: 16.0, thickness: 2.0,),
                itemCount: snap.data!.length)
              ),
            ]
          );
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}