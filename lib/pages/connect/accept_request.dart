import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class AcceptRequest extends StatelessWidget{
  final String? requesterName;
  AcceptRequest({super.key, required this.requesterName});

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accept Friend Request?"),),
      body: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text("${requesterName} sent you a friend request. Accept?"),
            SizedBox(height: 20.0),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async{
                    String? firstName = this.requesterName?.split(" ").first;
                    String username = "";
                    String email = "";
                    DocumentSnapshot<Map<String, dynamic>> querysnap = await this.firestore.collection('User').doc(this.auth.currentUser?.uid).get();
                    if(querysnap.exists){
                      username = querysnap.data()?['firstname'] + " " + querysnap.data()?['lastname'];
                    }
                    else
                    {
                      username = "";
                    }
                    try {
                      final snap = await this.firestore.collection('User').where('firstname', isEqualTo: firstName).get();
                      final userDoc = snap.docs.first;
                      email = userDoc.data()['email'];
                      final notifCollection = await this.firestore.collection('User').doc(userDoc.id).collection('Notifications');
                      await notifCollection.add(
                        {
                          'recipient': userDoc.data()['firstname']+" "+userDoc.data()['lastname'],
                          'notificationText': "$username accepted your friend request.",
                          'type': 'acceptedRequest',
                          'sentAt': FieldValue.serverTimestamp(),
                          'sentBy': username,
                          'unread': true,
                        }
                      );
                      final senderDocRef = this.firestore.collection('User').doc(this.auth.currentUser?.uid);
                      final recvDocRef = this.firestore.collection('User').doc(userDoc.id);
                      final sendData = await senderDocRef.get();
                      final recvData = await recvDocRef.get();
                      List<String?> senderFriends = List<String?>.from(sendData.data()?['friends'] ?? []);
                      List<String?> recvFriends = List<String?>.from(recvData.data()?['friends'] ?? []);
                      senderFriends.add(firstName);
                      await senderDocRef.update({'friends': senderFriends});
                      recvFriends.add(username);
                      await recvDocRef.update({'friends': recvFriends});
                      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendAcceptRequestEmail');
                      try{
                        final response = await callable.call(
                          {
                            'email': email,
                            'senderName': username,
                            'senderEmail': this.auth.currentUser?.email,
                          }
                        );
                        if(response.data['success']){
                          print(response.data['message']);
                          print("Email sent successfully!");
                        }
                        else{
                          print(response.data['message']);
                          print("Error in sending email");
                        }
                      } catch(e){
                        print("Exception: $e");
                      }
                    } catch (e){
                      print("Exception: $e");
                    }
                    GoRouter.of(context).pop();
                  },
                  child: Text("Yes")
                ),
                ElevatedButton(
                  onPressed: (){
                    print("Friend request denied");
                    GoRouter.of(context).pop();
                  },
                  child: Text("No")
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
