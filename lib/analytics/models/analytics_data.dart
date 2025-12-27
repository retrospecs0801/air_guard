// lib/analytics/models/analytics_data.dart
import 'package:flutter/material.dart';

/// Represents daily exposure data
class DailyExposure {
  final DateTime date;
  final int score;
  final String dayName;
  final bool isToday;

  DailyExposure({
    required this.date,
    required this.score,
    required this.dayName,
    this.isToday = false,
  });

  /// Get color based on exposure level
  Color get color {
    if (score <= 100) return Colors.green;
    if (score <= 250) return Colors.amber;
    if (score <= 400) return Colors.orange;
    return Colors.red;
  }

  /// Get exposure level name
  String get levelName {
    if (score <= 100) return 'Low';
    if (score <= 250) return 'Moderate';
    if (score <= 400) return 'High';
    return 'Critical';
  }
}

/// Represents a period of analytics (weekly or monthly)
class AnalyticsPeriod {
  final List<DailyExposure> data;
  final String insight;
  final double averageScore;
  final String trend; // "increasing", "decreasing", "stable"
  final int worstDayScore;
  final String worstDayName;
  final int safeDaysCount;
  final double comparisonPercentage; // vs previous period

  AnalyticsPeriod({
    required this.data,
    required this.insight,
    required this.averageScore,
    required this.trend,
    required this.worstDayScore,
    required this.worstDayName,
    required this.safeDaysCount,
    required this.comparisonPercentage,
  });

  IconData get trendIcon {
    if (trend == 'increasing') return Icons.trending_up;
    if (trend == 'decreasing') return Icons.trending_down;
    return Icons.trending_flat;
  }

  Color get trendColor {
    if (trend == 'increasing') return Colors.red;
    if (trend == 'decreasing') return Colors.green;
    return Colors.grey;
  }
}

/// Mock data generator for demonstration
class MockAnalyticsData {
  /// Generate weekly data (last 7 days)
  static AnalyticsPeriod getWeeklyData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Mock: Current day is Friday
    final friday = today.subtract(Duration(days: today.weekday - 5));

    final List<DailyExposure> weekData = [
      DailyExposure(
        date: friday.subtract(const Duration(days: 4)),
        score: 280,
        dayName: 'Mon',
      ),
      DailyExposure(
        date: friday.subtract(const Duration(days: 3)),
        score: 310,
        dayName: 'Tue',
      ),
      DailyExposure(
        date: friday.subtract(const Duration(days: 2)),
        score: 350,
        dayName: 'Wed',
      ),
      DailyExposure(
        date: friday.subtract(const Duration(days: 1)),
        score: 380,
        dayName: 'Thu',
      ),
      DailyExposure(
        date: friday,
        score: 390,
        dayName: 'Fri',
        isToday: true,
      ),
      // Future days (no data)
    ];

    final avgScore = weekData.map((e) => e.score).reduce((a, b) => a + b) / weekData.length;
    final worstDay = weekData.reduce((a, b) => a.score > b.score ? a : b);

    return AnalyticsPeriod(
      data: weekData,
      insight: 'High exposure alert detected',
      averageScore: avgScore,
      trend: 'increasing',
      worstDayScore: worstDay.score,
      worstDayName: worstDay.dayName,
      safeDaysCount: 0, // No safe days (all > 250)
      comparisonPercentage: 39, // +39% vs last week
    );
  }

  /// Generate monthly data (last 30 days)
  static AnalyticsPeriod getMonthlyData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<DailyExposure> monthData = [];

    // Generate 30 days of data with increasing trend
    for (int i = 29; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);

      // Create increasing trend: starting from 250 to 390
      // Week 1: 250-270
      // Week 2: 280-300
      // Week 3: 310-340
      // Week 4: 350-380
      // Week 5 (partial): 385-390

      int score;
      if (i >= 23) {
        // Week 1 (days 30-24 ago)
        score = 250 + (i % 7) * 3;
      } else if (i >= 16) {
        // Week 2 (days 23-17 ago)
        score = 280 + (i % 7) * 3;
      } else if (i >= 9) {
        // Week 3 (days 16-10 ago)
        score = 310 + (i % 7) * 5;
      } else if (i >= 2) {
        // Week 4 (days 9-3 ago)
        score = 350 + (i % 7) * 5;
      } else {
        // Week 5 (last 2 days)
        score = 385 + (2 - i) * 5;
      }

      monthData.add(DailyExposure(
        date: date,
        score: score,
        dayName: dayName,
        isToday: i == 0,
      ));
    }

    final avgScore = monthData.map((e) => e.score).reduce((a, b) => a + b) / monthData.length;
    final worstDay = monthData.reduce((a, b) => a.score > b.score ? a : b);
    final safeDays = monthData.where((e) => e.score <= 100).length;

    return AnalyticsPeriod(
      data: monthData,
      insight: 'Increasing trend detected',
      averageScore: avgScore,
      trend: 'increasing',
      worstDayScore: worstDay.score,
      worstDayName: worstDay.dayName,
      safeDaysCount: safeDays,
      comparisonPercentage: 28, // +28% vs last month
    );
  }

  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}