import 'package:flutter/material.dart';

//Card for user reviews
class ReviewCard extends StatelessWidget{
  final String pageName;
  final List<String> imgUrls;
  final String posterName;
  final String locationName;
  final int dayDiff;
  final String reviewText;
  const ReviewCard({super.key, required this.pageName, required this.imgUrls, required this.posterName, required this.locationName, required this.dayDiff, required this.reviewText});

  @override
  Widget build(BuildContext context) {
    String cardTitle= this.posterName;
    return Container(
      padding: EdgeInsets.only(left:20.0,right:20.0,top:10.0,bottom:10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image(image: AssetImage("assets/circle-profile-pic.jpg"), width: 80.0, height: 80.0),
              SizedBox(width: 27.0,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      "${this.dayDiff} days ago",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0,),
          if(imgUrls.isNotEmpty)
            SizedBox(
              height: 100.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
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
          SizedBox(height: 15.0,),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Location name: ${this.locationName}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              this.reviewText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}