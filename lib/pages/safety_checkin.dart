import 'package:flutter/material.dart';
import 'package:odyssey/components/location_card.dart';


class SafetyCheckin extends StatefulWidget {
  @override
  _SafetyCheckinState createState() => _SafetyCheckinState();
}

class _SafetyCheckinState extends State<SafetyCheckin> {
  // Sample data
  final List<Map<String, dynamic>> locations = [
    {
      'imageUrl': 'https://luxevaca.com/wp-content/uploads/2021/11/luxe-vaca-lake-tahoe-scaled.jpg', // Replace with actual image URLs
      'title': 'Lake Tahoe',
      'subtitle': 'Tahoe, California',
      'isChecked': false,
    },
    {
      'imageUrl': 'https://www.thelandingtahoe.com/content/uploads/2021/05/blue-lake-1090x700.jpeg',
      'title': 'Yosemite National Park',
      'subtitle': 'California',
      'isChecked': false,
    },
    // Add more locations as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location Check-in')),
      body: ListView.builder(
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          return LocationCard(
            imageUrl: location['imageUrl'],
            title: location['title'],
            subtitle: location['subtitle'],
            isChecked: location['isChecked'],
            onChecked: (checked) {
              setState(() {
                locations[index]['isChecked'] = checked;
              });
            },
          );
        },
      ),
    );
  }
}
