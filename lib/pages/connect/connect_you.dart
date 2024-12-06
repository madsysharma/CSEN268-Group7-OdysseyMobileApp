import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:odyssey/utils/paths.dart';

class ConnectYou extends StatelessWidget{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final List<ReviewCard>? cards;

  ConnectYou({Key? key, required this.cards}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if(cards?.length==0){
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
                    GoRouter.of(context).go('/connect/you'+Paths.post);
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
                  padding: const EdgeInsets.all(15.0),
                  shrinkWrap: true,
                  itemBuilder: (context, index){
                    return cards?[index];
                  },
                  separatorBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Divider(indent: 16.0, endIndent: 16.0, thickness: 2.0,),
                  ),
                  itemCount: cards!.length)
              ),
              SizedBox(height: 20.0,),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF006A68),
                    foregroundColor: Colors.white,
                    textStyle: Theme.of(context).textTheme.headlineSmall,
                    side: BorderSide(
                      width: 0.3,
                    ),
                  ),
                  onPressed: () async{
                    GoRouter.of(context).go('/connect/you'+Paths.post);
                  },
                  child: Text("Create new post", style: TextStyle(color: Colors.white),)
              ),
              SizedBox(height: 5.0),
            ],
          );
        }
  }
}