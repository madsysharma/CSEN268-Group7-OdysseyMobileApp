import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/subscription_card.dart';
import 'package:odyssey/components/navigation/app_bar.dart';

class ManageMembership extends StatefulWidget {
  const ManageMembership({super.key});

  @override
  State<ManageMembership> createState() => ManageMembershipState();
}

class ManageMembershipState extends State<ManageMembership> {
  String? currentMemberType; // Holds the current membership type of the user

  @override
  void initState() {
    super.initState();
    _fetchCurrentMembership(); // Fetch current membership on page load
  }

  // Fetch the user's current membership type from Firestore
  Future<void> _fetchCurrentMembership() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in.");
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('User') // Firestore collection
          .doc(user.uid) // Document matching the logged-in user's UID
          .get();

      if (userDoc.exists) {
        setState(() {
          currentMemberType = userDoc.data()?['membertype'] ?? 'BASIC'; // Default to BASIC
        });
      } else {
        throw Exception("User document does not exist.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch membership: $e')),
      );
    }
  }

  // Update the user's membership type in Firestore
  Future<void> _updateMembership(String newMemberType) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in.");
      }

      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .update({'membertype': newMemberType});

      setState(() {
        currentMemberType = newMemberType; // Update local state
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Membership updated to $newMemberType!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update membership: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: MyAppBar(title: "Manage Membership"),
      body: currentMemberType == null
          ? const Center(child: CircularProgressIndicator()) // Show loading spinner until membership is fetched
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: PageView(
                controller: PageController(viewportFraction: 0.8), // Slightly narrow cards for better UI
                children: [
                  // BASIC Plan
                  SubscriptionCard(
                    color: colorScheme.primary,
                    subscriptionType: "BASIC",
                    price: "0.00",
                    perks: [
                      "Access to travel content, safety tips, and basic planning tools.",
                      "Limited forums, group chats, and virtual meetups.",
                      "Save favorite locations and create wishlists.",
                      "Access online maps for navigation."
                    ],
                    message: "BASIC PLAN",
                    isSelected: currentMemberType == "BASIC", // Highlight if currently selected
                    onTap: () => _updateMembership("BASIC"),
                  ),
                  // PREMIUM Plan
                  SubscriptionCard(
                    color: colorScheme.secondary,
                    subscriptionType: "PREMIUM",
                    price: "15.99/month",
                    perks: [
                      "All BASIC features.",
                      "SOS alerts and live tracking for safety.",
                      "Budget and expense tracking.",
                      "Download and access offline maps.",
                      "Exclusive deals, discounts, and personalized recommendations."
                    ],
                    message: "PREMIUM PLAN",
                    isSelected: currentMemberType == "PREMIUM",
                    onTap: () => _updateMembership("PREMIUM"),
                  ),
                  // ELITE Plan
                  SubscriptionCard(
                    color: colorScheme.tertiary,
                    subscriptionType: "ELITE",
                    price: "29.99/month",
                    perks: [
                      "All PREMIUM features.",
                      "Concierge service and emergency travel support.",
                      "Travel insurance and access to vetted companions.",
                      "Exclusive high-end events and premium retreats."
                    ],
                    message: "ELITE PLAN",
                    isSelected: currentMemberType == "ELITE",
                    onTap: () => _updateMembership("ELITE"),
                  ),
                ],
              ),
            ),
    );
  }
}
