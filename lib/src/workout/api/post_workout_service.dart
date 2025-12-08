import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:heracle/core/network/dio_client.dart';

class PostWorkoutService {
  final DioClient _dioClient = DioClient();

  Future<Response> postWorkout({
    required String caption,
    required bool isPublic,
    required String tags,
    required int duration,
    required int volume,
    required String exercises, // JSON string
    required String? imagePath,
  }) async {
    try {
      // Validate exercises JSON structure
      final exercisesList = jsonDecode(exercises);
      if (exercisesList is! List) throw const FormatException('Exercises must be a list');
      _validateExercises(exercisesList);

      final Map<String, dynamic> data = {
        'caption': caption,
        'isPublic': isPublic,
        'tags': tags,
        'duration': duration,
        'volume': volume,
        'exercises': exercises,
      };

      if (imagePath != null && imagePath.isNotEmpty) {
        data['images'] = await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        );
      }

      final formData = FormData.fromMap(data);

      final response = await _dioClient.dio.post(
        '/api/post', // Assuming base URL is set in DioClient and we append /post
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  void _validateExercises(List<dynamic> exercises) {
    for (var ex in exercises) {
      if (ex is! Map<String, dynamic>) throw const FormatException('Invalid exercise format');
      if (!ex.containsKey('exerciseId') || ex['exerciseId'] is! String) {
        throw const FormatException('Missing or invalid exerciseId');
      }
      if (!ex.containsKey('exercise') || ex['exercise'] is! String) {
        throw const FormatException('Missing or invalid exercise name');
      }
      if (!ex.containsKey('sets') || ex['sets'] is! List) {
        throw const FormatException('Missing or invalid sets');
      }

      for (var set in ex['sets']) {
        if (set is! Map<String, dynamic>) throw const FormatException('Invalid set format');
        if (!set.containsKey('setNumber') || set['setNumber'] is! int) {
          throw const FormatException('Missing or invalid setNumber');
        }
        if (!set.containsKey('kg') || set['kg'] is! num) {
          throw const FormatException('Missing or invalid kg');
        }
        if (!set.containsKey('reps') || set['reps'] is! int) {
          throw const FormatException('Missing or invalid reps');
        }
        if (!set.containsKey('restSeconds') || set['restSeconds'] is! int) {
          throw const FormatException('Missing or invalid restSeconds');
        }
      }
    }
  }
}
