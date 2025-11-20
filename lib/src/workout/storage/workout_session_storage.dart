import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../core/helper/database_helper.dart';
import '../data/session_repository.dart';

class WorkoutSessionStorage {
  static final WorkoutSessionStorage instance = WorkoutSessionStorage._init();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // In-memory fallback storage
  final Map<String, Session> _memorySessions = {};
  final Map<String, List<Map<String, dynamic>>> _memoryExercises = {};

  WorkoutSessionStorage._init();

  Future<void> insertSession(Session session) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final map = {
        'id': session.id,
        'title': session.title,
        'content': session.content,
        'category': session.category,
        'exercises_count': session.exercisesCount,
        'created_at': now,
      };
      
      await db.insert('sessions', map);

      // insert exercises separately
      await _deleteSessionExercises(session.id);
      for (var i = 0; i < session.exercises.length; i++) {
        await _insertSessionExercise(session.id, session.exercises[i], i, now);
      }

      print('WorkoutSessionStorage: inserted session id=${session.id}, exercises=${session.exercises.length}');
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        _memorySessions[session.id] = session;
        _memoryExercises[session.id] = session.exercises.map((e) => Map<String, dynamic>.from(e)).toList();
        print('WorkoutSessionStorage: saved session to in-memory store id=${session.id}, exercises=${session.exercises.length}');
        return;
      }
      rethrow;
    }
  }

  Future<void> _insertSessionExercise(
    String sessionId, 
    Map<String, dynamic> exercise, 
    int position,
    int createdAt,
  ) async {
    try {
      final db = await _dbHelper.database;
      
      final exerciseMap = {
        'session_id': sessionId,
        'exercise_id': exercise['id']?.toString(),
        'name': exercise['name']?.toString() ?? '',
        'description': exercise['desc']?.toString() ?? '',
        'image_url': exercise['image']?.toString() ?? '',
        'sets_data': jsonEncode(exercise['sets'] ?? []),
        'position': position,
        'created_at': createdAt,
      };

      await db.insert('session_exercises', exerciseMap);
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        final list = _memoryExercises.putIfAbsent(sessionId, () => []);
        list.add(Map<String, dynamic>.from(exercise));
        return;
      }
      rethrow;
    }
  }

  Future<void> _deleteSessionExercises(String sessionId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('session_exercises', where: 'session_id = ?', whereArgs: [sessionId]);
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        _memoryExercises.remove(sessionId);
        return;
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExercisesForSession(String sessionId) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'session_exercises',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'position ASC',
      );

      return rows.map((row) => _mapRowToExercise(row)).toList();
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        final mem = _memoryExercises[sessionId] ?? [];
        return mem.map((m) => Map<String, dynamic>.from(m)).toList();
      }
      rethrow;
    }
  }

  Future<List<Session>> getAllSessions() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query('sessions', orderBy: 'created_at DESC');
      final sessions = <Session>[];
      
      for (final row in result) {
        final session = _mapRowToSession(row);
        final exercises = await getExercisesForSession(session.id);
        
        final updated = Session(
          id: session.id,
          title: session.title,
          content: session.content,
          category: session.category,
          exercisesCount: session.exercisesCount,
          exercises: exercises,
        );
        sessions.add(updated);
      }
      return sessions;
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        final list = _memorySessions.values.toList();
        list.sort((a, b) => b.id.compareTo(a.id));
        return list;
      }
      rethrow;
    }
  }

  Future<Session?> getSessionById(String id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query('sessions', where: 'id = ?', whereArgs: [id]);
      
      if (result.isEmpty) return null;
      
      final session = _mapRowToSession(result.first);
      final exercises = await getExercisesForSession(session.id);
      
      return Session(
        id: session.id,
        title: session.title,
        content: session.content,
        category: session.category,
        exercisesCount: session.exercisesCount,
        exercises: exercises,
      );
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        return _memorySessions[id];
      }
      rethrow;
    }
  }

  Future<int> updateSession(Session session) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final map = {
        'id': session.id,
        'title': session.title,
        'content': session.content,
        'category': session.category,
        'exercises_count': session.exercisesCount,
        'created_at': now,
      };
      
      final res = await db.update('sessions', map, where: 'id = ?', whereArgs: [session.id]);

      // update exercises: replace all for simplicity
      await _deleteSessionExercises(session.id);
      for (var i = 0; i < session.exercises.length; i++) {
        await _insertSessionExercise(session.id, session.exercises[i], i, now);
      }

      return res;
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        _memorySessions[session.id] = session;
        _memoryExercises[session.id] = session.exercises.map((e) => Map<String, dynamic>.from(e)).toList();
        return 1;
      }
      rethrow;
    }
  }

  Future<int> deleteSession(String id) async {
    try {
      final db = await _dbHelper.database;
      
      // delete exercises first (although CASCADE should handle this)
      await _deleteSessionExercises(id);
      
      return await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        _memoryExercises.remove(id);
        _memorySessions.remove(id);
        return 1;
      }
      rethrow;
    }
  }

  // Helper methods
  Session _mapRowToSession(Map<String, dynamic> row) {
    return Session(
      id: row['id'] as String,
      title: row['title'] as String,
      content: row['content'] as String? ?? '',
      category: row['category'] as String? ?? '',
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
      'sets': sets,
    };
  }

  // Clear all session data (useful for testing)
  Future<void> clearAllData() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('session_exercises');
      await db.delete('sessions');
      print('WorkoutSessionStorage: Cleared all session data');
    } catch (e) {
      _memoryExercises.clear();
      _memorySessions.clear();
      print('WorkoutSessionStorage: Cleared in-memory session data');
    }
  }

  /// Get session statistics
  Future<Map<String, int>> getSessionStats() async {
    try {
      final db = await _dbHelper.database;
      final sessionCount = (await db.rawQuery('SELECT COUNT(*) as count FROM sessions')).first['count'] as int;
      final exerciseCount = (await db.rawQuery('SELECT COUNT(*) as count FROM session_exercises')).first['count'] as int;
      
      return {
        'sessions': sessionCount,
        'exercises': exerciseCount,
      };
    } catch (e) {
      return {
        'sessions': _memorySessions.length,
        'exercises': _memoryExercises.values.fold(0, (sum, list) => sum + list.length),
      };
    }
  }

  /// Debug helper: prints all sessions and their exercises to console.
  Future<void> debugDumpAll() async {
    try {
      final db = await _dbHelper.database;
      final sessions = await db.query('sessions', orderBy: 'created_at DESC');
      print('--- DB SESSIONS DUMP (${sessions.length}) ---');
      
      for (final s in sessions) {
        print('session row: $s');
        final sessionId = s['id'] as String;
        final exercises = await db.query('session_exercises', where: 'session_id = ?', whereArgs: [sessionId], orderBy: 'position ASC');
        print('  exercises (${exercises.length}):');
        for (final ex in exercises) {
          print('    ex row: $ex');
        }
      }
      print('--- END SESSIONS DUMP ---');
    } catch (e) {
      print('WorkoutSessionStorage: debugDumpAll fallback to in-memory: $e');
      print('--- IN-MEMORY SESSIONS DUMP (${_memorySessions.length}) ---');
      for (final entry in _memorySessions.entries) {
        print('session: ${entry.key} -> ${entry.value.title}, exercises: ${_memoryExercises[entry.key]?.length ?? 0}');
      }
      print('--- END IN-MEMORY DUMP ---');
    }
  }
}
