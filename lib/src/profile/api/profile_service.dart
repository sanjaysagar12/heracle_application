// Profile API Service
// Provides mock data for profile page - simulates API responses

class ProfileApiService {
  /// Get user profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    return {
      'id': 'user_001',
      'name': 'Sanjay Sagar N',
      'username': '@sanjaysagar',
      'profileImageUrl': 'https://tse3.mm.bing.net/th/id/OIP.dvSVSBNTSG_uMW_J4J5pWwHaHa?w=1000&h=1000&rs=1&pid=ImgDetMain&o=7&rm=3',
      'bannerUrl': 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800',
      'isVerified': true,
      'isViewer':true,
      'bio': 'Fitness enthusiast | Gym lover',
      'highlights': 123,
      'following': 230000,
      'followers': 23,
      'isFollowing': true,
    };
  }

  /// Get workout categories/tags
  Future<List<Map<String, dynamic>>> getWorkoutCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      {'id': '1', 'name': 'Functional', 'isSelected': true},
      {'id': '2', 'name': 'Biceps', 'isSelected': false},
      {'id': '3', 'name': 'Triceps', 'isSelected': false},
      {'id': '4', 'name': 'Chest', 'isSelected': false},
      {'id': '5', 'name': 'Back', 'isSelected': false},
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

  /// Get sessions data
  Future<List<Map<String, dynamic>>> getSessions() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'id': 's1',
        'title': 'Morning Workout',
        'date': '2024-12-09',
        'duration': 45,
        'exercises': 12,
      },
      {
        'id': 's2',
        'title': 'Evening Cardio',
        'date': '2024-12-08',
        'duration': 30,
        'exercises': 8,
      },
    ];
  }

  /// Get posts data
  Future<List<Map<String, dynamic>>> getPosts() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'id': 'p1',
        'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
        'caption': 'Great workout today!',
        'likes': 150,
        'comments': 23,
      },
    ];
  }
}
