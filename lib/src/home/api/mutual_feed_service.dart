import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class MutualFeedService {
  final DioClient _dioClient = DioClient();

  Future<List<Map<String, dynamic>>> getMutualFeed() async {
    try {
      final response = await _dioClient.dio.get('/api/post/feed/all?page=1&limit=20');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load feed');
      }
    } catch (e) {
      print('Error fetching feed: $e');
      // Return empty list or rethrow based on preference. 
      // Returning empty list to avoid crashing UI if API fails initially
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    // Simulate API delay for testing
    await Future.delayed(const Duration(seconds: 2));
    
    // Return mock comments based on post ID
    if (postId == '1') {
      return [
        {
          'id': 'c1',
          'username': 'john_doe',
          'handle': '@john_fitness',
          'profileImage': 'https://i.pravatar.cc/150?img=12',
          'timeAgo': '1 day ago',
          'content': 'Great workout bro! Keep it up 💪',
          'replies': [
            {
              'id': 'r1',
              'username': 'zhambo',
              'handle': '@miyura_9812',
              'profileImage': 'https://i.pravatar.cc/150?img=33',
              'timeAgo': '1 day ago',
              'content': 'Thanks man! Appreciate it',
              'replies': [
                {
                  'id': 'r2',
                  'username': 'jane_smith',
                  'handle': '@jane_fit',
                  'profileImage': 'https://i.pravatar.cc/150?img=45',
                  'timeAgo': '20 hours ago',
                  'content': 'You guys are awesome!',
                  'replies': [],
                },
              ],
            },
          ],
        },
        {
          'id': 'c2',
          'username': 'mike_fitness',
          'handle': '@mike_lifts',
          'profileImage': 'https://i.pravatar.cc/150?img=15',
          'timeAgo': '2 days ago',
          'content': 'What was your PR?',
          'replies': [],
        },
      ];
    } else if (postId == '2') {
      return [
        {
          'id': 'c3',
          'username': 'healthy_eater',
          'handle': '@health_guru',
          'profileImage': 'https://i.pravatar.cc/150?img=20',
          'timeAgo': '5 hours ago',
          'content': 'That looks delicious! Recipe please?',
          'replies': [],
        },
      ];
    }

    return [];
  }

  Future<Map<String, dynamic>> addComment(String postId, String content) async {
    // Simulate API delay for testing
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Return mock comment
    return {
      'id': 'c${DateTime.now().millisecondsSinceEpoch}',
      'username': 'Eren Yeager',
      'handle': '@eren_yeager',
      'profileImage':
          'https://tse3.mm.bing.net/th/id/OIP.dvSVSBNTSG_uMW_J4J5pWwHaHa?w=1000&h=1000&rs=1&pid=ImgDetMain&o=7&rm=3',
      'timeAgo': 'Just now',
      'content': content,
      'replies': [],
    };
  }

  Future<Map<String, dynamic>> addReply(
    String postId,
    String commentId,
    String content,
  ) async {
    // Simulate API delay for testing
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Return mock reply
    return {
      'id': 'r${DateTime.now().millisecondsSinceEpoch}',
      'username': 'Eren Yeager',
      'handle': '@eren_yeager',
      'profileImage':
          'https://tse3.mm.bing.net/th/id/OIP.dvSVSBNTSG_uMW_J4J5pWwHaHa?w=1000&h=1000&rs=1&pid=ImgDetMain&o=7&rm=3',
      'timeAgo': 'Just now',
      'content': content,
      'replies': [],
    };
  }
}
