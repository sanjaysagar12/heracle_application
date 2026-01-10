import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class ExerciseService {
  final DioClient _dioClient = DioClient();

  Future<List<dynamic>> fetchExercises() async {
    try {
      final response = await _dioClient.dio.get('/api/workout/exercises');
      
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> fetchCategories() async {
    try {
      final response = await _dioClient.dio.get('/api/workout/categories');
      
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
