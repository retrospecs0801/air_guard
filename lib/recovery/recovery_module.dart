// lib/recovery/recovery_module.dart
import 'package:flutter/material.dart';
import 'recovery_screen.dart';

/// Public entry point for the Recovery module
/// Call this from your main.dart or home screen
class RecoveryModule {
  static Future<void> launch(
      BuildContext context, {
        required int pollutionDose,
        required String doseMessage,
      }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecoveryScreen(
          pollutionDose: pollutionDose,
          doseMessage: doseMessage,
        ),
      ),
    );
  }
}