import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odyssey/pages/safety/safety_sos.dart';
import 'package:odyssey/utils/paths.dart';

class Safety extends StatefulWidget {
  const Safety({super.key});

  @override
  _SafetyState createState() => _SafetyState();
}

class _SafetyState extends State<Safety> with TickerProviderStateMixin{
  String? currentMemberType;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // Repeats the animation
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(_controller);
    _fetchCurrentMembership();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fetch the user's current membership type from Firestore
  Future<void> _fetchCurrentMembership() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in.");
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          currentMemberType = userDoc.data()?['membertype'] ?? 'BASIC';
        });
      } else {
        throw Exception("User document does not exist.");
      }
    } catch (e) {
      _showErrorDialog("Failed to fetch membership: $e");
    }
  }

  // Show an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

void _showUpgradeOverlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Only Premium users can access this feature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value, 
                  child: const Icon(
                    Icons.add_alert_rounded,
                    color: Colors.yellow,
                    size: 40.0, 
                  ),
                );
              },
            ),
            const SizedBox(height: 16), 
            const Text('Do you want to update your membership?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/manageMembership');
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
        ],
      ),
    );
  }


// double _iconScale = 1.0;


// void _toggleScale() {
//   setState(() {
//     _iconScale = _iconScale == 1.0 ? 1.5 : 1.0;
//   });
// }


  void _navigateToLiveSharing() {
    if (currentMemberType == 'BASIC') {
      // Show the upgrade overlay if the user is BASIC
      _showUpgradeOverlay(); 
    } else {
      context.go(Paths.safeSharing);
    }
  }

  void _navigateToRating() {
    if (currentMemberType == 'BASIC') {
      _showUpgradeOverlay(); 
    } else {
      context.go(Paths.safeRating);
    }
  }

// Make all buttons with the same style
  Widget buildButton(String text, VoidCallback onPressed, double width) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF006A68),
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 3,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // set the fixed width for buttons based on the longest text
    double buttonWidth = 300; 

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 189, 220, 204),
        title: const Text("Travel Safety"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildButton("Location Checkin", () {
              context.go(Paths.locationCheckin);
            }, buttonWidth),
            SizedBox(height: 20),
            buildButton("Emergency Contact", () {
              context.go(Paths.emergencyContact);
            }, buttonWidth),
            SizedBox(height: 20),
            buildButton("Solo Travel Tips", () {
              context.go(Paths.travelTips);
            }, buttonWidth),
            SizedBox(height: 20),
            buildButton("Live Sharing", () {
              _navigateToLiveSharing();
            }, buttonWidth),
            SizedBox(height: 20),
            buildButton("Security Rating", () {
              _navigateToRating();
            }, buttonWidth),
            SizedBox(height: 20),
            buildButton("SOS", () {
              showSosOverlay(context); 
            }, buttonWidth),
          ],
        ),
      ),
    );
  }
}
