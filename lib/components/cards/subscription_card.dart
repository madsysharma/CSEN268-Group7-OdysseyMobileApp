import 'package:flutter/material.dart';

class SubscriptionCard extends StatelessWidget {
  final Color color;
  final String subscriptionType;
  final String price;
  final List<String> perks;
  final String message;
  final bool isSelected; // To highlight the selected plan
  final VoidCallback onTap; // Callback for selecting a plan

  const SubscriptionCard({
    super.key,
    required this.color,
    required this.subscriptionType,
    required this.price,
    required this.perks,
    required this.message,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap, // Handle tap to select this plan
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: isSelected ? color.withOpacity(0.7) : color, // Highlight if selected
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Plan Title
              Text(
                subscriptionType,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Divider(color: colorScheme.onPrimary, thickness: 1),
              const SizedBox(height: 8),

              // Price Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("\$",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onPrimary,
                          )),
                  Text(price,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          )),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "per month",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
              ),
              const SizedBox(height: 16),

              // Perks List
              Expanded(
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: perks
                      .map(
                        (perk) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            "• $perk",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Plan Message
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Action Button
              ElevatedButton(
                onPressed: onTap, // Call onTap when button is pressed
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? colorScheme.onPrimary.withOpacity(0.8) // Highlight selected button
                      : colorScheme.onPrimary,
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(isSelected ? "Current Plan" : "Choose This Plan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
