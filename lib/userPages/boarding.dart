class BoardingPoint {
  final String name;
  final double latitude;
  final double longitude;
  final bool isStart;
  final bool isEnd;
  final bool isIntermediate;
  // final String eta;

  BoardingPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isStart = false,
    this.isEnd = false,
    this.isIntermediate = false,
    // required this.eta,
  });

  factory BoardingPoint.fromMap(Map<dynamic, dynamic> data) {
    return BoardingPoint(
      name: data['name'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      isStart: data['isStart'] ?? false,
      isEnd: data['isEnd'] ?? false,
      isIntermediate: data['isIntermediate'] ?? false,
    );
  }
}

// to be retrieved from admin app data stored in firebase
// retrieve location from firebase realtime database

List<BoardingPoint> boardingPoints = [
  BoardingPoint(
    name: 'Point A',
    latitude: 25.421753,
    longitude: 81.861926,
    isStart: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point B',
    latitude: 25.414213,
    longitude: 81.857338,
    isIntermediate: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point C',
    latitude: 25.408271,
    longitude: 81.864996,
    isIntermediate: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point D',
    latitude: 25.401730,
    longitude: 81.869292,
    isIntermediate: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point E',
    latitude: 25.390336,
    longitude: 81.863561,
    isIntermediate: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point F',
    latitude: 25.371948,
    longitude: 81.875327,
    isIntermediate: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point G',
    latitude: 25.353154,
    longitude: 81.888751,
    isEnd: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point H',
    latitude: 25.343610,
    longitude: 81.896615,
    isEnd: true,
    // eta: '10:00 AM',
  ),
  // Add more boarding points here
];
