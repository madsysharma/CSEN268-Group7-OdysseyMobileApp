import 'package:odyssey/model/location.dart';

List<LocationDetails> locations = [
  LocationDetails(
    name: "Emerald Bay State Park",
    city: "Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 10, longitude: 10),
    images: [
      "https://encrypted-tbn1.gstatic.com/licensed-image?q=tbn:ANd9GcSCUi1-U09le4cBObofwWbeXBPgx2ux94e9yQVuLPR274-6kxajyVHnfYKGRqZuZDoZxPN7aibzQzUcdnVsstJymlpH0NzXHQiWVUt6YA"
    ],
    description:
        "A beautiful bay with crystal-clear water and breathtaking views. Known for its hiking trails and scenic overlooks.",
    reviews: Reviews(
      overview: RatingsOverview(
          oneStar: 5, twoStar: 10, threeStar: 15, fourStar: 50, fiveStar: 120),
      reviews: [
        Review(
            id: "1",
            userEmail: "user123@gmail.com",
            review: "Amazing views! A must-see if you're in Tahoe.",
            rating: 5),
        Review(
            id: "2",
            userEmail: "user456@gmail.com",
            review: "The hike was a bit tough, but worth it for the view!",
            rating: 4),
        Review(
            id: "3",
            userEmail: "user789@gmail.com",
            review: "Too crowded for my taste, but beautiful nonetheless.",
            rating: 3),
      ],
    ),
  ),
  LocationDetails(
    name: "Sand Harbor",
    city: "Lake Tahoe",
    images: [""],
    coordinates: GeoCoordinates(latitude: 10, longitude: 10),
    description:
        "Popular beach area with sandy shores and rocky landscapes, great for swimming, kayaking, and picnicking.",
    reviews: Reviews(
      overview: RatingsOverview(
          oneStar: 2, twoStar: 8, threeStar: 12, fourStar: 60, fiveStar: 110),
      reviews: [
        Review(
            id: "1",
            userEmail: "user111@gmail.com",
            review: "Loved the clear water and clean beach.",
            rating: 5),
        Review(
            id: "2",
            userEmail: "user222@gmail.com",
            review: "Parking was tough, but the views were worth it.",
            rating: 4),
        Review(
            id: "3",
            userEmail: "user333@gmail.com",
            review: "A little overcrowded, but still beautiful.",
            rating: 3),
      ],
    ),
  ),
  LocationDetails(
    name: "Heavenly Mountain Resort",
    city: "Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 10, longitude: 10),
    images: [
      "https://encrypted-tbn3.gstatic.com/licensed-image?q=tbn:ANd9GcQKC1k_jMLe-cG6jT5Zvb9319I4quk4ZwRmUMobfisXTHfF65RiOwe1Pi0S_Bz5iOyK1T9PG3-7WTG5GnXfPQb_4-9ePvH3YmKDBoON8A"
    ],
    description:
        "A major ski resort offering winter sports, summer hikes, and stunning gondola rides with panoramic views of the lake.",
    reviews: Reviews(
      overview: RatingsOverview(
          oneStar: 3, twoStar: 5, threeStar: 20, fourStar: 80, fiveStar: 200),
      reviews: [
        Review(
            userEmail: "user444@gmail.com",
            review: "Unbeatable views from the gondola. Worth every penny.",
            rating: 5),
        Review(
            userEmail: "user555@gmail.com",
            review:
                "Great skiing, but can get a bit crowded during peak season.",
            rating: 4),
        Review(
            userEmail: "user666@gmail.com",
            review: "Beautiful resort, but quite expensive.",
            rating: 3),
      ],
    ),
  ),
  LocationDetails(
    name: "D.L. Bliss State Park",
    city: "Lake Tahoe",
    images: [""],
    coordinates: GeoCoordinates(latitude: 10, longitude: 10),
    description:
        "Scenic state park with hiking trails, beaches, and breathtaking views of Lake Tahoe.",
    reviews: Reviews(
      overview: RatingsOverview(
          oneStar: 4, twoStar: 6, threeStar: 10, fourStar: 50, fiveStar: 130),
      reviews: [
        Review(
            userEmail: "user777@gmail.com",
            review: "The water was incredibly clear. A hidden gem!",
            rating: 5),
        Review(
            userEmail: "user888@gmail.com",
            review: "Loved the trails, though some parts were steep.",
            rating: 4),
        Review(
            userEmail: "user999@gmail.com",
            review: "Very scenic but not much shade.",
            rating: 3),
      ],
    ),
  ),
  LocationDetails(
    name: "Taylor Creek Visitor Center",
    city: "South Lake Tahoe",
    images: [""],
    coordinates: GeoCoordinates(latitude: 10, longitude: 10),
    description:
        "Educational visitor center with guided tours and a stream profile chamber to observe fish.",
    reviews: Reviews(
      overview: RatingsOverview(
          oneStar: 1, twoStar: 4, threeStar: 20, fourStar: 60, fiveStar: 85),
      reviews: [
        Review(
            userEmail: "user101@gmail.com",
            review: "Fantastic for kids and nature lovers.",
            rating: 5),
        Review(
            userEmail: "user102@gmail.com",
            review: "Learned a lot about local wildlife.",
            rating: 4),
        Review(
            userEmail: "user103@gmail.com",
            review: "It was nice, but expected a bit more.",
            rating: 3),
      ],
    ),
  ),
];
