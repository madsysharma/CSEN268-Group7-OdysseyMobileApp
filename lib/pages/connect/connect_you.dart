import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/components/shimmer_list.dart';
import 'package:odyssey/api/review.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:odyssey/model/review.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:odyssey/utils/date_time_utils.dart';

class ConnectYou extends StatefulWidget{
  ConnectYou({super.key});

  @override
  State<ConnectYou> createState() => _ConnectYouState();
}

class _ConnectYouState extends State<ConnectYou> with AutomaticKeepAliveClientMixin{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Future<List<ReviewCard>> _futureCards;

  @override
  void initState() {
    super.initState();
    reloadReviews();
  }

  void reloadReviews(){
    String? email = this.auth.currentUser?.email;
    setState(() {
      _futureCards = _load(email);
    });
  }

  Future<List<ReviewCard>> _load(String? email) async{
    await Future.delayed(Duration(seconds: 5));
    List<LocationReview> reviews = await fetchReviews(userEmail: email);
    return reviews
        .map((review) => ReviewCard(pageName: "ConnectYou", imgUrls: review.images ?? [], posterName: "You", locationName: review.locationName ?? "", dayDiff: getDayDifference(review.postedOn!), reviewText: review.reviewText!,))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: _futureCards,
      builder: (context, snap) {
        if(snap.connectionState == ConnectionState.waiting){
          return ShimmerList();
        }
        else if(snap.hasError){
          print('Error: ${snap.error}');
          return Center(
            child: Text("Something went wrong. Please try again."),
            );
        }
        else if(snap.data?.length==0){
          print("No reviews by you");
          return Center(
            child: Column(
              children: [
                Image(image: AssetImage("assets/icons8-passport-100.png"),),
                SizedBox(height: 20.0,),
                Text("Looks like you haven't posted anything yet. Your travelogue awaits!", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 20.0,),
                ElevatedButton(
                  onPressed: () async{
                    await GoRouter.of(context).push('/connect/you'+Paths.post);
                    reloadReviews();
                  },
                  child: Text("Create new post", style: Theme.of(context).textTheme.headlineSmall))
              ],
            ),
          );
        }
        else{
          print("You have posted these reviews");
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
              SizedBox(height: 10.0,),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    side: BorderSide(
                      width: 0.3,
                      color: Color(0xFF006A68),
                    ),
                  ),
                  onPressed: (){
                    GoRouter.of(context).go('/connect/you'+Paths.post);
                  },
                  child: Text("Create new post", style: Theme.of(context).textTheme.headlineSmall)
              ),
              SizedBox(height: 5.0),
            ],
          );
        }
      }
    );
  }

  @override
  bool get wantKeepAlive{
    return true;
  }
}