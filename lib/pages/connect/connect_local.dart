import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectLocal extends StatelessWidget{
  final List<ReviewCard>? cards;

  ConnectLocal({Key? key, required this.cards}) : super(key:key);

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context){
    if(cards == null || cards!.isEmpty){
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
                padding: const EdgeInsets.all(15.0),
                shrinkWrap: true,
                itemBuilder: (context, index){
                  return cards![index];
                },
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Divider(indent: 16.0, endIndent: 16.0, thickness: 2.0,),
                ),
                itemCount: cards!.length)
              ),
              SizedBox(height: 20.0,),
            ]
          );
        }
  }
}