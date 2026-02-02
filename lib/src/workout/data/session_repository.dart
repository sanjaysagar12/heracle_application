import '../storage/workout_session_storage.dart';
import '../storage/workout_logs_storage.dart';
import '../api/workout_session_api_service.dart';

class Session {
  final String id;
  final String backendId;
  final String title;
  final String content;
  final List<String> categories; // Refactored to list for M:N
  final int exercisesCount;
  final int position;
  final List<Map<String, dynamic>> exercises;

  Session({
    required this.id,
    this.backendId = '',
    required this.title,
    required this.content,
    this.categories = const [],
    required this.exercisesCount,
    this.position = 0,
    this.exercises = const [],
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
  final WorkoutSessionApiService _apiService;

  SessionRepository({
    WorkoutSessionStorage? sessionStorage,
    WorkoutLogsStorage? logsStorage,
    WorkoutSessionApiService? apiService,
  }) : _sessionStorage = sessionStorage ?? WorkoutSessionStorage.instance,
       _logsStorage = logsStorage ?? WorkoutLogsStorage.instance,
       _apiService = apiService ?? WorkoutSessionApiService();

  Future<List<Session>> getSessionsFromDb() async {
    return await _sessionStorage.getAllSessions();
  }

  Future<void> saveSessionToDb(Session session) async {
    Session sessionToSave = session;
    try {
      final response = await _apiService.createSession(session);
      // Assuming response contains 'id' field as per user request: { "id": "string" }
      if (response['id'] != null) {
        sessionToSave = Session(
          id: session.id,
          backendId: response['id'].toString(),
          title: session.title,
          content: session.content,
          categories: session.categories,
          exercisesCount: session.exercisesCount,
          position: session.position,
          exercises: session.exercises,
        );
      }
    } catch (e) {
      print('Failed to save session to API: $e');
      rethrow;
    }
    await _sessionStorage.insertSession(sessionToSave);
  }

  Future<void> saveWorkoutLogToDb(WorkoutLog log) async {
    await _logsStorage.insertWorkoutLog(log);
  }

  Future<List<WorkoutLog>> getWorkoutLogsFromDb({
    int? limit,
    int? offset,
  }) async {
    return await _logsStorage.getAllWorkoutLogs(limit: limit, offset: offset);
  }

  Future<WorkoutLog?> getWorkoutLogById(String id) async {
    return await _logsStorage.getWorkoutLogById(id);
  }

  Future<void> deleteWorkoutLog(String id) async {
    await _logsStorage.deleteWorkoutLog(id);
  }

  Future<void> deleteSession(String id) async {
    try {
      final session = await _sessionStorage.getSessionById(id);
      if (session != null && session.backendId.isNotEmpty) {
        await _apiService.deleteSession(session.backendId);
      }
    } catch (e) {
      print('Failed to delete session from API: $e');
      // Continue to delete locally even if offline?
      // Usually yes for user experience, but rethrowing lets UI know.
      // Assuming we want to delete locally regardless:
    }
    await _sessionStorage.deleteSession(id);
  }

  Future<Map<String, dynamic>> getWorkoutLogStats() async {
    return await _logsStorage.getWorkoutLogStats();
  }

  Future<void> updateSession(Session session) async {
    try {
      // Use backendId if available, otherwise fallback (or throw? assuming backendId is crucial for sync)
      final apiId = session.backendId.isNotEmpty
          ? session.backendId
          : session.id;
      // Note: If session was created offline, backendId might be empty.
      // Ideally we should sync first, but for now we follow user instruction to use this ID for editing.

      await _apiService.updateSession(apiId, session);
    } catch (e) {
      print('Failed to update session API: $e');
      rethrow;
    }
    await _sessionStorage.updateSession(session);
  }

  Future<void> updateSessionOrder(List<Session> sessions) async {
    await _sessionStorage.updateSessionOrder(sessions);
  }

  Future<void> syncSessionsOnLogin() async {
    try {
      // 1. Clear local data
      await _sessionStorage.clearAllData();

      // 2. Fetch from API
      final data = await _apiService.getSessions();

      // 3. Insert into local DB
      for (var item in data) {
        final session = Session(
          id: item['id']?.toString() ?? '',
          backendId:
              item['id']?.toString() ??
              '', // Treat API ID as backendId AND local ID initially? Or generate new local ID?
          // Usually sync keeps IDs consistent if possible. Let's use API ID as local ID for simplicity unless UUIDs clash.
          title: item['title'] ?? '',
          content: item['content'] ?? '',
          categories:
              (item['categories'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          exercisesCount: item['exercises'] != null
              ? (item['exercises'] as List).length
              : 0,
          position: item['position'] ?? 0,
          exercises:
              (item['exercises'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [],
        );
        await _sessionStorage.insertSession(session);
      }
      print('SessionRepository: Synced sessions successfully.');
    } catch (e) {
      print('SessionRepository: Failed to sync sessions: $e');
      // Don't rethrow to avoid blocking login flow? Or should we?
      // Usually better to log and continue, maybe show snackbar if context available (not here).
    }
  }
}
