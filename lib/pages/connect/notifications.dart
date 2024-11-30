import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odyssey/components/cards/notif_card.dart';

class Notifications extends StatefulWidget{
  final String fromScreen;
  Notifications({super.key, required this.fromScreen});

  @override
  State<Notifications> createState() => NotificationsState();
}

class NotificationsState extends State<Notifications> with AutomaticKeepAliveClientMixin{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> notifs = [];
  
  @override
  void initState() {
    super.initState();
    String? userId = this.auth.currentUser?.uid;
    loadNotifs(userId);
  }

  Future<void> loadNotifs(String? uid) async{
    final snap = await this.firestore.collection('User').doc(uid).collection('Notifications').get();
    setState(() {
      notifs = snap.docs.map((doc) => doc.data()).toList();
    });
    print("Notifications: ${this.notifs}");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: this.notifs.length,
              itemBuilder: (context, index){
                Map<String, dynamic> notif = this.notifs[index];
                return NotifCard(text: notif['notificationText'], type: notif['type'], unread: notif['unread'], fromScreen: widget.fromScreen, sentBy: notif['sentBy'], sentAt: notif['sentAt'].toDate(), acceptStatus: notif['accepted'],);
              }
            )
          )
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive{
    return true;
  }
}