// Profile Repository
// Handles data transformation and business logic for profile page

import '../api/profile_service.dart';

/// User Profile Model
class UserProfile {
  final String id;
  final String name;
  final String username;
  final String profileImageUrl;
  final String? bannerUrl;
  final bool isVerified;
  final String bio;
  final int highlights;
  final int following;
  final int followers;
  final bool isFollowing;
  final bool isViewer; // added

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.profileImageUrl,
    this.bannerUrl,
    required this.isVerified,
    required this.bio,
    required this.highlights,
    required this.following,
    required this.followers,
    required this.isFollowing,
    this.isViewer = false, // default false
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String,
      bannerUrl: json['bannerUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      bio: json['bio'] as String? ?? '',
      highlights: json['highlights'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      followers: json['followers'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
      isViewer: json['isViewer'] as bool? ?? false, // read from API
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? username,
    String? profileImageUrl,
    String? bannerUrl,
    bool? isVerified,
    String? bio,
    int? highlights,
    int? following,
    int? followers,
    bool? isFollowing,
    bool? isViewer, // added
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isVerified: isVerified ?? this.isVerified,
      bio: bio ?? this.bio,
      highlights: highlights ?? this.highlights,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      isFollowing: isFollowing ?? this.isFollowing,
      isViewer: isViewer ?? this.isViewer,
    );
  }

  /// Format large numbers (e.g., 230000 -> 230K)
  String get formattedFollowing => _formatNumber(following);
  String get formattedFollowers => _formatNumber(followers);
  String get formattedHighlights => highlights.toString();

  static String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}

/// Workout Category Model
class WorkoutCategory {
  final String id;
  final String name;
  final bool isSelected;

  WorkoutCategory({
    required this.id,
    required this.name,
    required this.isSelected,
  });

  factory WorkoutCategory.fromJson(Map<String, dynamic> json) {
    return WorkoutCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  WorkoutCategory copyWith({
    String? id,
    String? name,
    bool? isSelected,
  }) {
    return WorkoutCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Highlight Video Model
class HighlightVideo {
  final String id;
  final String thumbnailUrl;
  final String videoUrl;
  final int views;
  final String? platform;
  final String category;

  HighlightVideo({
    required this.id,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.views,
    this.platform,
    required this.category,
  });

  factory HighlightVideo.fromJson(Map<String, dynamic> json) {
    return HighlightVideo(
      id: json['id'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      videoUrl: json['videoUrl'] as String? ?? '',
      views: json['views'] as int? ?? 0,
      platform: json['platform'] as String?,
      category: json['category'] as String? ?? '',
    );
  }

  /// Format views count (e.g., 20300 -> 20.3K)
  String get formattedViews {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M Views';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K Views';
    }
    return '$views Views';
  }
}

/// Session Model
class WorkoutSession {
  final String id;
  final String title;
  final String date;
  final int duration;
  final int exercises;

  WorkoutSession({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    required this.exercises,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      duration: json['duration'] as int? ?? 0,
      exercises: json['exercises'] as int? ?? 0,
    );
  }
}

/// Post Model
class ProfilePost {
  final String id;
  final String imageUrl;
  final String caption;
  final int likes;
  final int comments;

  ProfilePost({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
  });

  factory ProfilePost.fromJson(Map<String, dynamic> json) {
    return ProfilePost(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      caption: json['caption'] as String? ?? '',
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
    );
  }
}

/// Profile Repository
class ProfileRepository {
  final ProfileApiService _apiService;

  ProfileRepository({ProfileApiService? apiService})
      : _apiService = apiService ?? ProfileApiService();

  /// Get user profile
  Future<UserProfile> getUserProfile() async {
    try {
      final data = await _apiService.getUserProfile();
      return UserProfile.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  /// Get workout categories
  Future<List<WorkoutCategory>> getWorkoutCategories() async {
    try {
      final data = await _apiService.getWorkoutCategories();
      return data.map((json) => WorkoutCategory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Get highlights filtered by category
  Future<List<HighlightVideo>> getHighlights({String? category}) async {
    try {
      final data = await _apiService.getHighlights(category: category);
      List<HighlightVideo> highlights = 
          data.map((json) => HighlightVideo.fromJson(json)).toList();
      
      // Filter by category if provided
      if (category != null && category.isNotEmpty) {
        highlights = highlights
            .where((h) => h.category.toLowerCase() == category.toLowerCase())
            .toList();
      }
      
      return highlights;
    } catch (e) {
      throw Exception('Failed to load highlights: $e');
    }
  }

  /// Get all highlights without filtering
  Future<List<HighlightVideo>> getAllHighlights() async {
    try {
      final data = await _apiService.getHighlights();
      return data.map((json) => HighlightVideo.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load highlights: $e');
    }
  }

  /// Get sessions
  Future<List<WorkoutSession>> getSessions() async {
    try {
      final data = await _apiService.getSessions();
      return data.map((json) => WorkoutSession.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load sessions: $e');
    }
  }

  /// Get posts
  Future<List<ProfilePost>> getPosts() async {
    try {
      final data = await _apiService.getPosts();
      return data.map((json) => ProfilePost.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load posts: $e');
    }
  }

  /// Update selected category
  List<WorkoutCategory> updateSelectedCategory(
    List<WorkoutCategory> categories,
    String categoryId,
  ) {
    return categories.map((cat) {
      return cat.copyWith(isSelected: cat.id == categoryId);
    }).toList();
  }

  /// Toggle follow status
  UserProfile toggleFollow(UserProfile profile) {
    final newFollowStatus = !profile.isFollowing;
    final newFollowers = newFollowStatus 
        ? profile.followers + 1 
        : profile.followers - 1;
    
    return profile.copyWith(
      isFollowing: newFollowStatus,
      followers: newFollowers,
    );
  }
}
