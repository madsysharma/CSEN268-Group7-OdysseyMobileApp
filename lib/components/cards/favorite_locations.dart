import 'package:flutter/material.dart';

class FavoriteLocations extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final Color fallbackBackgroundColor;

  const FavoriteLocations({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.fallbackBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                height: 150,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint("Failed to load image: $imageUrl");
                  return Container(
                    height: 150,
                    width: double.infinity,
                    color: fallbackBackgroundColor,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
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
