import '../api/exercise_api.dart';
import 'exercise_repository.dart';
import 'models/session_model.dart';
import 'models/add_exercise_request.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  @override
  Future<List<Exercise>> getExercises() async {
    return await ExerciseApi.fetchExercises();
  }

  @override
  Future<void> addExerciseToSession(String sessionId, AddExerciseRequest request) async {
    return await ExerciseApi.addExerciseToSession(sessionId, request);
  }
}
