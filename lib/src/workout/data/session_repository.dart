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

class SessionRepository {
  SessionRepository();
  
  Future<List<Session>> getSessionsFromDb() async {
    // fetch persisted sessions from storage
    return await WorkoutSessionStorage.instance.getAllSessions();
  }

  Future<void> saveSessionToDb(Session session) async {
    await WorkoutSessionStorage.instance.insertSession(session);
  }
}
