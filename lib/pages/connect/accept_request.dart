import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:odyssey/utils/spaces.dart';

class AcceptRequest extends StatelessWidget{
  final String? requesterName;
  final String? sentAt;
  AcceptRequest({super.key, required this.requesterName, required this.sentAt});
  
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(title: Text("Accept Friend Request?"), backgroundColor: const Color.fromARGB(255, 189, 220, 204),),
      body: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text("${requesterName} sent you a friend request. Accept?"),
            SizedBox(height: 20.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
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
                        String recipient = userDoc.data()['firstname']+" "+userDoc.data()['lastname'];
                        final notifCollection = await this.firestore.collection('User').doc(userDoc.id).collection('Notifications');
                        await notifCollection.add(
                          {
                            'recipient': recipient,
                            'notificationText': "$username accepted your friend request.",
                            'type': 'acceptedRequest',
                            'sentAt': FieldValue.serverTimestamp(),
                            'sentBy': username,
                            'unread': true,
                            'accepted': "Yes",
                          }
                        );
                        //Update notification status for the sender as well
                        final senderNotif = await this.firestore.collection('User').doc(this.auth.currentUser?.uid).collection('Notifications').where('notificationText', isEqualTo: '$recipient wants to connect with you on Odyssey. Make a new friend today!').get();
                        var filteredDocuments = senderNotif.docs;
                        if(this.sentAt == null && this.sentAt!.isNotEmpty){
                          filteredDocuments = filteredDocuments.where((d){
                            final sentTime = d.data()['sentAt'];
                            return sentTime.toDate().toString() == this.sentAt.toString();
                          }).toList();
                        }
                        var retrievedDoc = filteredDocuments.first;
                        await retrievedDoc.reference.update({'accepted':"Yes"});
                        final senderDocRef = this.firestore.collection('User').doc(this.auth.currentUser?.uid);
                        final recvDocRef = this.firestore.collection('User').doc(userDoc.id);
                        final sendData = await senderDocRef.get();
                        final recvData = await recvDocRef.get();
                        List<String?> senderFriends = List<String?>.from(sendData.data()?['friends'] ?? []);
                        List<String?> recvFriends = List<String?>.from(recvData.data()?['friends'] ?? []);
                        senderFriends.add(requesterName);
                        await senderDocRef.update({'friends': senderFriends});
                        recvFriends.add(username);
                        await recvDocRef.update({'friends': recvFriends});
                        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendAcceptRequestEmail');
                        try{
                          final idToken = await this.auth.currentUser?.getIdToken(true);
                          print("ID token: $idToken");
                          final data = {'email':email, 'senderName':username, 'senderEmail':this.auth.currentUser?.email, 'authToken': idToken};
                          print("Data: $data");
                          final response = await callable.call(data);
                          if(response.data['success']){
                            print(response.data['message']);
                            print("Email sent successfully!");
                            showMessageSnackBar(context, "Success! You and $requesterName are now friends.");
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
                ),
                smallHorizontal,
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async{
                      String? firstName = this.requesterName?.split(" ").first;
                      final snap = await this.firestore.collection('User').where('firstname', isEqualTo: firstName).get();
                      final userDoc = snap.docs.first;
                      String recipient = userDoc.data()['firstname']+" "+userDoc.data()['lastname'];
                      final senderNotif = await this.firestore.collection('User').doc(this.auth.currentUser?.uid).collection('Notifications').where('notificationText', isEqualTo: '$recipient wants to connect with you on Odyssey. Make a new friend today!').get();
                      var filteredDocuments = senderNotif.docs;
                      if(this.sentAt == null && this.sentAt!.isNotEmpty){
                        filteredDocuments = filteredDocuments.where((d){
                          final sentTime = d.data()['sentAt'];
                          return sentTime.toDate().toString() == this.sentAt.toString();
                        }).toList();
                      }
                      var retrievedDoc = filteredDocuments.first;
                      await retrievedDoc.reference.update({'accepted':"No"});
                      showMessageSnackBar(context, "You have not accepted $requesterName\'s friend request.");
                      GoRouter.of(context).pop();
                    },
                    child: Text("No")
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
