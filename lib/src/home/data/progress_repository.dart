import '../api/progress_service.dart';
import '../service/steps_counter.dart';
import 'targets_repository.dart';

class ProgressCard {
  final String workoutsLeft;
  final String steps;
  final String calsBurned;
  final String calsTaken;
  final String proteinTaken;
  final double stepsProgress;
  final double calsBurnedProgress;
  final double calsTakenProgress;
  final double proteinTakenProgress;
  // Add actual numeric values
  final int actualSteps;
  final int actualCalsBurned;
  final int actualCalsTaken;
  final int actualProteinTaken;
  final Map<String, int> targets;

  ProgressCard({
    required this.workoutsLeft,
    required this.steps,
    required this.calsBurned,
    required this.calsTaken,
    required this.proteinTaken,
    required this.stepsProgress,
    required this.calsBurnedProgress,
    required this.calsTakenProgress,
    required this.proteinTakenProgress,
    required this.actualSteps,
    required this.actualCalsBurned,
    required this.actualCalsTaken,
    required this.actualProteinTaken,
    required this.targets,
  });

  factory ProgressCard.fromJson(Map<String, dynamic> json, Map<String, int> targets) {
    final stepsValue = json['steps'] as int;
    final calsBurnedValue = json['calsBurned'] as int;
    final calsTakenValue = json['calsTaken'] as int;
    final proteinTakenValue = json['proteinTaken'] as int;

    return ProgressCard(
      workoutsLeft: formatNumber(json['workoutsLeft'] as int),
      steps: formatNumber(stepsValue),
      calsBurned: formatNumber(calsBurnedValue),
      calsTaken: formatNumber(calsTakenValue),
      proteinTaken: formatNumber(proteinTakenValue),
      stepsProgress: _calculateProgress(stepsValue, targets['steps'] ?? 10000),
      calsBurnedProgress: _calculateProgress(calsBurnedValue, targets['cals_burned'] ?? 500),
      calsTakenProgress: _calculateProgress(calsTakenValue, targets['cals_taken'] ?? 2000),
      proteinTakenProgress: _calculateProgress(proteinTakenValue, targets['protein_taken'] ?? 150),
      actualSteps: stepsValue,
      actualCalsBurned: calsBurnedValue,
      actualCalsTaken: calsTakenValue,
      actualProteinTaken: proteinTakenValue,
      targets: targets,
    );
  }

  static double _calculateProgress(int current, int target) {
    if (target <= 0) return 0.0;
    return (current / target).clamp(0.0, 1.0);
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
  final TargetsRepository _targetsRepository = TargetsRepository();

  ProgressRepository({ProgressService? progressService})
      : _progressService = progressService ?? ProgressService();

  Future<ProgressCard> getTodayProgress() async {
    try {
      final results = await Future.wait([
        _progressService.getTodayProgress(),
        _targetsRepository.getAllTargets(),
      ]);

      final data = results[0] as Map<String, dynamic>;
      final targets = results[1] as Map<String, int>;

      // Get real-time steps from step counter
      final realTimeSteps = _stepsCounter.currentSteps;

      // Override steps with real-time data if available
      final progressData = Map<String, dynamic>.from(data);
      if (realTimeSteps > 0) {
        progressData['steps'] = realTimeSteps;
      }

      return ProgressCard.fromJson(progressData, targets);
    } catch (e) {
      throw Exception('Failed to load progress: $e');
    }
  }

  Future<Map<String, int>> getTargets() async {
    return await _targetsRepository.getAllTargets();
  }

  Future<bool> updateTarget(String targetType, int targetValue) async {
    return await _targetsRepository.updateTarget(targetType, targetValue);
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
