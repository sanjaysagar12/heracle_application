class MutualFeedService {
  Future<List<Map<String, dynamic>>> getMutualFeed() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock data
    return [
      {
        'id': '1',
        'type': 'workout',
        'username': 'zhambo',
        'handle': '@miyura_9812',
        'profileImage': 'https://i.pravatar.cc/150?img=33',
        'timeAgo': '2 days ago',
        'content': 'My back hurt so much but do you know what hurts more the scare she gave me...',
        'tags': ['Back day', 'i_miss_her'],
        'images': [
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
          'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400',
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400',
          'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400',
        ],
        'duration': '1hr 23min',
        'volume': '5,355.6kg',
        'records': 'nil',
        'exercises': [
          '4 sets Bicep Curl (Dumbbell)',
          '4 sets Preacher Curl (Machine)',
          '3 sets Pull Up (Assisted)',
          '3 sets Lat Pulldown',
          '4 sets Cable Row',
        ],
        'likes': 23,
        'likedBy': [
          'https://i.pravatar.cc/150?img=1',
          'https://i.pravatar.cc/150?img=2',
          'https://i.pravatar.cc/150?img=3',
        ],
        'commentCount': 5,
      },
      {
        'id': '2',
        'type': 'nutrition',
        'username': 'zhambo',
        'handle': '@miyura_9812',
        'profileImage': 'https://i.pravatar.cc/150?img=33',
        'timeAgo': '2 days ago',
        'content': 'My back hurt so much but do you know what hurts more the scare she gave me...',
        'images': [
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400',
        ],
        'calories': 2032,
        'protein': 132,
        'carbs': 249,
        'fats': 56,
        'likes': 23,
        'likedBy': [
          'https://i.pravatar.cc/150?img=1',
          'https://i.pravatar.cc/150?img=2',
          'https://i.pravatar.cc/150?img=3',
        ],
        'commentCount': 3,
      },
      {
        'id': '3',
        'type': 'workout',
        'username': 'john_doe',
        'handle': '@john_fitness',
        'profileImage': 'https://i.pravatar.cc/150?img=12',
        'timeAgo': '5 hours ago',
        'content': 'Leg day complete! Feeling stronger every workout 💪',
        'tags': ['Leg day', 'progress'],
        'images': [
          'https://images.unsplash.com/photo-1434682881908-b43d0467b798?w=400',
          'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400',
        ],
        'duration': '55min',
        'volume': '4,200kg',
        'records': '2 PRs',
        'exercises': [
          '5 sets Squats (Barbell)',
          '4 sets Leg Press',
          '3 sets Lunges',
        ],
        'likes': 45,
        'likedBy': [
          'https://i.pravatar.cc/150?img=5',
          'https://i.pravatar.cc/150?img=6',
          'https://i.pravatar.cc/150?img=7',
        ],
        'commentCount': 0,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

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
          'likes': 5,
          'replies': [
            {
              'id': 'r1',
              'username': 'zhambo',
              'handle': '@miyura_9812',
              'profileImage': 'https://i.pravatar.cc/150?img=33',
              'timeAgo': '1 day ago',
              'content': 'Thanks man! Appreciate it',
              'likes': 2,
              'replies': [
                {
                  'id': 'r2',
                  'username': 'jane_smith',
                  'handle': '@jane_fit',
                  'profileImage': 'https://i.pravatar.cc/150?img=45',
                  'timeAgo': '20 hours ago',
                  'content': 'You guys are awesome!',
                  'likes': 1,
                  'replies': [],
                }
              ],
            }
          ],
        },
        {
          'id': 'c2',
          'username': 'mike_fitness',
          'handle': '@mike_lifts',
          'profileImage': 'https://i.pravatar.cc/150?img=15',
          'timeAgo': '2 days ago',
          'content': 'What was your PR?',
          'likes': 3,
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
          'likes': 8,
          'replies': [],
        },
      ];
    }

    return [];
  }

  Future<Map<String, dynamic>> addComment(String postId, String content) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Return mock comment
    return {
      'id': 'c${DateTime.now().millisecondsSinceEpoch}',
      'username': 'Eren Yeager',
      'handle': '@eren_yeager',
      'profileImage': 'https://tse3.mm.bing.net/th/id/OIP.dvSVSBNTSG_uMW_J4J5pWwHaHa?w=1000&h=1000&rs=1&pid=ImgDetMain&o=7&rm=3',
      'timeAgo': 'Just now',
      'content': content,
      'likes': 0,
      'replies': [],
    };
  }
}
