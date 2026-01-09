import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StreakStorage {
  static const String _keyStreakCount = 'streak_count';
  static const String _keyLastWorkoutDate = 'last_workout_date';
  static const String _keyBreakDaysUsed = 'break_days_used';
  static const String _keyBreakDates = 'break_dates'; // Changed from single date
  static const String _keyWeekStartDate = 'week_start_date';

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetWeek(prefs);
    return prefs.getInt(_keyStreakCount) ?? 0;
  }
  
  Future<String?> getLastWorkoutDate() async {
     final prefs = await SharedPreferences.getInstance();
     return prefs.getString(_keyLastWorkoutDate);
  }

  Future<int> getBreakDaysUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetWeek(prefs);
    return prefs.getInt(_keyBreakDaysUsed) ?? 0;
  }

  Future<bool> isBreakDayToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayStr();
    final breakDates = _getBreakDates(prefs);
    return breakDates.contains(today);
  }

  Future<bool> setBreakDay() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetWeek(prefs);

    final today = _getTodayStr();
    final lastWorkout = prefs.getString(_keyLastWorkoutDate);

    // If already worked out today, can't set break day
    if (lastWorkout == today) return false;

    final breakDates = _getBreakDates(prefs);

    // If already break day today, return true (idempotent)
    if (breakDates.contains(today)) return true;

    final breakDays = prefs.getInt(_keyBreakDaysUsed) ?? 0;
    if (breakDays >= 3) return false; // Max 3 break days

    breakDates.add(today);
    await prefs.setString(_keyBreakDates, jsonEncode(breakDates));
    await prefs.setInt(_keyBreakDaysUsed, breakDays + 1);
    
    return true;
  }

  Future<void> incrementStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetWeek(prefs);
    
    final lastDateStr = prefs.getString(_keyLastWorkoutDate);
    final today = DateTime.now();
    final todayStr = _getTodayStr();

    int currentStreak = prefs.getInt(_keyStreakCount) ?? 0;

    if (lastDateStr == null) {
      await prefs.setInt(_keyStreakCount, 1);
      await prefs.setString(_keyLastWorkoutDate, todayStr);
      return;
    }

    if (lastDateStr == todayStr) return;

    final lastDate = _parseDate(lastDateStr);
    final difference = today.difference(lastDate).inDays;

    if (difference == 1) {
      // Consecutive
      await prefs.setInt(_keyStreakCount, currentStreak + 1);
    } else {
      // Check if missed days were covered by break days
      bool allCovered = true;
      final breakDates = _getBreakDates(prefs);
      
      // Check every day between lastWorkout and today (exclusive)
      for (int i = 1; i < difference; i++) {
        final missedDay = lastDate.add(Duration(days: i));
        final missedDayStr = _dateToStr(missedDay);
        if (!breakDates.contains(missedDayStr)) {
          allCovered = false;
          break;
        }
      }
      
      if (allCovered) {
         // If supported by break days, increment streak
         await prefs.setInt(_keyStreakCount, currentStreak + 1);
      } else {
         // Reset if gap is not covered
         // User Rule: "go at least 4 days a week".
         // If strict consecutive check fails and not covered by break -> reset to 1
         await prefs.setInt(_keyStreakCount, 1);
      }
    }

    await prefs.setString(_keyLastWorkoutDate, todayStr);
  }

  Future<void> _checkAndResetWeek(SharedPreferences prefs) async {
    final lastWeekStartStr = prefs.getString(_keyWeekStartDate);
    final now = DateTime.now();
    // Monday is 1
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekStartStr = _dateToStr(currentWeekStart);

    if (lastWeekStartStr != currentWeekStartStr) {
      // New week
      await prefs.setInt(_keyBreakDaysUsed, 0);
      await prefs.setString(_keyBreakDates, jsonEncode([])); // Reset break dates
      await prefs.setString(_keyWeekStartDate, currentWeekStartStr);
    }
  }
  
  List<String> _getBreakDates(SharedPreferences prefs) {
    final jsonStr = prefs.getString(_keyBreakDates);
    if (jsonStr == null) return [];
    try {
      return List<String>.from(jsonDecode(jsonStr));
    } catch (e) {
      return [];
    }
  }

  String _getTodayStr() => _dateToStr(DateTime.now());
  String _dateToStr(DateTime d) => "${d.year}-${d.month}-${d.day}";

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}
