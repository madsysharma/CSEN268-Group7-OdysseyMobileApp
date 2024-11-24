import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:odyssey/utils/paths.dart';

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
    String? uid = this.auth.currentUser?.uid;
    _futureCards = _load(uid);
  }

  Future<List<ReviewCard>> _load(String? uid) async{
    final QuerySnapshot<Map<String, dynamic>> snap = await this.firestore.collection('Review').where('uid',isEqualTo: uid).get();
    return snap.docs
        .map((doc) => ReviewCard(pageName: "ConnectYou", imgUrls: doc.data()['images'] ?? []))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: _futureCards,
      builder: (context, snap) {
        if(snap.connectionState == ConnectionState.waiting){
          return Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20.0,),
                Text("Loading...")
              ],
            )
          );
        }
        else if(snap.hasError){
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
                  onPressed: (){
                    context.go('/connect/you'+Paths.post);
                  },
                  child: Text("Create new post", style: Theme.of(context).textTheme.headlineSmall))
              ],
            ),
          );
        }
        else{
          print("You have posted these reviews");
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
  bool get wantKeepAlive{
    return true;
  }
}