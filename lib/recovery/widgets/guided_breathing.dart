// lib/recovery/widgets/guided_breathing.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/recovery_task.dart';

class GuidedBreathingScreen extends StatefulWidget {
  final RecoveryTask task;
  final VoidCallback onComplete;

  const GuidedBreathingScreen({
    Key? key,
    required this.task,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<GuidedBreathingScreen> createState() => _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends State<GuidedBreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  int _remainingSeconds = 0;
  String _currentPhase = 'Inhale';
  bool _isRunning = false;

  final List<Map<String, dynamic>> _breathingCycle = [
    {'phase': 'Inhale', 'duration': 4},
    {'phase': 'Hold', 'duration': 4},
    {'phase': 'Exhale', 'duration': 4},
    {'phase': 'Hold', 'duration': 4},
  ];

  int _currentCycleIndex = 0;
  int _cyclesCompleted = 0;
  final int _totalCycles = 4;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.task.durationSeconds;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _startBreathing() {
    setState(() {
      _isRunning = true;
    });
    _runBreathingCycle();
  }

  void _runBreathingCycle() {
    final cycle = _breathingCycle[_currentCycleIndex];
    setState(() {
      _currentPhase = cycle['phase'];
    });

    // Animate based on phase
    if (cycle['phase'] == 'Inhale') {
      _animationController.forward();
    } else if (cycle['phase'] == 'Exhale') {
      _animationController.reverse();
    }

    // Move to next phase after duration
    // MODIFICATION: Explicitly cast cycle['duration'] to an int to fix the type error.
    _timer = Timer(Duration(seconds: cycle['duration'] as int), () {
      if (!mounted) return;

      setState(() {
        _currentCycleIndex = (_currentCycleIndex + 1) % _breathingCycle.length;
        // MODIFICATION: Also cast here to ensure type safety.
        _remainingSeconds -= cycle['duration'] as int;

        if (_currentCycleIndex == 0) {
          _cyclesCompleted++;
        }

        if (_cyclesCompleted >= _totalCycles || _remainingSeconds <= 0) {
          _completeExercise();
        } else {
          _runBreathingCycle();
        }
      });
    });
  }

  void _completeExercise() {
    _timer?.cancel();
    _animationController.stop();

    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Great Work!'),
          ],
        ),
        content: const Text(
          'You completed the breathing exercise. Deep breathing helps clear your airways and reduces pollution effects.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onComplete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _pauseBreathing() {
    _timer?.cancel();
    _animationController.stop();
    setState(() {
      _isRunning = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text(widget.task.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Circle
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Container(
                  width: 200 * _scaleAnimation.value,
                  height: 200 * _scaleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 40 * _scaleAnimation.value,
                        spreadRadius: 10 * _scaleAnimation.value,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _currentPhase,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 60),

            // Instructions
            Text(
              _isRunning ? 'Follow the circle' : widget.task.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Cycle Counter
            if (_isRunning)
              Text(
                'Cycle ${_cyclesCompleted + 1}/$_totalCycles',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            const SizedBox(height: 40),

            // Control Buttons
            if (!_isRunning)
              ElevatedButton.icon(
                onPressed: _startBreathing,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text(
                  'Start',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pauseBreathing,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _completeExercise,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
