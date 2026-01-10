import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
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
        'backend_id': session.backendId,
        'title': session.title,
        'content': session.content,
        // category columns removed from sessions table
        'exercises_count': session.exercisesCount,
        'position': session.position,
        'created_at': now,
      };
      
      await db.insert('sessions', map);

      // Insert categories links
      for (final catName in session.categories) {
        final catId = await _getOrCreateCategory(db, catName, now);
        // avoid duplicates
        await db.insert('session_category_links', {
          'session_id': session.id,
          'category_id': catId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

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

  Future<String> _getOrCreateCategory(Database db, String categoryName, int now) async {
    if (categoryName.isEmpty) return '';
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'session_categories',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [categoryName],
      );

      if (maps.isNotEmpty) {
        return maps.first['id'] as String;
      }

      // Create new category
      final newId = '${now}_${categoryName.hashCode}';
      await db.insert('session_categories', {
        'id': newId,
        'name': categoryName,
        'created_at': now,
      });
      return newId;
    } catch (e) {
      print('WorkoutSessionStorage: Error getting/creating category: $e');
      return '';
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
      
      // First ensure the exercise exists in exercises table
      await _insertOrUpdateExercise(exercise, createdAt);
      
      final exerciseMap = {
        'session_id': sessionId,
        'exercise_id': exercise['id']?.toString() ?? '',
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
        'tracking_type': exercise['trackingType']?.toString() ?? 'WEIGHT_AND_REPS',
        'created_at': createdAt,
      };
      
      await db.insert('exercises', exerciseData, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Ignore errors for fallback scenarios
      print('Failed to insert exercise: $e');
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
      final rows = await db.rawQuery('''
        SELECT se.exercise_id, se.sets_data, se.position,
               e.name, e.description, e.image_url, e.category, e.tracking_type
        FROM session_exercises se
        LEFT JOIN exercises e ON se.exercise_id = e.id
        WHERE se.session_id = ?
        ORDER BY se.position ASC
      ''', [sessionId]);

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
      // Get all sessions
      final result = await db.query('sessions', orderBy: 'position ASC, created_at DESC');
      
      // Batch fetch all categories for these sessions
      final allLinks = await db.rawQuery('''
        SELECT l.session_id, c.name 
        FROM session_category_links l
        JOIN session_categories c ON l.category_id = c.id
      ''');
      
      // Map session_id -> list of category names
      final categoryMap = <String, List<String>>{};
      for (final row in allLinks) {
        final sid = row['session_id'] as String;
        final name = row['name'] as String;
        if (categoryMap.containsKey(sid)) {
          categoryMap[sid]!.add(name);
        } else {
          categoryMap[sid] = [name];
        }
      }

      final sessions = <Session>[];
      
      for (final row in result) {
        final sessionId = row['id'] as String;
        final exercises = await getExercisesForSession(sessionId); // Still N+1 but necessary for complex exercise data
        final categories = categoryMap[sessionId] ?? [];
        
        final updated = Session(
          id: sessionId,
          backendId: row['backend_id'] as String? ?? '',
          title: row['title'] as String,
          content: row['content'] as String? ?? '',
          categories: categories,
          exercisesCount: row['exercises_count'] as int,
          position: (row['position'] as int?) ?? 0,
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
      
      final row = result.first;
      final exercises = await getExercisesForSession(id);
      final categories = await _getCategoriesForSession(db, id);
      
      return Session(
        id: id,
        backendId: row['backend_id'] as String? ?? '',
        title: row['title'] as String,
        content: row['content'] as String? ?? '',
        categories: categories,
        exercisesCount: row['exercises_count'] as int,
        position: (row['position'] as int?) ?? 0,
        exercises: exercises,
      );
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        return _memorySessions[id];
      }
      rethrow;
    }
  }

  Future<List<String>> _getCategoriesForSession(Database db, String sessionId) async {
    final result = await db.rawQuery('''
      SELECT c.name 
      FROM session_categories c
      JOIN session_category_links l ON c.id = l.category_id
      WHERE l.session_id = ?
    ''', [sessionId]);
    
    return result.map((r) => r['name'] as String).toList();
  }

  Future<int> updateSession(Session session) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final map = {
        'id': session.id,
        'backend_id': session.backendId,
        'title': session.title,
        'content': session.content,
        // categories removed
        'exercises_count': session.exercisesCount,
        'position': session.position,
        'created_at': now, 
      };
      
      final res = await db.update('sessions', map, where: 'id = ?', whereArgs: [session.id]);

      // update categories: delete old links, insert new
      await db.delete('session_category_links', where: 'session_id = ?', whereArgs: [session.id]);
      for (final catName in session.categories) {
        final catId = await _getOrCreateCategory(db, catName, now);
        await db.insert('session_category_links', {
          'session_id': session.id,
          'category_id': catId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // update exercises
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

  Future<void> updateSessionOrder(List<Session> sessions) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (int i = 0; i < sessions.length; i++) {
        final session = sessions[i];
        batch.update(
          'sessions',
          {'position': i},
          where: 'id = ?',
          whereArgs: [session.id],
        );
      }

      await batch.commit(noResult: true);
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        // Fallback for memory store (though unlikely to be needed for drag-drop in this specific catch block)
        return;
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
      'trackingType': row['tracking_type'] as String? ?? 'WEIGHT_AND_REPS',
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
