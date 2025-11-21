import '../api/progress_service.dart';

class ProgressCard {
  final String workoutsLeft; // Changed to String to handle formatted values
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
      workoutsLeft: _formatNumber(json['workoutsLeft'] as int),
      steps: _formatNumber(json['steps'] as int),
      calsBurned: _formatNumber(json['calsBurned'] as int),
      calsTaken: _formatNumber(json['calsTaken'] as int),
      proteinTaken: _formatNumber(json['proteinTaken'] as int),
    );
  }

  static String _formatNumber(int number) {
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
