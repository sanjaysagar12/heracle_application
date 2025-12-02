import 'dart:io';
import '../api/story_service.dart';

class StoryRepository {
  final StoryService _service;

  StoryRepository({StoryService? service})
      : _service = service ?? StoryService();

  Future<void> createStory(File file, String caption) async {
    try {
      await _service.createStory(file, caption);
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }
}
