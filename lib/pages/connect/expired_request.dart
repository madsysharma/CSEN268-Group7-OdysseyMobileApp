import 'package:flutter/material.dart';

class ExpiredRequest extends StatelessWidget{
  const ExpiredRequest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Expired Request"),
      ),
      body: Center(
        child: Text("This request is now invalid."),
      )
    );
  }
}