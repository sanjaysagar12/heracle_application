import 'package:shared_preferences/shared_preferences.dart';

class StepsStorage {
  static const String _todayStepsKey = 'today_steps';
  static const String _lastDateKey = 'last_date';
  static const String _baseStepsKey = 'base_steps';

  Future<void> saveTodaySteps(int steps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Check if it's a new day and reset if needed
      await _checkAndResetForNewDay(prefs, today);
      
      await prefs.setInt(_todayStepsKey, steps);
      await prefs.setString(_lastDateKey, today);
    } catch (e) {
      print('StepsStorage: Error saving today steps: $e');
    }
  }

  Future<int> getTodaySteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Check if it's a new day and reset if needed
      await _checkAndResetForNewDay(prefs, today);
      
      return prefs.getInt(_todayStepsKey) ?? 0;
    } catch (e) {
      print('StepsStorage: Error getting today steps: $e');
      return 0;
    }
  }

  Future<void> setBaseStepsForToday(int baseSteps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Check if it's a new day and reset if needed
      await _checkAndResetForNewDay(prefs, today);
      
      await prefs.setInt(_baseStepsKey, baseSteps);
      await prefs.setString(_lastDateKey, today);
    } catch (e) {
      print('StepsStorage: Error setting base steps: $e');
    }
  }

  Future<int> getBaseStepsForToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Check if it's a new day and reset if needed
      await _checkAndResetForNewDay(prefs, today);
      
      return prefs.getInt(_baseStepsKey) ?? -1;
    } catch (e) {
      print('StepsStorage: Error getting base steps: $e');
      return -1;
    }
  }

  Future<void> resetDailySteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await prefs.remove(_todayStepsKey);
      await prefs.remove(_baseStepsKey);
      await prefs.setString(_lastDateKey, today);
      
      print('StepsStorage: Daily steps reset for $today');
    } catch (e) {
      print('StepsStorage: Error resetting daily steps: $e');
    }
  }

  // Check if it's a new day and automatically reset data
  Future<void> _checkAndResetForNewDay(SharedPreferences prefs, String today) async {
    try {
      final lastDate = prefs.getString(_lastDateKey);
      
      if (lastDate != null && lastDate != today) {
        // It's a new day, reset all step data
        await prefs.remove(_todayStepsKey);
        await prefs.remove(_baseStepsKey);
        print('StepsStorage: New day detected ($lastDate -> $today), resetting step data');
      }
    } catch (e) {
      print('StepsStorage: Error checking for new day: $e');
    }
  }
}
