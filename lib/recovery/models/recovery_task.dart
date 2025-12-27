// lib/recovery/models/recovery_task.dart

enum TaskType { breathing, hydration, stretch, mask, diet, doctorCTA }

class RecoveryTask {
  final String id;
  final TaskType type;
  final String title;
  final String description;
  final int durationSeconds;
  final String icon;
  bool isCompleted;

  RecoveryTask({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.durationSeconds,
    required this.icon,
    this.isCompleted = false,
  });

  // Factory to create tasks based on exposure level
  static List<RecoveryTask> getTasksForLevel(String levelName) {
    switch (levelName) {
      case "Low":
        return [
          RecoveryTask(
            id: 'breathing_1',
            type: TaskType.breathing,
            title: 'Box Breathing',
            description: 'Inhale 4s — Hold 4s — Exhale 4s — Hold 4s',
            durationSeconds: 60,
            icon: '🫁',
          ),
          RecoveryTask(
            id: 'breathing_2',
            type: TaskType.breathing,
            title: 'Deep Breathing',
            description: 'Slow diaphragmatic breathing to clear airways',
            durationSeconds: 90,
            icon: '💨',
          ),
        ];

      case "Moderate":
        return [
          RecoveryTask(
            id: 'hydration',
            type: TaskType.hydration,
            title: 'Hydrate',
            description: 'Drink 300ml water slowly',
            durationSeconds: 0,
            icon: '💧',
          ),
          RecoveryTask(
            id: 'stretch_1',
            type: TaskType.stretch,
            title: 'Neck & Shoulder Stretch',
            description: 'Gentle stretches to improve circulation',
            durationSeconds: 60,
            icon: '🤸',
          ),
          RecoveryTask(
            id: 'breathing_3',
            type: TaskType.breathing,
            title: 'Light Breathing',
            description: 'Calm breathing exercise',
            durationSeconds: 60,
            icon: '🫁',
          ),
        ];

      case "High":
        return [
          RecoveryTask(
            id: 'mask',
            type: TaskType.mask,
            title: 'Wear Mask',
            description: 'Use N95/surgical mask when going outdoors',
            durationSeconds: 0,
            icon: '😷',
          ),
          RecoveryTask(
            id: 'diet_1',
            type: TaskType.diet,
            title: 'Anti-inflammatory Snack',
            description: 'Try turmeric milk or fresh fruit',
            durationSeconds: 0,
            icon: '🥛',
          ),
          RecoveryTask(
            id: 'diet_2',
            type: TaskType.diet,
            title: 'Healthy Diet',
            description: 'Avoid fried/processed foods today',
            durationSeconds: 0,
            icon: '🥗',
          ),
          RecoveryTask(
            id: 'breathing_4',
            type: TaskType.breathing,
            title: 'Calming Breath',
            description: 'Extended breathing to reduce stress',
            durationSeconds: 90,
            icon: '🫁',
          ),
        ];

      case "Critical":
        return [
          RecoveryTask(
            id: 'doctor',
            type: TaskType.doctorCTA,
            title: 'Contact Doctor',
            description: 'Medical advice recommended for this exposure level',
            durationSeconds: 0,
            icon: '👨‍⚕️',
          ),
          RecoveryTask(
            id: 'avoid_exposure',
            type: TaskType.mask,
            title: 'Stay Indoors',
            description: 'Move to clean/filtered area immediately',
            durationSeconds: 0,
            icon: '🏠',
          ),
        ];

      default:
        return [];
    }
  }
}