import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/components/connect_search_bar.dart';
import '../pages/connect_local.dart';
import '../pages/connect_friends.dart';
import '../pages/connect_you.dart';

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

  @override
  void initState() {
    super.initState();
    
    int initIndex = _tabRoutes.indexOf(widget.tab ?? 'local');
    if(initIndex == -1){
      initIndex = 0;
    }
    _tabController = TabController(vsync: this, length: _tabRoutes.length, initialIndex: initIndex);

    _tabController.addListener((){
      if(_tabController.indexIsChanging){
        context.go('/connect/${_tabRoutes[_tabController.index]}');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ConnectSearchBar(),
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