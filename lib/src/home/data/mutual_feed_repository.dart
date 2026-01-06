import '../../core/network/cache_manager.dart';
import '../api/mutual_feed_service.dart';

class LikedByUser {
  final String name;
  final String username;
  final String profileImage;
  final bool isFollowing;
  final bool isViewer;

  LikedByUser({
    required this.name,
    required this.username,
    required this.profileImage,
    this.isFollowing = false,
    this.isViewer = false,
  });

  factory LikedByUser.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('user')) {
      final user = json['user'] as Map<String, dynamic>;
      final username = (user['username'] as String?) ?? '';
      final name = (user['name'] as String?) ?? username;
      final profileImage = (user['avatarUrl'] as String?) ?? '';
      return LikedByUser(
        name: name,
        username: username,
        profileImage: profileImage,
        isFollowing: json['isFollowing'] as bool? ?? false,
        isViewer: json['isViewer'] as bool? ?? false,
      );
    }

    return LikedByUser(
      name: json['name'] as String? ?? 'Unknown',
      username: json['username'] as String? ?? json['name'] as String? ?? '',
      profileImage: json['profileImage'] as String? ?? '',
      isFollowing: json['isFollowing'] as bool? ?? false,
      isViewer: json['isViewer'] as bool? ?? false,
    );
  }
}

abstract class FeedPost {
  final String id;
  final String username;
  final String handle;
  final String profileImage;
  final String timeAgo;
  final String content;
  final List<String> images;
  final int likes;
  final List<LikedByUser> likedBy;
  final bool isLiked;
  final bool isOwnPost; // New field
  final int commentCount;

  FeedPost({
    required this.id,
    required this.username,
    required this.handle,
    required this.profileImage,
    required this.timeAgo,
    required this.content,
    required this.images,
    required this.likes,
    required this.likedBy,
    this.isLiked = false,
    this.isOwnPost = false, // Default to false
    required this.commentCount,
  });

  FeedPost copyWith({bool? isLiked, int? likes, int? commentCount});
}

class Exercise {
  final String name;
  final String imageUrl;

  Exercise({
    required this.name,
    required this.imageUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }
}

class WorkoutPost extends FeedPost {
  final List<String> tags;
  final String duration;
  final String volume;
  final String records;
  final List<Exercise> exercises;

  WorkoutPost({
    required super.id,
    required super.username,
    required super.handle,
    required super.profileImage,
    required super.timeAgo,
    required super.content,
    required super.images,
    required super.likes,
    required super.likedBy,
    super.isLiked,
    super.isOwnPost,
    required this.tags,
    required this.duration,
    required this.volume,
    required this.records,
    required this.exercises,
    required super.commentCount,
  });

  factory WorkoutPost.fromJson(Map<String, dynamic> json) {
    return WorkoutPost(
      id: json['id'] as String,
      username: json['username'] as String,
      handle: json['handle'] as String,
      profileImage: json['profileImage'] as String,
      timeAgo: json['timeAgo'] as String,
      content: json['content'] as String,
      tags: List<String>.from(json['tags'] ?? const []),
      images: List<String>.from(json['images'] ?? const []),
      duration: json['duration'] as String? ?? '',
      volume: json['volume'] as String? ?? '',
      records: json['records'] as String? ?? '',
      exercises: (json['exercises'] as List? ?? []).map((e) => Exercise.fromJson(e)).toList(),
      likes: (json['likes'] as int?) ?? 0,
      likedBy: (json['likedBy'] as List? ?? []).map((user) => LikedByUser.fromJson(user)).toList(),
      // read isLiked from API (default false)
      isLiked: json['isLiked'] as bool? ?? false,
      isOwnPost: json['isOwnPost'] as bool? ?? false,
      commentCount: json['commentCount'] as int? ?? 0,
    );
  }

