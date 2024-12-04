import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/components/searchbars/connect_search_bar.dart';
import 'connect_local.dart';
import 'connect_friends.dart';
import 'connect_you.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//The Connect page of the Odyssey App
class Connect extends StatefulWidget{
  final String? tab;

  const Connect({super.key, this.tab});

  @override
  State<Connect> createState() => _ConnectState();
}


class _ConnectState extends State<Connect> with SingleTickerProviderStateMixin{
  static const List<Tab> connectTabs = <Tab>[
    Tab(text: 'Local'),
    Tab(text: 'Friends'),
    Tab(text: 'You')
  ];

  late TabController _tabController;
  final List<String> _tabRoutes = ['local', 'friends', 'you'];
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? uid = "";
  int unreadNotifsNum = 0;

  @override
  void initState(){
    super.initState();
    this.uid = this.auth.currentUser?.uid;
    collectUnreadNotifs(uid);
    final int initIndex = _tabRoutes.indexOf(widget.tab ?? 'local').clamp(0, _tabRoutes.length - 1);
    _tabController = TabController(vsync: this, length: _tabRoutes.length, initialIndex: initIndex);
    _tabController.addListener((){
      if(_tabController.indexIsChanging){
        GoRouter.of(context).go('/connect/${_tabRoutes[_tabController.index]}');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> collectUnreadNotifs(String? uid) async{
    final CollectionReference<Map<String, dynamic>> ref = await this.firestore.collection('User').doc(uid).collection('Notifications');
    final QuerySnapshot<Map<String, dynamic>> snap = await ref.get();
    int notifCount = 0;
    for(var doc in snap.docs){
      print(doc.data());
      if(doc.data()['unread']==true){
        notifCount = notifCount + 1;
      }
    }
    print("Notification count: $notifCount");
    if(mounted){
      setState(() {
        print("Notification count set!");
        this.unreadNotifsNum = notifCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ConnectSearchBar(
        onNavigate: (toScreen) async{
          String dest = "";
          if(toScreen == 'Notifications'){
            dest = Paths.notifs;
            await GoRouter.of(context).push('/connect/${_tabRoutes[_tabController.index]}'+dest,);
            collectUnreadNotifs(uid);
          } else if(toScreen == 'Friends'){
            dest = Paths.friendReq;
            await GoRouter.of(context).push('/connect/${_tabRoutes[_tabController.index]}'+dest);
          }
        },
        numUnread: this.unreadNotifsNum,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            tabs: connectTabs,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ConnectLocal(),
                ConnectFriends(),
                ConnectYou()
              ],
            ),
          )
        ],
      )
    );
  }
}