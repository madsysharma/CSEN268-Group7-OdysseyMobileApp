import 'package:flutter/material.dart';
//Search bar for the Connect Page
class ConnectSearchBar extends StatefulWidget implements PreferredSizeWidget{
  final Function(String) onNavigate;
  final int numUnread;

  const ConnectSearchBar({super.key, required this.onNavigate, required this.numUnread});

  @override
  State<ConnectSearchBar> createState() => ConnectSearchBarState();

  @override
  Size get preferredSize => Size.fromHeight(56.0);
}


class ConnectSearchBarState extends State<ConnectSearchBar> with AutomaticKeepAliveClientMixin{
  int unreadChanging = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      this.unreadChanging = widget.numUnread;
    });
  }

  @override
  void didUpdateWidget(covariant ConnectSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.numUnread != oldWidget.numUnread) {
      setState(() {
        unreadChanging = widget.numUnread;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: Color(0xFFFFFFFF),
      padding: EdgeInsets.only(left:30.0,right:30.0,top:20.0,bottom:20.0),
      child: Row(
        children: [
          Flexible(
            child: SearchBar(
              hintText: "Filter posts",
              leading: Icon(Icons.search),
              trailing: [Icon(Icons.filter)],
              constraints: BoxConstraints(minHeight: 56.0),
              onTap: (){},
            ),
          ),
          SizedBox(width: 10.0,),
          IconButton(
            onPressed: (){
              widget.onNavigate('Friends');
            },
            icon: Icon(Icons.person_add),
          ),
          SizedBox(width: 10.0,),
          IconButton(
            onPressed: (){
              print("Number of unread notifs: ${this.unreadChanging}");
              widget.onNavigate('Notifications');
            },
            icon: Badge(label: Text(this.unreadChanging!=0 ? this.unreadChanging.toString() : ""), backgroundColor: this.unreadChanging!=0 ? Color(0xFFF71C0C) : Colors.white.withOpacity(0.0), child: Icon(Icons.notifications),)
          )
        ],
      )
    );
  }

  @override
  bool get wantKeepAlive => true;
}