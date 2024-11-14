import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget{
  final String pageName;
  const ReviewCard({super.key, required this.pageName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left:20.0,right:20.0,top:10.0,bottom:10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image(image: AssetImage("assets/circle-profile-pic.jpg"), width: 101.71, height: 90.0),
              SizedBox(width: 27.0,),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 54.0,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            this.pageName=="ConnectLocal"?"Name":"Friend Name",
                            style: Theme.of(context).textTheme.titleLarge,
                          )
                        ),
                      ),
                      SizedBox(
                        height: 32.0,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "x days ago",
                            style: Theme.of(context).textTheme.titleLarge,
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.0,),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Image(image: AssetImage("assets/photo-1528543606781-2f6e6857f318.jpeg")),
              ),
              SizedBox(height: 15.0,),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Generic review text",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}