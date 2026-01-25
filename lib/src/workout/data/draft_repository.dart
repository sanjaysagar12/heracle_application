import 'dart:convert';
import '../../../core/helper/database_helper.dart';

class DraftWorkout {
  final int? id;
  final String? sessionId;
  final String? sessionName;
  final int startTime;
  final String data; // JSON string of exercise logs
  final int createdAt;

  DraftWorkout({
    this.id,
    this.sessionId,
    this.sessionName,
    required this.startTime,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'session_name': sessionName,
      'start_time': startTime,
      'data': data,
      'created_at': createdAt,
    };
  }

  factory DraftWorkout.fromMap(Map<String, dynamic> map) {
    return DraftWorkout(
      id: map['id'],
      sessionId: map['session_id'],
      sessionName: map['session_name'],
      startTime: map['start_time'],
      data: map['data'],
      createdAt: map['created_at'],
    );
  }
}

class DraftRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> saveDraft(DraftWorkout draft) async {
    final db = await _dbHelper.database;
    // We only keep one draft at a time for simplicity in this version,
    // or maybe multiple? The requirement implies "if user comes out... resume".
    // Usually only one active workout allowed.
    // So we clear existing drafts before saving new validation.
    
    // Check if ID exists to update?
    // Actually, usually app state tracks the draft ID if it exists.
    // But since we want to resume even after kill, we effectively want a singleton draft.
    
    // Let's deleteAll first to ensure only one active draft.
    // Optimization: If we had an ID, update it. But simpler to just wipe and write for now or check.
    
    final existing = await getDraft();
    if (existing != null) {
      final values = draft.toMap();
      values.remove('id'); // ID is primary key and should not be updated to null
      await db.update(
        'draft_workouts',
        values,
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      await db.insert('draft_workouts', draft.toMap());
    }
  }

  Future<DraftWorkout?> getDraft() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'draft_workouts',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DraftWorkout.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteDraft() async {
    final db = await _dbHelper.database;
    await db.delete('draft_workouts');
  }

  Future<bool> hasDraft() async {
     final draft = await getDraft();
     return draft != null;
  }
}
