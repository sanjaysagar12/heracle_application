import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'heracle_app.db');
      
      return await openDatabase(
        path,
        version: 1, // Fresh install starts at version 1
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } on MissingPluginException catch (e) {
      print('DatabaseHelper: MissingPluginException - Plugin not available: $e');
      rethrow;
    } catch (e) {
      print('DatabaseHelper: Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createTables(Database db, int version) async {
    final batch = db.batch();
    
    // Create exercises table (master data)
    batch.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        category TEXT,
        tracking_type TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create session_categories table
    batch.execute('''
      CREATE TABLE session_categories (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create session_category_links table (Many-to-Many)
    batch.execute('''
      CREATE TABLE session_category_links (
        session_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        PRIMARY KEY (session_id, category_id),
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES session_categories (id) ON DELETE CASCADE
      )
    ''');

    // Create sessions table
    batch.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        backend_id TEXT,
        title TEXT NOT NULL,
        content TEXT,
        exercises_count INTEGER NOT NULL,
        position INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create session_exercises table
    batch.execute('''
      CREATE TABLE session_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        sets_data TEXT,
        position INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    // Create workout_logs table
    batch.execute('''
      CREATE TABLE workout_logs (
        id TEXT PRIMARY KEY,
        session_id TEXT,
        title TEXT NOT NULL,
        completed_at INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        total_volume INTEGER NOT NULL,
        total_sets INTEGER NOT NULL,
        exercises_count INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE SET NULL
      )
    ''');

    // Create workout_log_exercises table
    batch.execute('''
      CREATE TABLE workout_log_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_log_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        sets_data TEXT,
        position INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (workout_log_id) REFERENCES workout_logs (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    // Create targets table for fitness goals
    batch.execute('''
      CREATE TABLE targets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_type TEXT NOT NULL UNIQUE,
        target_value INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Insert default targets
    final now = DateTime.now().millisecondsSinceEpoch;
    batch.execute('''
      INSERT INTO targets (target_type, target_value, created_at, updated_at) VALUES
      ('steps', 10000, $now, $now),
      ('cals_burned', 500, $now, $now),
      ('cals_taken', 2000, $now, $now),
      ('protein_taken', 150, $now, $now)
    ''');

    // Create indexes for better performance
    batch.execute('CREATE INDEX idx_exercises_category ON exercises (category)');
    batch.execute('CREATE INDEX idx_sessions_created_at ON sessions (created_at DESC)');
    batch.execute('CREATE INDEX idx_session_exercises_session_id ON session_exercises (session_id)');
    batch.execute('CREATE INDEX idx_session_exercises_exercise_id ON session_exercises (exercise_id)');
    batch.execute('CREATE INDEX idx_workout_logs_completed_at ON workout_logs (completed_at DESC)');
    batch.execute('CREATE INDEX idx_workout_log_exercises_log_id ON workout_log_exercises (workout_log_id)');
    batch.execute('CREATE INDEX idx_workout_log_exercises_exercise_id ON workout_log_exercises (exercise_id)');
    batch.execute('CREATE INDEX idx_targets_type ON targets (target_type)');

    await batch.commit();
    print('DatabaseHelper: All tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No upgrades needed as we're starting fresh with the latest schema
    print('DatabaseHelper: Upgrading database from version $oldVersion to $newVersion (Clean Install Logic)');
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('DatabaseHelper: Database closed');
    }
  }

  Future<void> deleteDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'heracle_app.db');
      await databaseFactory.deleteDatabase(path);
      _database = null;
      print('DatabaseHelper: Database deleted successfully');
    } catch (e) {
      print('DatabaseHelper: Error deleting database: $e');
      rethrow;
    }
  }

  // Utility method for database health check
  Future<bool> isDatabaseHealthy() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT 1');
      return result.isNotEmpty;
    } catch (e) {
      print('DatabaseHelper: Database health check failed: $e');
      return false;
    }
  }

  // Get database info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final db = await database;
      final version = await db.getVersion();
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'heracle_app.db');
      
      return {
        'version': version,
        'path': path,
        'isOpen': db.isOpen,
      };
    } catch (e) {
      print('DatabaseHelper: Error getting database info: $e');
      return {};
    }
  }
}
