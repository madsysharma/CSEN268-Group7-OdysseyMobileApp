import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
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

  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? imagePath = prefs.getString('profile_image_path');

    if (imagePath != null) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
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
                child: _profileImage != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: FileImage(_profileImage!),
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
                  // Handle navigation or functionality
                },
              ),
              Divider(),
              ListTile(
                minVerticalPadding: 10,
                title: Text('Maps download network'),
                onTap: () {
                  // Handle navigation or functionality
                },
              ),
              Divider(),
              ListTile(
                minVerticalPadding: 10,
                title: Text('Manage membership'),
                onTap: () {
                  // Handle navigation or functionality
                },
              ),
              Divider(),
              ListTile(
                minVerticalPadding: 10,
                title: Text(
                  'Logout',
                ),
                onTap: () {
                  context.read<AuthBloc>().add(LogOutEvent());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
