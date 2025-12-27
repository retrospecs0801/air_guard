// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:geolocator/geolocator.dart';

import 'services/location_service.dart';
import 'services/storage_service.dart';
import 'services/exposure_service.dart';
import 'services/pollution_service.dart';

import 'recovery/recovery_module.dart';
import 'analytics/analytics_module.dart';
import 'community/community_screen.dart';

void main() {
  runApp(const ExposureApp());
}

class ExposureApp extends StatelessWidget {
  const ExposureApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exposure - Set Home & Auto Counter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final LocationService _loc = LocationService();
  final ExposureService _exposure = ExposureService();
  final PollutionService _pollution = PollutionService();

  Position? _currentPosition;
  double? _homeLat;
  double? _homeLng;
  String _status = 'Idle';

  StreamSubscription<Position>? _posSub;
  StreamSubscription<ExposureData>? _exposureSub;

  // UI state for exposure
  bool _isInside = true;
  Duration _totalExposure = Duration.zero;
  Duration _currentSession = Duration.zero;

  // UI state for pollution
  double? _lastKnownAqi;
  double? _currentAqi;
  double _pollutionDose = 0.0;
  String _doseMessage = 'Low';
  String? _aqiLocationName;

  late AnimationController _pulseController;

  // Add FocusNode for keyboard detection
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _loadHomeAndStart();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _exposureSub?.cancel();
    _exposure.dispose();
    _pulseController.dispose();
    _focusNode.dispose(); // Dispose the focus node
    super.dispose();
  }

  Future<void> _loadHomeAndStart() async {
    final savedDose = await StorageService.loadDose();
    if (mounted) {
      setState(() {
        _pollutionDose = savedDose;
      });
    }

    final home = await StorageService.loadHome();
    if (home != null) {
      _homeLat = home['lat'];
      _homeLng = home['lng'];
    }

    final ok = await _loc.ensurePermission();
    if (!ok) {
      setState(() => _status = 'Location permission missing');
      return;
    }

    _posSub = _loc.positionStream(accuracy: LocationAccuracy.best, distanceFilter: 0)
        .listen((pos) async {
      setState(() {
        _currentPosition = pos;
        _status = 'Location updated';
      });

      if (_currentAqi == null && !_isInside) {
        final aqiResult = await _pollution.getAqiForLocation(pos.latitude, pos.longitude);
        if (!mounted) return;
        setState(() {
          _currentAqi = aqiResult.aqi;
          _lastKnownAqi = aqiResult.aqi;
          _aqiLocationName = aqiResult.locationName;
          _status = aqiResult.status;
        });
      }
    }, onError: (e) {
      setState(() => _status = 'Position stream error: $e');
    });

    await _exposure.startMonitoring();

    if (_homeLat != null && _homeLng != null) {
      await _exposure.setHome(_homeLat!, _homeLng!);
    }

    _exposureSub = _exposure.stream.listen((data) {
      if (!mounted) return;

      final dose = _pollution.calculateDose(data.totalExposureToday, _currentAqi ?? _lastKnownAqi);
      final doseInfo = _pollution.getDoseMessage(dose);

      StorageService.saveDose(dose);

      setState(() {
        _isInside = data.isInsideHome;
        _totalExposure = data.totalExposureToday;
        _currentSession = data.currentSessionDuration;
        _pollutionDose = dose;
        _doseMessage = doseInfo.message;

        if (data.status != _status && data.status.isNotEmpty) {
          _status = data.status;
        }

        if (_isInside) {
          _currentAqi = null;
        }
      });
    });
  }

  // NEW: Handle keyboard input for testing
  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      double? newDose;

      if (event.logicalKey == LogicalKeyboardKey.digit1 || event.logicalKey == LogicalKeyboardKey.numpad1) {
        newDose = 90.0;
      } else if (event.logicalKey == LogicalKeyboardKey.digit2 || event.logicalKey == LogicalKeyboardKey.numpad2) {
        newDose = 250.0;
      } else if (event.logicalKey == LogicalKeyboardKey.digit3 || event.logicalKey == LogicalKeyboardKey.numpad3) {
        newDose = 350.0;
      } else if (event.logicalKey == LogicalKeyboardKey.digit4 || event.logicalKey == LogicalKeyboardKey.numpad4) {
        newDose = 600.0;
      }

      if (newDose != null) {
        final doseInfo = _pollution.getDoseMessage(newDose);
        StorageService.saveDose(newDose);

        setState(() {
          _pollutionDose = newDose!;
          _doseMessage = doseInfo.message;
          _status = 'Testing mode: Dose set to ${newDose.toInt()}';
        });
      }
    }
  }

  Future<void> _setHomeToCurrentLocation() async {
    setState(() => _status = 'Requesting current location...');
    try {
      final pos = await _loc.getCurrentPosition();
      await StorageService.saveHome(pos.latitude, pos.longitude);
      setState(() {
        _homeLat = pos.latitude;
        _homeLng = pos.longitude;
      });

      await _exposure.setHome(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() => _status = 'Failed to set home: $e');
    }
  }

  Future<void> _clearHome() async {
    await StorageService.clearHome();
    await _exposure.clearHome();
    await StorageService.saveDose(0.0);

    setState(() {
      _homeLat = null;
      _homeLng = null;
      _status = 'Home cleared';
      _totalExposure = Duration.zero;
      _currentSession = Duration.zero;
      _pollutionDose = 0.0;
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } else {
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
  }

  String _homeText() {
    if (_homeLat == null || _homeLng == null) return 'Not Set';
    return '${_homeLat!.toStringAsFixed(4)}, ${_homeLng!.toStringAsFixed(4)}';
  }

  String _currentLocationText() {
    if (_currentPosition == null) return 'Waiting for location...';
    return '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
  }

  String _distanceToHomeText() {
    if (_isInside) {
      return 'At Home';
    }

    if (_homeLat == null || _homeLng == null || _currentPosition == null) {
      return '-- m';
    }

    final distance = _loc.distanceBetween(
      _homeLat!,
      _homeLng!,
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    if (distance > 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }

    return '${distance.toStringAsFixed(0)} m';
  }

  Map<String, dynamic> _getTheme() {
    switch (_doseMessage) {
      case 'Low':
        return {
          'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
          'iconColor': const Color(0xFF10b981),
          'icon': Icons.check_circle_rounded,
        };
      case 'Moderate':
        return {
          'gradient': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
          'iconColor': const Color(0xFFf59e0b),
          'icon': Icons.warning_rounded,
        };
      case 'High':
        return {
          'gradient': [const Color(0xFFfa709a), const Color(0xFFfee140)],
          'iconColor': const Color(0xFFef4444),
          'icon': Icons.error_rounded,
        };
      case 'Critical':
        return {
          'gradient': [const Color(0xFFeb3349), const Color(0xFFf45c43)],
          'iconColor': const Color(0xFFdc2626),
          'icon': Icons.dangerous_rounded,
        };
      default:
        return {
          'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
          'iconColor': const Color(0xFF10b981),
          'icon': Icons.check_circle_rounded,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getTheme();
    final gradientColors = theme['gradient'] as List<Color>;

    // Wrap the entire Scaffold with KeyboardListener
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Header
                    const SizedBox(height: 20),
                    const Text(
                      'Pollution Exposure',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Main Exposure Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Big Exposure Indicator with animated icon
                              FadeTransition(
                                opacity: _pulseController,
                                child: Icon(
                                  theme['icon'],
                                  size: 100,
                                  color: theme['iconColor'],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _doseMessage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Exposure Level',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Divider
                              Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 30),

                              // Exposure Score
                              Row(
                                children: [
                                  Icon(Icons.cloud, color: Colors.white.withOpacity(0.8), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Exposure Score',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _pollutionDose.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: (_pollutionDose / 500).clamp(0.0, 1.0),
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Time Spent
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.hourglass_bottom_rounded, color: Colors.white.withOpacity(0.8), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Time Exposed Today',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _formatDuration(_totalExposure),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Current Session
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.directions_walk_rounded, color: Colors.white.withOpacity(0.8), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Current Session',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _formatDuration(_currentSession),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Distance to Home
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.home_work_rounded, color: Colors.white.withOpacity(0.8), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Distance to Home',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _distanceToHomeText(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // AQI Info Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, color: Colors.white.withOpacity(0.9), size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AQI from: ${_aqiLocationName ?? "..."}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_lastKnownAqi?.round() ?? "--"} US AQI',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Status indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_tethering, color: Colors.white.withOpacity(0.7), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Real-time monitoring active',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _setHomeToCurrentLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: gradientColors[0],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.my_location),
                              label: const Text(
                                'Set Home Here',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (_homeLat != null && _homeLng != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _clearHome,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text(
                                  'Clear Home',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            _status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Recovery Button Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.healing, color: Colors.white.withOpacity(0.9), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Recovery Plan',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                RecoveryModule.launch(
                                  context,
                                  pollutionDose: _pollutionDose.toInt(),
                                  doseMessage: _doseMessage,
                                );
                              },
                              icon: const Icon(Icons.healing),
                              label: const Text(
                                'Generate Recovery',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Analytics Button Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics_outlined, color: Colors.white.withOpacity(0.9), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Insights & Trends',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => AnalyticsModule.launch(context),
                              icon: const Icon(Icons.analytics_outlined),
                              label: const Text(
                                'View Analytics',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Community Button Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people, color: Colors.white.withOpacity(0.9), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Community Forum',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CommunityScreen()),
                                );
                              },
                              icon: const Icon(Icons.people),
                              label: const Text(
                                'Join Community',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}