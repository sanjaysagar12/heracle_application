import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StepsStorage {
  static const String _todayStepsKey = 'today_steps';
  static const String _lastDateKey = 'last_date';
  static const String _baseStepsKey = 'base_steps';
  static const String _offsetStepsKey = 'offset_steps'; // New key for reboot offset
  static const String _stepsHistoryKey = 'steps_history'; // New key for history (JSON map)

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

  // New method: Save offset steps
  Future<void> setOffsetStepsForToday(int offset) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // No date check needed here as it's usually called during calculation which checks date
      await prefs.setInt(_offsetStepsKey, offset);
    } catch (e) {
      print('StepsStorage: Error setting offset steps: $e');
    }
  }

  // New method: Get offset steps
  Future<int> getOffsetStepsForToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_offsetStepsKey) ?? 0;
    } catch (e) {
      print('StepsStorage: Error getting offset steps: $e');
      return 0;
    }
  }

  Future<void> resetDailySteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await prefs.remove(_todayStepsKey);
      await prefs.remove(_baseStepsKey);
      await prefs.remove(_offsetStepsKey); // Clear offset too
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
        // It's a new day, verify if we need to archive the previous day's steps
        // The last saved 'today_steps' belongs to 'lastDate'.
        final lastSteps = prefs.getInt(_todayStepsKey) ?? 0;
        if (lastSteps > 0) {
           await _archiveSteps(prefs, lastDate, lastSteps);
        }

        // It's a new day, reset all step data
        await prefs.remove(_todayStepsKey);
        await prefs.remove(_baseStepsKey);
        await prefs.remove(_offsetStepsKey); // Clear offset too
        print('StepsStorage: New day detected ($lastDate -> $today), archived $lastSteps steps & reset data');
      }
    } catch (e) {
      print('StepsStorage: Error checking for new day: $e');
    }
  }

  Future<void> _archiveSteps(SharedPreferences prefs, String date, int steps) async {
    try {
      final historyStr = prefs.getString(_stepsHistoryKey);
      Map<String, dynamic> history = {};
      if (historyStr != null) {
        history = jsonDecode(historyStr);
      }
      history[date] = steps;
      await prefs.setString(_stepsHistoryKey, jsonEncode(history));
    } catch (e) {
      print('StepsStorage: Error archiving steps: $e');
    }
  }

  Future<Map<String, int>> getStepsHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString(_stepsHistoryKey);
      if (historyStr != null) {
        final Map<String, dynamic> json = jsonDecode(historyStr);
        // Sort keys to ensure chronological order if needed, but Map is not ordered.
        // Convert to Map<String, int>
        return json.map((key, value) => MapEntry(key, value as int));
      }
      return {};
    } catch (e) {
      print('StepsStorage: Error getting steps history: $e');
      return {};
    }
  }
}
