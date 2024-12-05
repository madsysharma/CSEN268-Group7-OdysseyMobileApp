import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/components/searchbars/connect_search_bar.dart';
import 'package:odyssey/model/location.dart';
import 'connect_local.dart';
import 'connect_friends.dart';
import 'connect_you.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odyssey/api/get_locations.dart';

//The Connect page of the Odyssey App
class Connect extends StatefulWidget{
  final String? tab;

  const Connect({Key? key, this.tab}) : super(key : key);

  @override
  State<Connect> createState() => _ConnectState();
}


class _ConnectState extends State<Connect> with SingleTickerProviderStateMixin{
  final GlobalKey<ConnectLocalState> _localTabKey = GlobalKey();
  final GlobalKey<ConnectFriendsState> _friendsTabKey = GlobalKey();
  final GlobalKey<ConnectYouState> _youTabKey = GlobalKey();
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
  String? reviewSearchText = "";
  static List<String> filterNames = ["Arts", "Culture", "Food", "History", "Nature", "Safe Spot", "Hidden Gem", "Pet-Friendly", "Avoid"];
  static List<double> starRatings = [1.0, 2.0, 3.0, 4.0, 5.0];
  List<Map<String, dynamic>> selectedLocations = [];
  final List<Map<double,dynamic>> selectedRatings = [{1.0: false}, {2.0: false}, {3.0:false}, {4.0:false}, {5.0:false}];
  final List<Map<String, dynamic>> selectedFilters = [
    {"Arts": false},
    {"Culture": false},
    {"Food": false},
    {"History": false},
    {"Nature": false},
    {"Safe Spot": false},
    {"Hidden Gem": false},
    {"Pet-Friendly": false},
    {"Avoid": false},
  ];
  List<LocationDetails> locationsCollected = [];
  List<String>? labelsToSend = [];
  List<String>? locationsToSend = [];
  List<double>? ratingsToSend = [];

  @override
  void initState(){
    super.initState();
    this.uid = this.auth.currentUser?.uid;
    collectUnreadNotifs(uid);
    setLocations();
    final int initIndex = _tabRoutes.indexOf(widget.tab ?? 'local').clamp(0, _tabRoutes.length - 1);
    _tabController = TabController(vsync: this, length: _tabRoutes.length, initialIndex: initIndex);
    _tabController.addListener((){
      if(_tabController.indexIsChanging){
        return;
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

  Future<void> setLocations() async{
    var locs = await fetchLocationsFromFirestore();
    if(mounted){
      setState(() {
        this.locationsCollected = locs;
        this.selectedLocations = this.locationsCollected.map((i) => {i.name:false}).toList();
      });
    }
  }

  //refreshTab called only when setting filters and search criteria from the AppBar
  void refreshTab(int idx){
    if(idx == 0){
      _localTabKey.currentState?.reloadLocalReviews();
    } else if(idx == 1){
      _friendsTabKey.currentState?.reloadFriendReviews();
    } else if(idx == 2){
      _youTabKey.currentState?.reloadYourReviews();
    }
  }

  void displayBottomSheetFilters(){
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      isScrollControlled: true,
      builder: (sheetContext){
        return Padding(
          padding: EdgeInsets.only(
            left: 15.0,
            right: 15.0,
            top: 15.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 15.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Filters: ", style: Theme.of(context).textTheme.bodyLarge,),
                  IconButton(
                    onPressed: (){
                      Navigator.of(sheetContext).pop();
                    },
                    icon: Icon(Icons.close_outlined)
                  )
                ],
              ),
              Divider(),
              Text("Search for text in location: ", style: Theme.of(context).textTheme.bodyMedium),
              Flexible(
                child: SearchBar(
                  hintText: "Search within the review. Eg: local cuisine",
                  leading: Icon(Icons.search),
                  trailing: [Icon(Icons.filter)],
                  constraints: BoxConstraints(minHeight: 56.0),
                  onChanged: (value){
                    setState(() {
                      this.reviewSearchText = value;
                    });
                  },
                ),
              ),
              Text("Filters for review tags: ", style: Theme.of(context).textTheme.bodyMedium),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: filterNames.map((item){
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FilterChip(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      label: Container(width: 300.0, child: Text(item, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center,)),
                      avatar: this.selectedFilters.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] == false ? Icon(Icons.add) : null,
                      selected: this.selectedFilters.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item],
                      onSelected: (selected) {
                        setState(() {
                          var updatedResults = this.selectedFilters.firstWhere((filter) => filter.keys.contains(item), orElse: () => {item:false});
                          if (!updatedResults.containsKey(item)) {
                            selectedFilters.add({item: selected}); // Add a new map if not found
                          } else {
                            updatedResults[item] = selected; // Update the existing entry
                          }
                            selected == true ? this.labelsToSend?.add(item) : this.labelsToSend?.removeWhere((name) => name==item);
                        });
                      },
                    ),
                  );
                }
                ).toList(),
              ),
              Text("Filters for location names: ", style: Theme.of(context).textTheme.bodyMedium),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: locationsCollected.map((i) => i.name).toList().map((item){
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FilterChip(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      label: Container(width: 300.0, child: Text(item, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center,)),
                      avatar: this.selectedLocations.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] == false ? Icon(Icons.add) : null,
                      selected: this.selectedLocations.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item],
                      onSelected: (selected) {
                        setState(() {
                          var updatedResults = this.selectedLocations.firstWhere((filter) => filter.keys.contains(item), orElse: () => {item:false});
                          if (!updatedResults.containsKey(item)) {
                            selectedLocations.add({item: selected}); // Add a new map if not found
                          } else {
                            updatedResults[item] = selected; // Update the existing entry
                          }
                            selected == true ? this.locationsToSend?.add(item) : this.locationsToSend?.removeWhere((name) => name==item);
                        });
                      },
                    ),
                  );
                }
                ).toList(),
              ),
              Text("Filters for star ratings: ", style: Theme.of(context).textTheme.bodyMedium),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: starRatings.map((item){
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FilterChip(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      label: Container(width: 300.0, child: Text(item.toString(), style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center,)),
                      avatar: this.selectedRatings.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item] == false ? Icon(Icons.add) : null,
                      selected: this.selectedRatings.firstWhere((filter) => filter.keys.contains(item), orElse: ()=>{item: false})[item],
                      onSelected: (selected) {
                        setState(() {
                          var updatedResults = this.selectedRatings.firstWhere((filter) => filter.keys.contains(item), orElse: () => {item:false});
                          if (!updatedResults.containsKey(item)) {
                            selectedRatings.add({item: selected}); // Add a new map if not found
                          } else {
                            updatedResults[item] = selected; // Update the existing entry
                          }
                            selected == true ? this.ratingsToSend?.add(item) : this.ratingsToSend?.removeWhere((name) => name==item);
                        });
                      },
                    ),
                  );
                }
                ).toList(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF006A68),
                  foregroundColor: Colors.white,
                  textStyle: Theme.of(context).textTheme.labelMedium,
                  side: BorderSide(
                    width: 0.3,
                  ),
                ),
                onPressed: (){
                  Navigator.of(sheetContext).pop();
                  refreshTab(_tabController.index);
                },
                child: Text("Apply filters", style: TextStyle(color: Colors.white))
              )
            ],
          )
        );
      }
    );
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
            refreshTab(_tabController.index);
          }
        },
        setFilters: (){
          displayBottomSheetFilters();
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
                ConnectLocal(key: _localTabKey),
                ConnectFriends(key: _friendsTabKey),
                ConnectYou(key: _youTabKey)
              ],
            ),
          )
        ],
      )
    );
  }
}