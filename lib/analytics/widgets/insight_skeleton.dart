// lib/analytics/widgets/insight_skeleton.dart
import 'package:flutter/material.dart';

/// Skeleton loader for insight cards while AI generates content
class InsightSkeleton extends StatefulWidget {
  final Color accentColor;

  const InsightSkeleton({
    Key? key,
    this.accentColor = Colors.blue,
  }) : super(key: key);

  @override
  State<InsightSkeleton> createState() => _InsightSkeletonState();
}

class _InsightSkeletonState extends State<InsightSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accentColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.lightbulb, color: widget.accentColor, size: 28),
              const SizedBox(width: 12),
              const Text(
                'AI Insight',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Generating text
          Row(
            children: [
              Icon(Icons.auto_awesome, color: widget.accentColor.withOpacity(0.6), size: 16),
              const SizedBox(width: 8),
              Text(
                'Generating insight...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Shimmer lines
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerLine(width: double.infinity, opacity: 0.8),
                  const SizedBox(height: 10),
                  _buildShimmerLine(width: double.infinity, opacity: 0.7),
                  const SizedBox(height: 10),
                  _buildShimmerLine(width: 250, opacity: 0.6),
                  const SizedBox(height: 20),

                  // Recommendations section
                  Text(
                    'Recommendations:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildShimmerBullet(),
                  const SizedBox(height: 8),
                  _buildShimmerBullet(),
                  const SizedBox(height: 8),
                  _buildShimmerBullet(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLine({required double width, required double opacity}) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey[300]!.withOpacity(opacity),
            Colors.grey[100]!.withOpacity(opacity),
            Colors.grey[300]!.withOpacity(opacity),
          ],
          stops: [
            _shimmerAnimation.value - 0.3,
            _shimmerAnimation.value,
            _shimmerAnimation.value + 0.3,
          ].map((e) => e.clamp(0.0, 1.0)).toList(),
        ),
      ),
    );
  }

  Widget _buildShimmerBullet() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 14,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Expanded(
          child: _buildShimmerLine(width: double.infinity, opacity: 0.6),
        ),
      ],
    );
  }
}