import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ConnectFriends extends StatelessWidget{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final List<ReviewCard>? cards;

  ConnectFriends({Key? key, required this.cards}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if(this.cards!.isEmpty || this.cards == null){
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
                    return this.cards![index];
                  },
                  separatorBuilder: (context, index) => Divider(indent: 16.0, endIndent: 16.0, thickness: 2.0,),
                  itemCount: this.cards!.length),
              ),
              SizedBox(height: 20.0,),
            ],
          );
        }
      }
}