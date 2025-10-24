import 'models/session_model.dart';

abstract class SessionRepository {
  Future<List<WorkoutSession>> getSessions();
}
