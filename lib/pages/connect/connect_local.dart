import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:odyssey/components/shimmer_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odyssey/utils/date_time_utils.dart';

class ConnectLocal extends StatefulWidget{
  ConnectLocal({Key? key}): super(key:key);

  @override
  State<ConnectLocal> createState() => ConnectLocalState();
}

class ConnectLocalState extends State<ConnectLocal>{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Future<List<ReviewCard>> _futureCards;

  @override
  void initState() {
    super.initState();
    reloadLocalReviews();
  }

  void clearState(){
    setState(() {
      _futureCards = Future.value([]);
    });
  }

  void reloadLocalReviews({List<String>? locNames, List<String>? filters, List<double>? stars, String? search}){
    String? uid = this.auth.currentUser?.uid;
    setState(() {
      _futureCards = Future<List<ReviewCard>>.delayed(
        const Duration(seconds: 2),
        () => _loadLocalUserReviews(uid,locations: locNames, appliedFilters: filters, numStars: stars, searchText: search),
      );
    });
  }

  Future<List<ReviewCard>> _loadLocalUserReviews(String? uid, {List<String>? locations, List<String>? appliedFilters, List<double>? numStars, String? searchText}) async{
    //await Future.delayed(Duration(seconds: 1));
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
      if(homeloc == null || homeloc.isEmpty){
        print("Home location is empty");
        return [];
      }
      final localUserQuery = await this.firestore.collection('User').where('homelocation',isEqualTo: homeloc);
      final querySnap = await localUserQuery.get();
      List<String> names = [];
      List<ReviewCard> reviews = [];
      for(var doc in querySnap.docs){
        final data = doc.data();
        final firstname = data['firstname'] ?? "";
        final lastname = data['lastname'] ?? "";
        names.add("$firstname $lastname");
      }
      for(String n in names){
        final localReviewQuerySnap = await this.firestore.collection('Review').where('username',isEqualTo: n.split(" ").first).get();
        var filteredDocs = localReviewQuerySnap.docs;
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
          final images = List<String>.from(doc.data()['images']);
          final postedDate = doc.data()['postedOn'] ?? "";
          final dayDifference = postedDate != null ? getDayDifference(postedDate.toDate()) : 0;
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
  void didUpdateWidget(covariant ConnectLocal oldWidget) {
    super.didUpdateWidget(oldWidget);
    reloadLocalReviews(); // Trigger reload on widget update
  }

  @override
  Widget build(BuildContext context){
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
                  child: Text("No highlights shared for your location yet. Stay tuned!", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall)),
                SizedBox(height: 20.0,),
              ],
            ),
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
                itemCount: snap.data!.length)
              ),
              SizedBox(height: 20.0,),
            ]
          );
        }
      },
    );
  }
}