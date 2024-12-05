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
import 'package:odyssey/components/shimmer_list.dart';

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
  int _lastTabIndex = 0;
  late TabController _tabController;
  final List<String> _tabRoutes = ['local', 'friends', 'you'];
  List<bool> _isLoading = [true, true, true];
  List<Future<void>> _tabFutures = [Future.value(), Future.value(), Future.value()];
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? uid = "";
  int unreadNotifsNum = 0;
  String? reviewSearchText = "";
  static List<String> filterNames = ["Arts", "Culture", "Food", "History", "Nature", "Safe Spot", "Hidden Gem", "Pet-Friendly", "Avoid"];
  static List<double> starRatings = [1.0, 2.0, 3.0, 4.0, 5.0];
  List<Map<String, bool>> selectedLocations = [];
  List<Map<double, bool>> selectedRatings = [{1.0: false}, {2.0: false}, {3.0:false}, {4.0:false}, {5.0:false}];
  List<Map<String, bool>> selectedFilters = [
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
      if(!_tabController.indexIsChanging && _tabController.index != _lastTabIndex){
        _lastTabIndex = _tabController.index;
        refreshTab(_tabController.index);
      }
    });
    refreshTab(0);
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
        print("Selected locations: ${this.selectedLocations}");
      });
    }
  }

  Future<void> refreshTab(int idx) async{
    setState(() {
      _isLoading[idx] = true; // Set loading state before refresh
      _tabFutures[idx] = Future(() {
      // Clear the state of the current tab before reloading
        if (idx == 0) {
          _localTabKey.currentState?.clearState();
        } else if (idx == 1) {
          _friendsTabKey.currentState?.clearState();
        } else if (idx == 2) {
          _youTabKey.currentState?.clearState();
        }
      }).then((_) => loadTabData(idx)); // Reload data after clearing
    });

    await _tabFutures[idx]; // Wait for data to load

    setState(() {
      _isLoading[idx] = false; // Clear loading state after refresh
    });
  }

  //refreshTab called only when setting filters and search criteria from the AppBar
  Future<void> loadTabData(int idx) async{
    await Future.delayed(Duration(seconds: 2));
    if(idx == 0){
      print("Reload invoked for local");
      _localTabKey.currentState?.reloadLocalReviews(locNames: this.locationsToSend, filters: this.labelsToSend, stars: this.ratingsToSend, search: this.reviewSearchText);
    } else if(idx == 1){
      print("Reload invoked for friends");
      _friendsTabKey.currentState?.reloadFriendReviews(locNames: this.locationsToSend, filters: this.labelsToSend, stars: this.ratingsToSend, search: this.reviewSearchText);
    } else if(idx == 2){
      print("Reload invoked for you");
      _youTabKey.currentState?.reloadYourReviews(locNames: this.locationsToSend, filters: this.labelsToSend, stars: this.ratingsToSend, search: this.reviewSearchText);
    }
  }

  void displayBottomSheetFilters(){
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      builder: (sheetContext){
        return Padding(
          padding: EdgeInsets.only(
            left: 15.0,
            right: 15.0,
            top: 15.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 15.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Row(
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
                        print("Review search text is now: ${this.reviewSearchText}");
                      });
                    },
                  ),
                ),
                SizedBox(height: 20.0),
                Text("Filters for review tags: ", style: Theme.of(context).textTheme.bodyMedium),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.center,
                  children: filterNames.map((item) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilterChip(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                        label: Text(
                          item,
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                        avatar: this.selectedFilters
                              .firstWhere(
                                (filter) => filter.keys.contains(item),
                                orElse: () => {item: false},
                              )[item] == false ? Icon(Icons.add) : null,
                        selected: this.selectedFilters
                                  .firstWhere(
                                    (filter) => filter.keys.contains(item),
                                    orElse: () => {item: false},
                                  )[item] ?? false,
                        onSelected: (selected) {
                                      setState(() {
                                        var updatedResults = this.selectedFilters.firstWhere(
                                          (filter) => filter.keys.contains(item),
                                          orElse: () => {item: false},
                                        );
                                        if (!updatedResults.containsKey(item)) {
                                          selectedFilters.add({item: selected}); // Add a new map if not found
                                        } else {
                                          updatedResults[item] = selected; // Update the existing entry
                                        }
                                        selected == true ? this.labelsToSend?.add(item) : this.labelsToSend?.removeWhere((name) => name == item);
                                        print("Labels are now: ${this.labelsToSend}");
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                ),
                SizedBox(height: 20.0),
                Text("Filters for location names: ", style: Theme.of(context).textTheme.bodyMedium),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.center,
                  children: locationsCollected.map((item) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilterChip(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      label: Text(
                        item.name,
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                      avatar: this.selectedLocations
                              .firstWhere(
                                (filter) => filter.keys.contains(item),
                                orElse: () => {item.name: false},
                              )[item] == false ? Icon(Icons.add) : null,
                        selected: this.selectedLocations
                                  .firstWhere(
                                    (filter) => filter.keys.contains(item),
                                    orElse: () => {item.name: false},
                                  )[item] ?? false,
                        onSelected: (selected) {
                                      setState(() {
                                        var updatedResults = this.selectedLocations.firstWhere(
                                          (filter) => filter.keys.contains(item),
                                          orElse: () => {item.name: false},
                                        );
                                        if (!updatedResults.containsKey(item)) {
                                          selectedLocations.add({item.name: selected}); // Add a new map if not found
                                        } else {
                                          updatedResults[item.name] = selected; // Update the existing entry
                                        }
                                        selected == true ? this.locationsToSend?.add(item.name) : this.locationsToSend?.removeWhere((name) => name == item.name);
                                        print("Locations are now: ${this.locationsToSend}");
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                ),
                SizedBox(height: 20.0),
                Text("Filters for star ratings: ", style: Theme.of(context).textTheme.bodyMedium),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.center,
                  children: starRatings.map((item) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilterChip(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      label: Text(
                        item.toString(),
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                      avatar: this.selectedRatings
                              .firstWhere(
                                (filter) => filter.keys.contains(item),
                                orElse: () => {item: false},
                              )[item] == false ? Icon(Icons.add) : null,
                        selected: this.selectedRatings
                                  .firstWhere(
                                    (filter) => filter.keys.contains(item),
                                    orElse: () => {item: false},
                                  )[item] ?? false,
                        onSelected: (selected) {
                                      setState(() {
                                        var updatedResults = this.selectedRatings.firstWhere(
                                          (filter) => filter.keys.contains(item),
                                          orElse: () => {item: false},
                                        );
                                        if (!updatedResults.containsKey(item)) {
                                          selectedRatings.add({item: selected}); // Add a new map if not found
                                        } else {
                                          updatedResults[item] = selected; // Update the existing entry
                                        }
                                        selected == true ? this.ratingsToSend?.add(item) : this.ratingsToSend?.removeWhere((name) => name == item);
                                        print("Ratings are now: ${this.ratingsToSend}");
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                ),
                SizedBox(height: 20.0),
                Flexible(
                  child: Wrap(
                    spacing: 8.0, // Add spacing between buttons
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center, // Align buttons to the center
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size.fromWidth(50.0),
                          backgroundColor: Color(0xFF006A68),
                          foregroundColor: Colors.white,
                          textStyle: Theme.of(context).textTheme.labelMedium,
                          side: BorderSide(
                            width: 0.3,
                          ),
                        ),
                        onPressed: (){
                          Navigator.of(sheetContext).pop();
                          print("Selected filters are: ${this.reviewSearchText} ${this.locationsToSend} ${this.labelsToSend} ${this.ratingsToSend}");
                          refreshTab(_tabController.index);
                        },
                        child: Text("Apply filters", style: TextStyle(color: Colors.white))
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size.fromWidth(50.0),
                          backgroundColor: Color(0xFF006A68),
                          foregroundColor: Colors.white,
                          textStyle: Theme.of(context).textTheme.labelMedium,
                          side: BorderSide(
                            width: 0.3,
                          ),
                        ),
                        onPressed: (){
                          this.selectedLocations = this.selectedLocations.map((i) {
                            i.updateAll((key, value) => false);
                            return i;
                          }).toList();
                          this.selectedFilters = this.selectedLocations.map((i) {
                            i.updateAll((key, value) => false);
                            return i;
                          }).toList();
                          this.selectedRatings = this.selectedRatings.map((i) {
                            i.updateAll((key, value) => false);
                            return i;
                          }).toList();
                          this.reviewSearchText = "";
                          print("Filters cleared");
                          print("Selected filters are: ${this.reviewSearchText} ${this.locationsToSend} ${this.labelsToSend} ${this.ratingsToSend}");
                          /*Navigator.of(sheetContext).pop();
                          print("Selected filters are: ${this.reviewSearchText} ${this.locationsToSend} ${this.labelsToSend} ${this.ratingsToSend}");
                          refreshTab(_tabController.index);*/
                        },
                        child: Text("Clear filters", style: TextStyle(color: Colors.white))
                      )
                    ],
                  ),
                ),
                SizedBox(height: 20.0),
              ],
            ),
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
                FutureBuilder<void>(
                  future: _tabFutures[0],
                  builder: (context, snapshot){
                    if(_isLoading[0] == true){
                      return ShimmerList();
                    }
                    if(snapshot.connectionState == ConnectionState.waiting){
                      return ShimmerList();
                    }
                    else if(snapshot.hasError){
                      return Center(child: Text("Error encountered in loading data: ${snapshot.error}"));
                    }
                    else{
                      return ConnectLocal(key: _localTabKey);
                    }
                  }
                ),
                FutureBuilder<void>(
                  future: _tabFutures[1],
                  builder: (context, snapshot){
                    if(_isLoading[1] == true){
                      return ShimmerList();
                    }
                    if(snapshot.connectionState == ConnectionState.waiting){
                      return ShimmerList();
                    }
                    else if(snapshot.hasError){
                      return Center(child: Text("Error encountered in loading data: ${snapshot.error}"));
                    }
                    else{
                      return ConnectFriends(key: _friendsTabKey);
                    }
                  }
                ),
                FutureBuilder<void>(
                  future: _tabFutures[2],
                  builder: (context, snapshot){
                    if(_isLoading[2] == true){
                      return ShimmerList();
                    }
                    if(snapshot.connectionState == ConnectionState.waiting){
                      return ShimmerList();
                    }
                    else if(snapshot.hasError){
                      return Center(child: Text("Error encountered in loading data: ${snapshot.error}"));
                    }
                    else{
                      return ConnectYou(key: _youTabKey);
                    }
                  }
                ),
              ],
            ),
          )
        ],
      )
    );
  }
}