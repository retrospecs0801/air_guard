// lib/analytics/analytics_module.dart
import 'package:flutter/material.dart';
import 'analytics_screen.dart';

/// Public entry point for the Analytics module
/// Call this from your main.dart or home screen
class AnalyticsModule {
  static Future<void> launch(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AnalyticsScreen(),
      ),
    );
  }
}