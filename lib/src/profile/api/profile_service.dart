import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ProfileApiService {
  /// Get user profile data
  Future<Map<String, dynamic>> getUserProfile(String username) async {
    try {
      final response = await DioClient().dio.get('/api/user/$username');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  /// Get workout categories/tags
  Future<List<Map<String, dynamic>>> getWorkoutCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      {'id': '1', 'name': 'Functional', 'isSelected': true},
      {'id': '2', 'name': 'Biceps', 'isSelected': false},
      {'id': '3', 'name': 'Triceps', 'isSelected': false},
      {'id': '4', 'name': 'Chest', 'isSelected': false},
      {'id': '5', 'name': 'Back', 'isSelected': falclearse},
      {'id': '6', 'name': 'Legs', 'isSelected': false},
    ];
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
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'id': 's1',
        'title': 'Chest Day',
        'content': 'Heavy chest workout focused on strength', 
        'category': 'Chest',
        'exercisesCount': 3,
        'position': 0,
        'exercises': [
           {
             'id': 'e1', 
             'name': 'Bench Press (Barbell)',
             'desc': 'Chest',
             'image': 'https://media.istockphoto.com/id/482806950/photo/bench-press-exercise.jpg?s=612x612&w=0&k=20&c=OwC49pB9P5P50GjWqXhQZ6IcF1sjXb1XwZp1Qy5Z5yU=',
             'sets': [
               {'kg': 20, 'reps': 12},
               {'kg': 25, 'reps': 10},
               {'kg': 30, 'reps': 8},
             ]
           },
           {
             'id': 'e2', 
             'name': 'Incline Dumbbell Press',
             'desc': 'Upper Chest',
             'image': 'https://media.istockphoto.com/id/531536728/photo/incline-dumbbell-press.jpg?s=612x612&w=0&k=20&c=J5q1o7wX5z8K3n7b7x1o8jX9v4l2m0n3o6p9q2r5s8=',
             'sets': [
               {'kg': 15, 'reps': 12},
               {'kg': 17.5, 'reps': 10},
             ]
           },
           {
             'id': 'e3', 
             'name': 'Cable Flys',
             'desc': 'Isolation',
             'image': 'https://media.istockphoto.com/id/1132086660/photo/cable-crossover-exercise.jpg?s=612x612&w=0&k=20&c=1m2n3o4p5q6r7s8t9u0v1w2x3y4z5a6b7c8d9e0f=',
             'sets': [
               {'kg': 10, 'reps': 15},
               {'kg': 10, 'reps': 15},
             ]
           },
        ],
      },
      {
        'id': 's2',
        'title': 'Leg Day',
        'content': 'Quad focused leg workout',
        'category': 'Legs',
        'exercisesCount': 2,
        'position': 1,
        'exercises': [
           {
             'id': 'e4', 
             'name': 'Squat (Barbell)',
             'desc': 'Legs',
             'image': 'https://media.istockphoto.com/id/597973710/photo/barbell-squat.jpg?s=612x612&w=0&k=20&c=3s4t5u6v7w8x9y0z1a2b3c4d5e6f7g8h9i0j1k2l=',
             'sets': [
               {'kg': 60, 'reps': 10},
               {'kg': 80, 'reps': 8},
             ]
           },
           {
             'id': 'e5', 
             'name': 'Leg Extension',
             'desc': 'Quads',
             'image': 'https://media.istockphoto.com/id/175438852/photo/leg-extension.jpg?s=612x612&w=0&k=20&c=5m6n7o8p9q0r1s2t3u4v5w6x7y8z9a0b1c2d3e4f=',
             'sets': [
               {'kg': 40, 'reps': 15},
               {'kg': 45, 'reps': 12},
             ]
           },
        ],
      },
    ];
  }

  /// Get posts data
  Future<List<Map<String, dynamic>>> getPosts() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'id': 'p1',
        'type': 'workout',
        'username': 'Sanjay Sagar N',
        'handle': '@sanjaysagar',
        'profileImage': 'https://tse3.mm.bing.net/th/id/OIP.dvSVSBNTSG_uMW_J4J5pWwHaHa?w=1000&h=1000&rs=1&pid=ImgDetMain&o=7&rm=3',
        'isVerified': true,
        'timeAgo': '2h ago',
        'content': 'Great workout today! Focused on chest and triceps. Feeling stronger every day. #fitness #gym #workout',
        'likes': 150,
        'commentCount': 23,
        'isLiked': true,
        'likedBy': [
          {'name': 'John Doe', 'profileImage': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100'},
          {'name': 'Jane Smith', 'profileImage': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'},
        ],
        'tags': ['Chest', 'Triceps', 'Strength'],
        'duration': '1h 30m',
        'volume': '12,500 kg',
        'records': '3 PRs',
        'images': [
          'https://images.unsplash.com/photo-1581009146145-b5ef050c149a?w=800',
        ],
        'exercises': [
          {
            'name': 'Bench Press',
            'imageUrl': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=100',
          },
          {
            'name': 'Tricep Pushdown',
            'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=100',
          },
          { 
            'name': 'Bicep Curls',
            'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=100',
          },
          {
            'name': 'Tricep Pushdown',
            'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=100',
          },
          {
            'name': 'Tricep Pushdown',
            'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=100',
          }
        ],
      },
      {
        'id': 'p2',
        'type': 'nutrition',
        'username': 'Sanjay Sagar N',
        'handle': '@sanjaysagar',
        'profileImage': 'https://tse3.mm.bing.net/th/id/OIP.dvSVSBNTSG_uMW_J4J5pWwHaHa?w=1000&h=1000&rs=1&pid=ImgDetMain&o=7&rm=3',
        'isVerified': true,
        'timeAgo': '5h ago',
        'content': 'Post-workout meal: Chicken breast with rice and broccoli. Keeping it clean and simple.',
        'likes': 85,
        'commentCount': 10,
        'isLiked': false,
        'likedBy': [
           {'name': 'Mike Ross', 'profileImage': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100'},
        ],
        'meals': [
          { 
            'mealType': 'Breakfast',
            'content': 'Oatmeal with berries and almond butter',
            'calories': 450,
            'protein': 25,
            'carbs': 50,
            'fats': 15,
            'images': [
              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
            ],
          },
          {
            'mealType': 'Lunch',
            'content': 'Chicken Breast, Rice & Broccoli',
            'calories': 650,
            'protein': 45,
            'carbs': 60,
            'fats': 15,
            'images': [
              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
            ],
          },
          {
            'mealType': 'Dinner',
            'content': 'Grilled Salmon, Quinoa, Steamed Vegetables',
            'calories': 550,
            'protein': 35,
            'carbs': 50,
            'fats': 20,
            'images': [
              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
            ],
          }
        ],
      },
    ];
  }
}
