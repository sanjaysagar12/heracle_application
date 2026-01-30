import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../../../../core/network/dio_client.dart';

class StoriesService {
  final DioClient _dioClient = DioClient();

  /// Fetch stories carousel from backend using the new API endpoint.
  /// Falls back to mock data if any network error occurs.
  Future<List<Map<String, dynamic>>> getStories() async {
    try {
      // Get stories carousel with Bearer token
      final response = await _dioClient.dio.get(
        '/api/story/carousel'
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch story carousel: ${response.statusCode}');
      }

      final responseData = response.data as Map<String, dynamic>;
      final List<dynamic> items = responseData['items'] as List<dynamic>;

      // Transform API response to match UI expectations
      return items.map((item) {
        final username = (item['username'] as String?) ?? '';
        final name = (item['name'] as String?) ?? username;
        final avatarUrl = (item['avatarUrl'] as String?) ?? '';
        final isViewed = (item['isViewed'] as bool?) ?? false;
        final storiesData = (item['stories'] as List<dynamic>?) ?? [];

        // Map stories to legacy format
        final stories = storiesData.map((story) {
          final id = story['id'] as String? ?? '';
          final mediaType = (story['mediaType'] as String? ?? 'IMAGE').toUpperCase();
          final mediaUrl = story['mediaUrl'] as String? ?? '';
          final thumbnailUrl = story['thumbnailUrl'] as String? ?? '';
          final caption = story['caption'] as String? ?? '';
          final isLiked = story['isLiked'] as bool? ?? false;
          final likes = story['likes'] as int? ?? 0;
          final views = story['views'] as int? ?? 0;
          
          final isHighlighted = story['isHighlighted'] as bool? ?? false;
          
          return {
            'id': id,
            'type': mediaType == 'IMAGE' ? 'image' : (mediaType == 'VIDEO' ? 'video' : 'image'),
            'mediaUrl': mediaUrl,
            'thumbnailUrl': thumbnailUrl,
            'text': caption,
            'duration': 5,
            'isLiked': isLiked,
            'likes': likes,
            'views': views,
            'likedBy': <Map<String, dynamic>>[], 
            'isHighlighted': isHighlighted,
          };
        }).toList();

        return {
          'id': username,
          'username': username, // Use handle
          'name': name, // Use display name
          'profileImage': avatarUrl ?? '',
          'hasStory': stories.isNotEmpty,
          'isViewed': isViewed,
          'stories': stories,
        };
      }).toList().cast<Map<String, dynamic>>();

    } catch (e, st) {
      developer.log('StoriesService.getStories API failed: $e\n$st');
      throw Exception('Failed to fetch stories: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDiscoverStories() async {
    try {
      // Fetch discover stories from backend
      final response = await _dioClient.dio.get(
        '/api/feed',
        queryParameters: {
          'page': 1,
          'limit': 10,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch discover stories: ${response.statusCode}');
      }

      final responseData = response.data as Map<String, dynamic>;
      final List<dynamic> items = responseData['items'] as List<dynamic>;

      return items.cast<Map<String, dynamic>>();

    } catch (e, st) {
      developer.log('StoriesService.getDiscoverStories API failed: $e\n$st');
      throw Exception('Failed to fetch discover stories: $e');
    }
  }

  /// Send like request for a discover story
  Future<void> likeDiscoverStory(String storyId) async {
    try {
      final response = await _dioClient.dio.post('/api/feed/$storyId/like');
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to like discover story: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error liking discover story: $e');
      rethrow;
    }
  }

  /// Search for users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/social/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to search users: ${response.statusCode}');
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data.cast<Map<String, dynamic>>(); 
    } catch (e) {
      developer.log('Error searching users: $e');
      rethrow;
    }
  }

  /// Fetch user's own stories
  Future<Map<String, dynamic>> getMyStories() async {
    try {
      final response = await _dioClient.dio.get('/api/story/my');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch my stories: ${response.statusCode}');
      }

      final responseData = response.data as Map<String, dynamic>;
      final user = responseData['user'] as Map<String, dynamic>;
      final storiesData = responseData['stories'] as List<dynamic>;

      final stories = storiesData.map((story) {
        final id = story['id'] as String? ?? '';
        final mediaType = (story['mediaType'] as String? ?? 'IMAGE').toUpperCase();
          final mediaUrl = story['mediaUrl'] as String? ?? story['imageUrl'] as String? ?? '';
        final thumbnailUrl = story['thumbnailUrl'] as String? ?? story['thumbnail'] as String? ?? '';
        final caption = story['caption'] as String? ?? story['text'] as String? ?? '';
        final isLiked = story['isLiked'] as bool? ?? false;
        final likes = story['likes'] as int? ?? 0;
        final views = story['views'] as int? ?? 0;
        
        final isHighlighted = story['isHighlighted'] as bool? ?? false;
        
        return {
          'id': id,
          'type': mediaType == 'IMAGE' ? 'image' : (mediaType == 'VIDEO' ? 'video' : 'image'),
          'mediaUrl': mediaUrl,
          'thumbnailUrl': thumbnailUrl,
          'text': caption,
          'duration': 5,
          'isLiked': isLiked,
          'likes': likes,
          'views': views,
          'likedBy': <Map<String, dynamic>>[],
          'isHighlighted': isHighlighted,
        };
      }).toList();

      return {
        'id': user['id'] ?? 'me',
        'username': user['username'] ?? 'You', // Use handle
        'name': user['name'] ?? '', // Use name
        'profileImage': user['avatarUrl'] ?? '',
        'hasStory': stories.isNotEmpty,
        'isViewed': false,
        'isMyStory': true, // Special flag to indicate this is user's own story
        'stories': stories,
      };
    } catch (e) {
      developer.log('Error fetching my stories: $e');
      // Return empty story user if error
      return {
        'id': 'me',
        'username': 'You',
        'name': '',
        'profileImage': '',
        'hasStory': false,
        'isViewed': false,
        'isMyStory': true,
        'stories': [],
      };
    }
  }

