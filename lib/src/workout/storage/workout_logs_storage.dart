import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/helper/database_helper.dart';
import '../data/session_repository.dart';

class WorkoutLogsStorage {
  static final WorkoutLogsStorage _instance = WorkoutLogsStorage._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // In-memory fallback storage
  final Map<String, WorkoutLog> _memoryLogs = {};
  final Map<String, List<Map<String, dynamic>>> _memoryLogExercises = {};

  WorkoutLogsStorage._internal();

  factory WorkoutLogsStorage() => _instance;

  static WorkoutLogsStorage get instance => _instance;

  Future<void> insertWorkoutLog(WorkoutLog log) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Insert workout log
      final logMap = {
        'id': log.id,
        'session_id': log.sessionId,
        'title': log.title,
        'completed_at': log.completedAt.millisecondsSinceEpoch,
        'duration': log.duration,
        'total_volume': log.totalVolume,
        'total_sets': log.totalSets,
        'exercises_count': log.exercisesCount,
        'created_at': now,
      };

      await db.insert('workout_logs', logMap);

      // Insert workout log exercises
      await _deleteWorkoutLogExercises(log.id);
      for (var i = 0; i < log.exercises.length; i++) {
        await _insertWorkoutLogExercise(log.id, log.exercises[i], i, now);
      }

