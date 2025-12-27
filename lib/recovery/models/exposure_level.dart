// lib/recovery/models/exposure_level.dart

import 'dart:ui';

import 'package:flutter/material.dart';

enum ExposureLevel { Low, Moderate, High, Critical }

class ExposureLevelHelper {
  static ExposureLevel fromScore(int score) {
    if (score <= 100) return ExposureLevel.Low;  //100
    if (score <= 300) return ExposureLevel.Moderate; //250
    if (score < 500) return ExposureLevel.High; //400
    return ExposureLevel.Critical;
  }

  static String defaultDoseMessage(ExposureLevel level) {
    switch (level) {
      case ExposureLevel.Low:
        return "Low exposure — breathing exercises recommended";
      case ExposureLevel.Moderate:
        return "Moderate exposure — hydration & light movement";
      case ExposureLevel.High:
        return "High exposure — mask, diet & breathing";
      case ExposureLevel.Critical:
        return "Critical exposure — consult a doctor immediately";
    }
  }

  static Color getLevelColor(ExposureLevel level) {
    switch (level) {
      case ExposureLevel.Low:
        return Colors.green;
      case ExposureLevel.Moderate:
        return Colors.amber;
      case ExposureLevel.High:
        return Colors.orange;
      case ExposureLevel.Critical:
        return Colors.red;
    }
  }

  static String getLevelName(ExposureLevel level) {
    switch (level) {
      case ExposureLevel.Low:
        return "Low";
      case ExposureLevel.Moderate:
        return "Moderate";
      case ExposureLevel.High:
        return "High";
      case ExposureLevel.Critical:
        return "Critical";
    }
  }
}