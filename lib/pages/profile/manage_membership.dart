import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/subscription_card.dart';
import 'package:odyssey/components/navigation/app_bar.dart';

class ManageMembership extends StatefulWidget {
  const ManageMembership({super.key});

  @override
  State<ManageMembership> createState() => ManageMembershipState();
}

class ManageMembershipState extends State<ManageMembership> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: MyAppBar(title: "Manage Membership"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PageView(
          controller: PageController(viewportFraction: 0.8), // Set viewport for sliding effect
          children: [
            SubscriptionCard(
              color: colorScheme.primary,
              subscriptionType: "BASIC",
              price: "0.00",
              perks: ["Access to travel forums", "Limited travel guides"],
              message: "BASIC PLAN",
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
            ),
          ],
        ),
      ),
    );
  }
}
