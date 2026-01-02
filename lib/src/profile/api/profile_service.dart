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



  /// Get highlights (video posts)
  Future<List<Map<String, dynamic>>> getHighlights({String? category}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      {
        'id': 'h1',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
        'videoUrl': 'https://example.com/video1.mp4',
        'views': 20300,
        'platform': 'tiktok',
        'category': 'Functional',
      },
      {
        'id': 'h2',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400',
        'videoUrl': 'https://example.com/video2.mp4',
        'views': 20300,
        'platform': 'tiktok',
        'category': 'Functional',
      },
      {
        'id': 'h3',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400',
        'videoUrl': 'https://example.com/video3.mp4',
        'views': 20300,
        'platform': null,
        'category': 'Functional',
      },
      {
        'id': 'h4',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1550345332-09e3ac987658?w=400',
        'videoUrl': 'https://example.com/video4.mp4',
        'views': 20300,
        'platform': 'tiktok',
        'category': 'Biceps',
      },
      {
        'id': 'h5',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1581009146145-b5ef050c149a?w=400',
        'videoUrl': 'https://example.com/video5.mp4',
        'views': 20300,
        'platform': null,
        'category': 'Functional',
      },
      {
        'id': 'h6',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400',
        'videoUrl': 'https://example.com/video6.mp4',
        'views': 20300,
        'platform': 'tiktok',
        'category': 'Triceps',
      },
      {
        'id': 'h7',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400',
        'videoUrl': 'https://example.com/video7.mp4',
        'views': 20300,
        'platform': null,
        'category': 'Functional',
      },
      {
        'id': 'h8',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=400',
        'videoUrl': 'https://example.com/video8.mp4',
        'views': 20300,
        'platform': 'tiktok',
        'category': 'Biceps',
      },
      {
        'id': 'h9',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=400',
        'videoUrl': 'https://example.com/video9.mp4',
        'views': 20300,
        'platform': null,
        'category': 'Functional',
      },
    ];
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
