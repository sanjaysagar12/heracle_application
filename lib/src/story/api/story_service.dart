import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class StoryService {
  final DioClient _dioClient = DioClient();

  Future<void> createStory(File file, String caption, {bool isHighlighted = false}) async {
    try {
      String fileName = file.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'caption': caption,
        'isHighlighted': isHighlighted.toString(),
      });

      final response = await _dioClient.dio.post(
        '/api/story',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw Exception('Failed to create story: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating story: $e');
      rethrow;
    }
  }
}