      print('WorkoutLogsStorage: Inserted workout log ${log.id} with ${log.exercises.length} exercises');
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        // Fallback to in-memory storage
        _memoryLogs[log.id] = log;
        _memoryLogExercises[log.id] = log.exercises.map((e) => Map<String, dynamic>.from(e)).toList();
        print('WorkoutLogsStorage: Saved workout log to in-memory storage: ${log.id}');
        return;
      }
      print('WorkoutLogsStorage: Error inserting workout log ${log.id}: $e');
      rethrow;
    }
  }

  Future<void> _insertWorkoutLogExercise(
    String logId, 
    Map<String, dynamic> exercise, 
    int position,
    int createdAt,
  ) async {
    try {
      final db = await _dbHelper.database;
      
      // First ensure the exercise exists in exercises table
      await _insertOrUpdateExercise(exercise, createdAt);
      
      final exerciseMap = {
        'workout_log_id': logId,
        'exercise_id': exercise['id']?.toString() ?? '',
        'sets_data': jsonEncode(exercise['sets'] ?? []),
        'position': position,
        'created_at': createdAt,
      };

      await db.insert('workout_log_exercises', exerciseMap);
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        final list = _memoryLogExercises.putIfAbsent(logId, () => []);
        list.add(Map<String, dynamic>.from(exercise));
        return;
      }
      rethrow;
    }
  }

  Future<void> _insertOrUpdateExercise(Map<String, dynamic> exercise, int createdAt) async {
    try {
      final db = await _dbHelper.database;
      final exerciseId = exercise['id']?.toString() ?? '';
      
      if (exerciseId.isEmpty) return;
      
      final exerciseData = {
        'id': exerciseId,
        'name': exercise['name']?.toString() ?? '',
        'description': exercise['desc']?.toString() ?? '',
        'image_url': exercise['image']?.toString() ?? '',
        'category': exercise['category']?.toString() ?? '',
        'created_at': createdAt,
      };
      
      await db.insert('exercises', exerciseData, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Ignore errors for fallback scenarios
      print('Failed to insert exercise: $e');
    }
  }

  Future<void> _deleteWorkoutLogExercises(String logId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('workout_log_exercises', where: 'workout_log_id = ?', whereArgs: [logId]);
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        _memoryLogExercises.remove(logId);
        return;
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getWorkoutLogExercises(String logId) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.rawQuery('''
        SELECT wle.exercise_id, wle.sets_data, wle.position,
               e.name, e.description, e.image_url, e.category
        FROM workout_log_exercises wle
        LEFT JOIN exercises e ON wle.exercise_id = e.id
        WHERE wle.workout_log_id = ?
        ORDER BY wle.position ASC
      ''', [logId]);

      return rows.map((row) => _mapRowToExercise(row)).toList();
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        final mem = _memoryLogExercises[logId] ?? [];
        return mem.map((m) => Map<String, dynamic>.from(m)).toList();
      }
      rethrow;
    }
  }

  Future<List<WorkoutLog>> getAllWorkoutLogs({int? limit, int? offset}) async {
    try {
      final db = await _dbHelper.database;
      
      String query = 'SELECT * FROM workout_logs ORDER BY completed_at DESC';
      List<dynamic> args = [];
      
      if (limit != null) {
        query += ' LIMIT ?';
        args.add(limit);
        
        if (offset != null) {
          query += ' OFFSET ?';
          args.add(offset);
        }
      }

      final rows = await db.rawQuery(query, args);
      final logs = <WorkoutLog>[];

      for (final row in rows) {
        final log = _mapRowToWorkoutLog(row);
        final exercises = await getWorkoutLogExercises(log.id);
        
        final completeLog = WorkoutLog(
          id: log.id,
          sessionId: log.sessionId,
          title: log.title,
          completedAt: log.completedAt,
          duration: log.duration,
          totalVolume: log.totalVolume,
          totalSets: log.totalSets,
          exercisesCount: log.exercisesCount,
          exercises: exercises,
        );
        
        logs.add(completeLog);
      }

      return logs;
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        // Return in-memory logs
        final list = _memoryLogs.values.toList();
        list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        
        if (limit != null) {
          final startIndex = offset ?? 0;
          final endIndex = startIndex + limit;
          return list.sublist(
            startIndex,
            endIndex > list.length ? list.length : endIndex,
          );
        }
        
        return list;
      }
      rethrow;
    }
  }

  Future<WorkoutLog?> getWorkoutLogById(String id) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query('workout_logs', where: 'id = ?', whereArgs: [id]);
      
      if (rows.isEmpty) return null;
      
      final log = _mapRowToWorkoutLog(rows.first);
      final exercises = await getWorkoutLogExercises(log.id);
      
      return WorkoutLog(
        id: log.id,
        sessionId: log.sessionId,
        title: log.title,
        completedAt: log.completedAt,
        duration: log.duration,
        totalVolume: log.totalVolume,
        totalSets: log.totalSets,
        exercisesCount: log.exercisesCount,
        exercises: exercises,
      );
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        return _memoryLogs[id];
      }
      rethrow;
    }
  }

  Future<void> deleteWorkoutLog(String id) async {
    try {
      final db = await _dbHelper.database;
      
      // Delete exercises first (although CASCADE should handle this)
      await _deleteWorkoutLogExercises(id);
      
      // Delete workout log
      await db.delete('workout_logs', where: 'id = ?', whereArgs: [id]);
      
      print('WorkoutLogsStorage: Deleted workout log: $id');
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        _memoryLogs.remove(id);
        _memoryLogExercises.remove(id);
        return;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWorkoutLogStats() async {
    try {
      final db = await _dbHelper.database;
      
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_logs,
          SUM(total_volume) as total_volume,
          SUM(total_sets) as total_sets,
          SUM(duration) as total_duration,
          AVG(total_volume) as avg_volume_per_workout
        FROM workout_logs
      ''');
      
      final row = result.first;
      return {
        'totalLogs': row['total_logs'] ?? 0,
        'totalVolume': row['total_volume'] ?? 0,
        'totalSets': row['total_sets'] ?? 0,
        'totalDuration': row['total_duration'] ?? 0,
        'avgVolumePerWorkout': row['avg_volume_per_workout'] ?? 0.0,
      };
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        // Calculate stats from in-memory data
        final logs = _memoryLogs.values.toList();
        final totalLogs = logs.length;
        final totalVolume = logs.fold(0, (sum, log) => sum + log.totalVolume);
        final totalSets = logs.fold(0, (sum, log) => sum + log.totalSets);
        final totalDuration = logs.fold(0, (sum, log) => sum + log.duration);
        final avgVolume = totalLogs > 0 ? totalVolume / totalLogs : 0.0;
        
        return {
          'totalLogs': totalLogs,
          'totalVolume': totalVolume,
          'totalSets': totalSets,
          'totalDuration': totalDuration,
          'avgVolumePerWorkout': avgVolume,
        };
      }
      rethrow;
    }
  }

  // Helper methods
  WorkoutLog _mapRowToWorkoutLog(Map<String, dynamic> row) {
    return WorkoutLog(
      id: row['id'] as String,
      sessionId: row['session_id'] as String?,
      title: row['title'] as String,
      completedAt: DateTime.fromMillisecondsSinceEpoch(row['completed_at'] as int),
      duration: row['duration'] as int,
      totalVolume: row['total_volume'] as int,
      totalSets: row['total_sets'] as int,
      exercisesCount: row['exercises_count'] as int,
      exercises: [], // Will be populated by caller
    );
  }

  Map<String, dynamic> _mapRowToExercise(Map<String, dynamic> row) {
    final setsData = row['sets_data'] as String?;
    final sets = setsData != null && setsData.isNotEmpty
        ? (jsonDecode(setsData) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    return {
      'id': row['exercise_id'] as String? ?? '',
      'name': row['name'] as String? ?? '',
      'desc': row['description'] as String? ?? '',
      'image': row['image_url'] as String? ?? '',
      'category': row['category'] as String? ?? '',
      'sets': sets,
    };
  }

  // Clear all data (useful for testing)
  Future<void> clearAllData() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('workout_log_exercises');
      await db.delete('workout_logs');
      print('WorkoutLogsStorage: Cleared all workout log data');
    } catch (e) {
      _memoryLogs.clear();
      _memoryLogExercises.clear();
      print('WorkoutLogsStorage: Cleared in-memory workout log data');
    }
  }
}
