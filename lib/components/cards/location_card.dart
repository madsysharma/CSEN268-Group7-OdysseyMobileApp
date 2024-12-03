import 'package:flutter/material.dart';

class LocationCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final bool isChecked;
  final ValueChanged<bool?>? onChecked;

  const LocationCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.isChecked = false,
    this.onChecked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              height: 150,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Prevent overflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Checkbox(
                  value: isChecked,
                  onChanged: onChecked,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
