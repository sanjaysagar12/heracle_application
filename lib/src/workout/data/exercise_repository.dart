import '../api/exercise_service.dart';

class ExerciseRepository {
  final ExerciseService _service = ExerciseService();

  Future<List<Map<String, String>>> getExercises() async {
    try {
      final data = await _service.fetchExercises();
      return _mapExercises(data);
    } catch (e) {
      print('Error fetching exercises: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> syncExercises() async {
    try {
      final data = await _service.syncExercises();
      return _mapExercises(data);
    } catch (e) {
      print('Error syncing exercises: $e');
      rethrow;
    }
  }

  List<Map<String, String>> _mapExercises(List<dynamic> data) {
    return data.map((e) {
      final categories = e['category'] is List
          ? (e['category'] as List).join(', ')
          : (e['category']?.toString() ?? 'Other');
      return {
        'id': (e['id'] ?? e['_id'])?.toString() ?? '',
        'name': e['name']?.toString() ?? '',
        'desc': e['desc']?.toString() ?? e['description']?.toString() ?? '',
        'image':
            e['image']?.toString() ??
            e['image_url']?.toString() ??
            e['gifUrl']?.toString() ??
            '',
        'category': categories,
        // Map trackingType from DB (tracking_type) or API (trackingType)
        'trackingType':
            e['trackingType']?.toString() ??
            e['tracking_type']?.toString() ??
            'WEIGHT_AND_REPS',
      };
    }).toList();
  }

  Future<List<Map<String, String>>> getCategories() async {
    try {
      final data = await _service.fetchCategories();
      return data
          .map(
            (e) => {
              'id': e['id']?.toString() ?? '',
              'name': e['name']?.toString() ?? '',
              'image': e['image']?.toString() ?? '',
            },
          )
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }
}