  @override
  WorkoutPost copyWith({bool? isLiked, int? likes, int? commentCount}) {
    return WorkoutPost(
      id: id,
      username: username,
      handle: handle,
      profileImage: profileImage,
      timeAgo: timeAgo,
      content: content,
      tags: tags,
      images: images,
      duration: duration,
      volume: volume,
      records: records,
      exercises: exercises,
      likes: likes ?? this.likes,
      likedBy: likedBy,
      isLiked: isLiked ?? this.isLiked,
      isOwnPost: isOwnPost,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}


class NutritionMeal {
  final String mealType;
  final String content;
  final List<String> images;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  NutritionMeal({
    required this.mealType,
    required this.content,
    required this.images,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  factory NutritionMeal.fromJson(Map<String, dynamic> json) {
    return NutritionMeal(
      mealType: json['mealType'] as String? ?? 'Meal',
      content: json['content'] as String? ?? '',
      images: List<String>.from(json['images'] ?? []),
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fats: (json['fats'] as num?)?.toInt() ?? 0,
    );
  }
}

class NutritionPost extends FeedPost {
  final List<NutritionMeal> meals;

  NutritionPost({
    required super.id,
    required super.username,
    required super.handle,
    required super.profileImage,
    required super.timeAgo,
    required super.content,
    required super.images,
    required super.likes,
    required super.likedBy,
    super.isLiked,
    super.isOwnPost,
    required super.commentCount,
    required this.meals,
  });

  factory NutritionPost.fromJson(Map<String, dynamic> json) {
    // If meals is null/empty, we can provide empty list
    final mealsList = (json['meals'] as List? ?? [])
        .map((e) => NutritionMeal.fromJson(e as Map<String, dynamic>))
        .toList();

    return NutritionPost(
      id: json['id'] as String,
      username: json['username'] as String,
      handle: json['handle'] as String,
      profileImage: json['profileImage'] as String,
      timeAgo: json['timeAgo'] as String,
      content: mealsList.isNotEmpty ? mealsList.first.content : '', // Fallback content
      images: [], // Nutrition post usually shows meal images separately
      likes: (json['likes'] as int?) ?? 0,
      likedBy: (json['likedBy'] as List? ?? []).map((user) => LikedByUser.fromJson(user)).toList(),
      isLiked: json['isLiked'] as bool? ?? false,
      isOwnPost: json['isOwnPost'] as bool? ?? false,
      commentCount: json['commentCount'] as int? ?? 0,
      meals: mealsList,
    );
  }

  @override
  NutritionPost copyWith({
    bool? isLiked,
    int? likes,
    int? commentCount,
  }) {
    return NutritionPost(
      id: id,
      username: username,
      handle: handle,
      profileImage: profileImage,
      timeAgo: timeAgo,
      content: content,
      images: images,
      likes: likes ?? this.likes,
      likedBy: likedBy,
      isLiked: isLiked ?? this.isLiked,
      isOwnPost: isOwnPost,
      commentCount: commentCount ?? this.commentCount,
      meals: meals,
    );
  }
}


class Comment {
  final String id;
  final String username;
  final String handle;
  final String profileImage;
  final String timeAgo;
  final String content;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.username,
    required this.handle,
    required this.profileImage,
    required this.timeAgo,
    required this.content,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    String username = '';
    String handle = '';
    String profileImage = '';

    if (json.containsKey('user')) {
      final user = json['user'] as Map<String, dynamic>;
      username = (user['username'] as String?) ?? (user['name'] as String?) ?? '';
      handle = (user['handle'] as String?) ?? username;
      profileImage = (user['profileImage'] as String?) ?? (user['avatarUrl'] as String?) ?? '';
    } else {
      username = (json['username'] as String?) ?? (json['name'] as String?) ?? '';
      handle = (json['handle'] as String?) ?? '';
      profileImage = (json['profileImage'] as String?) ?? (json['avatarUrl'] as String?) ?? '';
    }

    return Comment(
      id: json['id']?.toString() ?? '',
      username: username,
      handle: handle,
      profileImage: profileImage,
      timeAgo: (json['timeAgo'] as String?) ?? (json['createdAt'] as String?) ?? '',
      content: (json['content'] as String?) ?? (json['text'] as String?) ?? '',
      replies: (json['replies'] as List? ?? [])
          .map((reply) => Comment.fromJson(reply))
          .toList(),
    );
  }

  Comment copyWith({
    String? id,
    String? username,
    String? handle,
    String? profileImage,
    String? timeAgo,
    String? content,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      username: username ?? this.username,
      handle: handle ?? this.handle,
      profileImage: profileImage ?? this.profileImage,
      timeAgo: timeAgo ?? this.timeAgo,
      content: content ?? this.content,
      replies: replies ?? this.replies,
    );
  }

  Comment copyWithReply(Comment newReply) {
    return Comment(
      id: id,
      username: username,
      handle: handle,
      profileImage: profileImage,
      timeAgo: timeAgo,
      content: content,
      replies: [...replies, newReply],
    );
  }
}

class MutualFeedRepository {
  final MutualFeedService _service;
  final CacheManager _cacheManager = CacheManager();

  MutualFeedRepository({MutualFeedService? service})
      : _service = service ?? MutualFeedService();

  Future<List<FeedPost>> getMutualFeed() async {
    try {
      final data = await _service.getMutualFeed();
      // Cache the successful response
      await _cacheManager.cacheData('mutual_feed', data);
      return _mapFeedData(data);
    } catch (e) {
      // Try to load from cache
      final cachedData = await _cacheManager.getCachedData('mutual_feed');
      if (cachedData != null && cachedData is List) {
        return _mapFeedData(List<Map<String, dynamic>>.from(cachedData));
      }
      throw Exception('Failed to load mutual feed: $e');
    }
  }

  List<FeedPost> _mapFeedData(List<Map<String, dynamic>> data) {
    return data.map((json) {
      final type = json['type'] as String? ?? 'workout'; // Default to workout if missing
      
      if (type == 'nutrition') {
        return NutritionPost.fromJson(json);
      } else {
        return WorkoutPost.fromJson(json);
      }
    }).toList();
  }

  Future<void> likePost(String postId, {bool isMeal = false}) async {
    try {
      if (isMeal) {
        await _service.likeMealPost(postId);
      } else {
        await _service.likePost(postId);
      }
      
      // Update local state is complex without knowing if it's a like or unlike from API
      // For now, we assume success and toggle locally in UI logic above this layer if needed, 
      // but Repository usually fetches fresh data or relies on UI optimistic updates.
      // Here we will just perform the API call.
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  Future<List<Comment>> getComments(String postId, {bool isMeal = false}) async {
    try {
      final commentsData = isMeal 
          ? await _service.getMealComments(postId)
          : await _service.getPostComments(postId);

      return commentsData.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  Future<Comment> addComment(String postId, String content, {bool isMeal = false}) async {
    try {
      final commentData = isMeal 
          ? await _service.addMealComment(postId, content)
          : await _service.addComment(postId, content);
          
      return Comment.fromJson(commentData);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<Comment> addReply(String postId, String commentId, String content, {bool isMeal = false}) async {
    try {
      final replyData = isMeal
          ? await _service.addMealReply(postId, commentId, content)
          : await _service.addReply(postId, commentId, content);
          
      return Comment.fromJson(replyData);
    } catch (e) {
      throw Exception('Failed to add reply: $e');
    }
  }

  Future<List<LikedByUser>> getPostLikes(String postId) async {
    try {
      final data = await _service.getPostLikes(postId);
      final likesList = (data['likes'] as List? ?? []);
      return likesList.map((entry) {
        return LikedByUser.fromJson(entry as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load post likes: $e');
    }
  }

  Future<void> followUser(String username) async {
    try {
      await _service.followUser(username);
    } catch (e) {
      throw Exception('Failed to follow/unfollow user: $e');
    }
  }
}
