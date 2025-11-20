class ProgressRepository {
  ProgressRepository();

  Future<List<double>> getWeeklyActivity() async {
    // simulate API/network delay
    await Future.delayed(const Duration(milliseconds: 400));
    // mock values for Mon..Sun
    return [40, 60, 30, 80, 55, 70, 50];
  }

  Future<Map<String, double>> getTodayNutrition() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // mock nutrition values: calories, protein, carbs, fats
    return {
      'calories': 1850,
      'protein': 120,
      'carbs': 200,
      'fats': 65,
    };
  }

  Future<List<double>> getMonthlyProgress() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // mock values for Week 1-4
    return [150, 220, 180, 240];
  }
}
