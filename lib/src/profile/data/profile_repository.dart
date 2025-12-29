// Profile Repository
// Handles data transformation and business logic for profile page

import '../api/profile_service.dart';
import '../../workout/data/session_repository.dart';
import '../../home/data/mutual_feed_repository.dart';
import '../../feed/data/stories_repository.dart'; // Added import

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
  final bool isViewer;
  final bool hasStory; // added

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
    this.isViewer = false,
    this.hasStory = false,
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
      isViewer: json['isViewer'] as bool? ?? false,
      hasStory: json['hasStory'] as bool? ?? false,
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
    bool? isViewer,
    bool? hasStory,
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
      hasStory: hasStory ?? this.hasStory,
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


/// Connection User Model (Followers/Following)
class ConnectionUser {
  final String id;
  final String name;
  final String username;
  final String profileImageUrl;
  final bool isFollowing;

  ConnectionUser({
    required this.id,
    required this.name,
    required this.username,
    required this.profileImageUrl,
    required this.isFollowing,
  });

  factory ConnectionUser.fromJson(Map<String, dynamic> json) {
    return ConnectionUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }
  
  ConnectionUser copyWith({
    String? id,
    String? name,
    String? username,
    String? profileImageUrl,
    bool? isFollowing,
  }) {
    return ConnectionUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}



// Remove local ProfilePost class as we now use FeedPost

/// Profile Repository
class ProfileRepository {
  final ProfileApiService _apiService;
  final MutualFeedRepository _mutualFeedRepository; // Use composition for actions

  ProfileRepository({ProfileApiService? apiService, MutualFeedRepository? mutualFeedRepository})
      : _apiService = apiService ?? ProfileApiService(),
        _mutualFeedRepository = mutualFeedRepository ?? MutualFeedRepository();

  /// Get user profile
  Future<UserProfile> getUserProfile(String username) async {
    try {
      final data = await _apiService.getUserProfile(username);
      return UserProfile.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  /// Get workout categories
  Future<List<WorkoutCategory>> getWorkoutCategories() async {
    try {
      final sessions = await getSessions();
      final categoryNames = sessions.map((s) => s.category).toSet().toList();
      
      return categoryNames.map((name) => WorkoutCategory(
        id: name.toLowerCase(),
        name: name,
        isSelected: false,
      )).toList();
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

  /// Get user feed items (replaces getAllHighlights for feed tab)
  Future<List<DiscoverStory>> getUserFeed(String userId) async {
    try {
      final data = await _apiService.getUserFeed(userId);
      // Ensure 'items' exists and is a list
      final items = (data['items'] as List<dynamic>?) ?? [];
      
      return items.map((item) {
        final user = item['user'] as Map<String, dynamic>;
        final createdAt = item['createdAt'] as String;
        
        return DiscoverStory(
          id: item['id'],
          username: user['username'] ?? '',
          profileImage: user['avatarUrl'] ?? '',
          content: item['caption'] ?? '',
          hashtags: [], // API doesn't seem to return hashtags in this feed endpoint yet
          imageUrl: item['mediaUrl'] ?? '',
          thumbnail: item['thumbnail'] ?? '', // Add thumbnail support
          mediaType: item['mediaType'] ?? 'IMAGE',
          platform: 'Heracle',
          platformHandle: '@${user['username'] ?? ''}',
          timeAgo: _calculateTimeAgo(createdAt),
          isLiked: item['isLiked'] ?? false,
          likesCount: item['likeCount'] ?? 0,
          likedBy: [],
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load user feed: $e');
    }
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

  /// Get all highlights without filtering (Deprecating in favor of getUserFeed for main feed)
  Future<List<HighlightVideo>> getAllHighlights() async {
    try {
      final data = await _apiService.getHighlights();
      return data.map((json) => HighlightVideo.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load highlights: $e');
    }
  }

  /// Get sessions
  Future<List<Session>> getSessions() async {
    try {
      final data = await _apiService.getSessions();
      return data.map((json) => Session(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        exercisesCount: json['exercisesCount'] as int? ?? 0,
        position: json['position'] as int? ?? 0,
        exercises: (json['exercises'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      )).toList();
    } catch (e) {
      throw Exception('Failed to load sessions: $e');
    }
  }

  /// Get posts
  Future<List<FeedPost>> getPosts(String username) async {
    try {
      final data = await _apiService.getUserPosts(username);
      return data.map((json) {
        final type = json['type'] as String? ?? 'workout';
        if (type == 'workout') {
          return WorkoutPost.fromJson(json);
        } else if (type == 'nutrition') {
          return NutritionPost.fromJson(json);
        }
        throw Exception('Unknown post type: $type');
      }).toList();
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

  /// Get followers
  Future<List<ConnectionUser>> getFollowers() async {
    try {
      final data = await _apiService.getFollowers();
      return data.map((json) => ConnectionUser.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load followers: $e');
    }
  }

  /// Get following
  Future<List<ConnectionUser>> getFollowing() async {
    try {
      final data = await _apiService.getFollowing();
      return data.map((json) => ConnectionUser.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load following: $e');
    }
  }
}
