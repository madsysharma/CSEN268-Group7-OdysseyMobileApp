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

      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
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
              child: Column(
                children: [
                  Text(
                    "Choose Your Plan",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView(
                      controller: PageController(viewportFraction: 0.85),
                      children: [
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
                          isSelected: currentMemberType == "BASIC",
                          onTap: () => _updateMembership("BASIC"),
                        ),
                        SubscriptionCard(
                          color: colorScheme.secondary,
                          subscriptionType: "PREMIUM",
                          price: "15.99",
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
                        SubscriptionCard(
                          color: colorScheme.tertiary,
                          subscriptionType: "ELITE",
                          price: "29.99",
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
                ],
              ),
            ),
    );
  }
}
