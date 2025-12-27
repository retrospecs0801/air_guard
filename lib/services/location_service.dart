// lib/services/location_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionSub;

  /// Request permissions and return whether we have them
  Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// One-shot current position (throws if permissions missing)
  Future<Position> getCurrentPosition({LocationAccuracy accuracy = LocationAccuracy.best}) async {
    final ok = await ensurePermission();
    if (!ok) {
      throw Exception('Location not available or permission denied');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: accuracy);
  }

  /// Start a stream of positions. Useful for live tracking.
  Stream<Position> positionStream({LocationAccuracy accuracy = LocationAccuracy.best, int distanceFilter = 0}) {
    final settings = LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter);
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Helper: distance between two points in meters
  double distanceBetween(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude);
  }

  /// Cancel internal subscriptions if used
  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }
}
