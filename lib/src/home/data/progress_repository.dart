import '../../core/network/cache_manager.dart';
import '../api/progress_service.dart';
import '../service/steps_counter.dart';
import '../storage/daily_nutrition_storage.dart'; // Added
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
  final CacheManager _cacheManager = CacheManager();
  final DailyNutritionStorage _nutritionStorage = DailyNutritionStorage(); // Added

  ProgressRepository({ProgressService? progressService})
      : _progressService = progressService ?? ProgressService();

  Future<ProgressCard> getTodayProgress() async {
    try {
      final results = await Future.wait([
        _progressService.getTodayProgress(), // 0
        _targetsRepository.getAllTargets(),  // 1
        _nutritionStorage.getTodayNutrition(), // 2
      ]);

      final data = results[0] as Map<String, dynamic>;
      final targets = results[1] as Map<String, int>;
      final localNutrition = results[2] as Map<String, int>; // Added

      // Cache the successful API response
      await _cacheManager.cacheData('progress_today', data);

      return _buildProgressCard(data, targets, localNutrition); // Pass localNutrition
    } catch (e) {
      // Try to load from cache
      final cachedData = await _cacheManager.getCachedData('progress_today');
      if (cachedData != null) {
        final targets = await _targetsRepository.getAllTargets(); // Targets are local SQLite, safe to call
        final localNutrition = await _nutritionStorage.getTodayNutrition(); // Get local even on error
        return _buildProgressCard(cachedData, targets, localNutrition);
      }
      throw Exception('Failed to load progress: $e');
    }
  }

  ProgressCard _buildProgressCard(Map<String, dynamic> data, Map<String, int> targets, [Map<String, int>? localNutrition]) {
     final realTimeSteps = _stepsCounter.currentSteps;
      final calsBurned = _calculateCaloriesBurned(realTimeSteps);

      final progressData = Map<String, dynamic>.from(data);
      progressData['steps'] = realTimeSteps;
      progressData['calsBurned'] = calsBurned;
      
      // Override with local nutrition data if available
      if (localNutrition != null) {
        progressData['calsTaken'] = localNutrition['calories'];
        progressData['proteinTaken'] = localNutrition['protein'];
      }

      return ProgressCard.fromJson(progressData, targets);
  }

  /// Calculate calories burned based on steps
  /// Average person burns approximately 0.04 calories per step
  /// This can vary based on weight, pace, and terrain
  int _calculateCaloriesBurned(int steps) {
    if (steps <= 0) return 0;

    // Using a standard calculation: 0.04 calories per step
    // This is an average for a person weighing around 70kg (154 lbs)
    const double caloriesPerStep = 0.04;
    return (steps * caloriesPerStep).round();
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
