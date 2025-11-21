class ProgressService {
  Future<Map<String, dynamic>> getTodayProgress() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock data - removed steps and calsBurned as they'll be calculated
    return {
      'workoutsLeft': 10,
      'calsTaken': 1200,
      'proteinTaken': 76,
    };
  }
}
