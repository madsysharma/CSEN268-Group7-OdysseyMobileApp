import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odyssey/bloc/auth/auth_bloc.dart';
import 'package:odyssey/bloc/locations/locations_bloc.dart';
import 'package:odyssey/components/home_locations_list.dart';
import 'package:odyssey/components/search_places.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName = "";

  @override
  void initState() {
    context.read<LocationsBloc>().add(FetchLocations());
    super.initState();
    getUserName(auth.currentUser?.uid);
  }

  Future<void> getUserName(String? uid) async{
    var ref = await firestore.collection('User').doc(uid).get();
    if(mounted){
      setState(() {
        this.userName = ref.data()?['firstname'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).viewPadding.top;
     //auth.currentUser?.displayName ?? auth.currentUser?.email;
    return Padding(
      padding: EdgeInsets.only(top: topInset + 16.0, left: 16, right:16 , bottom :16),
      child: Column(
        children: [
          Text(
            "Hi, ${this.userName}!",
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 16),
          SearchPlaces(),
          HomeLocationsList()
        ],
      ),
    );
  }
}
