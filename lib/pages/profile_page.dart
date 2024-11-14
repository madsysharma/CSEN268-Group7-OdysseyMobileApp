import 'package:flutter/material.dart';
import 'package:odyssey/components/navigation/app_bar.dart';
import 'package:odyssey/components/navigation/bottom_bar.dart';
import 'package:odyssey/utils/spaces.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: MyAppBar(title: "Profile"),
        body: Column(
          children: [
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50.0,
                    backgroundImage: AssetImage('assets/profile.png'),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      extraLargeVertical,
                      Text("Profile Name"),
                      extraSmallVertical,
                      Text("Profile Location")
                    ],
                  )
                ],
              ),
            ),
            ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: Text('Edit profile'),
                  onTap: () {
                    // Handle navigation or functionality
                  },
                ),
                Divider(),
                ListTile(
                  title: Text('Saved locations'),
                  onTap: () {
                    // Handle navigation or functionality
                  },
                ),
                Divider(),
                ListTile(
                  title: Text('Maps download network'),
                  onTap: () {
                    // Handle navigation or functionality
                  },
                ),
                Divider(),
                ListTile(
                  title: Text('Manage membership'),
                  onTap: () {
                    // Handle navigation or functionality
                  },
                ),
                Divider(),
                ListTile(
                  title: Text('Logout'),
                  onTap: () {
                    // Handle logout functionality
                  },
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: MyBottomAppBar());
  }
}
