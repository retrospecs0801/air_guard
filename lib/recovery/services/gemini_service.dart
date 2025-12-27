// lib/recovery/services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // PUT YOUR GEMINI API KEY HERE
  static const String _apiKey = 'AIzaSyBkzYxIGc8wia4JALLx7hSWtrriz0_H83E33';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // Fallback messages if API fails
  static final Map<String, String> _fallbackInsights = {
    'Low':
    'Great work! Your breathing exercises help calm airways and reduce the immediate effects of pollutants.',
    'Moderate':
    'Well done! Hydration and movement support your body\'s recovery from pollution exposure today.',
    'High':
    'Good progress! Combining mask use and dietary choices helps lower your pollution burden. Stay cautious.',
    'Critical':
    'Your score indicates medical advice is recommended. Please contact a healthcare provider if you feel unwell.',
  };

  // EXISTING METHOD - UNCHANGED
  static Future<String> generateInsight({
    required String exposureLevel,
    required int score,
    required List<String> completedTasks,
  }) async {
    try {
      // Build the prompt
      final prompt = '''You are a friendly health-assistant copywriter. Generate a concise 2-3 sentence encouraging insight for a user who just completed these recovery tasks:
- exposure_level: $exposureLevel
- score: $score
- tasks_completed: ${completedTasks.join(', ')}

Tone: encouraging, factual, non-medical (except for Critical where advise to see doctor).
Limit: 2-3 sentences, plain language, ≤40 words.''';

      final response = await http
          .post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.isNotEmpty) {
          return text.trim();
        }
      }

      // If API fails, return fallback
      return _fallbackInsights[exposureLevel] ?? _fallbackInsights['Low']!;
    } catch (e) {
      print('Gemini API error: $e');
      // Return fallback on any error
      return _fallbackInsights[exposureLevel] ?? _fallbackInsights['Low']!;
    }
  }

  // ==================== NEW METHODS FOR ANALYTICS ====================

  /// Generate weekly analytics insight with actionable recommendations
  static Future<String> generateWeeklyAnalytics({
    required int averageScore,
    required String trend,
    required int comparisonPercentage,
    required int worstDayScore,
    required String worstDayName,
    required String dailyScores,
  }) async {
    try {
      final prompt = '''Analyze weekly pollution exposure data and provide actionable insight:

Data: $dailyScores
Avg: $averageScore, Trend: $trend (+$comparisonPercentage%), Worst: $worstDayName ($worstDayScore)
Today: Friday, Weekend coming

Generate 2-3 sentences with:
1. Severity assessment and trend
2. Weekend advice
3. Bullet points with actionable recommendations (use • for bullets, include emojis)

Format recommendations as:
• 😷 [specific action]
• 🏠 [specific action]
• 💨 [specific action]

Max 60 words total.''';

      final response = await http
          .post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.isNotEmpty) {
          return text.trim();
        }
      }

      return _getFallbackWeeklyInsight(averageScore, comparisonPercentage);
    } catch (e) {
      print('Gemini API error (weekly): $e');
      return _getFallbackWeeklyInsight(averageScore, comparisonPercentage);
    }
  }

  /// Generate monthly analytics insight with long-term recommendations
  static Future<String> generateMonthlyAnalytics({
    required int averageScore,
    required String trend,
    required int comparisonPercentage,
    required String weeklyBreakdown,
  }) async {
    try {
      final prompt = '''Analyze monthly pollution exposure trend and provide actionable insight:

30-day avg: $averageScore, Trend: $trend (+$comparisonPercentage%)
Weekly: $weeklyBreakdown

Generate 2-3 sentences with:
1. Monthly pattern analysis
2. Long-term health impact
3. Bullet points with lifestyle recommendations (use • for bullets, include emojis)

Format recommendations as:
• 🏢 [lifestyle change]
• ⏰ [timing advice]
• 💨 [home improvement]

Max 70 words total.''';

      final response = await http
          .post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.isNotEmpty) {
          return text.trim();
        }
      }

      return _getFallbackMonthlyInsight(averageScore, comparisonPercentage);
    } catch (e) {
      print('Gemini API error (monthly): $e');
      return _getFallbackMonthlyInsight(averageScore, comparisonPercentage);
    }
  }

  // ==================== FALLBACK MESSAGES ====================

  static String _getFallbackWeeklyInsight(int avg, int comparison) {
    if (avg >= 300) {
      return '''⚠️ High exposure alert! Your pollution exposure averaged $avg this week (+$comparison% vs last week).

Recommendations:
• 🏠 Cancel outdoor weekend plans and stay indoors
• 😷 Wear N95 masks for essential outings only
• 💨 Run air purifiers on high setting
• 🛒 Order groceries online instead of shopping''';
    } else if (avg >= 200) {
      return '''⚠️ Your exposure averaged $avg this week (+$comparison% increase).

Recommendations:
• ⏰ Avoid outdoor activities during peak hours
• 😷 Wear masks in crowded areas
• 💧 Stay well hydrated throughout the day
• 🌳 Choose routes with more greenery''';
    } else if (avg >= 100) {
      return '''ℹ️ Moderate exposure this week (avg: $avg).

Recommendations:
• ✅ Continue monitoring air quality
• 🚶 Light outdoor exercise is acceptable
• 🌤️ Check AQI before planning activities''';
    } else {
      return '''✅ Good news! Your exposure is low this week (avg: $avg).

Recommendations:
• 🏃 Enjoy outdoor activities safely
• 🌳 Good time for exercise outdoors
• ✅ Maintain current habits''';
    }
  }

  static String _getFallbackMonthlyInsight(int avg, int comparison) {
    if (avg >= 300) {
      return '''📈 Monthly exposure averaged $avg (+$comparison% vs last month). Pattern shows consistent increase.

Recommendations:
• 🏢 Work remotely when possible
• ⏰ Avoid peak traffic hours (7-9am, 5-7pm)
• 💨 Invest in HEPA air purifiers for home
• 🍎 Include anti-inflammatory foods in diet''';
    } else if (avg >= 200) {
      return '''📈 Your monthly exposure is $avg (+$comparison% increase).

Recommendations:
• 🚗 Carpool or use public transit off-peak
• 💨 Consider air quality when planning activities
• 🏠 Improve indoor air quality
• 📱 Use AQI monitoring apps regularly''';
    } else if (avg >= 100) {
      return '''ℹ️ Monthly exposure: $avg (moderate level).

Recommendations:
• ✅ Continue current precautions
• 📊 Monitor trends weekly
• 🌳 Spend time in green spaces when possible''';
    } else {
      return '''✅ Excellent! Monthly exposure is low (avg: $avg).

Recommendations:
• 🏃 Maintain active outdoor lifestyle
• 🌱 Continue healthy habits
• 📊 Keep tracking for awareness''';
    }
  }
}