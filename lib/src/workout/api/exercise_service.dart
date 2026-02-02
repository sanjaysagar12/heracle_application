import '../../../../core/network/dio_client.dart';
import '../../../../core/helper/database_helper.dart';

class ExerciseService {
  final DioClient _dioClient = DioClient();

  // Database helper instance
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<dynamic>> fetchExercises() async {
    try {
      final db = await _dbHelper.database;
      final localData = await db.query('exercises');

      if (localData.isNotEmpty) {
        return localData;
      }

      // If empty, fetch from API and sync
      return await syncExercises();
    } catch (e) {
      // Fallback to API if DB fails
      try {
        final response = await _dioClient.dio.get('/api/workout/exercises');
        if (response.statusCode == 200) {
          return response.data as List<dynamic>;
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<List<dynamic>> syncExercises() async {
    try {
      final response = await _dioClient.dio.get('/api/workout/exercises');

      if (response.statusCode == 200) {
        final exercises = response.data as List<dynamic>;
        final db = await _dbHelper.database;

        await db.transaction((txn) async {
          // Clear existing exercises
          await txn.delete('exercises');

          // Batch insert
          final batch = txn.batch();
          for (var exercise in exercises) {
            batch.insert('exercises', {
              'id': exercise['id'],
              'name': exercise['name'],
              'description': exercise['description'] ?? '',
              'image_url': exercise['imageUrl'] ?? '',
              'category': exercise['category'] ?? 'Other',
              'tracking_type': exercise['trackingType'] ?? 'reps_weight',
              'created_at': DateTime.now().millisecondsSinceEpoch,
            });
          }
          await batch.commit(noResult: true);
        });

        return exercises;
      } else {
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> fetchCategories() async {
    try {
      final response = await _dioClient.dio.get('/api/workout/categories');

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
