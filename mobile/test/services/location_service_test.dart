import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:resqlink_mobile/services/location_service.dart';

void main() {
  group('LocationService', () {
    test('returns the current position when permissions are available', () async {
      final expected = _position(latitude: 32.221, longitude: 76.319);
      final platform = _FakeLocationPlatform(
        serviceEnabled: true,
        permission: LocationPermission.whileInUse,
        currentPosition: expected,
      );
      final service = LocationService(platform: platform);

      final result = await service.getCurrentPosition();

      expect(result.latitude, expected.latitude);
      expect(result.longitude, expected.longitude);
      expect(platform.requestPermissionCalls, 0);
    });

    test('requests permission before resolving the position', () async {
      final expected = _position(latitude: 31.104, longitude: 77.173);
      final platform = _FakeLocationPlatform(
        serviceEnabled: true,
        permission: LocationPermission.denied,
        permissionAfterRequest: LocationPermission.whileInUse,
        currentPosition: expected,
      );
      final service = LocationService(platform: platform);

      final result = await service.getCurrentPosition();

      expect(result.latitude, expected.latitude);
      expect(platform.requestPermissionCalls, 1);
    });

    test('throws when location permission remains denied', () async {
      final platform = _FakeLocationPlatform(
        serviceEnabled: true,
        permission: LocationPermission.denied,
        permissionAfterRequest: LocationPermission.denied,
        currentPosition: _position(latitude: 0, longitude: 0),
      );
      final service = LocationService(platform: platform);

      await expectLater(
        service.getCurrentPosition(),
        throwsA(isA<LocationPermissionDeniedException>()),
      );
    });
  });
}

Position _position({
  required double latitude,
  required double longitude,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime(2026, 4, 18),
    accuracy: 8,
    altitude: 1200,
    altitudeAccuracy: 2,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

class _FakeLocationPlatform implements LocationPlatform {
  _FakeLocationPlatform({
    required this.serviceEnabled,
    required this.permission,
    required this.currentPosition,
    this.permissionAfterRequest = LocationPermission.denied,
  });

  final bool serviceEnabled;
  final Position currentPosition;
  final LocationPermission permissionAfterRequest;
  int requestPermissionCalls = 0;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<Position> getCurrentPosition() async => currentPosition;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalls++;
    permission = permissionAfterRequest;
    return permission;
  }

  LocationPermission permission;
}
