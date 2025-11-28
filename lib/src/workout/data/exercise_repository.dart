import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class ExerciseRepository {
  final DioClient _dioClient = DioClient();

  Future<List<Map<String, String>>> getExercises() async {
    try {
      final response = await _dioClient.dio.get('/api/workout/exercises');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => {
          'id': e['_id']?.toString() ?? '',
          'name': e['name']?.toString() ?? '',
          'desc': e['description']?.toString() ?? '',
          'image': e['gifUrl']?.toString() ?? '',
          'category': e['bodyPart']?.toString() ?? 'Other',
        }).toList();
      } else {
        throw Exception('Failed to load exercises');
      }
    } catch (e) {
      // Fallback to empty list or rethrow depending on requirement
      // For now rethrow to let UI handle error state if needed
      print('Error fetching exercises: $e');
      return [];
    }
  }
}
