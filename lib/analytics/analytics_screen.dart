// lib/analytics/analytics_screen.dart
import 'package:flutter/material.dart';
import 'models/analytics_data.dart';
import 'services/analytics_insight_service.dart';
import 'widgets/stats_cards.dart';
import 'widgets/weekly_chart.dart';
import 'widgets/monthly_chart.dart';
import 'widgets/insight_card.dart';
import 'widgets/comparison_card.dart';
import 'widgets/insight_skeleton.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsPeriod weeklyData;
  late AnalyticsPeriod monthlyData;
  late List<String> recommendations;

  // AI-generated insights
  String? weeklyInsight;
  String? monthlyInsight;

  // Loading states
  bool _isLoadingWeeklyInsight = true;
  bool _isLoadingMonthlyInsight = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadInsights();
  }

  void _loadData() {
    // Load mock data immediately (synchronous)
    weeklyData = MockAnalyticsData.getWeeklyData();
    monthlyData = MockAnalyticsData.getMonthlyData();
    recommendations = AnalyticsInsightService.getRecommendations(weeklyData);
  }

  Future<void> _loadInsights() async {
    // Load both insights in parallel for better performance
    final results = await Future.wait([
      AnalyticsInsightService.getWeeklyInsight(weeklyData),
      AnalyticsInsightService.getMonthlyInsight(monthlyData),
    ]);

    if (mounted) {
      setState(() {
        weeklyInsight = results[0];
        monthlyInsight = results[1];
        _isLoadingWeeklyInsight = false;
        _isLoadingMonthlyInsight = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.purple.withOpacity(0.1),
        foregroundColor: Colors.purple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly Section Header
            _buildSectionHeader(
              icon: Icons.calendar_view_week,
              title: 'This Week',
              subtitle: 'Last 7 days overview',
            ),
            const SizedBox(height: 16),

            // Weekly Stats
            StatsCards(data: weeklyData, period: 'week'),
            const SizedBox(height: 16),

            // Weekly Comparison
            ComparisonCard(
              data: weeklyData,
              currentPeriod: 'This Week',
              previousPeriod: 'Last Week',
            ),
            const SizedBox(height: 16),

            // Weekly Chart
            WeeklyChart(data: weeklyData),
            const SizedBox(height: 16),

            // Weekly Insight - with loading state
            _isLoadingWeeklyInsight
                ? const InsightSkeleton(accentColor: Colors.orange)
                : InsightCard(
              insight: weeklyInsight!,
              recommendations: recommendations,
              accentColor: Colors.orange,
            ),
            const SizedBox(height: 32),

            // Monthly Section Divider
            const Divider(thickness: 2, height: 32),
            const SizedBox(height: 16),

            // Monthly Section Header
            _buildSectionHeader(
              icon: Icons.calendar_month,
              title: 'This Month',
              subtitle: 'Last 30 days trends',
            ),
            const SizedBox(height: 16),

            // Monthly Stats
            StatsCards(data: monthlyData, period: 'month'),
            const SizedBox(height: 16),

            // Monthly Comparison
            ComparisonCard(
              data: monthlyData,
              currentPeriod: 'This Month',
              previousPeriod: 'Last Month',
            ),
            const SizedBox(height: 16),

            // Monthly Chart
            MonthlyChart(data: monthlyData),
            const SizedBox(height: 16),

            // Monthly Insight - with loading state
            _isLoadingMonthlyInsight
                ? const InsightSkeleton(accentColor: Colors.purple)
                : InsightCard(
              insight: monthlyInsight!,
              accentColor: Colors.purple,
            ),
            const SizedBox(height: 24),

            // Disclaimer
            _buildDisclaimer(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.purple, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ℹ️ This is mock data for demonstration purposes. '
                  'In production, analytics will use actual exposure data from your device\'s local storage. '
                  'AI insights are generated in real-time by Gemini.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.purple),
            SizedBox(width: 12),
            Text('About Analytics'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This analytics dashboard helps you understand your pollution exposure patterns over time.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Weekly and monthly exposure charts'),
              Text('• Real-time AI-powered insights (Gemini)'),
              Text('• Actionable recommendations'),
              Text('• Trend analysis and comparisons'),
              Text('• Color-coded exposure levels'),
              SizedBox(height: 12),
              Text(
                'Note: This MVP uses mock data. AI insights are generated in real-time. Production version will track your actual daily exposure.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}