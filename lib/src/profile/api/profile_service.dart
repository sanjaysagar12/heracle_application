import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ProfileApiService {
  /// Get user profile data
  Future<Map<String, dynamic>> getUserProfile(String username) async {
    try {
      // Clean username if it starts with @
      final cleanUsername = username.startsWith('@') ? username.substring(1) : username;
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
  Future<List<Map<String, dynamic>>> getFollowers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': 'u1',
        'name': 'Sarah Miller',
        'username': 'sarah_m',
        'profileImageUrl': 'https://i.pravatar.cc/150?img=47',
        'isFollowing': true,
      },
      {
        'id': 'u2',
        'name': 'John Doe',
        'username': 'johndoe',
        'profileImageUrl': 'https://i.pravatar.cc/150?img=12',
         'isFollowing': false,
      },
      {
        'id': 'u3',
        'name': 'Emma Wilson',
        'username': 'emma_w',
        'profileImageUrl': 'https://i.pravatar.cc/150?img=20',
        'isFollowing': true,
      },
       {
        'id': 'u4',
        'name': 'Alex Thompson',
        'username': 'alex_t',
        'profileImageUrl': 'https://i.pravatar.cc/150?img=15',
        'isFollowing': false,
      },
       {
        'id': 'u5',
        'name': 'Emily Davis',
        'username': 'emily_d',
        'profileImageUrl': 'https://i.pravatar.cc/150?img=5',
        'isFollowing': true,
      },
    ];
  }

  /// Get following list
  Future<List<Map<String, dynamic>>> getFollowing() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': 'u6',
        'name': 'Mike Ross',
        'username': 'mikeross',
        'profileImageUrl': 'https://i.pravatar.cc/150?img=13',
        'isFollowing': true,
      },
      {
        'id': 'u7',
        'name': 'Rachel Green',
        'username': 'rachelg',
        'profileImageUrl': 'https://i.pravatar.cc/150?img=25',
        'isFollowing': true,
      },
      {
        'id': 'u1',
        'name': 'Sarah Miller',
        'username': 'sarah_m',
        'profileImageUrl': 'https://i.pravatar.cc/150?img=47',
        'isFollowing': true,
      },
       {
        'id': 'u3',
        'name': 'Emma Wilson',
        'username': 'emma_w',
        'profileImageUrl': 'https://i.pravatar.cc/150?img=20',
        'isFollowing': true,
      },
    ];
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

  /// Get user posts data
  Future<List<Map<String, dynamic>>> getUserPosts(String username) async {
    try {
      // Clean username if it starts with @
      final cleanUsername = username.startsWith('@') ? username.substring(1) : username;
      final response = await DioClient().dio.get('https://leno-api-heracle.portos.cloud/api/user/$cleanUsername/posts');
      
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
}
