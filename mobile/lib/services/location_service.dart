import 'package:geolocator/geolocator.dart';

abstract class LocationPlatform {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition();
}

class GeolocatorLocationPlatform implements LocationPlatform {
  const GeolocatorLocationPlatform();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();
}

class LocationServiceDisabledException implements Exception {
  @override
  String toString() => 'Location services are disabled.';
}

class LocationPermissionDeniedException implements Exception {
  LocationPermissionDeniedException(this.permission);

  final LocationPermission permission;

  @override
  String toString() =>
      'Location permission was not granted: ${permission.name}.';
}

class LocationService {
  LocationService({LocationPlatform? platform})
      : _platform = platform ?? const GeolocatorLocationPlatform();

  final LocationPlatform _platform;

  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await _platform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    var permission = await _platform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _platform.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException(permission);
    }

    return _platform.getCurrentPosition();
  }
}
