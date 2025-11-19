import '../api/mutual_feed_service.dart';
import '../presentation/widgets/workout_post_card.dart';

abstract class FeedPost {
  final String id;
  final String username;
  final String handle;
  final String profileImage;
  final String timeAgo;
  final String content;
  final List<String> images;
  final int likes;
  final List<String> likedBy;
  final bool isLiked;
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
    required this.commentCount,
  });

  FeedPost copyWith({bool? isLiked, int? likes, int? commentCount});
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
      tags: List<String>.from(json['tags']),
      images: List<String>.from(json['images']),
      duration: json['duration'] as String,
      volume: json['volume'] as String,
      records: json['records'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => Exercise(name: e as String))
          .toList(),
      likes: json['likes'] as int,
      likedBy: List<String>.from(json['likedBy']),
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
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

class NutritionPost extends FeedPost {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

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
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required super.commentCount,
  });

  factory NutritionPost.fromJson(Map<String, dynamic> json) {
    return NutritionPost(
      id: json['id'] as String,
      username: json['username'] as String,
      handle: json['handle'] as String,
      profileImage: json['profileImage'] as String,
      timeAgo: json['timeAgo'] as String,
      content: json['content'] as String,
      images: List<String>.from(json['images']),
      calories: json['calories'] as int,
      protein: json['protein'] as int,
      carbs: json['carbs'] as int,
      fats: json['fats'] as int,
      likes: json['likes'] as int,
      likedBy: List<String>.from(json['likedBy']),
      commentCount: json['commentCount'] as int? ?? 0,
    );
  }

  @override
  NutritionPost copyWith({bool? isLiked, int? likes, int? commentCount}) {
    return NutritionPost(
      id: id,
      username: username,
      handle: handle,
      profileImage: profileImage,
      timeAgo: timeAgo,
      content: content,
      images: images,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      likes: likes ?? this.likes,
      likedBy: likedBy,
      isLiked: isLiked ?? this.isLiked,
      commentCount: commentCount ?? this.commentCount,
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
  final int likes;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.username,
    required this.handle,
    required this.profileImage,
    required this.timeAgo,
    required this.content,
    required this.likes,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      username: json['username'] as String,
      handle: json['handle'] as String,
      profileImage: json['profileImage'] as String,
      timeAgo: json['timeAgo'] as String,
      content: json['content'] as String,
      likes: json['likes'] as int,
      replies: (json['replies'] as List)
          .map((reply) => Comment.fromJson(reply))
          .toList(),
    );
  }
}

class MutualFeedRepository {
  final MutualFeedService _mutualFeedService;

  MutualFeedRepository({MutualFeedService? mutualFeedService})
      : _mutualFeedService = mutualFeedService ?? MutualFeedService();

  Future<List<FeedPost>> getMutualFeed() async {
    try {
      final data = await _mutualFeedService.getMutualFeed();
      return data.map((json) {
        final type = json['type'] as String;
        if (type == 'workout') {
          return WorkoutPost.fromJson(json);
        } else if (type == 'nutrition') {
          return NutritionPost.fromJson(json);
        }
        throw Exception('Unknown post type: $type');
      }).toList();
    } catch (e) {
      throw Exception('Failed to load mutual feed: $e');
    }
  }

  Future<List<Comment>> getPostComments(String postId) async {
    try {
      final data = await _mutualFeedService.getPostComments(postId);
      return data.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  Future<Comment> addComment(String postId, String content) async {
    try {
      final data = await _mutualFeedService.addComment(postId, content);
      return Comment.fromJson(data);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }
}
