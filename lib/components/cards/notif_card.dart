import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odyssey/pages/connect/connect.dart';

class NotifCard extends StatefulWidget{
  final String text;
  final String type;
  final bool unread;
  final String fromScreen;
  final String sentBy;
  final DateTime sentAt;
  final String acceptStatus;
  const NotifCard({super.key, required this.text, required this.type, required this.unread, required this.fromScreen, required this.sentBy, required this.sentAt, required this.acceptStatus});

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
    print("Accept status: ${widget.acceptStatus}");
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
          if (widget.fromScreen == 'Notifications') {
            context.findAncestorStateOfType<ConnectState>()?.collectUnreadNotifs(this.auth.currentUser?.uid);
          }
        } catch(e) {
          print("Exception in updating notification: $e");
        }
        if(widget.type == 'friendRequest' && widget.acceptStatus == 'Not yet'){
          GoRouter.of(context).go('/connect/${widget.fromScreen}'+'/notifications/acceptreq?sentBy=${widget.sentBy}&sentAt=${widget.sentAt.toString()}');
        }
        else if(widget.type == 'friendRequest' && (widget.acceptStatus == 'Yes' || widget.acceptStatus == 'No')){
          GoRouter.of(context).go('/connect/${widget.fromScreen}'+'/notifications/expiredreq');
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