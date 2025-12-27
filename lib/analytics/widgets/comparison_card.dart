// lib/analytics/widgets/comparison_card.dart
import 'package:flutter/material.dart';
import '../models/analytics_data.dart';

/// Shows comparison with previous period
class ComparisonCard extends StatelessWidget {
  final AnalyticsPeriod data;
  final String currentPeriod; // "This Week" or "This Month"
  final String previousPeriod; // "Last Week" or "Last Month"

  const ComparisonCard({
    Key? key,
    required this.data,
    required this.currentPeriod,
    required this.previousPeriod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWorse = data.comparisonPercentage > 0;
    final color = isWorse ? Colors.red : Colors.green;
    final icon = isWorse ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentPeriod vs $previousPeriod',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                    children: [
                      TextSpan(
                        text: '${data.comparisonPercentage.abs().round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 20,
                        ),
                      ),
                      TextSpan(
                        text: isWorse ? ' worse' : ' better',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Average: ${data.averageScore.round()} (${data.trend})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}