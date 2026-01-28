import '../../core/network/cache_manager.dart';
import '../api/mutual_feed_service.dart';
import '../../../core/helper/time_formatter.dart';
import 'user_suggestion.dart';

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
      profileImage:
          (json['profileImage'] as String?) ??
          (json['avatarUrl'] as String?) ??
          '',
      isFollowing: json['isFollowing'] as bool? ?? false,
      isViewer: json['isViewer'] as bool? ?? false,
    );
  }
}

abstract class FeedPost {
  final String id;
  final String name;
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
    required this.name,
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

  FeedPost copyWith({
    bool? isLiked,
    int? likes,
    int? commentCount,
    bool? isOwnPost,
  });
}

class ExerciseSet {
  final int setNumber;
  final num kg;
  final int reps;
  final int time;
  final int restSeconds;

  ExerciseSet({
    required this.setNumber,
    required this.kg,
    required this.reps,
    required this.time,
    required this.restSeconds,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      setNumber: json['setNumber'] as int? ?? 0,
      kg: json['kg'] as num? ?? 0,
      reps: json['reps'] as int? ?? 0,
      time: json['time'] as int? ?? 0,
      restSeconds: json['restSeconds'] as int? ?? 0,
    );
  }
}

class Exercise {
  final String name;
  final String imageUrl;
  final List<ExerciseSet> sets;

  Exercise({required this.name, required this.imageUrl, this.sets = const []});

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Handle image from r2 if provided in the exercise object from API
    String image = json['imageUrl'] as String? ?? '';
    if (image.isEmpty) {
      image = json['image'] as String? ?? '';
    }
    return Exercise(
      name: json['name'] as String? ?? json['exercise'] as String? ?? '',
      imageUrl: image,
      sets: (json['sets'] as List? ?? [])
          .map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
          .toList(),
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
    required super.name,
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
    String name = '';
    String username = '';
    String handle = '';
    String profileImage = '';

    if (json.containsKey('user') && json['user'] is Map) {
      final user = json['user'] as Map<String, dynamic>;
      username = user['username'] as String? ?? '';
      name = user['name'] as String? ?? username;
      handle =
          '@$username'; // Assuming handle is derived from username if not present
      profileImage = user['avatarUrl'] as String? ?? '';
    } else {
      username = json['username'] as String? ?? '';
      name = json['name'] as String? ?? username;
      handle = json['handle'] as String? ?? '';
      profileImage = json['profileImage'] as String? ?? '';
    }

    return WorkoutPost(
      id: json['id'] as String,
      name: name,
      username: username,
      handle: handle,
      profileImage: profileImage,
      timeAgo: json['createdAt'] != null
          ? TimeFormatter.formatRelativeTime(json['createdAt'])
          : (json['timeAgo'] as String? ?? ''),
      content:
          (json['caption'] as String?) ?? (json['content'] as String?) ?? '',
      tags: List<String>.from(json['tags'] ?? const []),
      images: (json['images'] as List? ?? [])
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .map((e) => e.toString())
          .toList(),
      duration:
          json['duration']?.toString() ?? '', // Convert to string if number
      volume: json['volume']?.toString() ?? '',
      records: json['records']?.toString() ?? '',
      exercises: (json['exercises'] as List? ?? [])
          .map((e) => Exercise.fromJson(e))
          .toList(),
      likes: (json['likeCount'] as int?) ?? (json['likes'] as int?) ?? 0,
      likedBy: (json['likedBy'] as List? ?? [])
          .map((user) => LikedByUser.fromJson(user))
          .toList(),
      // read isLiked from API (default false)
      isLiked: json['isLiked'] as bool? ?? false,
      isOwnPost: json['isOwnPost'] as bool? ?? false,
      commentCount: (json['commentCount'] as int?) ?? 0,
    );
  }

