import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle/core/utils/eta_utils.dart';

void main() {
  group('EtaUtils.calculate', () {
    test('returns correct ETA for normal speed', () {
      // 10 km at 30 km/h = 20 minutes
      final eta = EtaUtils.calculate(distanceMeters: 10000, speedKmh: 30);
      expect(eta.inMinutes, 20);
    });

    test('clamps speed to minimum', () {
      // 5 km at 1 km/h (below min) → clamped to 5 km/h → 1 hour
      final eta = EtaUtils.calculate(distanceMeters: 5000, speedKmh: 1);
      expect(eta.inMinutes, 60);
    });

    test('clamps speed to maximum', () {
      // 240 km at 200 km/h (above max) → clamped to 120 km/h → 2 hours
      final eta = EtaUtils.calculate(distanceMeters: 240000, speedKmh: 200);
      expect(eta.inHours, 2);
    });

    test('handles zero distance', () {
      final eta = EtaUtils.calculate(distanceMeters: 0, speedKmh: 30);
      expect(eta.inSeconds, 0);
    });
  });

  group('EtaUtils.calculateWithDefaultSpeed', () {
    test('uses default vehicle speed of 25 km/h', () {
      // 25 km at 25 km/h = 1 hour
      final eta = EtaUtils.calculateWithDefaultSpeed(25000);
      expect(eta.inMinutes, 60);
    });
  });

  group('EtaUtils.calculateWalkingEta', () {
    test('uses walking speed of 4 km/h', () {
      // 4 km at 4 km/h (clamped to min 5) → 48 min
      // Walking speed is 4 km/h which is below minSpeedKmh of 5
      // So it gets clamped to 5 km/h → 4/5 hr = 48 min
      final eta = EtaUtils.calculateWalkingEta(4000);
      expect(eta.inMinutes, 48);
    });
  });

  group('EtaUtils.normalizeSpeedMsToKmh', () {
    test('converts m/s to km/h correctly', () {
      // 10 m/s = 36 km/h
      expect(EtaUtils.normalizeSpeedMsToKmh(10), 36);
    });

    test('falls back to default speed when too slow', () {
      // 0.2 m/s = 0.72 km/h → below 1.0 → returns default 25 km/h
      expect(EtaUtils.normalizeSpeedMsToKmh(0.2), EtaUtils.defaultVehicleSpeedKmh);
    });

    test('clamps high speed to max', () {
      // 40 m/s = 144 km/h → clamped to 120 km/h
      expect(EtaUtils.normalizeSpeedMsToKmh(40), EtaUtils.maxSpeedKmh);
    });

    test('clamps low valid speed to min', () {
      // 1.0 m/s = 3.6 km/h → above 1.0 threshold, clamped to 5 km/h min
      expect(EtaUtils.normalizeSpeedMsToKmh(1.0), EtaUtils.minSpeedKmh);
    });
  });

  group('EtaUtils.formatEta', () {
    test('shows "< 1 min" for very short durations', () {
      expect(EtaUtils.formatEta(const Duration(seconds: 30)), '< 1 min');
    });

    test('shows minutes for sub-hour durations', () {
      expect(EtaUtils.formatEta(const Duration(minutes: 15)), '15 min');
    });

    test('shows hours and minutes for longer durations', () {
      expect(EtaUtils.formatEta(const Duration(hours: 1, minutes: 15)), '1 hr 15 min');
    });

    test('shows just hours when no remainder minutes', () {
      expect(EtaUtils.formatEta(const Duration(hours: 2)), '2 hr');
    });

    test('shows zero as < 1 min', () {
      expect(EtaUtils.formatEta(Duration.zero), '< 1 min');
    });
  });
}
