import 'package:flutter/material.dart';

class ConnectSearchBar extends StatelessWidget{
  const ConnectSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 20.0, bottom: 20.0),
      child: Container(
        color: Color(0xFFFFFFFF),
        width: 430.0,
        child: Row(
          children: [
            SearchBar(
              hintText: "Search for posts",
              leading: Icon(Icons.search),
              constraints: BoxConstraints(minWidth: 250.0, minHeight: 56.0),
            ),
            SizedBox(width: 30.0,),
            IconButton(onPressed: (){}, icon: Image.asset("assets/icons8-bell-96.png"), constraints: BoxConstraints(minHeight: 30.0, maxHeight: 30.0, minWidth: 30.0, maxWidth: 30.0),),
            SizedBox(width: 30.0,),
            IconButton(onPressed: (){}, icon: Image.asset("assets/icons8-add-user-male-96.png"), constraints: BoxConstraints(minHeight: 30.0, maxHeight: 30.0, minWidth: 30.0, maxWidth: 30.0))
          ],
        ),
      ),
    );
  }
}