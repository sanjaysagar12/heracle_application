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
}
