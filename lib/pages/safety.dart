import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/pages/safety_checkin.dart';
import 'package:odyssey/pages/safety_sos.dart';
import 'package:odyssey/paths.dart';

class Safety extends StatelessWidget{
  const Safety({super.key});

  // make all buttons with same style
  Widget buildButton(String text, VoidCallback onPressed, double width) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF006A68),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // set the fixed width for buttons based on the longest text
    double buttonWidth = 200; 
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 189, 220, 204),
        title: Text("Travel Safety"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildButton("Location Checkin", () {
              context.go(Paths.locationCheckin); // Navigates to safety/location-checkin
            }, buttonWidth),
            SizedBox(height: 20),
            buildButton("Emergency Contact", () {
              
            }, buttonWidth),
            SizedBox(height: 20),
            buildButton("Solo Safety Tips", () {
              
            }, buttonWidth),
            SizedBox(height: 20),
            buildButton("Live Sharing", () {
              
            }, buttonWidth),
            SizedBox(height: 20),
            buildButton("SOS", () {
              showOverlay(context); 
            }, buttonWidth),
          ],
        ),
      ),
    );
  }
}
