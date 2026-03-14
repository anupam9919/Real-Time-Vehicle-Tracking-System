import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vehicle/core/services/location_service.dart';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock the GeolocatorPlatform to control permission/service behaviour.
class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

void main() {
  late MockGeolocatorPlatform mockGeolocator;
  late LocationService locationService;

  setUp(() {
    mockGeolocator = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocator;
    locationService = const LocationService();
  });

  Position createMockPosition({
    double latitude = 25.4358,
    double longitude = 81.8463,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  group('LocationService.getCurrentPosition', () {
    test('throws when location services are disabled', () async {
      when(() => mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      expect(
        () => locationService.getCurrentPosition(),
        throwsA(isA<LocationServiceException>()),
      );
    });

    test('throws when permission is denied', () async {
      when(() => mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => mockGeolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      expect(
        () => locationService.getCurrentPosition(),
        throwsA(isA<LocationServiceException>()),
      );
    });

    test('throws when permission is permanently denied', () async {
      when(() => mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);

      expect(
        () => locationService.getCurrentPosition(),
        throwsA(isA<LocationServiceException>()),
      );
    });

    test('returns position when permission is granted', () async {
      final mockPosition = createMockPosition();

      when(() => mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(() => mockGeolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenAnswer((_) async => mockPosition);

      final result = await locationService.getCurrentPosition();
      expect(result.latitude, 25.4358);
      expect(result.longitude, 81.8463);
    });

    test('requests permission when initially denied, then granted', () async {
      final mockPosition = createMockPosition();

      when(() => mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => mockGeolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(() => mockGeolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenAnswer((_) async => mockPosition);

      final result = await locationService.getCurrentPosition();
      expect(result.latitude, 25.4358);

      verify(() => mockGeolocator.requestPermission()).called(1);
    });
  });

  group('LocationService.distanceBetween', () {
    test('delegates to Geolocator.distanceBetween', () {
      when(() => mockGeolocator.distanceBetween(
            any(), any(), any(), any(),
          )).thenReturn(1500.0);

      final result = locationService.distanceBetween(25.0, 81.0, 26.0, 82.0);
      expect(result, 1500.0);
    });
  });

  group('LocationServiceException', () {
    test('toString includes message', () {
      const exception = LocationServiceException('test error');
      expect(exception.toString(), contains('test error'));
    });
  });
}
