// lib/services/pollution_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

// Data class to hold the results from our service
class PollutionData {
  final double? aqi;
  final double dose;
  final String status;
  final String message;

  PollutionData({
    this.aqi,
    this.dose = 0.0,
    this.status = "Idle",
    this.message = "Low",
  });
}

// Enum to define the pollution dose level
enum PollutionLevel { low, moderate, high, critical }

class PollutionService {
  // ------------------------------------------------------------
  // Set your WAQI token here (or inject via constructor)
  // Example token format: '51bb235709d3bf96fe7f048bd31fec5a2e1fb33d'
  // ------------------------------------------------------------
  final String waqiToken = '51bb235709d3bf96fe7f048bd31fec5a2e1fb33d';

  // --- PUBLIC API ---

  /// Fetches the nearest AQI for the given coordinates using WAQI.
  /// Uses the WAQI `feed/geo:lat;lng` endpoint which returns the nearest station.
  /// Verifies station is within `maxDistanceMeters` before returning.
  Future<({double? aqi, String? locationName, String status})> getAqiForLocation(
      double lat, double lng,
      {int maxDistanceMeters = 20000}) async {
    try {
      if (waqiToken == 'YOUR_WAQI_TOKEN_HERE' || waqiToken.trim().isEmpty) {
        return (aqi: null, locationName: null, status: 'WAQI token not set.');
      }

      // WAQI uses a path like /feed/geo:LAT;LNG
      final path = '/feed/geo:$lat;$lng';
      final uri = Uri.https('api.waqi.info', path, {'token': waqiToken});

      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        return (aqi: null, locationName: null, status: 'WAQI HTTP error: ${resp.statusCode}');
      }

      final Map<String, dynamic> body = json.decode(resp.body) as Map<String, dynamic>;

      // WAQI top-level status field
      final statusStr = (body['status'] ?? '').toString();
      if (statusStr != 'ok') {
        final msg = body['data'] != null ? json.encode(body['data']) : 'WAQI responded: $statusStr';
        return (aqi: null, locationName: null, status: 'WAQI error: $msg');
      }

      final Map<String, dynamic> data = (body['data'] ?? {}) as Map<String, dynamic>;

      // aqi (already on US scale or WAQI's scale)
      final int? aqiInt = (data['aqi'] is num) ? (data['aqi'] as num).toInt() : null;
      final double? aqiVal = aqiInt != null ? aqiInt.toDouble() : null;

      // station coordinates: data.city.geo => [lat, lon]
      List<dynamic>? geo = (data['city']?['geo']) as List<dynamic>?;
      double? stationLat;
      double? stationLng;
      if (geo != null && geo.length >= 2) {
        stationLat = (geo[0] as num).toDouble();
        stationLng = (geo[1] as num).toDouble();
      }

      // compute distance if coords available
      double? distanceMeters;
      if (stationLat != null && stationLng != null) {
        distanceMeters = _haversineDistanceMeters(lat, lng, stationLat, stationLng);
      }

      // If station is too far, return not-local
      if (distanceMeters != null && distanceMeters > maxDistanceMeters) {
        return (
        aqi: null,
        locationName: null,
        status: 'Nearest WAQI station is ${distanceMeters.round()} m away — beyond maxDistance ($maxDistanceMeters m).'
        );
      }

      // location name from WAQI
      final String? locationName = (data['city']?['name'] as String?)?.trim();

      // success
      return (
      aqi: aqiVal,
      locationName: locationName,
      status: 'WAQI: ${aqiInt ?? 'N/A'} at ${locationName ?? 'Unknown'}${distanceMeters != null ? ' (${distanceMeters.round()} m)' : ''}'
      );
    } catch (e) {
      return (aqi: null, locationName: null, status: 'Network error WAQI: $e');
    }
  }

  // --- helper: haversine distance in meters ---
  double _haversineDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  /// Calculates the pollution dose based on exposure time and AQI.
  /// Converts duration to fractional hours and multiplies by AQI (time-weighted dose).
  double calculateDose(Duration exposureDuration, double? aqi) {
    if (aqi == null || aqi <= 0) {
      return 0.0;
    }

    // Convert duration to fractional hours
    final double hours = exposureDuration.inSeconds / 3600.0;
    return hours * aqi;
  }

  /// Determines the pollution level and message based on the dose.
  ({PollutionLevel level, String message}) getDoseMessage(double dose) {
    if (dose <= 100) {
      return (level: PollutionLevel.low, message: 'Low');
    } else if (dose <= 300) {
      return (level: PollutionLevel.moderate, message: 'Moderate');
    } else if (dose <= 500) {
      return (level: PollutionLevel.high, message: 'High');
    } else {
      return (level: PollutionLevel.critical, message: 'Critical');
    }
  }

  // (Optional helper) Extract PM2.5 concentration from WAQI response map if you need it
  // Example usage: double? pm25 = extractPm25FromWaqiMap(data);
  double? extractPm25FromWaqiMap(Map<String, dynamic> waqiData) {
    try {
      final pm25 = waqiData['iaqi']?['pm25']?['v'];
      if (pm25 is num) return pm25.toDouble();
    } catch (_) {}
    return null;
  }
}
