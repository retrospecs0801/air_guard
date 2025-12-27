// lib/recovery/widgets/task_card.dart
import 'package:flutter/material.dart';
import '../models/recovery_task.dart';
import 'guided_breathing.dart';

class TaskCard extends StatelessWidget {
  final RecoveryTask task;
  final VoidCallback onComplete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onComplete,
  }) : super(key: key);

  void _handleStart(BuildContext context) {
    if (task.type == TaskType.breathing) {
      // Open guided breathing screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GuidedBreathingScreen(
            task: task,
            onComplete: onComplete,
          ),
        ),
      );
    } else {
      // For non-breathing tasks, show simple confirmation dialog
      _showTaskDialog(context);
    }
  }

  void _showTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(task.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            if (task.type == TaskType.doctorCTA) ...[
              const SizedBox(height: 16),
              const Text(
                'Your exposure score suggests medical advice is recommended. Please contact a healthcare professional if you feel unwell.',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (task.type == TaskType.doctorCTA)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Here you could add actual phone dialer or teleconsult link
                onComplete();
              },
              child: const Text('Contact Doctor'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onComplete();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: task.isCompleted ? 0 : 2,
      color: task.isCompleted ? Colors.grey[100] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: task.isCompleted
            ? BorderSide(color: Colors.green[300]!, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? Colors.green[100]
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: task.isCompleted
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                    : Text(task.icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),

            // Task Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (task.durationSeconds > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${task.durationSeconds}s',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Action Button
            if (!task.isCompleted)
              ElevatedButton(
                onPressed: () => _handleStart(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Start'),
              ),
          ],
        ),
      ),
    );
  }
}