import 'package:odyssey/model/location.dart';

const String firebaseStoragePrefix = "https://firebasestorage.googleapis.com/v0/b/csen268-f24-g7-dcfb7.firebasestorage.app/o/location_images%2F";
const String mediaSuffix = "?alt=media";

List<LocationDetails> locations = [
  LocationDetails(
    name: "Emerald Bay State Park",
    city: "Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.9571, longitude: -120.1107),
    images: [
      "https://firebasestorage.googleapis.com/v0/b/csen268-f24-g7-dcfb7.firebasestorage.app/o/location_images%2Femerald-bay-park-1.jpeg?alt=media"
    ],
    description:
        "A beautiful bay with crystal-clear water and breathtaking views. Known for its hiking trails and scenic overlooks.",
    tags: ['Nature'], // Using only the given tags
  ),
  LocationDetails(
    name: "Sand Harbor",
    city: "Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 39.1004, longitude: -120.0112),
    images: [
      "https://firebasestorage.googleapis.com/v0/b/csen268-f24-g7-dcfb7.firebasestorage.app/o/location_images%2Fsand-harbor-1.jpeg?alt=media"
    ],
    description:
        "Popular beach area with sandy shores and rocky landscapes, great for swimming, kayaking, and picnicking.",
    tags: ['Nature', 'Culture'], // Using only the given tags
  ),
  LocationDetails(
    name: "Heavenly Mountain Resort",
    city: "Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.9338, longitude: -119.9403),
    images: [
      "https://firebasestorage.googleapis.com/v0/b/csen268-f24-g7-dcfb7.firebasestorage.app/o/location_images%2Fheavenly-mountain-resort-1.jpeg?alt=media"
    ],
    description:
        "A major ski resort offering winter sports, summer hikes, and stunning gondola rides with panoramic views of the lake.",
    tags: ['Nature', 'Culture'], // Using only the given tags
  ),
  LocationDetails(
    name: "D.L. Bliss State Park",
    city: "Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 39.0431, longitude: -120.1228),
    images: [
      "https://firebasestorage.googleapis.com/v0/b/csen268-f24-g7-dcfb7.firebasestorage.app/o/location_images%2Fbliss-state-park-1.jpg?alt=media"
    ],
    description:
        "Scenic state park with hiking trails, beaches, and breathtaking views of Lake Tahoe.",
    tags: ['Nature'], // Using only the given tags
  ),
  LocationDetails(
    name: "Taylor Creek Visitor Center",
    city: "South Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.9407, longitude: -120.0486),
    images: [
      "https://firebasestorage.googleapis.com/v0/b/csen268-f24-g7-dcfb7.firebasestorage.app/o/location_images%2Ftaylor-creek-visitor-center-1.jpg?alt=media"
    ],
    description:
        "Educational visitor center with guided tours and a stream profile chamber to observe fish.",
    tags: ['Culture', 'History'], // Using only the given tags
  ),
];