  /// Send like request for a story
  Future<void> likeStory(String storyId) async {
    try {
      final response = await _dioClient.dio.post('/api/story/$storyId/like');
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to like story: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error liking story: $e');
      rethrow;
    }
  }

  /// Send comment on a story
  Future<Map<String, dynamic>> commentOnStory(String storyId, String text) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/story/$storyId/comment',
        data: {'text': text},
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to comment on story: ${response.statusCode}');
      }
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Error commenting on story: $e');
      rethrow;
    }
  }

  /// Reply to a comment
  Future<Map<String, dynamic>> replyToComment(String commentId, String text) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/story/comment/$commentId/reply',
        data: {'text': text},
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to reply to comment: ${response.statusCode}');
      }
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Error replying to comment: $e');
      rethrow;
    }
  }

  /// Delete a story comment
  Future<void> deleteStoryComment(String commentId) async {
    try {
      final response = await _dioClient.dio.delete('/api/story/comment/$commentId');
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
      developer.log('Story comment deleted successfully: $commentId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Treat 404 as success (comment already deleted)
        developer.log('Comment deletion returned 404, treating as success: $commentId');
        return;
      }
      developer.log('Error deleting story comment: $e');
      rethrow;
    } catch (e) {
      developer.log('Error deleting story comment: $e');
      rethrow;
    }
  }

  /// Highlight a story
  Future<void> highlightStory(String storyId, bool isHighlighted) async {
    try {
      final response = await _dioClient.dio.patch(
        '/api/story/$storyId/highlight',
        data: {'isHighlighted': isHighlighted},
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to highlight story: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error highlighting story: $e');
      rethrow;
    }
  }

  /// Delete a story
  Future<void> deleteStory(String storyId) async {
    try {
      final response = await _dioClient.dio.delete('/api/story/$storyId');
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete story: ${response.statusCode}');
      }
      developer.log('Story deleted successfully: $storyId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Treat 404 as success (resource already gone or route issue handled gracefully)
        developer.log('Story deletion returned 404, treating as success: $storyId');
        return;
      }
      developer.log('Error deleting story: $e');
      rethrow;
    } catch (e) {
      developer.log('Error deleting story: $e');
      rethrow;
    }
  }

  /// Record a view for a story
  Future<void> viewStory(String storyId) async {
    try {
      // Fire and forget view recording
      await _dioClient.dio.post('/api/story/$storyId/view');
    } catch (e) {
      // Log error but don't disrupt UI for view tracking
      developer.log('Error recording story view: $e');
    }
  }

  /// Get comments for a story
  Future<List<Map<String, dynamic>>> getStoryComments(String storyId) async {
    try {
      final response = await _dioClient.dio.get('/api/story/$storyId/comments');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch story comments: ${response.statusCode}');
      }

      final responseData = response.data as Map<String, dynamic>;
      final List<dynamic> comments = responseData['comments'] as List<dynamic>;
      
      return comments.cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('Error fetching story comments: $e');
      rethrow;
    }
  }

  /// Get story details (views, likes)
  Future<Map<String, dynamic>> getStoryDetails(String storyId) async {
    try {
      final response = await _dioClient.dio.get('/api/story/$storyId/engagement');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch story details: ${response.statusCode}');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Error fetching story details: $e');
      rethrow;
    }
  }

  List<String> _extractHashtags(String text) {
    final RegExp hashtagRegex = RegExp(r'#(\w+)');
    final matches = hashtagRegex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }

  String _calculateTimeAgo(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }


}
