import 'package:flutter/material.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FriendRequest extends StatefulWidget{
  FriendRequest({super.key});

  @override
  State<FriendRequest> createState() => FriendRequestState();
}

class FriendRequestState extends State<FriendRequest> with AutomaticKeepAliveClientMixin{
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<String> friendsToAdd = [];
  Map<String, String> emailIds = {};
  List<String> searchResults = [];

  @override
  void initState() {
    super.initState();
    String? userId = this.auth.currentUser?.uid;
    loadDetails(userId);
    print("Friends to add:");
    print(this.friendsToAdd);
    print("Email ids: ");
    print(this.emailIds);
  }

  Future<void> loadDetails(String? uid) async{
    final QuerySnapshot<Map<String, dynamic>> snap = await this.firestore.collection('User').get();
    for(var doc in snap.docs){
      String fullName = "${doc.data()['firstname'] ?? 'Unknown'} ${doc.data()['lastname'] ?? ''}".trim();
      String email = doc.data()['email'] ?? '';
      if(email.isNotEmpty && fullName.isNotEmpty){
        this.friendsToAdd.add(fullName);
        this.emailIds[fullName]=doc.data()['email'];
      }
    }
  }

  void autoCompleteSearch(String ip){
    if(ip.isEmpty){
      setState((){
        this.searchResults = [];
      });
      return;
    }
    setState(() {
      this._isSearching = true;
    });

    try
    {
      List<String> fetchResults = [];
      if(this.friendsToAdd.isEmpty){
        fetchResults = [];
      }
      else
      {
        fetchResults = this.friendsToAdd.where((f) => f.contains(ip)).toList();
      }
      setState(() {
        this.searchResults = fetchResults;
      });
    }
    catch(e)
    {
      print("Error fetching user list");
      setState(() {
        this.searchResults = [];
      });
    }
    finally
    {
      setState(() {
        this._isSearching = false;
      });
    }
  }

  void createRequestDialog(String text) async{
    String? recepientEmail = emailIds[text]??'';
    String? username = "";
    DocumentSnapshot<Map<String, dynamic>> snap = await this.firestore.collection('User').doc(this.auth.currentUser?.uid).get();
    if(snap.exists){
      username = "${snap.data()?['firstname'] ?? 'Unknown'} ${snap.data()?['lastname'] ?? ''}".trim();
    }
    showDialog(
      context: context,
      builder: (context){
        return SimpleDialog(
          title: Text("Want to add $text as a friend?", style: Theme.of(context).textTheme.headlineSmall),
          children: [
            Padding(
              padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 0.0),
              child: Text("An email will be sent to $recepientEmail.", style: Theme.of(context).textTheme.bodyMedium),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 24.0, top: 24.0, bottom: 24.0),
                  child: Row(
                    children: [
                      SimpleDialogOption(
                        onPressed: () async{
                          if(recepientEmail.isNotEmpty){
                            final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendFriendRequestEmail');
                            try
                            {
                              print("Sender name: $username");
                              print("Sender email: ${this.auth.currentUser?.email}");
                              print("Recipient email: $recepientEmail");
                              final idToken = await this.auth.currentUser?.getIdToken(true);
                              print("ID token: $idToken");
                              final data = {'email':recepientEmail, 'senderName':username, 'senderEmail':this.auth.currentUser?.email, 'authToken': idToken};
                              print("Data: $data");
                              final response = await callable.call(data);
                              if(response.data['success']){
                                print(response.data['message']);
                                try{
                                  final query = await this.firestore.collection('User').where('email', isEqualTo: recepientEmail).get();
                                  final userDoc = query.docs.first;
                                  final notifCollection = await this.firestore.collection('User').doc(userDoc.id).collection('Notifications');
                                  await notifCollection.
                                  add(
                                    {
                                      'recipient': userDoc.data()['firstname']+" "+userDoc.data()['lastname'],
                                      'notificationText': "$username wants to connect with you on Odyssey. Make a new friend today!",
                                      'type': 'friendRequest',
                                      'sentAt': FieldValue.serverTimestamp(),
                                      'sentBy': username,
                                      'unread': true,
                                      'accepted': 'Not yet',
                                    }
                                  );
                                  Navigator.of(context).pop();
                                  showMessageSnackBar(context, "Success! Email sent to $text");
                                } catch(e) {
                                  Navigator.of(context).pop();
                                  showMessageSnackBar(context, "Error: $e");
                                }
                              }
                              else{
                                print('Error: ${response.data['message']}');
                                Navigator.of(context).pop();
                                showMessageSnackBar(context, "Error in sending email");
                              }
                            } on FirebaseAuthException catch (e) {
                              print("Error: ${e.message}");
                              Navigator.of(context).pop();
                              showMessageSnackBar(context, "Sending friend request failed. Please try again");
                            }
                          }
                          else
                          {
                            Navigator.of(context).pop();
                            showMessageSnackBar(context, "Cannot send email without recipient. Please try again.");
                          }
                        },
                        child: Text("Yes", style: Theme.of(context).textTheme.labelLarge)
                      ),
                      SimpleDialogOption(
                        onPressed: (){
                          Navigator.of(context).pop();
                        },
                        child: Text("No", style: Theme.of(context).textTheme.labelLarge)
                      ),
                    ],
                  )
                )
              ],
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: Text("Friend Request",)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: this._searchController,
              onChanged: autoCompleteSearch,
              decoration: InputDecoration(
                hintText: "Search for people.",
                prefixIcon: _isSearching ? CircularProgressIndicator() : Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0)
              ),
            ),
            SizedBox(height: 10.0),
            Expanded(
              child: ListView.separated(
                itemCount: this.searchResults.length,
                itemBuilder: (context, index){
                  return ListTile(
                    title: Text(this.searchResults[index]),
                    onTap: (){
                      createRequestDialog(this.searchResults[index]);
                    },
                  );
                },
                separatorBuilder: (context, index){
                  if(index < this.searchResults.length - 1){
                    return Divider(indent: 16.0, endIndent: 16.0, thickness: 2.0,);
                  }
                  else
                  {
                    return Divider(indent: 0.0, endIndent: 0.0, thickness: 0.0,);
                  }
                },
              )
            )
          ],
        )
      ),
    );
  }

  @override
  bool get wantKeepAlive{
    return true;
  }
}