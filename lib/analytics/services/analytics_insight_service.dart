// lib/analytics/services/analytics_insight_service.dart
import '../../recovery/services/gemini_service.dart';
import '../models/analytics_data.dart';

/// Service for generating AI-powered analytics insights
/// Uses Gemini API with fallback to default messages
class AnalyticsInsightService {
  /// Generate weekly insight with AI
  static Future<String> getWeeklyInsight(AnalyticsPeriod data) async {
    // Format daily scores for prompt
    final dailyScores = data.data
        .map((d) => '${d.dayName}:${d.score}')
        .join(', ');

    try {
      final insight = await GeminiService.generateWeeklyAnalytics(
        averageScore: data.averageScore.round(),
        trend: data.trend,
        comparisonPercentage: data.comparisonPercentage.abs().round(),
        worstDayScore: data.worstDayScore,
        worstDayName: data.worstDayName,
        dailyScores: dailyScores,
      );
      return insight;
    } catch (e) {
      print('Weekly insight generation failed: $e');
      // Fallback is already handled in GeminiService
      rethrow;
    }
  }

  /// Generate monthly insight with AI
  static Future<String> getMonthlyInsight(AnalyticsPeriod data) async {
    // Calculate weekly breakdown for prompt
    final weeklyBreakdown = _calculateWeeklyBreakdown(data);

    try {
      final insight = await GeminiService.generateMonthlyAnalytics(
        averageScore: data.averageScore.round(),
        trend: data.trend,
        comparisonPercentage: data.comparisonPercentage.abs().round(),
        weeklyBreakdown: weeklyBreakdown,
      );
      return insight;
    } catch (e) {
      print('Monthly insight generation failed: $e');
      // Fallback is already handled in GeminiService
      rethrow;
    }
  }

  /// Generate actionable recommendations based on exposure level
  /// These are shown separately from AI insights
  static List<String> getRecommendations(AnalyticsPeriod weeklyData) {
    final avg = weeklyData.averageScore.round();

    if (avg >= 300) {
      return [
        '🏠 Stay indoors this weekend',
        '🛒 Order groceries online instead of shopping',
        '💨 Run air purifiers on high setting',
        '😷 Keep N95 masks ready if you must go out',
        '🧘 Schedule indoor activities and exercise',
      ];
    } else if (avg >= 200) {
      return [
        '⏰ Avoid outdoor activities during peak hours',
        '😷 Wear masks in crowded areas',
        '🌳 Choose routes with more greenery',
        '💧 Stay hydrated to help your body recover',
      ];
    } else if (avg >= 100) {
      return [
        '✅ Continue monitoring air quality',
        '🚶 Light outdoor exercise is okay',
        '🌤️ Check AQI before planning outdoor activities',
      ];
    } else {
      return [
        '✅ Air quality is good',
        '🏃 Enjoy outdoor activities',
        '🌳 Good time for exercise outdoors',
      ];
    }
  }

  /// Helper to calculate weekly breakdown string for monthly prompt
  static String _calculateWeeklyBreakdown(AnalyticsPeriod data) {
    final weeklyAvgs = <String>[];

    for (int i = 0; i < data.data.length; i += 7) {
      final weekData = data.data.skip(i).take(7).toList();
      if (weekData.isNotEmpty) {
        final avg = weekData.map((e) => e.score).reduce((a, b) => a + b) / weekData.length;
        final weekNum = (i ~/ 7) + 1;
        weeklyAvgs.add('Week$weekNum:${avg.round()}');
      }
    }

    return weeklyAvgs.join(', ');
  }
}