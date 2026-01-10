import '../../workout/data/session_repository.dart';
import '../../workout/api/workout_session_api_service.dart';

class ProfileSessionRepository extends SessionRepository {
  final WorkoutSessionApiService _apiService;

  ProfileSessionRepository({WorkoutSessionApiService? apiService})
      : _apiService = apiService ?? WorkoutSessionApiService();

  @override
  Future<void> deleteSession(String id) async {
    // For profile sessions, the 'id' is already the backend ID.
    // We skip the local DB lookup and call the API directly.
    try {
      await _apiService.deleteSession(id);
    } catch (e) {
      print('Failed to delete session from API: $e');
      rethrow;
    }
  }
}
