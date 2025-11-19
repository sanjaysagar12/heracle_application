class ProgressRepository {
  ProgressRepository();

  Future<List<double>> getWeeklyActivity() async {
    // simulate API/network delay
    await Future.delayed(const Duration(milliseconds: 400));
    // mock values for Mon..Sun
    return [40, 60, 30, 80, 55, 70, 50];
  }
}
