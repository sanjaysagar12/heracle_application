import 'models/session_model.dart';
import 'models/add_exercise_request.dart';

abstract class ExerciseRepository {
  Future<List<Exercise>> getExercises();
  Future<void> addExerciseToSession(String sessionId, AddExerciseRequest request);
}
