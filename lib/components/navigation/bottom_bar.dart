import 'package:flutter/material.dart';
import 'package:odyssey/components/buttons/bar_button.dart';
class MyBottomAppBar extends StatelessWidget {
  const MyBottomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;

    return BottomAppBar(
      color: colorScheme.secondaryContainer,
      padding: EdgeInsets.all(0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BarButton(icon: Icon(Icons.home), text: 'Home', onPressed: () {  },),
          BarButton(icon: Icon(Icons.people), text: 'Connect', onPressed: () {  },),
          BarButton(icon: Icon(Icons.maps_ugc), text: 'Maps', onPressed: () {  },),
          BarButton(icon: Icon(Icons.safety_check), text: 'Safety', onPressed: () {  },),
          BarButton(icon: Icon(Icons.person), text: 'Profile', onPressed: () {  },)
        ],
      )
    );
  }
}