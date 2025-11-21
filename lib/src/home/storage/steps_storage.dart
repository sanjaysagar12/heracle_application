import 'package:shared_preferences/shared_preferences.dart';

class StepsStorage {
  static const String _todayStepsKey = 'today_steps';
  static const String _lastDateKey = 'last_date';
  static const String _baseStepsKey = 'base_steps';

  Future<void> saveTodaySteps(int steps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await prefs.setInt('${_todayStepsKey}_$today', steps);
      await prefs.setString(_lastDateKey, today);
    } catch (e) {
      print('StepsStorage: Error saving today steps: $e');
    }
  }

  Future<int> getTodaySteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      return prefs.getInt('${_todayStepsKey}_$today') ?? 0;
    } catch (e) {
      print('StepsStorage: Error getting today steps: $e');
      return 0;
    }
  }

  Future<void> setBaseStepsForToday(int baseSteps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await prefs.setInt('${_baseStepsKey}_$today', baseSteps);
    } catch (e) {
      print('StepsStorage: Error setting base steps: $e');
    }
  }

  Future<int> getBaseStepsForToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      return prefs.getInt('${_baseStepsKey}_$today') ?? -1;
    } catch (e) {
      print('StepsStorage: Error getting base steps: $e');
      return -1;
    }
  }

  Future<void> resetDailySteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await prefs.remove('${_todayStepsKey}_$today');
      await prefs.remove('${_baseStepsKey}_$today');
    } catch (e) {
      print('StepsStorage: Error resetting daily steps: $e');
    }
  }

  Future<void> cleanOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Remove data older than 7 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      
      for (final key in keys) {
        if (key.contains(_todayStepsKey) || key.contains(_baseStepsKey)) {
          final dateStr = key.split('_').last;
          try {
            final date = DateTime.parse(dateStr);
            if (date.isBefore(cutoffDate)) {
              await prefs.remove(key);
            }
          } catch (e) {
            // Invalid date format, skip
          }
        }
      }
    } catch (e) {
      print('StepsStorage: Error cleaning old data: $e');
    }
  }
}
