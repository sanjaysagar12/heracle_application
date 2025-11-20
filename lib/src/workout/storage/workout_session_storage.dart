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
  // optional in-memory logs fallback (keeps behavior consistent if needed)
  final Map<String, WorkoutLog> _memoryLogs = {};
  final Map<String, List<Map<String, dynamic>>> _memoryLogExercises = {};

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
    return await openDatabase(
      path,
      version: 2, // bump to 2 to support workout_logs migration
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // add workout_logs tables for version 2
          await db.execute('''
          CREATE TABLE workout_logs (
            id TEXT PRIMARY KEY,
            sessionId TEXT,
            title TEXT NOT NULL,
            completedAt INTEGER NOT NULL,
            duration INTEGER NOT NULL,
            totalVolume INTEGER NOT NULL,
            totalSets INTEGER NOT NULL,
            exercisesCount INTEGER NOT NULL
          )
          ''');
          await db.execute('''
          CREATE TABLE workout_log_exercises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            logId TEXT NOT NULL,
            exerciseId TEXT,
            name TEXT,
            desc TEXT,
            image TEXT,
            sets TEXT,
            position INTEGER DEFAULT 0,
            FOREIGN KEY (logId) REFERENCES workout_logs (id) ON DELETE CASCADE
          )
          ''');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    // sessions table
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

    // session_exercises table
    await db.execute('''
    CREATE TABLE session_exercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sessionId TEXT NOT NULL,
      exerciseId TEXT,
      name TEXT,
      desc TEXT,
      image TEXT,
      sets TEXT,
      position INTEGER DEFAULT 0,
      FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
    )
    ''');

    // workout_logs table (history)
    await db.execute('''
    CREATE TABLE workout_logs (
      id TEXT PRIMARY KEY,
      sessionId TEXT,
      title TEXT NOT NULL,
      completedAt INTEGER NOT NULL,
      duration INTEGER NOT NULL,
      totalVolume INTEGER NOT NULL,
      totalSets INTEGER NOT NULL,
      exercisesCount INTEGER NOT NULL
    )
    ''');

    // workout_log_exercises table
    await db.execute('''
    CREATE TABLE workout_log_exercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      logId TEXT NOT NULL,
      exerciseId TEXT,
      name TEXT,
      desc TEXT,
      image TEXT,
      sets TEXT,
      position INTEGER DEFAULT 0,
      FOREIGN KEY (logId) REFERENCES workout_logs (id) ON DELETE CASCADE
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
        final count =
            (await db.query('sessions', where: 'id = ?', whereArgs: [session.id]))
                .length;
        print(
            'WorkoutSessionStorage: inserted session id=${session.id}, sessions_table_count_for_id=$count, exercises=${session.exercises.length}');
      } catch (e) {
        print('WorkoutSessionStorage: debug log failed: $e');
      }
    } catch (e) {
      // Fallback to in-memory if plugin not available or other DB errors
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        _memorySessions[session.id] = session;
        _memoryExercises[session.id] =
            session.exercises.map((e) => Map<String, dynamic>.from(e)).toList();
        print(
            'WorkoutSessionStorage: saved session to in-memory store id=${session.id}, exercises=${session.exercises.length}');
        return;
      }
      rethrow;
    }
  }

  Future<void> insertSessionExercise(String sessionId, Map<String, dynamic> exercise,
      {int position = 0}) async {
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
      final result = await db.query('sessions', orderBy: 'createdAt DESC'); // most recent first
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
        // return in-memory sessions (sort by id descending as proxy for recency)
        final list = _memorySessions.values.toList();
        list.sort((a, b) => b.id.compareTo(a.id)); // most recent first (by ID)
        return list;
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
        _memoryExercises[session.id] =
            session.exercises.map((e) => Map<String, dynamic>.from(e)).toList();
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

  // Workout logs methods
  Future<void> insertWorkoutLog(WorkoutLog log) async {
    try {
      final db = await instance.database;
      final map = _workoutLogToMap(log);
      await db.insert(
        'workout_logs',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // insert exercises for this log
      await deleteExercisesForWorkoutLog(log.id);
      for (var i = 0; i < log.exercises.length; i++) {
        await insertWorkoutLogExercise(log.id, log.exercises[i], position: i);
      }

      print('WorkoutSessionStorage: inserted workout log id=${log.id}, exercises=${log.exercises.length}');
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        // fallback to in-memory
        _memoryLogs[log.id] = log;
        _memoryLogExercises[log.id] = log.exercises.map((e) => Map<String, dynamic>.from(e)).toList();
        print('WorkoutSessionStorage: saved workout log to in-memory id=${log.id}');
        return;
      }
      rethrow;
    }
  }

  Future<void> insertWorkoutLogExercise(String logId, Map<String, dynamic> exercise, {int position = 0}) async {
    try {
      final db = await instance.database;
      final map = _exerciseToMapForLog(logId, exercise, position);
      await db.insert('workout_log_exercises', map, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        final list = _memoryLogExercises.putIfAbsent(logId, () => []);
        list.add(Map<String, dynamic>.from(exercise));
        return;
      }
      rethrow;
    }
  }

  Future<void> deleteExercisesForWorkoutLog(String logId) async {
    try {
      final db = await instance.database;
      await db.delete('workout_log_exercises', where: 'logId = ?', whereArgs: [logId]);
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        _memoryLogExercises.remove(logId);
        return;
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExercisesForWorkoutLog(String logId) async {
    try {
      final db = await instance.database;
      final rows = await db.query(
        'workout_log_exercises',
        where: 'logId = ?',
        whereArgs: [logId],
        orderBy: 'position ASC',
      );
      return rows.map((r) => _mapToExercise(r)).toList();
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        final mem = _memoryLogExercises[logId] ?? [];
        return mem.map((m) => Map<String, dynamic>.from(m)).toList();
      }
      rethrow;
    }
  }

  Future<List<WorkoutLog>> getAllWorkoutLogs() async {
    try {
      final db = await instance.database;
      final result = await db.query('workout_logs', orderBy: 'completedAt DESC');
      final logs = <WorkoutLog>[];
      for (final row in result) {
        final log = _mapToWorkoutLog(row);
        final exercises = await getExercisesForWorkoutLog(log.id);
        final updated = WorkoutLog(
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
        logs.add(updated);
      }
      return logs;
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('No implementation found')) {
        // in-memory fallback (return memory logs sorted by insertion id)
        final list = _memoryLogs.values.toList();
        list.sort((a, b) => b.id.compareTo(a.id));
        return list;
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

  /// Debug method: delete database and recreate
  Future<void> resetDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'sessions.db');
      await deleteDatabase(path);
      _database = null;
      print('WorkoutSessionStorage: database deleted');
      // next call to database getter will recreate it
    } catch (e) {
      print('WorkoutSessionStorage: reset failed: $e');
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
      'desc': ex['desc']?.toString(),
      'image': ex['image']?.toString(),
      'sets': jsonEncode(ex['sets'] ?? []),
      'position': position,
    };
  }

  Map<String, dynamic> _mapToExercise(Map<String, Object?> row) {
    final setsJson = row['sets'] as String?;
    final sets = setsJson == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(setsJson) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return {
      'id': row['exerciseId'] as String? ?? '',
      'name': row['name'] as String? ?? '',
      'desc': row['desc'] as String? ?? '',
      'image': row['image'] as String? ?? '',
      'sets': sets,
    };
  }

  // Helpers for workout_logs table
  Map<String, Object?> _workoutLogToMap(WorkoutLog log) {
    return {
      'id': log.id,
      'sessionId': log.sessionId,
      'title': log.title,
      'completedAt': log.completedAt.millisecondsSinceEpoch,
      'duration': log.duration,
      'totalVolume': log.totalVolume,
      'totalSets': log.totalSets,
      'exercisesCount': log.exercisesCount,
    };
  }

  WorkoutLog _mapToWorkoutLog(Map<String, Object?> row) {
    return WorkoutLog(
      id: row['id'] as String,
      sessionId: row['sessionId'] as String?,
      title: row['title'] as String,
      completedAt: DateTime.fromMillisecondsSinceEpoch(row['completedAt'] as int),
      duration: (row['duration'] as int),
      totalVolume: (row['totalVolume'] as int),
      totalSets: (row['totalSets'] as int),
      exercisesCount: (row['exercisesCount'] as int),
      exercises: [],
    );
  }

  Map<String, Object?> _exerciseToMapForLog(String logId, Map<String, dynamic> ex, int position) {
    return {
      'logId': logId,
      'exerciseId': ex['id']?.toString(),
      'name': ex['name']?.toString(),
      'desc': ex['desc']?.toString(),
      'image': ex['image']?.toString(),
      'sets': jsonEncode(ex['sets'] ?? []),
      'position': position,
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
      final logs = await db.query('workout_logs', orderBy: 'completedAt DESC');
      print('--- DB WORKOUT LOGS DUMP (${logs.length}) ---');
      for (final l in logs) {
        print('log row: $l');
        final logId = l['id'] as String;
        final lex = await db.query('workout_log_exercises', where: 'logId = ?', whereArgs: [logId], orderBy: 'position ASC');
        print('  log exercises (${lex.length}):');
        for (final ex in lex) {
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
      print('--- IN-MEMORY LOGS DUMP (${_memoryLogs.length}) ---');
      for (final entry in _memoryLogs.entries) {
        print('log: ${entry.key} -> ${entry.value.title}, exercises: ${_memoryLogExercises[entry.key]?.length ?? 0}');
      }
      print('--- END IN-MEMORY DUMP ---');
    }
  }
}
