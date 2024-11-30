import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
import 'package:odyssey/components/alerts/alert_dialog.dart';
import 'package:odyssey/components/navigation/app_bar.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:odyssey/utils/spaces.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  String? imageUrl;
    String? getCurrentUserId() {
    final User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Future<void> _loadProfileImage() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception("User not logged in");
      }

      final docSnapshot =
          await FirebaseFirestore.instance.collection('User').doc(userId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        imageUrl = data['imageUrl'] as String?;
        setState(() {});
      }
    } catch (e) {
      print("Error loading profile image: $e");
      // Optionally, show an error message to the user.
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => MyAlertDialog(
        title: 'Logout',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Are you sure you want to logout?",
                style: Theme.of(context).textTheme.headlineSmall),
            mediumVertical,
            ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(LogOutEvent());
                },
                child: Text("Yes, Logout")),
            smallVertical,
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: "Profile"),
      body: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              largeVertical,
              Center(
                child: imageUrl != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(imageUrl!),
                      )
                    : Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
                      ),
              ),
              mediumVertical,
              Text("Profile Name",
                  style: Theme.of(context).textTheme.headlineLarge),
              extraSmallVertical,
              Text("Profile Location",
                  style: Theme.of(context).textTheme.headlineSmall)
            ],
          ),
          mediumVertical,
          ListView(
            shrinkWrap: true,
            padding: smallPadding,
            children: [
              ListTile(
                minVerticalPadding: 10,
                title: Text('Edit profile'),
                onTap: () {
                  GoRouter.of(context).go(Paths.editProfile);
                },
              ),
              Divider(),
              ListTile(
                minVerticalPadding: 10,
                title: Text('Saved locations'),
                onTap: () {
                  GoRouter.of(context).go(Paths.savedLocations);
                },
              ),
              Divider(),
              ListTile(
                minVerticalPadding: 10,
                title: Text('Maps download network'),
                onTap: () {
                  GoRouter.of(context).go(Paths.downloadNetwork);
                },
              ),
              Divider(),
              ListTile(
                minVerticalPadding: 10,
                title: Text('Manage membership'),
                onTap: () {
                  GoRouter.of(context).go(Paths.manageMembership);
                },
              ),
              Divider(),
              ListTile(
                minVerticalPadding: 10,
                title: Text(
                  'Logout',
                ),
                onTap: () {
                  _showLogoutDialog();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
