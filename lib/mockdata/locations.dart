import 'package:odyssey/model/location.dart';

const String firebaseStoragePrefix = "https://firebasestorage.googleapis.com/v0/b/csen268-f24-g7-dcfb7.firebasestorage.app/o/location_images%2F";
const String mediaSuffix = "?alt=media";

List<LocationDetails> locations = [
  // Locations within 10 miles (Santa Clara)
  LocationDetails(
    name: "California's Great America",
    city: "Santa Clara",
    coordinates: GeoCoordinates(latitude: 37.3723, longitude: -121.9749),
    images: [
      "$firebaseStoragePrefix" + "california-greate-america-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "california-greate-america-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "california-greate-america-3.jpg$mediaSuffix"
    ],
    description:
        "A large amusement park with rides, live entertainment, and family-friendly attractions.",
    tags: ['Culture'],
  ),
  LocationDetails(
    name: "Levi's Stadium",
    city: "Santa Clara",
    coordinates: GeoCoordinates(latitude: 37.4036, longitude: -121.9756),
    images: [
      "$firebaseStoragePrefix" + "levis-stadium-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "levis-stadium-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "levis-stadium-3.jpeg$mediaSuffix"
    ],
    description:
        "Home of the San Francisco 49ers and a venue for concerts, events, and sporting activities.",
    tags: ['Culture'],
  ),
  LocationDetails(
    name: "Intel Museum",
    city: "Santa Clara",
    coordinates: GeoCoordinates(latitude: 37.3911, longitude: -121.9721),
    images: [
      "$firebaseStoragePrefix" + "intel-museum-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "intel-musenum-2.jpeg$mediaSuffix"
    ],
    description:
        "A museum showcasing the history of Intel and the innovations in computing technology.",
    tags: ['History'],
  ),
  LocationDetails(
    name: "Rosicrucian Egyptian Museum",
    city: "San Jose",
    coordinates: GeoCoordinates(latitude: 37.3153, longitude: -121.9120),
    images: [
      "$firebaseStoragePrefix" + "egyptian-museum-1.jpg$mediaSuffix",
      "$firebaseStoragePrefix" + "egyptian-museum-2.JPG$mediaSuffix",
      "$firebaseStoragePrefix" + "egyptian-museum-3.jpg$mediaSuffix"
    ],
    description:
        "A museum with an extensive collection of ancient Egyptian artifacts and exhibits.",
    tags: ['History'],
  ),
  LocationDetails(
    name: "Winchester Mystery House",
    city: "San Jose",
    coordinates: GeoCoordinates(latitude: 37.2970, longitude: -121.9503),
    images: [
      "$firebaseStoragePrefix" + "mystery-house-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "mystery-house-2.jpg$mediaSuffix"
    ],
    description:
        "A mysterious Victorian mansion known for its architectural curiosities and ghost stories.",
    tags: ['Culture'],
  ),

  // Locations within 20 miles
  LocationDetails(
    name: "Mission San Jose",
    city: "Fremont",
    coordinates: GeoCoordinates(latitude: 37.5249, longitude: -121.9183),
    images: [
      "$firebaseStoragePrefix" + "mission-san-jose-2.jpg$mediaSuffix"
    ],
    description:
        "One of the historic California missions, with a museum and beautiful gardens.",
    tags: ['History'],
  ),
  LocationDetails(
    name: "Apple Park Visitor Center",
    city: "Cupertino",
    coordinates: GeoCoordinates(latitude: 37.3318, longitude: -122.0300),
    images: [
      "$firebaseStoragePrefix" + "apple-visitor-center-1.jpg$mediaSuffix",
      "$firebaseStoragePrefix" + "apple-visitor-center-2.jpg$mediaSuffix",
      "$firebaseStoragePrefix" + "apple-visitor-center-3.jpg$mediaSuffix"
    ],
    description:
        "A sleek visitor center at Apple's headquarters, featuring an interactive exhibit and cafe.",
    tags: ['Culture'],
  ),
  LocationDetails(
    name: "Stanford University",
    city: "Stanford",
    coordinates: GeoCoordinates(latitude: 37.4275, longitude: -122.1697),
    images: [
      "$firebaseStoragePrefix" + "stanford-university-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "stanford-university-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "stanford-university-3.jpeg$mediaSuffix"
    ],
    description:
        "A prestigious university with beautiful architecture and expansive grounds.",
    tags: ['History', 'Culture'],
  ),
  LocationDetails(
    name: "Palo Alto Baylands Nature Preserve",
    city: "Palo Alto",
    coordinates: GeoCoordinates(latitude: 37.4419, longitude: -122.1559),
    images: [
      "$firebaseStoragePrefix" + "baylands-nature-preserve-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "baylands-nature-preserve-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "baylands-nature-preserve-3.jpeg$mediaSuffix"
    ],
    description:
        "A large wildlife preserve with marshes, hiking trails, and birdwatching opportunities.",
    tags: ['Nature'],
  ),
  LocationDetails(
    name: "Berkeley Art Museum and Pacific Film Archive",
    city: "Berkeley",
    coordinates: GeoCoordinates(latitude: 37.8697, longitude: -122.2594),
    images: [
      "$firebaseStoragePrefix" + "berkeley-art-museum-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "berkeley-art-museum-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "berkeley-art-museum-3.jpeg$mediaSuffix"
    ],
    description:
        "A museum and archive showcasing art and cinema with a diverse collection of exhibitions.",
    tags: ['Arts'],
  ),

  // Locations within 100 miles
  LocationDetails(
    name: "Golden Gate Bridge",
    city: "San Francisco",
    coordinates: GeoCoordinates(latitude: 37.8199, longitude: -122.4783),
    images: [
      "$firebaseStoragePrefix" + "golden-gate-bridge-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "golden-gate-bridge-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "golden-gate-bridge-3.jpeg$mediaSuffix"
    ],
    description:
        "An iconic suspension bridge connecting San Francisco to Marin County, offering stunning views.",
    tags: ['Culture', 'History'],
  ),
  LocationDetails(
    name: "Fisherman's Wharf",
    city: "San Francisco",
    coordinates: GeoCoordinates(latitude: 37.8080, longitude: -122.4177),
    images: [
      "$firebaseStoragePrefix" + "fishermans-wharf-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "fishermans-wharf-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "fishermans-wharf-3.jpeg$mediaSuffix"
    ],
    description:
        "A popular waterfront district known for seafood restaurants, shops, and attractions like Pier 39.",
    tags: ['Food', 'Culture'],
  ),
  LocationDetails(
    name: "Alcatraz Island",
    city: "San Francisco",
    coordinates: GeoCoordinates(latitude: 37.8267, longitude: -122.4230),
    images: [
      "$firebaseStoragePrefix" + "alcatraz-island-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "alcatraz-island-2.jpeg$mediaSuffix"
    ],
    description:
        "A historic island known for its former prison and now a national park and tourist destination.",
    tags: ['History', 'Culture'],
  ),
  LocationDetails(
    name: "Big Basin Redwoods State Park",
    city: "Boulder Creek",
    coordinates: GeoCoordinates(latitude: 37.1881, longitude: -122.2084),
    images: [
      "$firebaseStoragePrefix" + "big-basin-redwoods-state-park-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "big-basin-redwoods-state-park-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "big-basin-redwoods-state-park-3.jpeg$mediaSuffix"
    ],
    description:
        "A scenic park featuring towering redwoods, hiking trails, and a variety of wildlife.",
    tags: ['Nature'],
  ),
  LocationDetails(
    name: "Point Reyes National Seashore",
    city: "Point Reyes Station",
    coordinates: GeoCoordinates(latitude: 38.0832, longitude: -123.0204),
    images: [
      "$firebaseStoragePrefix" + "point-reyes-national-seashore-1.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "point-reyes-national-seashore-2.jpeg$mediaSuffix",
      "$firebaseStoragePrefix" + "point-reyes-national-seashore-3.jpeg$mediaSuffix"
    ],
    description:
        "A rugged coastline with cliffs, beaches, and wildlife, perfect for hiking and nature watching.",
    tags: ['Nature'],
  ),
];
