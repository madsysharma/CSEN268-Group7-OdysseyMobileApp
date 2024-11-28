import 'package:flutter/material.dart';

void showOverlay(BuildContext context) {
    late OverlayEntry overlayEntry;

    // Define the overlay entry and close button action
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.3, 
        left: MediaQuery.of(context).size.width * 0.1,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Do you want to call SOS",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        overlayEntry.remove();
                      },
                      child: Text("Yes"),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        overlayEntry.remove();
                      },
                      child: Text("No"),
                    ),
                  ],
                ),
                
              ],
            ),
          ),
        ),
      ),
    );


    // Insert the overlay into the Overlay widget
    Overlay.of(context).insert(overlayEntry);
  }