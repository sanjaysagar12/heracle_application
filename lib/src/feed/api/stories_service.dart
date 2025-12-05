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
          final imageUrl = story['imageUrl'] as String? ?? '';
          final caption = story['caption'] as String? ?? '';
          final isLiked = story['isLiked'] as bool? ?? false;
          final likes = story['likes'] as int? ?? 0;
          final views = story['views'] as int? ?? 0;
          
          return {
            'id': id,
            'type': mediaType == 'IMAGE' ? 'image' : (mediaType == 'VIDEO' ? 'video' : 'image'),
            'imageUrl': imageUrl,
            'text': caption,
            'duration': 5,
            'isLiked': isLiked,
            'likes': likes,
            'views': views,
            'likedBy': <Map<String, dynamic>>[], // Can be extended later
          };
        }).toList();

        return {
          'id': username,
          'username': name,
          'profileImage': avatarUrl ?? '',
          'hasStory': stories.isNotEmpty,
          'isViewed': isViewed,
          'stories': stories,
        };
      }).toList().cast<Map<String, dynamic>>();

    } catch (e, st) {
      developer.log('StoriesService.getStories API failed, falling back to mock data: $e\n$st');
      // Fallback: original mock data (keeps UI working)
      return [
        {
          'id': '1',
          'username': 'Kendra Jane',
          'profileImage': 'https://i.pravatar.cc/150?img=45',
          'hasStory': true,
          'isViewed': false,
          'stories': [
            {
              'id': '1_1',
              'type': 'image',
              'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
              'text': 'Leg day completed! 💪',
              'duration': 5,
              'isLiked': false,
              'likedBy': [
                {'name': 'Sarah Miller', 'profileImage': 'https://i.pravatar.cc/150?img=47', 'isFollowing': false},
                {'name': 'Johnny Bhai', 'profileImage': 'https://i.pravatar.cc/150?img=12', 'isFollowing': true},
              ],
            },
            {
              'id': '1_2',
              'type': 'image',
              'imageUrl': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=800',
              'text': 'New PR on squats! 🏋️',
              'duration': 5,
            },
            {
              'id': '1_3',
              'type': 'text',
              'text': 'Gym motivation:\n\n"The pain you feel today will be the strength you feel tomorrow"',
              'backgroundColor': '#D4FC79',
              'duration': 4,
            },
          ],
        },
        {
          'id': '2',
          'username': 'Johnny Bhai',
          'profileImage': 'https://i.pravatar.cc/150?img=12',
          'hasStory': true,
          'isViewed': false,
          'stories': [
            {
              'id': '2_1',
              'type': 'image',
              'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
              'text': 'Cardio session 🏃‍♂️',
              'duration': 5,
            },
            {
              'id': '2_2',
              'type': 'image',
              'imageUrl': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
              'text': 'Morning grind 🌅',
              'duration': 5,
            },
          ],
        },
        {
          'id': '3',
          'username': 'Joseph Ismati',
          'profileImage': 'https://i.pravatar.cc/150?img=33',
          'hasStory': true,
          'isViewed': false,
          'stories': [
            {
              'id': '3_1',
              'type': 'image',
              'imageUrl': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800',
              'text': 'Chest and back today',
              'duration': 5,
            },
            {
              'id': '3_2',
              'type': 'text',
              'text': 'Protein shake recipe:\n\n- 2 scoops protein\n- 1 banana\n- Almond milk\n- Peanut butter',
              'backgroundColor': '#FF6B6B',
              'duration': 6,
            },
            {
              'id': '3_3',
              'type': 'image',
              'imageUrl': 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800',
              'text': 'Post workout meal 🍗',
              'duration': 5,
            },
          ],
        },
        {
          'id': '4',
          'username': 'Ronnie Herr',
          'profileImage': 'https://i.pravatar.cc/150?img=56',
          'hasStory': true,
          'isViewed': false,
          'stories': [
            {
              'id': '4_1',
              'type': 'image',
              'imageUrl': 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800',
              'text': 'Arm day 💪',
              'duration': 5,
            },
          ],
        },
        {
          'id': '5',
          'username': 'Sarah Miller',
          'profileImage': 'https://i.pravatar.cc/150?img=47',
          'hasStory': true,
          'isViewed': false,
          'stories': [
            {
              'id': '5_1',
              'type': 'image',
              'imageUrl': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
              'text': 'Yoga flow 🧘‍♀️',
              'duration': 5,
            },
            {
              'id': '5_2',
              'type': 'image',
              'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
              'text': 'Stretching is important!',
              'duration': 5,
            },
          ],
        },
      ];
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

      return items.map((item) {
        final user = item['user'] as Map<String, dynamic>;
        final createdAt = item['createdAt'] as String;
        
        return {
          'id': item['id'],
          'username': user['username'] ?? '',
          'profileImage': user['avatarUrl'] ?? '',
          'content': item['caption'] ?? '',
          'hashtags': _extractHashtags(item['caption'] ?? ''),
          'imageUrl': item['mediaUrl'] ?? '',
          'mediaType': item['mediaType'] ?? 'IMAGE',
          'platform': 'Heracle', // Default platform for internal feed
          'platformHandle': '@${user['username'] ?? ''}',
          'label': '',
          'timeAgo': _calculateTimeAgo(createdAt),
          'isLiked': item['isLiked'] ?? false,
          'likesCount': item['likeCount'] ?? 0,
          'likedBy': <Map<String, dynamic>>[], // API doesn't return likedBy list
        };
      }).toList().cast<Map<String, dynamic>>();

    } catch (e, st) {
      developer.log('StoriesService.getDiscoverStories API failed, falling back to mock data: $e\n$st');
      return _getMockDiscoverStories();
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
        final imageUrl = story['imageUrl'] as String? ?? '';
        final caption = story['caption'] as String? ?? '';
        final isLiked = story['isLiked'] as bool? ?? false;
        final likes = story['likes'] as int? ?? 0;
        final views = story['views'] as int? ?? 0;
        
        return {
          'id': id,
          'type': mediaType == 'IMAGE' ? 'image' : (mediaType == 'VIDEO' ? 'video' : 'image'),
          'imageUrl': imageUrl,
          'text': caption,
          'duration': 5,
          'isLiked': isLiked,
          'likes': likes,
          'views': views,
          'likedBy': <Map<String, dynamic>>[],
        };
      }).toList();

      return {
        'id': user['id'] ?? 'me',
        'username': user['name'] ?? user['username'] ?? 'You',
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
  Future<void> commentOnStory(String storyId, String text) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/story/$storyId/comment',
        data: {'text': text},
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to comment on story: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error commenting on story: $e');
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

  List<Map<String, dynamic>> _getMockDiscoverStories() {
    return [
      {
        'id': '1',
        'username': 'Kendra Jane',
        'profileImage': 'https://i.pravatar.cc/150?img=45',
        'content': 'had a nice workout sessions',
        'hashtags': ['Gymills'],
        'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
        'platform': 'TikTok',
        'platformHandle': '@radhew',
        'label': 'AB ATTACK',
        'timeAgo': '2h ago',
        'isLiked': false,
        'likesCount': 124,
        'likedBy': [
          {'name': 'Sarah Miller', 'profileImage': 'https://i.pravatar.cc/150?img=47', 'isFollowing': false},
          {'name': 'Johnny Bhai', 'profileImage': 'https://i.pravatar.cc/150?img=12', 'isFollowing': true},
          {'name': 'Joseph Ismati', 'profileImage': 'https://i.pravatar.cc/150?img=33', 'isFollowing': false},
          {'name': 'Ronnie Herr', 'profileImage': 'https://i.pravatar.cc/150?img=56', 'isFollowing': true},
          {'name': 'Emma Wilson', 'profileImage': 'https://i.pravatar.cc/150?img=20', 'isFollowing': false},
        ],
      },
      {
        'id': '2',
        'username': 'Kendra Jane',
        'profileImage': 'https://i.pravatar.cc/150?img=45',
        'content': '''Just finished a 45-minute HIIT session.Sweat, smiles, progress.Pushed through the hardest set.Feeling stronger every week.Recovery stretch time.''',
        'hashtags': ['Gymills','Gymills','Gymills','Gymills','Gymills''Gymills','Gymills','Gymills','Gymills'],
        'imageUrl': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400',
        'platform': 'Instagram',
        'platformHandle': '@fitness_queen',
        'timeAgo': '5h ago',
        'isLiked': false,
        'likesCount': 89,
        'likedBy': [
          {'name': 'Mike Johnson', 'profileImage': 'https://i.pravatar.cc/150?img=13', 'isFollowing': true},
          {'name': 'Lisa Anderson', 'profileImage': 'https://i.pravatar.cc/150?img=21', 'isFollowing': false},
          {'name': 'David Lee', 'profileImage': 'https://i.pravatar.cc/150?img=31', 'isFollowing': true},
        ],
      },
      {
        'id': '3',
        'username': 'Kendra Jane',
        'profileImage': 'https://i.pravatar.cc/150?img=45',
        'content': 'side effects of bodybuilding',
        'hashtags': ['Gymills'],
        'imageUrl': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400',
        'platform': 'Instagram',
        'platformHandle': '@kendra_fit',
        'timeAgo': '8h ago',
        'isLiked': false,
        'likesCount': 256,
        'likedBy': [
          {'name': 'Alex Thompson', 'profileImage': 'https://i.pravatar.cc/150?img=15', 'isFollowing': false},
          {'name': 'Rachel Green', 'profileImage': 'https://i.pravatar.cc/150?img=25', 'isFollowing': true},
          {'name': 'Chris Brown', 'profileImage': 'https://i.pravatar.cc/150?img=35', 'isFollowing': false},
          {'name': 'Monica Geller', 'profileImage': 'https://i.pravatar.cc/150?img=40', 'isFollowing': true},
          {'name': 'Ross Smith', 'profileImage': 'https://i.pravatar.cc/150?img=50', 'isFollowing': false},
          {'name': 'Phoebe White', 'profileImage': 'https://i.pravatar.cc/150?img=55', 'isFollowing': false},
        ],
      },
      {
        'id': '4',
        'username': 'Kendra Jane',
        'profileImage': 'https://i.pravatar.cc/150?img=45',
        'content': 'had a nice workout sessions',
        'hashtags': ['Gymills'],
        'imageUrl': 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400',
        'platform': 'YouTube',
        'platformHandle': '@kendraworkouts',
        'timeAgo': '1d ago',
        'isLiked': false,
        'likesCount': 432,
        'likedBy': [
          {'name': 'Tom Hanks', 'profileImage': 'https://i.pravatar.cc/150?img=11', 'isFollowing': true},
          {'name': 'Julia Roberts', 'profileImage': 'https://i.pravatar.cc/150?img=22', 'isFollowing': false},
          {'name': 'Brad Pitt', 'profileImage': 'https://i.pravatar.cc/150?img=32', 'isFollowing': true},
          {'name': 'Jennifer Aniston', 'profileImage': 'https://i.pravatar.cc/150?img=42', 'isFollowing': false},
        ],
      },
    ];
  }
}
