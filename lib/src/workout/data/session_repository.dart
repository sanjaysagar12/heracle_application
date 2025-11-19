import '../storage/workout_session_storage.dart';

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
  SessionRepository();
  
  Future<List<Session>> getSessionsFromDb() async {
    // fetch persisted sessions from storage
    return await WorkoutSessionStorage.instance.getAllSessions();
  }

  Future<void> saveSessionToDb(Session session) async {
    await WorkoutSessionStorage.instance.insertSession(session);
  }

  Future<void> saveWorkoutLogToDb(WorkoutLog log) async {
    await WorkoutSessionStorage.instance.insertWorkoutLog(log);
  }

  Future<List<WorkoutLog>> getWorkoutLogsFromDb() async {
    return await WorkoutSessionStorage.instance.getAllWorkoutLogs();
  }
}
