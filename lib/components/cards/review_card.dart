import 'package:flutter/material.dart';

//Card for user reviews
class ReviewCard extends StatelessWidget{
  final String pageName;
  final List<String> imgUrls;
  const ReviewCard({super.key, required this.pageName, required this.imgUrls});

  @override
  Widget build(BuildContext context) {
    String cardTitle="";
    switch(this.pageName){
      case "ConnectLocal":
        cardTitle = "Name";
      case "ConnectFriends":
        cardTitle = "Friend Name";
      case "ConnectYou":
        cardTitle = "You";
    }
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
                            cardTitle,
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Expanded(
                    child: ListView.builder(
                      itemBuilder: (context, index){
                        var newImage = Image.network(
                        this.imgUrls[index],
                        loadingBuilder: (context, child, loadingProgress){
                          if(loadingProgress==null){
                            return child;
                          } else {
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded/loadingProgress.expectedTotalBytes! : null,
                              ),
                            );
                          }
                        },
                        errorBuilder: (context, error, stackTrace){
                          return Text("Failed to load image");
                        },);
                        return newImage;
                      },
                      itemCount: this.imgUrls.length,
                    ),
                  ),
                )
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