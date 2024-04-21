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
}

// to be retrieved from admin app data stored in firebase
// retrieve location from firebase realtime database

List<BoardingPoint> boardingPoints = [
  BoardingPoint(
    name: 'Point A',
    latitude: 25.42042,
    longitude: 81.94188,
    isStart: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point B',
    latitude: 25.41815,
    longitude: 81.93974,
    isIntermediate: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point C',
    latitude: 25.41825,
    longitude: 81.93974,
    isIntermediate: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point D',
    latitude: 25.41835,
    longitude: 81.93974,
    isIntermediate: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point E',
    latitude: 25.41845,
    longitude: 81.93974,
    isIntermediate: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point G',
    latitude: 25.49855,
    longitude: 81.93974,
    isIntermediate: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point F',
    latitude: 25.451721,
    longitude: 81.869599,
    isEnd: true,
    // eta: '10:00 AM',
  ),
  BoardingPoint(
    name: 'Point J',
    latitude: 26.451721,
    longitude: 81.869599,
    isEnd: true,
    // eta: '10:00 AM',
  ),
  // Add more boarding points here
];
