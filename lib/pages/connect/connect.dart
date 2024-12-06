import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/components/alerts/snack_bar.dart';
import 'package:odyssey/components/searchbars/connect_search_bar.dart';
import 'package:odyssey/model/location.dart';
import 'package:shimmer/shimmer.dart';
import 'connect_local.dart';
import 'connect_friends.dart';
import 'connect_you.dart';
import 'package:odyssey/utils/paths.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odyssey/api/get_locations.dart';
import 'package:odyssey/components/cards/review_card.dart';
import 'package:odyssey/api/review.dart';
import 'package:odyssey/model/review.dart';
import 'package:odyssey/utils/date_time_utils.dart';

//The Connect page of the Odyssey App
class Connect extends StatefulWidget{
  final String? tab;

  Connect({Key? key, this.tab}) : super(key : key);
  @override
  State<Connect> createState() => _ConnectState();
}


class _ConnectState extends State<Connect> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin{
  static const List<Tab> connectTabs = <Tab>[
    Tab(text: 'Local'),
    Tab(text: 'Friends'),
    Tab(text: 'You')
  ];
  int _lastTabIndex = 0;
  late TabController _tabController;
  final List<String> _tabRoutes = ['local', 'friends', 'you'];
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
  List<String>? _previousLabelsToSend;
  List<String>? _previousLocationsToSend;
  List<double>? _previousRatingsToSend;


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
        fetchTabData(_tabController.index);
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
        print("Selected locations: ${this.selectedLocations}");
      });
    }
  }

  void clearFilters() {
  print("clearFilters invoked");
  setState(() {
    // Reset all filters
    selectedLocations = selectedLocations.map((i) {
      return i.map((key, _) => MapEntry(key, false));
    }).toList();
    selectedFilters = selectedFilters.map((i) {
      return i.map((key, _) => MapEntry(key, false));
    }).toList();
    selectedRatings = selectedRatings.map((i) {
      return i.map((key, _) => MapEntry(key, false));
    }).toList();

    // Clear search text and filter lists
    reviewSearchText = "";
    labelsToSend?.clear();
    locationsToSend?.clear();
    ratingsToSend?.clear();
    _previousLabelsToSend = null;
    _previousLocationsToSend = null;
    _previousRatingsToSend = null;

    print("Filters cleared");
    print("Selected filters are: $reviewSearchText $locationsToSend $labelsToSend $ratingsToSend");
  });
}

  Future<List<ReviewCard>> fetchTabData(int idx) async{
    if(idx == 0){
      print("Reload invoked for local");
      return loadLocalUserReviews(this.auth.currentUser?.uid, locations: this.locationsToSend, appliedFilters: this.labelsToSend, numStars: this.ratingsToSend, searchText: this.reviewSearchText);
    } else if(idx == 1){
      print("Reload invoked for friends");
      return loadFriendReviews(this.auth.currentUser?.uid, locations: this.locationsToSend, appliedFilters: this.labelsToSend, numStars: this.ratingsToSend, searchText: this.reviewSearchText);
    } else if(idx == 2){
      return loadYourReviews(this.auth.currentUser?.email, locations: this.locationsToSend, appliedFilters: this.labelsToSend, numStars: this.ratingsToSend, searchText: this.reviewSearchText);
    } else {
      return [];
    }
  }

  Future<List<ReviewCard>> loadLocalUserReviews(String? uid, {List<String>? locations, List<String>? appliedFilters, List<double>? numStars, String? searchText}) async{
    await Future.delayed(const Duration(seconds: 3));
    try {
      if(uid == null){
        print("UID is null!");
        return [];
      }
      final snap = await this.firestore.collection('User').doc(uid).get();
      if(!snap.exists){
        print("Error: document doesn't exist for uid");
        return [];
      }
      final homeloc = snap.data()?['homelocation'];
      if(homeloc == null || homeloc.isEmpty){
        print("Home location is empty");
        return [];
      }
      final localUserQuery = await this.firestore.collection('User').where('homelocation',isEqualTo: homeloc);
      final querySnap = await localUserQuery.get();
      List<String> names = [];
      List<ReviewCard> reviews = [];
      for(var doc in querySnap.docs){
        final data = doc.data();
        final firstname = data['firstname'] ?? "";
        final lastname = data['lastname'] ?? "";
        names.add("$firstname $lastname");
      }
      for(String n in names){
        final localReviewQuerySnap = await this.firestore.collection('Review').where('username',isEqualTo: n.split(" ").first).get();
        var filteredDocs = localReviewQuerySnap.docs;
        if(searchText != null && searchText.isNotEmpty){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return data['reviewText'].contains(searchText);
          }).toList();
        }
        if(locations != null && locations.isNotEmpty){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return locations.contains(data['locationName']);
          }).toList();
        }
        if(appliedFilters != null && appliedFilters.isNotEmpty){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return data['tags'].toSet().intersection(appliedFilters.toSet()).isNotEmpty;
          }).toList();
        }
        if(numStars != null && numStars.isNotEmpty){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return numStars.contains(data['rating'].toDouble());
          }).toList();
        }
        for(var doc in filteredDocs){
          final images = List<String>.from(doc.data()['images']);
          final postedDate = doc.data()['postedOn'] ?? "";
          final dayDifference = postedDate != null ? getDayDifference(postedDate.toDate()) : 0;
          final revText = doc.data()['reviewtext'] ?? "";
          reviews.add(ReviewCard(pageName: "ConnectLocal", imgUrls: images, posterName: n.split(" ").first, locationName: doc.data()['locationname'], dayDiff: dayDifference, reviewText: revText,));
        }
      }
      print('Loaded reviews: ${reviews.length}');
      return reviews;
    } catch (e, stackTrace) {
      print("Error loading local user reviews: $e");
      print(stackTrace);
      return [];
    }
  }

  Future<List<ReviewCard>> loadFriendReviews(String? uid, {List<String>? locations, List<String>? appliedFilters, List<double>? numStars, String? searchText}) async{
    await Future.delayed(const Duration(seconds: 3));
    final snap = await firestore.collection('User').doc(uid).get();
    if (!snap.exists || snap.data()?['friends'] == null) {
      print("No friends found for user: $uid");
      return [];
    }
    List<String> friendlist = List<String>.from((snap.data()?['friends'] ?? []).where((e) => e!=null));
    print('Processed friend list: $friendlist');
    List<ReviewCard> reviews = [];
    for(String f in friendlist){
      print("Friend: ${f.split(" ").first}");
      final fetchQuery = await this.firestore.collection('User').where('firstname', isEqualTo: f.split(" ").first).get();
      final friendId = fetchQuery.docs.first.id;
      print("Friend ID: $friendId");
      final querySnap = await this.firestore.collection('Review').where('userId', isEqualTo: friendId).get();
      var filteredDocs = querySnap.docs;
      print("Filtered docs: $filteredDocs");
      if(searchText != null && searchText.isNotEmpty){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return data['reviewText'].contains(searchText);
          }).toList();
        }
        if(locations != null && locations.isNotEmpty){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return locations.contains(data['locationName']);
          }).toList();
        }
        if(appliedFilters != null && appliedFilters.isNotEmpty){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return data['tags'].toSet().intersection(appliedFilters.toSet()).isNotEmpty;
          }).toList();
        }
        if(numStars != null && numStars.isNotEmpty){
          filteredDocs = filteredDocs.where((doc){
            final data = doc.data();
            return numStars.contains(data['rating'].toDouble());
          }).toList();
        }
      for(var doc in filteredDocs){
        final postedDate = doc.data()['postedOn'] ?? "";
        final dayDifference = getDayDifference(postedDate.toDate());
        final revText = doc.data()['reviewText'] ?? "";
        print("Posted date: $postedDate, day difference: $dayDifference, review text: $revText");
        reviews.add(ReviewCard(pageName: "ConnectFriends",imgUrls: List<String>.from(doc.data()['images']), posterName: f, locationName: doc.data()['locationName'], dayDiff: dayDifference, reviewText: revText,));
      }
    }
    print("Reviews: $reviews");
    return reviews;
  }

  Future<List<ReviewCard>> loadYourReviews(String? email, {List<String>? locations, List<String>? appliedFilters, List<double>? numStars, String? searchText}) async{
    await Future.delayed(const Duration(seconds: 3));
    print("Loading your reviews!");
    print("Applied locations: $locations");
    print("Applied ratings: $numStars");
    print("Search query: $searchText");
    print("Applied filters: ${appliedFilters?.toSet()}");
    List<LocationReview> reviews = await fetchReviews(userEmail: email);
    if(locations != null && locations.isNotEmpty){
      reviews = reviews.where((r){
        return locations.contains(r.locationName);
      }).toList();
    }
    print("Reviews is now: $reviews");
    if(appliedFilters != null && appliedFilters.isNotEmpty){
      reviews = reviews.where((r){
        print("Applied filters: ${appliedFilters.toSet()}");
        print("Tags: ${r.tags!.toSet()}");
        print("Intersection: ${appliedFilters.toSet().intersection(r.tags!.toSet())}");
        return appliedFilters.toSet().intersection(r.tags!.toSet()).isNotEmpty;
      }).toList();
    }
    print("Reviews is now: $reviews");
    if(numStars != null && numStars.isNotEmpty){
      reviews = reviews.where((r){
        return numStars.contains(r.rating);
      }).toList();
    }
    print("Reviews is now: $reviews");
    if(searchText != null && searchText.isNotEmpty){
      reviews = reviews.where((r){
        return r.reviewText!.contains(searchText);
      }).toList();
    }
    print("Reviews is finally: $reviews");
    return reviews
        .map((review) => ReviewCard(pageName: "ConnectYou", imgUrls: review.images ?? [], posterName: "You", locationName: review.locationName ?? "", dayDiff: getDayDifference(review.postedOn!), reviewText: review.reviewText!,))
        .toList();
  }

  void displayBottomSheetFilters() async{
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      enableDrag: true,
      showDragHandle: true,
      builder: (sheetContext){
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: DraggableScrollableSheet(
            expand: true,
            initialChildSize: 1.0,
            snap: true,
            builder: (_, controller){
              return StatefulBuilder(
                builder: (context, setSheetState){
                  return SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Filters: ", style: TextStyle(fontWeight: FontWeight.bold),),
                              IconButton(
                                onPressed: (){
                                  Navigator.of(sheetContext).pop();
                                },
                                icon: Icon(Icons.close_outlined)
                              )
                            ],
                          ),
                        ),
                      ),
                      Divider(),
                      SizedBox(height: 20.0),
                      Text("Search for text in location: ", style: TextStyle(fontWeight: FontWeight.bold),),
                      SizedBox(height: 20.0),
                      Flexible(
                        child: SearchBar(
                          hintText: "Eg: local cuisine",
                          leading: Icon(Icons.search),
                          trailing: [Icon(Icons.filter_list)],
                          constraints: BoxConstraints(minHeight: 56.0, maxHeight: 56.0, maxWidth: 300.0, minWidth: 300.0),
                          onChanged: (value){
                            setSheetState((){
                              setState(() {
                                this.reviewSearchText = value;
                                print("Review search text is now: ${this.reviewSearchText}");
                              });
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 20.0),
                      Text("Filters for review tags: ", style: TextStyle(fontWeight: FontWeight.bold),),
                      SizedBox(height: 20.0),
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
                                            setSheetState((){
                                              final updatedFilter = selectedFilters.firstWhere((filter) => filter.keys.contains(item), orElse: () => {item: false},); 
                                              updatedFilter[item] = selected;
                                              print("Label selected? $selected");
                                              setState(() {
                                                if (selected) {
                                                  labelsToSend?.add(item);
                                                } else {
                                                  labelsToSend?.remove(item);
                                                }
                                                print("Labels are now: ${this.labelsToSend}");
                                              });
                                            });
                                          },
                                        ),
                                      );
                                    }).toList(),
                      ),
                      SizedBox(height: 20.0),
                      Text("Filters for location names: ", style: TextStyle(fontWeight: FontWeight.bold),),
                      SizedBox(height: 20.0),
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
                                      (filter) => filter.keys.contains(item.name),
                                      orElse: () => {item.name: false},
                                    )[item.name] == false ? Icon(Icons.add) : null,
                              selected: this.selectedLocations
                                        .firstWhere(
                                          (filter) => filter.keys.contains(item.name),
                                          orElse: () => {item.name: false},
                                        )[item.name] ?? false,
                              onSelected: (selected) {
                                            setSheetState((){
                                              final updatedFilter = selectedLocations.firstWhere((filter) => filter.keys.contains(item.name), orElse: () => {item.name: false},); 
                                              updatedFilter[item.name] = selected;
                                              print("Location selected? $selected");
                                              setState(() {
                                                if (selected) {
                                                  locationsToSend?.add(item.name);
                                                } else {
                                                  locationsToSend?.remove(item.name);
                                                }
                                                print("Locations are now: ${this.locationsToSend}");
                                              });
                                            });
                                          },
                                        ),
                                      );
                                    }).toList(),
                      ),
                      SizedBox(height: 20.0),
                      Text("Filters for star ratings: ", style: TextStyle(fontWeight: FontWeight.bold),),
                      SizedBox(height: 20.0),
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
                                            setSheetState((){
                                              final updatedFilter = selectedRatings.firstWhere((filter) => filter.keys.contains(item), orElse: () => {item: false},); 
                                              updatedFilter[item] = selected;
                                              print("Rating selected? $selected");
                                              setState(() {
                                                if (selected) {
                                                  ratingsToSend?.add(item);
                                                } else {
                                                  ratingsToSend?.remove(item);
                                                }
                                                print("Ratings are now: ${this.ratingsToSend}");
                                              });
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
                            SizedBox(
                              width: 150.0,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF006A68),
                                  foregroundColor: Colors.white,
                                  textStyle: Theme.of(context).textTheme.labelMedium,
                                  side: BorderSide(
                                    width: 0.3,
                                  ),
                                ),
                                onPressed: (){
                                  if(reviewSearchText!.isEmpty && locationsToSend!.isEmpty && labelsToSend!.isEmpty && ratingsToSend!.isEmpty){
                                    showMessageSnackBar(sheetContext, "Select at least one filter!");
                                  } else if (_previousLabelsToSend == labelsToSend || _previousLocationsToSend == locationsToSend || _previousRatingsToSend == ratingsToSend){
                                    showMessageSnackBar(sheetContext, "Filters haven't changed! Not reloading");
                                  } else{
                                    print("Review filters changed");
                                    setSheetState((){
                                    setState(() {
                                      _previousLabelsToSend = List.from(labelsToSend ?? []);
                                      _previousLocationsToSend = List.from(locationsToSend ?? []);
                                      _previousRatingsToSend = List.from(ratingsToSend ?? []);
                                      fetchTabData(_tabController.index);
                                    });// Force reload
                                  });
                                    Navigator.of(sheetContext).pop();
                                    print("Selected filters are: ${this.reviewSearchText} ${this.locationsToSend} ${this.labelsToSend} ${this.ratingsToSend}");
                                  }
                                },
                                child: Text("Apply filters", style: TextStyle(color: Colors.white))
                              ),
                            ),
                            SizedBox(
                              width: 150.0,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(50.0, 40.0),
                                  backgroundColor: Color(0xFF006A68),
                                  foregroundColor: Colors.white,
                                  textStyle: Theme.of(context).textTheme.labelMedium,
                                  side: BorderSide(
                                    width: 0.3,
                                  ),
                                ),
                                onPressed: (){
                                  clearFilters();
                                  setSheetState((){
                                    setState(() {
                                      fetchTabData(_tabController.index);
                                  });// Force reload
                                  });
                                  fetchTabData(_tabController.index);
                                },
                                child: Text("Clear filters", style: TextStyle(color: Colors.white))
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 20.0),
                    ],
                  ),
                );
            });
            }),
        );
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: ConnectSearchBar(
        onNavigate: (toScreen) async{
          String dest = "";
          if(toScreen == 'Notifications'){
            dest = Paths.notifs;
            GoRouter.of(context).go('/connect/${_tabRoutes[_tabController.index]}'+dest,);
            collectUnreadNotifs(uid);
            fetchTabData(_tabController.index);
          } else if(toScreen == 'Friends'){
            dest = Paths.friendReq;
            GoRouter.of(context).go('/connect/${_tabRoutes[_tabController.index]}'+dest);
            fetchTabData(_tabController.index);
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
      FutureBuilder<List<ReviewCard>>(
        future: fetchTabData(0),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5, // Adjust the count based on your needs
        itemBuilder: (context, index) {
          return ListTile(
            title: Container(
              height: 20,
              width: 200,
              color: Colors.white,
            ),
          );
        },
      ),
    );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return ConnectLocal(cards: snapshot.data ?? []);
          }
        },
      ),
      FutureBuilder<List<ReviewCard>>(
        future: fetchTabData(1),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5, // Adjust the count based on your needs
        itemBuilder: (context, index) {
          return ListTile(
            title: Container(
              height: 20,
              width: 200,
              color: Colors.white,
            ),
          );
        },
      ),
    );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return ConnectFriends(cards: snapshot.data ?? []);
          }
        },
      ),
      FutureBuilder<List<ReviewCard>>(
        future: fetchTabData(2),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5, // Adjust the count based on your needs
        itemBuilder: (context, index) {
          return ListTile(
            title: Container(
              height: 20,
              width: 200,
              color: Colors.white,
            ),
          );
        },
      ),
    );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return ConnectYou(cards: snapshot.data ?? []);
          }
        },
      ),
    ],
            ),
          ),
        ]
      )
    );
  }

  @override 
  bool get wantKeepAlive => true;
}