import 'package:flutter/material.dart';
import 'package:odyssey/components/home_locations_list.dart';
import 'package:odyssey/components/search_places.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Hi User!",
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 16),
          SearchPlaces(),
          HomeLocationsList()
        ],
      ),
    );
  }
}
