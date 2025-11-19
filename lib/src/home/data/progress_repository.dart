import '../api/progress_service.dart';

class ProgressCard {
  final int workoutsLeft;
  final int steps;
  final int calsBurned;
  final int calsTaken;
  final int proteinTaken;

  ProgressCard({
    required this.workoutsLeft,
    required this.steps,
    required this.calsBurned,
    required this.calsTaken,
    required this.proteinTaken,
  });

  factory ProgressCard.fromJson(Map<String, dynamic> json) {
    return ProgressCard(
      workoutsLeft: json['workoutsLeft'] as int,
      steps: json['steps'] as int,
      calsBurned: json['calsBurned'] as int,
      calsTaken: json['calsTaken'] as int,
      proteinTaken: json['proteinTaken'] as int,
    );
  }
}

class ProgressRepository {
  final ProgressService _progressService;

  ProgressRepository({ProgressService? progressService})
      : _progressService = progressService ?? ProgressService();

  Future<ProgressCard> getTodayProgress() async {
    try {
      final data = await _progressService.getTodayProgress();
      return ProgressCard.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load progress: $e');
    }
  }
}
