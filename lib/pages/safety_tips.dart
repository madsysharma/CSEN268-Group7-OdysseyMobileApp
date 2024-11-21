// SafetyTipsList Page
import 'package:flutter/material.dart';
import 'package:odyssey/components/cards/safety_tip_card.dart';

class SafetyTips extends StatelessWidget {
  const SafetyTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solo Travel Tips'),
        backgroundColor: Color.fromARGB(255, 189, 220, 204),  // AppBar color
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          SafetyTipCard(
            title: 'Plan Ahead, but Stay Flexible',
            content: 'Research your destination before you go, but be open to spontaneous adventures. Have a rough itinerary, but allow room for changes and discoveries.',
          ),
          SizedBox(height: 16),
          SafetyTipCard(
            title: 'Accommodation Choices',
            content: 'Consider staying in hostels or guesthouses to meet other travelers, but choose places with good reviews and safety ratings.',
          ),
          SizedBox(height: 16),
          SafetyTipCard(
            title: 'Avoid Using Your Phone While Driving',
            content: 'Distracted driving is dangerous. Keep your focus on the road and avoid using your phone.',
          ),
          SizedBox(height: 16),
          SafetyTipCard(
            title: 'Stay Connected',
            content: 'Ensure you have access to maps, a translation app, and your accommodations\'s contact details.',
          ),
        ],
      ),
    );
  }
}