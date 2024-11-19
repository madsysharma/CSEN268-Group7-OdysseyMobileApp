class Location {
  String name;
  String city;
  String img;

  Location({required this.name, required this.city, required this.img});

  getLocation() {}
}

class LocationDetails {
  String name;
  String city;
  String img;
  String description;
  Reviews reviews;

  LocationDetails(
      {required this.name,
      required this.city,
      required this.img,
      required this.description,
      required this.reviews});
}

class RatingsOverview {
  int oneStar;
  int twoStar;
  int threeStar;
  int fourStar;
  int fiveStar;

  RatingsOverview({
    required this.oneStar,
    required this.twoStar,
    required this.threeStar,
    required this.fourStar,
    required this.fiveStar,
  });
}

class Reviews {
  RatingsOverview overview;
  List<Review> reviews;

  Reviews({required this.overview, required this.reviews});
}

class Review {
  String userId;
  String review;
  int rating;

  Review({
    required this.userId,
    required this.review,
    required this.rating,
  });
}
