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
  String? currentMemberType;

  @override
  void initState() {
    super.initState();
    _fetchCurrentMembership();
  }

  Future<void> _fetchCurrentMembership() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in.");
      }

      // Fetch the user's document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('User') // Replace with your Firestore collection name
          .doc(user.uid) // Use the current user's UID
          .get();

      if (userDoc.exists) {
        setState(() {
          currentMemberType = userDoc.data()?['membertype'] ?? 'BASIC';
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

  Future<void> _updateMembership(String newMemberType) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in.");
      }

      // Update the user's `membertype` in Firestore
      await FirebaseFirestore.instance
          .collection('User') // Replace with your Firestore collection name
          .doc(user.uid) // Use the current user's UID
          .update({'membertype': newMemberType});

      setState(() {
        currentMemberType = newMemberType;
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
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: PageView(
                controller: PageController(viewportFraction: 0.8),
                children: [
                  SubscriptionCard(
                    color: colorScheme.primary,
                    subscriptionType: "BASIC",
                    price: "0.00",
                    perks: ["Access to travel forums", "Limited travel guides"],
                    message: "BASIC PLAN",
                    isSelected: currentMemberType == "BASIC",
                    onTap: () => _updateMembership("BASIC"),
                  ),
                  SubscriptionCard(
                    color: colorScheme.secondary,
                    subscriptionType: "PREMIUM",
                    price: "15.99",
                    perks: [
                      "Exclusive travel guides",
                      "Discounts on accommodations",
                      "Personalized trip recommendations"
                    ],
                    message: "PREMIUM PLAN",
                    isSelected: currentMemberType == "PREMIUM",
                    onTap: () => _updateMembership("PREMIUM"),
                  ),
                  SubscriptionCard(
                    color: colorScheme.tertiary,
                    subscriptionType: "ELITE",
                    price: "29.99",
                    perks: [
                      "All premium benefits",
                      "Priority support",
                      "Exclusive travel concierge"
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
