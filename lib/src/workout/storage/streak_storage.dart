import 'package:shared_preferences/shared_preferences.dart';

class StreakStorage {
  static const String _keyStreakCount = 'streak_count';
  static const String _keyLastWorkoutDate = 'last_workout_date';

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreakCount) ?? 0;
  }
  
  Future<String?> getLastWorkoutDate() async {
     final prefs = await SharedPreferences.getInstance();
     return prefs.getString(_keyLastWorkoutDate);
  }

  Future<void> incrementStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_keyLastWorkoutDate);
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";

    int currentStreak = prefs.getInt(_keyStreakCount) ?? 0;

    if (lastDateStr == null) {
      // First workout ever
      await prefs.setInt(_keyStreakCount, 1);
      await prefs.setString(_keyLastWorkoutDate, todayStr);
      return;
    }

    if (lastDateStr == todayStr) {
      // Already worked out today, do nothing
      return;
    }

    final lastDate = _parseDate(lastDateStr);
    final difference = today.difference(lastDate).inDays;

    if (difference == 1) {
      // Consecutive day
      await prefs.setInt(_keyStreakCount, currentStreak + 1);
    } else if (difference >= 4) {
      // Missed 3 or more consecutive days (e.g. Mon -> Fri is diff 4, missed Tue/Wed/Thu)
      await prefs.setInt(_keyStreakCount, 1);
    } else {
       // Missed 1 or 2 days, maintain streak but add to count?
       // Usually you don't increment if you missed a day, you just keep it.
       // But user request was vague "if user miss one 3 days a week reset".
       // If I miss 1 day, I shouldn't lose streak, but should I evaluate +1?
       // "Streak" usually implies consecutive.
       // However, often apps have "freeze" or leniency.
       // If I simply strictly increment only on diff==1, then diff==2 (missed 1 day) would NOT increment.
       // If I don't increment, the streak count stays same.
       // But if I workout today, it should probably count `currentStreak + 1` if I'm not resetting?
       // Let's assume if it doesn't reset, it continues (increments).
       await prefs.setInt(_keyStreakCount, currentStreak + 1);
    }

    await prefs.setString(_keyLastWorkoutDate, todayStr);
  }
  
  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}
