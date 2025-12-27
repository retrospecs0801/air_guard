// lib/services/exposure_service.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';
import 'storage_service.dart';

class ExposureData {
  final bool isInsideHome;
  final Duration totalExposureToday;
  final Duration currentSessionDuration;
  final String status; // human readable

  ExposureData({
    required this.isInsideHome,
    required this.totalExposureToday,
    required this.currentSessionDuration,
    required this.status,
  });

  ExposureData copyWith({
    bool? isInsideHome,
    Duration? totalExposureToday,
    Duration? currentSessionDuration,
    String? status,
  }) {
    return ExposureData(
      isInsideHome: isInsideHome ?? this.isInsideHome,
      totalExposureToday: totalExposureToday ?? this.totalExposureToday,
      currentSessionDuration: currentSessionDuration ?? this.currentSessionDuration,
      status: status ?? this.status,
    );
  }
}

class ExposureService {
  // Singleton
  static final ExposureService _instance = ExposureService._internal();
  factory ExposureService() => _instance;
  ExposureService._internal();

  // Configuration
  final double _radiusMeters = 15.0;
  // <- 2 meters as requested
  final LocationService _loc = LocationService();

  // Stream to broadcast UI updates
  final StreamController<ExposureData> _controller =
  StreamController<ExposureData>.broadcast();

  Stream<ExposureData> get stream => _controller.stream;

  // Internal state
  double? _homeLat;
  double? _homeLng;
  Duration _totalExposureToday = Duration.zero;
  DateTime? _sessionStart;
  bool _isInsideHome = true; // assume inside until first check
  StreamSubscription<Position>? _posSub;
  Timer? _tickTimer; // ticks every second while session active

  // Persistence keys
  static const _prefTotalKey = 'exposure_total_seconds';
  static const _prefDateKey = 'exposure_total_date'; // store yyyy-MM-dd

  // Start monitoring positions (call once at app start)
  Future<void> startMonitoring() async {
    // Load persisted totals and reset if day changed
    await _loadPersistedTotal();

    // Start listening to position stream (UI or app should ensure permissions)
    _posSub?.cancel();
    _posSub = _loc.positionStream(accuracy: LocationAccuracy.best, distanceFilter: 0)
        .listen(_onPosition, onError: (e) {
      _emit(status: 'Position stream error: $e');
    });
  }

  Future<void> stopMonitoring() async {
    await _posSub?.cancel();
    _posSub = null;
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  // Set home coordinates (called by UI after saving home)
  Future<void> setHome(double lat, double lng) async {
    _homeLat = lat;
    _homeLng = lng;
    // When home is set, ensure monitoring is active:
    await startMonitoring();
    // Immediately evaluate current location (we may not have a position yet; _onPosition will handle)
    _emit(status: 'Home set. Monitoring enabled.');
  }

  Future<void> clearHome() async {
    _homeLat = null;
    _homeLng = null;
    // If a session was running, close it
    if (_sessionStart != null) {
      await _stopSessionAndPersist(); // add partial session into total
    }
    _emit(status: 'Home cleared. Monitoring paused.');
  }

  // Internal: handle each position update
  void _onPosition(Position pos) {
    if (_homeLat == null || _homeLng == null) {
      // nothing to do until home is configured
      _emit(status: 'Waiting for home to be set');
      return;
    }

    final distance = _loc.distanceBetween(_homeLat!, _homeLng!, pos.latitude, pos.longitude);
    final currentlyInside = distance <= _radiusMeters;

    // On first run, set baseline _isInsideHome to current value (avoid accidental session start)
    if (_sessionStart == null && _isInsideHome == true && currentlyInside == false) {
      // leaving home (start session)
      _startSession();
    } else if (_sessionStart == null && _isInsideHome == true && currentlyInside == true) {
      // still inside; nothing
    } else if (_sessionStart == null && _isInsideHome == false && currentlyInside == false) {
      // previously outside & still outside -> nothing
    } else {
      // Normal change detection
      if (_isInsideHome && !currentlyInside) {
        // left home
        _startSession();
      } else if (!_isInsideHome && currentlyInside) {
        // returned home
        _stopSessionAndPersist();
      }
    }

    // update tracked inside flag
    _isInsideHome = currentlyInside;

    // Update current session duration for UI
    Duration currentDuration = Duration.zero;
    if (_sessionStart != null) {
      currentDuration = DateTime.now().difference(_sessionStart!);
    } else {
      currentDuration = Duration.zero;
    }

    _emit(
      isInside: _isInsideHome,
      currentSessionDuration: currentDuration,
      status: 'Distance to home: ${distance.toStringAsFixed(0)} m',
    );
  }

  // Start a session (user left home)
  void _startSession() {
    if (_sessionStart != null) return; // already started
    _sessionStart = DateTime.now();
    // Start tick timer so UI sees live session duration (every second)
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentDuration = DateTime.now().difference(_sessionStart!);
      _emit(currentSessionDuration: currentDuration, status: 'Outside home (session running)');
    });
    _emit(status: 'Session started');
  }

  // Stop a session, add to total and persist
  Future<void> _stopSessionAndPersist() async {
    if (_sessionStart == null) return;
    final now = DateTime.now();
    final sessionDuration = now.difference(_sessionStart!);
    _totalExposureToday += sessionDuration;

    // persist
    await _persistTotal();

    // clear session
    _sessionStart = null;
    _tickTimer?.cancel();
    _tickTimer = null;

    _emit(isInside: true, currentSessionDuration: Duration.zero, status: 'Returned home; session saved');
  }

  // Emit current state over stream
  void _emit({
    bool? isInside,
    Duration? totalExposure,
    Duration? currentSessionDuration,
    String? status,
  }) {
    final data = ExposureData(
      isInsideHome: isInside ?? _isInsideHome,
      totalExposureToday: totalExposure ?? _totalExposureToday,
      currentSessionDuration: currentSessionDuration ?? (_sessionStart != null ? DateTime.now().difference(_sessionStart!) : Duration.zero),
      status: status ?? (_sessionStart != null ? 'Outside home' : 'At home'),
    );
    if (!_controller.isClosed) _controller.add(data);
  }

  // Persistence helpers
  Future<void> _persistTotal() async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = _totalExposureToday.inSeconds;
    final todayStr = _yyyyMMdd(DateTime.now());
    await prefs.setInt(_prefTotalKey, seconds);
    await prefs.setString(_prefDateKey, todayStr);
  }

  Future<void> _loadPersistedTotal() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_prefDateKey);
    final todayStr = _yyyyMMdd(DateTime.now());
    if (savedDate == null || savedDate != todayStr) {
      // new day — reset
      _totalExposureToday = Duration.zero;
      await prefs.remove(_prefTotalKey);
      await prefs.setString(_prefDateKey, todayStr);
    } else {
      final seconds = prefs.getInt(_prefTotalKey) ?? 0;
      _totalExposureToday = Duration(seconds: seconds);
    }
    // emit initial state
    _emit(status: 'Loaded persisted total');
  }

  static String _yyyyMMdd(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> dispose() async {
    await stopMonitoring();
    await _controller.close();
  }
}
