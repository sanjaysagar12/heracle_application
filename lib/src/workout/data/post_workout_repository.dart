import 'dart:convert';
import '../api/post_workout_service.dart';

class PostWorkoutRepository {
  final PostWorkoutService _service = PostWorkoutService();

  Future<void> postWorkout({
    required String caption,
    required bool isPublic,
    required List<String> tags,
    required int duration,
    required int volume,
    required List<Map<String, dynamic>> exercises,
    required List<String> imagePaths,
  }) async {
    try {
      final tagsString = tags.join(',');
      final exercisesString = jsonEncode(exercises);

      await _service.postWorkout(
        caption: caption,
        isPublic: isPublic,
        tags: tagsString,
        duration: duration,
        volume: volume,
        exercises: exercisesString,
        imagePaths: imagePaths,
      );
    } catch (e) {
      rethrow;
    }
  }
}
