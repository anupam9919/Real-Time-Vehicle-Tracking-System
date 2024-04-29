class BoardingPoint {
  final String name;
  final double latitude;
  final double longitude;
  final bool isStart;
  final bool isEnd;
  final bool isIntermediate;

  BoardingPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isStart = false,
    this.isEnd = false,
    this.isIntermediate = false,
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