  @override
  WorkoutPost copyWith({
    bool? isLiked,
    int? likes,
    int? commentCount,
    bool? isOwnPost,
  }) {
    return WorkoutPost(
      id: id,
      name: name,
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
      isOwnPost: isOwnPost ?? this.isOwnPost,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

class NutritionFoodItem {
  final String name;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final int quantity;
  final String servingSize;

  NutritionFoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.quantity,
    required this.servingSize,
  });

  factory NutritionFoodItem.fromJson(Map<String, dynamic> json) {
    // Check if it has customFood or food object
    final foodData =
        (json['customFood'] as Map<String, dynamic>?) ??
        (json['food'] as Map<String, dynamic>?) ??
        {};

    return NutritionFoodItem(
      name: foodData['name'] as String? ?? 'Unknown Food',
      calories: (foodData['calories'] as num?)?.toInt() ?? 0,
      protein: (foodData['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (foodData['fat'] as num?)?.toDouble() ?? 0.0,
      carbs: (foodData['carbs'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      servingSize: foodData['servingSize'] as String? ?? 'serving',
    );
  }
}

class NutritionMeal {
  final String sessionId;
  final String mealType;
  final String content;
  final List<String> images;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final List<NutritionFoodItem> foodItems;

  NutritionMeal({
    required this.sessionId, // Added
    required this.mealType,
    required this.content,
    required this.images,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.foodItems = const [],
  });

  factory NutritionMeal.fromJson(Map<String, dynamic> json) {
    final foodItems = (json['nutritionLogs'] as List? ?? [])
        .map((e) => NutritionFoodItem.fromJson(e as Map<String, dynamic>))
        .toList();

    int totalCal = (json['calories'] as num?)?.toInt() ?? 0;
    int totalProt = (json['protein'] as num?)?.toInt() ?? 0;
    int totalCarb = (json['carbs'] as num?)?.toInt() ?? 0;
    int totalFat = (json['fats'] as num?)?.toInt() ?? 0;

    // If totals are missing but we have items, sum them up
    if (totalCal == 0 && foodItems.isNotEmpty) {
      for (var item in foodItems) {
        totalCal += item.calories;
        totalProt += item.protein.toInt();
        totalCarb += item.carbs.toInt();
        totalFat += item.fat.toInt();
      }
    }

    return NutritionMeal(
      sessionId: json['sessionId'] as String? ?? json['id'] as String? ?? '',
      mealType: json['mealType'] as String? ?? 'Meal',
      content:
          (json['caption'] as String?) ?? (json['content'] as String?) ?? '',
      images: (json['images'] as List? ?? [])
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .map((e) => e.toString())
          .toList(),
      calories: totalCal,
      protein: totalProt,
      carbs: totalCarb,
      fats: totalFat,
      foodItems: foodItems,
    );
  }

  NutritionMeal copyWith({
    String? sessionId,
    String? mealType,
    String? content,
    List<String>? images,
    int? calories,
    int? protein,
    int? carbs,
    int? fats,
    List<NutritionFoodItem>? foodItems,
  }) {
    return NutritionMeal(
      sessionId: sessionId ?? this.sessionId,
      mealType: mealType ?? this.mealType,
      content: content ?? this.content,
      images: images ?? this.images,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      foodItems: foodItems ?? this.foodItems,
    );
  }
}

class NutritionPost extends FeedPost {
  final List<NutritionMeal> meals;

  /// Returns the sessionId of the first meal for deletion purposes
  String get sessionId => meals.isNotEmpty ? meals.first.sessionId : id;

  NutritionPost({
    required super.id,
    required super.name,
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
    // Check for 'meals' (from feed) or 'sessions' (from details)
    final sessionsList = (json['sessions'] as List?);
    final mealsData = sessionsList ?? (json['meals'] as List? ?? []);

    final mealsList = mealsData
        .map((e) => NutritionMeal.fromJson(e as Map<String, dynamic>))
        .toList();

    String name = '';
    String username = '';
    String handle = '';
    String profileImage = '';

    if (json.containsKey('user') && json['user'] is Map) {
      final user = json['user'] as Map<String, dynamic>;
      username = user['username'] as String? ?? '';
      name = user['name'] as String? ?? username;
      handle = '@$username';
      profileImage = user['avatarUrl'] as String? ?? '';
    } else {
      username = json['username'] as String? ?? '';
      name = json['name'] as String? ?? username;
      handle = json['handle'] as String? ?? '';
      profileImage = json['profileImage'] as String? ?? '';
    }

    return NutritionPost(
      id: json['id'] as String,
      name: name,
      username: username,
      handle: handle,
      profileImage: profileImage,
      timeAgo: json['createdAt'] != null
          ? TimeFormatter.formatRelativeTime(json['createdAt'])
          : (json['timeAgo'] as String? ?? ''),
      content: mealsList.isNotEmpty
          ? mealsList.first.content
          : (json['caption'] as String?) ?? '',
      images: [],
      likes:
          (json['likeCount'] as int?) ??
          (json['likes'] is int ? json['likes'] as int : 0),
      likedBy:
          (json['likes'] is List
                  ? json['likes'] as List
                  : (json['likedBy'] as List? ?? []))
              .map((user) => LikedByUser.fromJson(user))
              .toList(),
      isLiked: json['isLiked'] as bool? ?? false,
      isOwnPost: json['isOwnPost'] as bool? ?? false,
      commentCount: (json['commentCount'] as int?) ?? 0,
      meals: mealsList,
    );
  }

  @override
  NutritionPost copyWith({
    bool? isLiked,
    int? likes,
    int? commentCount,
    List<NutritionMeal>? meals,
    bool? isOwnPost,
  }) {
    return NutritionPost(
      id: id,
      name: name,
      username: username,
      handle: handle,
      profileImage: profileImage,
      timeAgo: timeAgo,
      content: content,
      images: images,
      likes: likes ?? this.likes,
      likedBy: likedBy,
      isLiked: isLiked ?? this.isLiked,
      isOwnPost: isOwnPost ?? this.isOwnPost,
      commentCount: commentCount ?? this.commentCount,
      meals: meals ?? this.meals, // Updated
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
      username =
          (user['username'] as String?) ?? (user['name'] as String?) ?? '';
      handle = (user['handle'] as String?) ?? username;
      profileImage =
          (user['profileImage'] as String?) ??
          (user['avatarUrl'] as String?) ??
          '';
    } else {
      username =
          (json['username'] as String?) ?? (json['name'] as String?) ?? '';
      handle = (json['handle'] as String?) ?? '';
      profileImage =
          (json['profileImage'] as String?) ??
          (json['avatarUrl'] as String?) ??
          '';
    }

    // Format the time using TimeFormatter for human-readable display
    final rawTime = json['timeAgo'] ?? json['createdAt'] ?? '';
    final formattedTime = TimeFormatter.formatRelativeTime(rawTime);

    return Comment(
      id: json['id']?.toString() ?? '',
      username: username,
      handle: handle,
      profileImage: profileImage,
      timeAgo: formattedTime,
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

  Future<List<UserSuggestion>> getSuggestions() async {
    try {
      final data = await _service.getUserSuggestions();
      return data.map((json) => UserSuggestion.fromJson(json)).toList();
    } catch (e) {
      // Return empty list on failure rather than blocking UI?
      // Or throw to handle in provider. Let's throw for now.
      print('Failed to load suggestions: $e');
      return [];
    }
  }

  Future<FeedPost> getPostDetails(String postId, {bool isMeal = false}) async {
    try {
      final data = isMeal
          ? await _service.getMealPostDetails(postId)
          : await _service.getPostDetails(postId);

      // If explicitly requested as meal, or if 'type' is nutrition, or if it has 'sessions' (meal details specific)
      final type = data['type'] as String?;
      final isNutrition =
          isMeal ||
          type == 'nutrition' ||
          data.containsKey('sessions') ||
          data.containsKey('meals');

      if (isNutrition) {
        if (data['meals'] == null &&
            data['sessions'] == null &&
            data['exercises'] != null) {
          return WorkoutPost.fromJson(data);
        }
        return NutritionPost.fromJson(data);
      } else {
        return WorkoutPost.fromJson(data);
      }
    } catch (e) {
      throw Exception('Failed to load post details: $e');
    }
  }

  List<FeedPost> _mapFeedData(List<Map<String, dynamic>> data) {
    return data
        .map((json) {
          try {
            final type = json['type'] as String? ?? 'workout';

            if (type == 'nutrition') {
              // Basic validation to ensure we don't return an empty/broken nutrition post
              // if the structure is actually a workout (has exercises but no meals)
              if (json['meals'] == null && json['exercises'] != null) {
                // This is likely a mislabeled workout post
                return WorkoutPost.fromJson(json);
              }
              return NutritionPost.fromJson(json);
            } else {
              return WorkoutPost.fromJson(json);
            }
          } catch (e) {
            print('Error parsing feed post: $e');
            print('JSON: $json');
            return null;
          }
        })
        .where((post) => post != null)
        .cast<FeedPost>()
        .toList();
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

  Future<List<Comment>> getComments(
    String postId, {
    bool isMeal = false,
  }) async {
    try {
      final commentsData = isMeal
          ? await _service.getMealComments(postId)
          : await _service.getPostComments(postId);

      return commentsData.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  Future<Comment> addComment(
    String postId,
    String content, {
    bool isMeal = false,
  }) async {
    try {
      final commentData = isMeal
          ? await _service.addMealComment(postId, content)
          : await _service.addComment(postId, content);

      return Comment.fromJson(commentData);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<Comment> addReply(
    String postId,
    String commentId,
    String content, {
    bool isMeal = false,
  }) async {
    try {
      final replyData = isMeal
          ? await _service.addMealReply(postId, commentId, content)
          : await _service.addReply(postId, commentId, content);

      return Comment.fromJson(replyData);
    } catch (e) {
      throw Exception('Failed to add reply: $e');
    }
  }

  Future<List<LikedByUser>> getPostLikes(
    String postId, {
    bool isMeal = false,
  }) async {
    try {
      final data = isMeal
          ? await _service.getMealLikes(postId)
          : await _service.getPostLikes(postId);
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
