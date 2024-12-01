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
  ),
  LocationDetails(
    name: "Sand Harbor",
    city: "Lake Tahoe",
    images: [""],
    coordinates: GeoCoordinates(latitude: 10, longitude: 10),
    description:
        "Popular beach area with sandy shores and rocky landscapes, great for swimming, kayaking, and picnicking.",
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
  ),
  LocationDetails(
    name: "D.L. Bliss State Park",
    city: "Lake Tahoe",
    images: [""],
    coordinates: GeoCoordinates(latitude: 10, longitude: 10),
    description:
        "Scenic state park with hiking trails, beaches, and breathtaking views of Lake Tahoe.",
  ),
  LocationDetails(
    name: "Taylor Creek Visitor Center",
    city: "South Lake Tahoe",
    images: [""],
    coordinates: GeoCoordinates(latitude: 10, longitude: 10),
    description:
        "Educational visitor center with guided tours and a stream profile chamber to observe fish.",
  ),
];
