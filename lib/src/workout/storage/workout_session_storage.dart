import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/session_repository.dart';

class WorkoutSessionStorage {
  static final WorkoutSessionStorage instance = WorkoutSessionStorage._init();

  static Database? _database;

  // In-memory fallback storage
  final Map<String, Session> _memorySessions = {};
  final Map<String, List<Map<String, dynamic>>> _memoryExercises = {};

  WorkoutSessionStorage._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB('sessions.db');
      return _database!;
    } on MissingPluginException catch (e) {
      // Plugin not available (tests / web). Fall back to in-memory.
      print('WorkoutSessionStorage: MissingPluginException, using in-memory storage. $e');
      rethrow;
    } catch (e) {
      // Other errors: rethrow so callers can handle or fall back.
      print('WorkoutSessionStorage: DB init error: $e');
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // sessions table (no avatars column)
    await db.execute('''
    CREATE TABLE sessions (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      content TEXT,
      category TEXT,
      exercisesCount INTEGER NOT NULL,
      createdAt INTEGER NOT NULL
    )
    ''');

    // session_exercises table: each row linked to session via sessionId
    await db.execute('''
    CREATE TABLE session_exercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sessionId TEXT NOT NULL,
      exerciseId TEXT,
      name TEXT,
      image TEXT,
      sets TEXT,
      position INTEGER DEFAULT 0,
      FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
    )
    ''');
  }

  Future<void> insertSession(Session session) async {
    try {
      final db = await instance.database;
      final map = _sessionToMap(session);
      await db.insert(
        'sessions',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // insert exercises separately
      await deleteExercisesForSession(session.id);
      for (var i = 0; i < session.exercises.length; i++) {
        await insertSessionExercise(session.id, session.exercises[i], position: i);
      }

      // Debug log: verify insertion
      try {
        final count = (await db.query('sessions', where: 'id = ?', whereArgs: [session.id])).length;
        print('WorkoutSessionStorage: inserted session id=${session.id}, sessions_table_count_for_id=$count, exercises=${session.exercises.length}');
      } catch (e) {
        print('WorkoutSessionStorage: debug log failed: $e');
      }
    } catch (e) {
      // Fallback to in-memory if plugin not available or other DB errors
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        _memorySessions[session.id] = session;
        _memoryExercises[session.id] = session.exercises.map((e) => Map<String, dynamic>.from(e)).toList();
        print('WorkoutSessionStorage: saved session to in-memory store id=${session.id}, exercises=${session.exercises.length}');
        return;
      }
      rethrow;
    }
  }

  Future<void> insertSessionExercise(String sessionId, Map<String, dynamic> exercise, {int position = 0}) async {
    try {
      final db = await instance.database;
      final map = _exerciseToMap(sessionId, exercise, position);
      await db.insert('session_exercises', map, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        final list = _memoryExercises.putIfAbsent(sessionId, () => []);
        list.add(Map<String, dynamic>.from(exercise));
        return;
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExercisesForSession(String sessionId) async {
    try {
      final db = await instance.database;
      final rows = await db.query(
        'session_exercises',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
        orderBy: 'position ASC',
      );
      return rows.map((r) => _mapToExercise(r)).toList();
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        final mem = _memoryExercises[sessionId] ?? [];
        return mem.map((m) => Map<String, dynamic>.from(m)).toList();
      }
      rethrow;
    }
  }

  Future<void> deleteExercisesForSession(String sessionId) async {
    try {
      final db = await instance.database;
      await db.delete('session_exercises', where: 'sessionId = ?', whereArgs: [sessionId]);
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        _memoryExercises.remove(sessionId);
        return;
      }
      rethrow;
    }
  }

  Future<List<Session>> getAllSessions() async {
    try {
      final db = await instance.database;
      final result = await db.query('sessions', orderBy: 'createdAt DESC');
      final sessions = <Session>[];
      for (final row in result) {
        final session = _mapToSession(row);
        // load exercises for this session
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
        // return in-memory sessions
        return _memorySessions.values.toList();
      }
      rethrow;
    }
  }

  Future<Session?> getSessionById(String id) async {
    try {
      final db = await instance.database;
      final result = await db.query('sessions', where: 'id = ?', whereArgs: [id]);
      if (result.isNotEmpty) {
        final session = _mapToSession(result.first);
        final exercises = await getExercisesForSession(session.id);
        return Session(
          id: session.id,
          title: session.title,
          content: session.content,
          category: session.category,
          exercisesCount: session.exercisesCount,
          exercises: exercises,
        );
      }
      return null;
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        return _memorySessions[id];
      }
      rethrow;
    }
  }

  Future<int> updateSession(Session session) async {
    try {
      final db = await instance.database;
      final map = _sessionToMap(session);
      final res = await db.update('sessions', map, where: 'id = ?', whereArgs: [session.id]);

      // update exercises: replace all for simplicity
      await deleteExercisesForSession(session.id);
      for (var i = 0; i < session.exercises.length; i++) {
        await insertSessionExercise(session.id, session.exercises[i], position: i);
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
      final db = await instance.database;
      // delete exercises first (ON DELETE CASCADE may not be enabled consistently)
      await deleteExercisesForSession(id);
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

  Future close() async {
    try {
      final db = await instance.database;
      await db.close();
      _database = null;
    } catch (e) {
      // ignore missing plugin on close for in-memory fallback
      print('WorkoutSessionStorage: close ignored: $e');
      _database = null;
    }
  }

  // Helpers to convert between Session and Map (sessions table)
  Map<String, Object?> _sessionToMap(Session s) {
    return {
      'id': s.id,
      'title': s.title,
      'content': s.content,
      'category': s.category,
      'exercisesCount': s.exercisesCount,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Session _mapToSession(Map<String, Object?> row) {
    return Session(
      id: row['id'] as String,
      title: row['title'] as String,
      content: row['content'] as String? ?? '',
      category: row['category'] as String? ?? '',
      exercisesCount: (row['exercisesCount'] as int?) ?? 0,
      exercises: [], // will be populated after reading session_exercises
    );
  }

  // Helpers for session_exercises table
  Map<String, Object?> _exerciseToMap(String sessionId, Map<String, dynamic> ex, int position) {
    return {
      'sessionId': sessionId,
      'exerciseId': ex['id']?.toString(),
      'name': ex['name']?.toString(),
      'image': ex['image']?.toString(),
      'sets': jsonEncode(ex['sets'] ?? []),
      'position': position,
    };
  }

  Map<String, dynamic> _mapToExercise(Map<String, Object?> row) {
    final setsJson = row['sets'] as String?;
    final sets = setsJson == null ? <Map<String, dynamic>>[] : (jsonDecode(setsJson) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return {
      'id': row['exerciseId'] as String? ?? '',
      'name': row['name'] as String? ?? '',
      'image': row['image'] as String? ?? '',
      'sets': sets,
    };
  }

  /// Debug helper: prints all sessions and their exercises to console.
  Future<void> debugDumpAll() async {
    try {
      final db = await instance.database;
      final sessions = await db.query('sessions', orderBy: 'createdAt DESC');
      print('--- DB SESSIONS DUMP (${sessions.length}) ---');
      for (final s in sessions) {
        print('session row: $s');
        final sessionId = s['id'] as String;
        final exercises = await db.query('session_exercises', where: 'sessionId = ?', whereArgs: [sessionId], orderBy: 'position ASC');
        print('  exercises (${exercises.length}):');
        for (final ex in exercises) {
          print('    ex row: $ex');
        }
      }
      print('--- END DUMP ---');
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
