import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../data/session_repository.dart';

class WorkoutSessionApiService {
  final DioClient _dioClient = DioClient();

  Future<Map<String, dynamic>> createSession(Session session) async {
    try {
      final data = {
        "title": session.title,
        "content": session.content,
        "category": session.category,
        "position": session.position,
        "exercises": session.exercises.map((e) {
          return {
            "id": e['id'],
            "sets": (e['sets'] as List).map((s) {
              return {
                "kg": s['kg'],
                "reps": s['reps'],
              };
            }).toList(),
          };
        }).toList(),
      };

      final response = await _dioClient.dio.post(
        '/api/workout/sessions',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // The API returns an array, but for creation we usually expect a single object or the created object.
        // Based on the user request description: "the response will be like [ ... ]" for GET request.
        // For POST, typically it returns the created object. 
        // IF the user implies POST also returns a list or something else, I should check.
        // Assuming standard REST: returns the created object. 
        // Wait, the user said "send post request ... and then store it".
        // The user didn't explicitly specify POST response format, but usually it's the object.
        return response.data; 
      } else {
        throw Exception('Failed to create session: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getSessions() async {
    try {
      final response = await _dioClient.dio.get('/api/workout/sessions');
      
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Failed to load sessions: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
