import 'package:flutter/material.dart';
import 'package:odyssey/components/review_card.dart';

class ConnectFriends extends StatelessWidget{
  const ConnectFriends({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: double.infinity),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReviewCard(pageName:"ConnectFriends"),
            Divider(indent: 16.0, endIndent: 16.0, thickness: 2.0,),
            ReviewCard(pageName:"ConnectFriends"),
            Divider(indent: 16.0, endIndent: 16.0, thickness: 2.0,),
            ReviewCard(pageName:"ConnectFriends"),
          ]
        )
      ),
    );
  }
}