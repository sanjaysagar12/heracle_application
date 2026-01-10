import '../api/exercise_service.dart';

class ExerciseRepository {
  final ExerciseService _service = ExerciseService();

  Future<List<Map<String, String>>> getExercises() async {
    try {
      final data = await _service.fetchExercises();
      
      return data.map((e) {
        final categories = e['category'] is List ? (e['category'] as List).join(', ') : (e['category']?.toString() ?? 'Other');
        return {
          'id': (e['id'] ?? e['_id'])?.toString() ?? '',
          'name': e['name']?.toString() ?? '',
          'desc': e['desc']?.toString() ?? e['description']?.toString() ?? '',
          'image': e['image']?.toString() ?? e['gifUrl']?.toString() ?? '',
          'category': categories,
          'trackingType': e['trackingType']?.toString() ?? 'WEIGHT_AND_REPS', // Default to WEIGHT_AND_REPS
        };
      }).toList();
    } catch (e) {
      // Fallback to empty list or rethrow depending on requirement
      // For now rethrow to let UI handle error state if needed
      print('Error fetching exercises: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> getCategories() async {
    try {
      final data = await _service.fetchCategories();
      return data.map((e) => {
        'id': e['id']?.toString() ?? '',
        'name': e['name']?.toString() ?? '',
        'image': e['image']?.toString() ?? '',
      }).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }
}
