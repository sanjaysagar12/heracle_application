import 'package:shared_preferences/shared_preferences.dart';

class DailyNutritionStorage {
  static const String _calsTakenKey = 'today_cals_taken';
  static const String _proteinTakenKey = 'today_protein_taken';
  static const String _fatTakenKey = 'today_fat_taken';
  static const String _carbsTakenKey = 'today_carbs_taken';
  static const String _fiberTakenKey = 'today_fiber_taken';
  static const String _lastDateKey = 'nutrition_last_date';

  Future<void> saveTodayNutrition(int calories, int protein, int fat, int carbs, int fiber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Check if it's a new day and reset if needed
      await _checkAndResetForNewDay(prefs, today);
      
      await prefs.setInt(_calsTakenKey, calories);
      await prefs.setInt(_proteinTakenKey, protein);
      await prefs.setInt(_fatTakenKey, fat);
      await prefs.setInt(_carbsTakenKey, carbs);
      await prefs.setInt(_fiberTakenKey, fiber);
      await prefs.setString(_lastDateKey, today);
    } catch (e) {
      print('DailyNutritionStorage: Error saving today nutrition: $e');
    }
  }

  Future<void> addNutrition(int calories, int protein, {int fat = 0, int carbs = 0, int fiber = 0}) async {
    try {
      final current = await getTodayNutrition();
      final newCals = current['calories']! + calories;
      final newProtein = current['protein']! + protein;
      final newFat = current['fat']! + fat;
      final newCarbs = current['carbs']! + carbs;
      final newFiber = current['fiber']! + fiber;
      await saveTodayNutrition(newCals, newProtein, newFat, newCarbs, newFiber);
    } catch (e) {
      print('DailyNutritionStorage: Error adding nutrition: $e');
    }
  }

  Future<Map<String, int>> getTodayNutrition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Check if it's a new day and reset if needed
      await _checkAndResetForNewDay(prefs, today);
      
      final cals = prefs.getInt(_calsTakenKey) ?? 0;
      final protein = prefs.getInt(_proteinTakenKey) ?? 0;
      final fat = prefs.getInt(_fatTakenKey) ?? 0;
      final carbs = prefs.getInt(_carbsTakenKey) ?? 0;
      final fiber = prefs.getInt(_fiberTakenKey) ?? 0;
      
      return {
        'calories': cals, 
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
      };
    } catch (e) {
      print('DailyNutritionStorage: Error getting today nutrition: $e');
      return {
        'calories': 0, 
        'protein': 0,
        'fat': 0,
        'carbs': 0,
        'fiber': 0,
      };
    }
  }

  Future<void> _checkAndResetForNewDay(SharedPreferences prefs, String today) async {
    try {
      final lastDate = prefs.getString(_lastDateKey);
      
      if (lastDate != null && lastDate != today) {
        // It's a new day, reset data
        await prefs.remove(_calsTakenKey);
        await prefs.remove(_proteinTakenKey);
        await prefs.remove(_fatTakenKey);
        await prefs.remove(_carbsTakenKey);
        await prefs.remove(_fiberTakenKey);
        print('DailyNutritionStorage: New day detected ($lastDate -> $today), resetting nutrition data');
      }
    } catch (e) {
      print('DailyNutritionStorage: Error checking for new day: $e');
    }
  }
}
