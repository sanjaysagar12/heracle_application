class ProgressService {
  Future<Map<String, dynamic>> getTodayProgress() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock data
    return {
      'workoutsLeft': 10,
      'steps': 100,
      'calsBurned': 0,
      'calsTaken': 1200,
      'proteinTaken': 76,
    };
  }
}
