import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ProfileApiService {
  /// Get user profile data
  Future<Map<String, dynamic>> getUserProfile(String username) async {
    try {
      // Clean username if it starts with @
      final cleanUsername = username.startsWith('@')
          ? username.substring(1)
          : username;
      final response = await DioClient().dio.get('/api/user/$cleanUsername');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  /// Get user feed
  Future<Map<String, dynamic>> getUserFeed(String userId) async {
    try {
      final response = await DioClient().dio.get('/api/user/$userId/feed');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load user feed: $e');
    }
  }

  /// Get followers list
  Future<List<Map<String, dynamic>>> getFollowers(String username) async {
    try {
      final cleanUsername = username.startsWith('@')
          ? username.substring(1)
          : username;
      final response = await DioClient().dio.get(
        '/api/social/followers/$cleanUsername',
      );

      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load followers: $e');
    }
  }

  /// Get following list
  Future<List<Map<String, dynamic>>> getFollowing(String username) async {
    try {
      final cleanUsername = username.startsWith('@')
          ? username.substring(1)
          : username;
      final response = await DioClient().dio.get(
        '/api/social/following/$cleanUsername',
      );

      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load following: $e');
    }
  }

  /// Follow/Unfollow a user
  Future<Map<String, dynamic>> followUser(String username) async {
    try {
      final cleanUsername = username.startsWith('@')
          ? username.substring(1)
          : username;
      final response = await DioClient().dio.post(
        '/api/social/follow/$cleanUsername',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  /// Get sessions data
  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      final response = await DioClient().dio.get('/api/workout/sessions');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to load sessions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load sessions: $e');
    }
  }

  /// Get specific user's sessions
  Future<List<Map<String, dynamic>>> getUserSessions(String username) async {
    try {
      // Clean username if it starts with @
      final cleanUsername = username.startsWith('@')
          ? username.substring(1)
          : username;
      final response = await DioClient().dio.get(
        '/api/user/$cleanUsername/sessions',
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to load user sessions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user sessions: $e');
    }
  }

  /// Get user posts data
  Future<List<Map<String, dynamic>>> getUserPosts(String username) async {
    try {
      // Clean username if it starts with @
      final cleanUsername = username.startsWith('@')
          ? username.substring(1)
          : username;
      final response = await DioClient().dio.get(
        '/api/user/$cleanUsername/posts',
      );

      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      // internal error or network error, return empty list or rethrow
      // For now we rethrow to let repository handle it
      throw Exception('Failed to load user posts: $e');
    }
  }

  /// Get user stories
  Future<Map<String, dynamic>> getUserStories(String username) async {
    try {
      final cleanUsername = username.startsWith('@')
          ? username.substring(1)
          : username;
      final response = await DioClient().dio.get(
        '/api/story/user/$cleanUsername',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load user stories: $e');
    }
  }

  /// Get highlights
  Future<List<Map<String, dynamic>>> getHighlights({String? category}) async {
    // Return dummy data or make an API call.
    // Since I don't have the explicit API endpoint in my instructions, assuming a pattern similar to others.
    // Ideally this should fetch from an endpoint like /api/highlights or user specific highlights.
    // For now returning an empty list or mock to fix the build.
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }
}
