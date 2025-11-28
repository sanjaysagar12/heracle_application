import '../api/exercise_service.dart';

class ExerciseRepository {
  final ExerciseService _service = ExerciseService();

  Future<List<Map<String, String>>> getExercises() async {
    try {
      final data = await _service.fetchExercises();
      
      return data.map((e) => {
        'id': e['_id']?.toString() ?? '',
        'name': e['name']?.toString() ?? '',
        'desc': e['description']?.toString() ?? '',
        'image': e['gifUrl']?.toString() ?? '',
        'category': e['bodyPart']?.toString() ?? 'Other',
      }).toList();
    } catch (e) {
      // Fallback to empty list or rethrow depending on requirement
      // For now rethrow to let UI handle error state if needed
      print('Error fetching exercises: $e');
      return [];
    }
  }
}
