import '../storage/workout_session_storage.dart';
import '../storage/workout_logs_storage.dart';

class Session {
  final String id;
  final String title;
  final String content;
  final String category;
  final int exercisesCount;
  final List<Map<String, dynamic>> exercises; // list of exercise entries (each may include 'image')

  Session({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.exercisesCount,
    this.exercises = const [], // default empty
  });
}

class WorkoutLog {
  final String id;
  final String? sessionId; // optional: links to original session template
  final String title;
  final DateTime completedAt;
  final int duration; // in seconds
  final int totalVolume; // kg
  final int totalSets;
  final int exercisesCount;
  final List<Map<String, dynamic>> exercises;

  WorkoutLog({
    required this.id,
    this.sessionId,
    required this.title,
    required this.completedAt,
    required this.duration,
    required this.totalVolume,
    required this.totalSets,
    required this.exercisesCount,
    this.exercises = const [],
  });
}

class SessionRepository {
  final WorkoutSessionStorage _sessionStorage;
  final WorkoutLogsStorage _logsStorage;
  
  SessionRepository({
    WorkoutSessionStorage? sessionStorage,
    WorkoutLogsStorage? logsStorage,
  }) : _sessionStorage = sessionStorage ?? WorkoutSessionStorage.instance,
       _logsStorage = logsStorage ?? WorkoutLogsStorage.instance;
  
  Future<List<Session>> getSessionsFromDb() async {
    return await _sessionStorage.getAllSessions();
  }

  Future<void> saveSessionToDb(Session session) async {
    await _sessionStorage.insertSession(session);
  }

  Future<void> saveWorkoutLogToDb(WorkoutLog log) async {
    await _logsStorage.insertWorkoutLog(log);
  }

  Future<List<WorkoutLog>> getWorkoutLogsFromDb({int? limit, int? offset}) async {
    return await _logsStorage.getAllWorkoutLogs(limit: limit, offset: offset);
  }

  Future<WorkoutLog?> getWorkoutLogById(String id) async {
    return await _logsStorage.getWorkoutLogById(id);
  }

  Future<void> deleteWorkoutLog(String id) async {
    await _logsStorage.deleteWorkoutLog(id);
  }

  Future<void> deleteSession(String id) async {
    await _sessionStorage.deleteSession(id);
  }

  Future<Map<String, dynamic>> getWorkoutLogStats() async {
    return await _logsStorage.getWorkoutLogStats();
  }

  Future<void> updateSession(Session session) async {
    await _sessionStorage.updateSession(session);
  }
}
