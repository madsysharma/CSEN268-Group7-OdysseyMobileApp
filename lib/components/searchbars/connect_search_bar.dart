import 'package:flutter/material.dart';

//Search bar for the Connect Page
class ConnectSearchBar extends StatelessWidget implements PreferredSizeWidget{
  const ConnectSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFFFFFFF),
      padding: EdgeInsets.only(left:30.0,right:30.0,top:20.0,bottom:20.0),
      child: Row(
        children: [
          Flexible(
            child: SearchBar(
              hintText: "Search for posts",
              leading: Icon(Icons.search),
              constraints: BoxConstraints(minHeight: 56.0),
            ),
          ),
          SizedBox(width: 10.0,),
          IconButton(
            onPressed: (){},
            icon: Image.asset("assets/icons8-bell-96.png"), constraints: BoxConstraints(minHeight: 50.0, maxHeight: 50.0, minWidth: 50.0, maxWidth: 50.0),
          ),
          SizedBox(width: 10.0,),
          IconButton(
            onPressed: (){},
            icon: Image.asset("assets/icons8-add-user-male-96.png"), constraints: BoxConstraints(minHeight: 50.0, maxHeight: 50.0, minWidth: 50.0, maxWidth: 50.0)
          )
        ],
      )
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(56.0);
}