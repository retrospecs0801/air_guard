// lib/recovery/recovery_screen.dart
import 'package:flutter/material.dart';
import 'models/exposure_level.dart';
import 'models/recovery_task.dart';
import 'widgets/task_card.dart';
import 'widgets/completion_screen.dart';
import 'services/gemini_service.dart';

class RecoveryScreen extends StatefulWidget {
  final int pollutionDose;
  final String doseMessage;

  const RecoveryScreen({
    Key? key,
    required this.pollutionDose,
    required this.doseMessage,
  }) : super(key: key);

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  late ExposureLevel exposureLevel;
  late List<RecoveryTask> tasks;
  bool isRecoveryStarted = false;

  @override
  void initState() {
    super.initState();
    exposureLevel = ExposureLevelHelper.fromScore(widget.pollutionDose);
    tasks = RecoveryTask.getTasksForLevel(
      ExposureLevelHelper.getLevelName(exposureLevel),
    );
  }

  int get completedTasksCount => tasks.where((t) => t.isCompleted).length;
  bool get allTasksCompleted =>
      tasks.isNotEmpty && tasks.every((t) => t.isCompleted);

  void _startRecovery() {
    setState(() {
      isRecoveryStarted = true;
    });
  }

  Future<void> _completeRecovery() async {
    // Generate insight message
    final levelName = ExposureLevelHelper.getLevelName(exposureLevel);
    final completedTaskTitles =
    tasks.where((t) => t.isCompleted).map((t) => t.title).toList();

    final insight = await GeminiService.generateInsight(
      exposureLevel: levelName,
      score: widget.pollutionDose,
      completedTasks: completedTaskTitles,
    );

    if (!mounted) return;

    // Navigate to completion screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CompletionScreen(
          exposureLevel: levelName,
          insight: insight,
          completedTasks: completedTaskTitles,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = ExposureLevelHelper.getLevelColor(exposureLevel);
    final levelName = ExposureLevelHelper.getLevelName(exposureLevel);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Recovery Plan'),
        backgroundColor: levelColor.withOpacity(0.1),
        foregroundColor: levelColor,
        elevation: 0,
      ),
      body: !isRecoveryStarted ? _buildSummaryScreen(levelColor, levelName) : _buildTaskList(),
    );
  }

  Widget _buildSummaryScreen(Color levelColor, String levelName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Level Badge
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: levelColor.withOpacity(0.2),
              border: Border.all(color: levelColor, width: 4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  levelName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Exposure',
                  style: TextStyle(
                    fontSize: 14,
                    color: levelColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Score Display
          Text(
            'Exposure Score: ${widget.pollutionDose}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.doseMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Goal Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.eco, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reverse effects of pollution you consumed today',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Task Preview
          Text(
            '${tasks.length} Recovery Tasks',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: tasks.map((task) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(task.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      task.title,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Start Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _startRecovery,
              style: ElevatedButton.styleFrom(
                backgroundColor: levelColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Recovery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return Column(
      children: [
        // Progress Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Recovery Tasks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$completedTasksCount/${tasks.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: tasks.isEmpty ? 0 : completedTasksCount / tasks.length,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),

        // Task Cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                onComplete: () {
                  setState(() {
                    task.isCompleted = true;
                  });
                  if (allTasksCompleted) {
                    _completeRecovery();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}