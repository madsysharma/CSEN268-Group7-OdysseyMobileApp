import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequest extends StatefulWidget{
  FriendRequest({super.key});

  @override
  State<FriendRequest> createState() => _FriendRequestState();
}

class _FriendRequestState extends State<FriendRequest> with AutomaticKeepAliveClientMixin{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Future<List<String>> friends;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String? userId = this.auth.currentUser?.uid;
    friends = loadUsers(userId);
  }

  Future<List<String>> loadUsers(String? uid) async{
    List<String> userList = [];
    final QuerySnapshot<Map<String, dynamic>> snap = await this.firestore.collection('User').get();
    for(var doc in snap.docs){
      userList.add(doc.data()['firstname']+" "+doc.data()['lastname']);
    }
    return userList;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: Text("Friend Request",)),
      body: Container(),
    );
  }

  @override
  bool get wantKeepAlive{
    return true;
  }
}