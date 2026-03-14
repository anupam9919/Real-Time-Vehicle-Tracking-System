import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle/core/utils/distance_utils.dart';

void main() {
  group('DistanceUtils.haversine', () {
    test('returns 0 for same coordinates', () {
      final distance = DistanceUtils.haversine(28.6139, 77.2090, 28.6139, 77.2090);
      expect(distance, 0.0);
    });

    test('calculates correct distance between two known cities', () {
      // Delhi (28.6139°N, 77.2090°E) → Mumbai (19.0760°N, 72.8777°E)
      // Known distance ≈ 1,153 km
      final distance = DistanceUtils.haversine(28.6139, 77.2090, 19.0760, 72.8777);
      final distanceKm = distance / 1000;
      expect(distanceKm, closeTo(1153, 20)); // ±20 km tolerance
    });

    test('calculates small distances accurately', () {
      // Two points ~1 km apart in Prayagraj
      final distance = DistanceUtils.haversine(25.4358, 81.8463, 25.4268, 81.8463);
      expect(distance, closeTo(1000, 50)); // ±50m tolerance
    });

    test('is symmetric — distance A→B == distance B→A', () {
      final ab = DistanceUtils.haversine(25.4358, 81.8463, 28.6139, 77.2090);
      final ba = DistanceUtils.haversine(28.6139, 77.2090, 25.4358, 81.8463);
      expect(ab, closeTo(ba, 0.01));
    });
  });

  group('DistanceUtils.formatDistance', () {
    test('formats meters when < 1000', () {
      expect(DistanceUtils.formatDistance(450), '450 m');
    });

    test('formats km when >= 1000', () {
      expect(DistanceUtils.formatDistance(2300), '2.3 km');
    });

    test('formats exactly 1000m as km', () {
      expect(DistanceUtils.formatDistance(1000), '1.0 km');
    });

    test('rounds meters to nearest whole number', () {
      expect(DistanceUtils.formatDistance(99.7), '100 m');
    });

    test('formats large distances', () {
      expect(DistanceUtils.formatDistance(1153000), '1153.0 km');
    });
  });
}
