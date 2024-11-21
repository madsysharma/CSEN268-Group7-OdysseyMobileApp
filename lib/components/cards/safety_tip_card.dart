import 'package:flutter/material.dart';

class SafetyTipCard extends StatelessWidget {
  final String title;
  final String content;

  const SafetyTipCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color.fromARGB(255, 189, 220, 204),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10), 
            Text(
              content, 
              style: TextStyle(
                fontSize: 16,  
                color: Colors.black, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}