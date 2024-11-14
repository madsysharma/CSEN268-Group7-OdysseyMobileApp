import 'package:flutter/material.dart';
import 'package:odyssey/components/connect_search_bar.dart';
import '../pages/connect_local.dart';
import '../pages/connect_friends.dart';
import '../pages/connect_you.dart';

//The Connect page of the Odyssey App
class Connect extends StatefulWidget{
  const Connect({super.key});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: connectTabs.length);
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
              children: connectTabs.map((Tab t){
                  final String label = t.text!;
                  final String className = "Connect$label";
                  switch (className) {
                    case 'ConnectFriends':
                      return ConnectFriends();
                    case 'ConnectYou':
                      return ConnectYou();
                    case 'ConnectLocal':
                      return ConnectLocal();
                    default:
                      return ConnectLocal();
                  }
                }
              ).toList(),
            ),
          )
        ],
      )
    );
  }
}