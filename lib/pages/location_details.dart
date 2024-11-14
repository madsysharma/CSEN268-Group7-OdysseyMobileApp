import 'package:flutter/material.dart';
import 'package:odyssey/model/location.dart';

class LocationDetailsPage extends StatelessWidget {
  final LocationDetails location;
  const LocationDetailsPage({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Image.network(
            location.img,
            height: 400,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.image, size: 100, color: Colors.grey),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                scrollDirection: Axis.vertical,
                children: [
                  Text(
                    location.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 4),
                  Text(
                    location.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
