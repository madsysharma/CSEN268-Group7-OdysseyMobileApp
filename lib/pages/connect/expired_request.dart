import 'package:flutter/material.dart';

class ExpiredRequest extends StatelessWidget{
  const ExpiredRequest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Expired Request"),
        backgroundColor: const Color.fromARGB(255, 189, 220, 204)
      ),
      body: Center(
        child: Text("This request is now invalid."),
      )
    );
  }
}