import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class MutualFeedService {
  final Dio _dio = DioClient().dio;

  Future<List<Map<String, dynamic>>> getMutualFeed() async {
    try {
      final response = await _dio.get('/api/post/feed/all');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to load mutual feed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final response = await _dio.get('/api/post/$postId/comments');
      
      if (response.data is Map<String, dynamic> && response.data.containsKey('comments')) {
        return List<Map<String, dynamic>>.from(response.data['comments']);
      }
      
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('DEBUG: getPostComments error: $e');
      throw Exception('Failed to load comments: $e');
    }
  }

  Future<Map<String, dynamic>> addComment(String postId, String content) async {
    try {
      final response = await _dio.post(
        '/api/post/$postId/comment',
        data: {'text': content},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<Map<String, dynamic>> addReply(
    String postId,
    String commentId,
    String content,
  ) async {
    try {
      final response = await _dio.post(
        '/api/post/comment/$commentId/reply',
        data: {'text': content},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to add reply: $e');
    }
  }
  Future<void> likePost(String postId) async {
    try {
      await _dio.post('/api/post/$postId/like');
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  Future<Map<String, dynamic>> getPostLikes(String postId) async {
    try {
      final response = await _dio.get('/api/post/$postId/likes');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load post likes: $e');
    }
  }

  Future<void> followUser(String username) async {
    try {
      final cleanUsername = username.startsWith('@') ? username.substring(1) : username;
      await _dio.post('/api/social/follow/$cleanUsername', data: {});
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }
}
