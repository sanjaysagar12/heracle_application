import '../api/progress_service.dart';
import '../service/steps_counter.dart';

class ProgressCard {
  final String workoutsLeft;
  final String steps;
  final String calsBurned;
  final String calsTaken;
  final String proteinTaken;

  ProgressCard({
    required this.workoutsLeft,
    required this.steps,
    required this.calsBurned,
    required this.calsTaken,
    required this.proteinTaken,
  });

  factory ProgressCard.fromJson(Map<String, dynamic> json) {
    return ProgressCard(
      workoutsLeft: formatNumber(json['workoutsLeft'] as int),
      steps: formatNumber(json['steps'] as int),
      calsBurned: formatNumber(json['calsBurned'] as int),
      calsTaken: formatNumber(json['calsTaken'] as int),
      proteinTaken: formatNumber(json['proteinTaken'] as int),
    );
  }

  // Changed from private to public static method
  static String formatNumber(int number) {
    if (number >= 1000) {
      double thousands = number / 1000.0;
      if (thousands == thousands.roundToDouble()) {
        return '${thousands.round()}k';
      } else {
        return '${thousands.toStringAsFixed(1)}k';
      }
    }
    return number.toString();
  }
}

class ProgressRepository {
  final ProgressService _progressService;
  final StepsCounter _stepsCounter = StepsCounter();

  ProgressRepository({ProgressService? progressService})
      : _progressService = progressService ?? ProgressService();

  Future<ProgressCard> getTodayProgress() async {
    try {
      final data = await _progressService.getTodayProgress();

      // Get real-time steps from step counter
      final realTimeSteps = _stepsCounter.currentSteps;

      // Override steps with real-time data if available
      final progressData = Map<String, dynamic>.from(data);
      if (realTimeSteps > 0) {
        progressData['steps'] = realTimeSteps;
      }

      return ProgressCard.fromJson(progressData);
    } catch (e) {
      throw Exception('Failed to load progress: $e');
    }
  }

  // Listen to real-time step updates
  Stream<int> get stepsStream => _stepsCounter.stepsStream;

  Future<void> startStepTracking() async {
    await _stepsCounter.startListening();
  }

  Future<void> stopStepTracking() async {
    await _stepsCounter.stopListening();
  }
}
