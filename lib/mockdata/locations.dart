import 'package:odyssey/model/location.dart';

const String firebaseStoragePrefix = "https://firebasestorage.googleapis.com/v0/b/csen268-f24-g7-dcfb7.firebasestorage.app/o/location_images%2F";
const String mediaSuffix = "?alt=media";

List<LocationDetails> locations = [
  // Existing Locations
  LocationDetails(
    name: "Emerald Bay State Park",
    city: "Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.9571, longitude: -120.1107),
    images: [
      "$firebaseStoragePrefix" + "emerald-bay-park-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "emerald-bay-state-park-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "emerald-bay-state-park-3.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "emerald-bay-state-park-4.jpeg$mediaSuffix"
    ],
    description:
        "A beautiful bay with crystal-clear water and breathtaking views. Known for its hiking trails and scenic overlooks.",
    tags: ['Nature'],
  ),
  LocationDetails(
    name: "Sand Harbor",
    city: "Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 39.1004, longitude: -120.0112),
    images: [
      "$firebaseStoragePrefix" + "sand-harbor-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "sand-harbor-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "sand-harbor-3.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "sand-harbor-4.jpeg$mediaSuffix"
    ],
    description:
        "Popular beach area with sandy shores and rocky landscapes, great for swimming, kayaking, and picnicking.",
    tags: ['Nature', 'Culture'],
  ),
  LocationDetails(
    name: "Heavenly Mountain Resort",
    city: "Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.9338, longitude: -119.9403),
    images: [
      "$firebaseStoragePrefix" + "heavenly-mountain-resort-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "heavenly-mountain-resort-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "heavenly-mountain-resort-3.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "heavenly-mountain-resort-4.jpeg$mediaSuffix"
    ],
    description:
        "A major ski resort offering winter sports, summer hikes, and stunning gondola rides with panoramic views of the lake.",
    tags: ['Nature', 'Culture'],
  ),
  LocationDetails(
    name: "D.L. Bliss State Park",
    city: "Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 39.0431, longitude: -120.1228),
    images: [
      "$firebaseStoragePrefix" + "bliss-state-park-1.jpg$mediaSuffix",
      "$firebaseStoragePrefix" + "bliss-state-park-2.jpg$mediaSuffix"
    ],
    description:
        "Scenic state park with hiking trails, beaches, and breathtaking views of Lake Tahoe.",
    tags: ['Nature'],
  ),
  LocationDetails(
    name: "Taylor Creek Visitor Center",
    city: "South Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.9407, longitude: -120.0486),
    images: [
      "$firebaseStoragePrefix" + "taylor-creek-visitor-center-1.jpg$mediaSuffix",
      "$firebaseStoragePrefix" + "taylor-creek-visitor-center-2.jpg$mediaSuffix",
      "$firebaseStoragePrefix" + "taylor-creek-visitor-center-3.jpg$mediaSuffix"
    ],
    description:
        "Educational visitor center with guided tours and a stream profile chamber to observe fish.",
    tags: ['Culture', 'History'],
  ),
  
  // 10 miles range
  LocationDetails(
    name: "Barton Memorial Hospital",
    city: "South Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.9483, longitude: -119.9794),
    images: [
      "$firebaseStoragePrefix" + "barton-memorial-hospital-1.jpg$mediaSuffix"
    ],
    description:
        "A local hospital providing healthcare services to the Lake Tahoe region.",
    tags: ['Culture'],
  ),
  LocationDetails(
    name: "Echo Lake",
    city: "South Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.9257, longitude: -120.0121),
    images: [
      "$firebaseStoragePrefix" + "echo-lake-1.jpg$mediaSuffix"
    ],
    description:
        "A beautiful alpine lake, popular for kayaking, fishing, and relaxing by the water.",
    tags: ['Nature'],
  ),
  LocationDetails(
    name: "South Lake Tahoe Beaches",
    city: "South Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.9393, longitude: -119.9773),
    images: [
      "$firebaseStoragePrefix" + "south-lake-tahoe-beaches-1.jpg$mediaSuffix"
    ],
    description:
        "A collection of beaches around the South Lake Tahoe area, great for picnics, sunbathing, and watersports.",
    tags: ['Nature'],
  ),
  LocationDetails(
    name: "Stateline Lookout",
    city: "South Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.9583, longitude: -119.9361),
    images: [
      "$firebaseStoragePrefix" + "stateline-lookout-1.jpg$mediaSuffix"
    ],
    description:
        "A scenic overlook that provides panoramic views of the Lake Tahoe region and surrounding mountains.",
    tags: ['Nature'],
  ),
  LocationDetails(
    name: "Lakeview Commons",
    city: "South Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.9431, longitude: -119.9774),
    images: [
      "$firebaseStoragePrefix" + "lakeview-commons-1.jpg$mediaSuffix"
    ],
    description:
        "A popular public park with views of the lake, picnic areas, and access to a sandy beach.",
    tags: ['Nature'],
  ),
  
  // 20 miles range
  LocationDetails(
    name: "Mount Tallac Trailhead",
    city: "South Lake Tahoe",
    coordinates: GeoCoordinates(latitude: 38.8834, longitude: -120.0217),
    images: [
      "$firebaseStoragePrefix" + "mount-tallac-trailhead-1.jpg$mediaSuffix"
    ],
    description:
        "A popular trail leading to the summit of Mount Tallac, offering sweeping views of Lake Tahoe.",
    tags: ['Nature'],
  ),
  LocationDetails(
    name: "Meeks Bay",
    city: "Tahoma",
    coordinates: GeoCoordinates(latitude: 39.0801, longitude: -120.1547),
    images: [
      "$firebaseStoragePrefix" + "meeks-bay-1.jpg$mediaSuffix"
    ],
    description:
        "A serene bay on the west shore of Lake Tahoe, offering a sandy beach, picnic areas, and hiking trails.",
    tags: ['Nature'],
  ),
  LocationDetails(
    name: "Tahoma Market",
    city: "Tahoma",
    coordinates: GeoCoordinates(latitude: 39.0346, longitude: -120.1173),
    images: [
      "$firebaseStoragePrefix" + "tahoma-market-1.jpg$mediaSuffix"
    ],
    description:
        "A local market offering fresh produce, groceries, and community services.",
    tags: ['Food'],
  ),
  LocationDetails(
    name: "Sugar Pine Point State Park",
    city: "Homewood",
    coordinates: GeoCoordinates(latitude: 39.0723, longitude: -120.1348),
    images: [
      "$firebaseStoragePrefix" + "sugar-pine-point-park-1.jpg$mediaSuffix"
    ],
    description:
        "A peaceful state park offering hiking, camping, and swimming opportunities along Lake Tahoe's western shore.",
    tags: ['Nature'],
  ),
  LocationDetails(
    name: "Granlibakken Resort",
    city: "Tahoe City",
    coordinates: GeoCoordinates(latitude: 39.1867, longitude: -120.1396),
    images: [
      "$firebaseStoragePrefix" + "granlibakken-resort-1.jpg$mediaSuffix"
    ],
    description:
        "A resort offering skiing, hiking, and dining, located in the Tahoe City area.",
    tags: ['Nature', 'Culture'],
  ),
  
  // 100 miles range
  LocationDetails(
    name: "Reno, Nevada",
    city: "Reno",
    coordinates: GeoCoordinates(latitude: 39.5296, longitude: -119.8138),
    images: [
      "$firebaseStoragePrefix" + "reno-nevada-1.jpg$mediaSuffix"
    ],
    description:
        "A major city known for its casinos, art, and outdoor activities.",
    tags: ['Culture', 'Food'],
  ),
  LocationDetails(
    name: "Squaw Valley Ski Resort",
    city: "Olympic Valley",
    coordinates: GeoCoordinates(latitude: 39.2007, longitude: -120.2331),
    images: [
      "$firebaseStoragePrefix" + "squaw-valley-ski-resort-1.jpg$mediaSuffix"
    ],
    description:
        "A world-class ski resort known for its Olympic history and winter sports.",
    tags: ['Nature', 'Culture'],
  ),
  LocationDetails(
    name: "Tahoe City",
    city: "Tahoe City",
    coordinates: GeoCoordinates(latitude: 39.1701, longitude: -120.1439),
    images: [
      "$firebaseStoragePrefix" + "tahoe-city-1.jpg$mediaSuffix"
    ],
    description:
        "A charming town known for its lakeside activities, dining, and art galleries.",
    tags: ['Culture'],
  ),
  LocationDetails(
    name: "Truckee",
    city: "Truckee",
    coordinates: GeoCoordinates(latitude: 39.327, longitude: -120.1852),
    images: [
      "$firebaseStoragePrefix" + "truckee-1.jpg$mediaSuffix"
    ],
    description:
        "A historic town offering shops, dining, and access to nearby lakes and outdoor recreation.",
    tags: ['Culture', 'History'],
  ),
  LocationDetails(
    name: "Nevada State Museum",
    city: "Carson City",
    coordinates: GeoCoordinates(latitude: 39.1605, longitude: -119.7669),
    images: [
      "$firebaseStoragePrefix" + "nevada-state-museum-1.jpg$mediaSuffix"
    ],
    description:
        "A museum showcasing the history of Nevada, with exhibits on local history and mining.",
    tags: ['Culture', 'History'],
  ),
];
