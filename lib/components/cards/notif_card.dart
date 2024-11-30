import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotifCard extends StatefulWidget{
  final String text;
  final String type;
  final bool unread;
  final String fromScreen;
  final String sentBy;
  final DateTime sentAt;
  const NotifCard({super.key, required this.text, required this.type, required this.unread, required this.fromScreen, required this.sentBy, required this.sentAt});

  @override
  State<NotifCard> createState() => NotifCardState();
}

class NotifCardState extends State<NotifCard> with AutomaticKeepAliveClientMixin{
  late bool isUnread;
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    isUnread = widget.unread;
    print("Notification details:");
    print("Text: ${widget.text}");
    print("From screen: ${widget.fromScreen}");
    print("Type: ${widget.type}");
    print("Is it unread? ${widget.unread}");
    print("Sent by: ${widget.sentBy}");
    print("Sent at: ${widget.sentAt}");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () async{
        setState(() {
          if(isUnread){
            isUnread = false;
          }
        });
        final snap = await this.firestore.collection('User').doc(this.auth.currentUser?.uid).collection('Notifications').where('notificationText', isEqualTo: widget.text).where('sentBy', isEqualTo: widget.sentBy).where('sentAt', isEqualTo: Timestamp.fromDate(widget.sentAt)).get();
        try{
          await snap.docs.first.reference.update({'unread':false});
          print("Notification updated");
        } catch(e) {
          print("Exception in updating notification: $e");
        }
        if(widget.type == 'friendRequest'){
          GoRouter.of(context).go('/connect/${widget.fromScreen}'+'/notifications/acceptreq?q=${widget.sentBy}');
        }
      },
      child: Container(
        padding: EdgeInsets.only(left:10.0,right:10.0,top:5.0,bottom:5.0),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF030303), width: 1.0),
          borderRadius: BorderRadius.all(Radius.zero),
        ),
        child: Row(
          children: [
            Icon(Icons.circle, color: isUnread ? Color(0xFFBA2020) : Color(0xFF7A7777)),
            SizedBox(width: 10.0),
            Expanded(
              child: Text(widget.text, style: TextStyle(color: isUnread ? Color(0xFF030303) : Color(0xFF5C5A5A)), overflow: TextOverflow.ellipsis,)
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive{
    return true;
  }
}