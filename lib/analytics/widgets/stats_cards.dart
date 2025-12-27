// lib/analytics/widgets/stats_cards.dart
import 'package:flutter/material.dart';
import '../models/analytics_data.dart';

/// Quick stats overview cards
class StatsCards extends StatelessWidget {
  final AnalyticsPeriod data;
  final String period; // "week" or "month"

  const StatsCards({
    Key? key,
    required this.data,
    required this.period,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.speed,
            label: 'Average',
            value: data.averageScore.round().toString(),
            color: _getColorForScore(data.averageScore.round()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.warning_amber,
            label: 'Worst Day',
            value: '${data.worstDayScore}',
            subtitle: data.worstDayName,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: data.trendIcon,
            label: 'Trend',
            value: '${data.comparisonPercentage.abs().round()}%',
            subtitle: data.trend,
            color: data.trendColor,
          ),
        ),
      ],
    );
  }

  Color _getColorForScore(int score) {
    if (score <= 100) return Colors.green;
    if (score <= 250) return Colors.amber;
    if (score <= 400) return Colors.orange;
    return Colors.red;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}