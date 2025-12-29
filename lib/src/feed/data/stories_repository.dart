import '../api/stories_service.dart';
import '../../home/data/mutual_feed_repository.dart';

class StoryViewerInfo {
  final String id;
  final String username;
  final String? avatarUrl;
  final String viewedAt;

  StoryViewerInfo({required this.id, required this.username, this.avatarUrl, required this.viewedAt});
  
  factory StoryViewerInfo.fromJson(Map<String, dynamic> json) {
    return StoryViewerInfo(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      avatarUrl: json['avatarUrl']?.toString(),
      viewedAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class StoryLikerInfo {
  final String id;
  final String username;
  final String? avatarUrl;
  final String likedAt;

  StoryLikerInfo({required this.id, required this.username, this.avatarUrl, required this.likedAt});

  factory StoryLikerInfo.fromJson(Map<String, dynamic> json) {
    return StoryLikerInfo(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      avatarUrl: json['avatarUrl']?.toString(),
      likedAt: json['likedAt']?.toString() ?? '',
    );
  }
}

class StoryDetails {
  final List<StoryViewerInfo> viewers;
  final List<StoryLikerInfo> likes;
  final int viewsCount;
  final int likesCount;

  StoryDetails({required this.viewers, required this.likes, required this.viewsCount, required this.likesCount});
}

class StoryContent {
  final String id;
  final String type; // 'image' or 'text'
  final String? imageUrl;
  final String? text;
  final String? backgroundColor;
  final Duration duration;
  final bool isLiked;
  final int likes;
  final int views;
  final List<LikedByUser> likedBy;

  StoryContent({
    required this.id,
    required this.type,
    this.imageUrl,
    this.text,
    this.backgroundColor,
    this.duration = const Duration(seconds: 5),
    this.isLiked = false,
    this.likes = 0,
    this.views = 0,
    this.likedBy = const [],
  });

  factory StoryContent.fromJson(Map<String, dynamic> json) {
    return StoryContent(
      id: json['id'] as String,
      type: json['type'] as String,
      imageUrl: json['imageUrl'] as String?,
      text: json['text'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      duration: Duration(
        seconds: json['duration'] as int? ?? 5,
      ),
      isLiked: json['isLiked'] as bool? ?? false,
      likes: json['likes'] as int? ?? 0,
      views: json['views'] as int? ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)
          ?.map((e) => LikedByUser.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  StoryContent copyWith({
    String? id,
    String? type,
    String? imageUrl,
    String? text,
    String? backgroundColor,
    Duration? duration,
    bool? isLiked,
    int? likes,
    int? views,
    List<LikedByUser>? likedBy,
  }) {
    return StoryContent(
      id: id ?? this.id,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      text: text ?? this.text,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      duration: duration ?? this.duration,
      isLiked: isLiked ?? this.isLiked,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}

class StoryUser {
  final String id;
  final String username;
  final String profileImage;
  final bool hasStory;
  final bool isViewed;
  final List<StoryContent> stories;
  final bool isMyStory; // New field to indicate if this is user's own story

  StoryUser({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.hasStory,
    required this.isViewed,
    this.stories = const [],
    this.isMyStory = false,
  });

  factory StoryUser.fromJson(Map<String, dynamic> json) {
    return StoryUser(
      id: json['id'] as String,
      username: json['username'] as String,
      profileImage: json['profileImage'] as String,
      hasStory: json['hasStory'] as bool? ?? false,
      isViewed: json['isViewed'] as bool? ?? false,
      stories: (json['stories'] as List<dynamic>?)
              ?.map((e) => StoryContent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isMyStory: json['isMyStory'] as bool? ?? false,
    );
  }

  StoryUser copyWith({
    String? id,
    String? username,
    String? profileImage,
    bool? hasStory,
    bool? isViewed,
    List<StoryContent>? stories,
    bool? isMyStory,
  }) {
    return StoryUser(
      id: id ?? this.id,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      hasStory: hasStory ?? this.hasStory,
      isViewed: isViewed ?? this.isViewed,
      stories: stories ?? this.stories,
      isMyStory: isMyStory ?? this.isMyStory,
    );
  }
}

class DiscoverStory {
  final String id;
  final String username;
  final String profileImage;
  final String content;
  final List<String> hashtags;
  final String? imageUrl;
  final String? thumbnail;
  final String? platform;
  final String? platformHandle;
  final String? label;
  final String? timeAgo;
  final bool isLiked;
  final int likesCount;
  final List<LikedByUser> likedBy;
  final bool isViewed;
  final String mediaType; // 'IMAGE' or 'VIDEO'

  DiscoverStory({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.content,
    required this.hashtags,
    required this.imageUrl,
    this.thumbnail,
    this.platform,
    this.platformHandle,
    this.label,
    required this.timeAgo,
    this.isLiked = false,
    this.likesCount = 0,
    this.likedBy = const [],
    this.isViewed = false,
    this.mediaType = 'IMAGE',
  });

  factory DiscoverStory.fromJson(Map<String, dynamic> json) {
    return DiscoverStory(
      id: json['id'] as String,
      username: json['username'] as String,
      profileImage: json['profileImage'] as String,
      content: json['content'] as String,
      hashtags: (json['hashtags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      imageUrl: json['imageUrl'] as String? ?? '',
      thumbnail: json['thumbnail'] as String?,
      platform: json['platform'] as String?,
      platformHandle: json['platformHandle'] as String?,
      label: json['label'] as String?,
      timeAgo: json['timeAgo'] as String? ?? '',
      isLiked: json['isLiked'] as bool? ?? false,
      likesCount: json['likesCount'] as int? ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => LikedByUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mediaType: json['mediaType'] as String? ?? 'IMAGE',
    );
  }

  DiscoverStory copyWith({
    String? id,
    String? username,
    String? profileImage,
    String? content,
    List<String>? hashtags,
    String? imageUrl,
    String? thumbnail,
    String? platform,
    String? platformHandle,
    String? label,
    String? timeAgo,
    bool? isLiked,
    int? likesCount,
    List<LikedByUser>? likedBy,
    bool? isViewed,
    String? mediaType,
  }) {
    return DiscoverStory(
      id: id ?? this.id,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      content: content ?? this.content,
      hashtags: hashtags ?? this.hashtags,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      platform: platform ?? this.platform,
      platformHandle: platformHandle ?? this.platformHandle,
      label: label ?? this.label,
      timeAgo: timeAgo ?? this.timeAgo,
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      isViewed: isViewed ?? this.isViewed,
      mediaType: mediaType ?? this.mediaType,
    );
  }
}

class StoriesRepository {
  final StoriesService _storiesService;

  StoriesRepository({StoriesService? storiesService})
      : _storiesService = storiesService ?? StoriesService();

  Future<List<StoryUser>> getStories() async {
    try {
      final data = await _storiesService.getStories();
      return data.map((json) => StoryUser.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load stories: $e');
    }
  }

  Future<StoryUser> getMyStories() async {
    try {
      final data = await _storiesService.getMyStories();
      return StoryUser.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load my stories: $e');
    }
  }

  Future<List<DiscoverStory>> getDiscoverStories() async {
    try {
      final data = await _storiesService.getDiscoverStories();
      return data.map((json) => DiscoverStory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load discover stories: $e');
    }
  }

  Future<void> likeStory(String storyId) async {
    await _storiesService.likeStory(storyId);
  }

  Future<void> likeDiscoverStory(String storyId) async {
    await _storiesService.likeDiscoverStory(storyId);
  }

  Future<void> commentOnStory(String storyId, String text) async {
    await _storiesService.commentOnStory(storyId, text);
  }

  Future<void> replyToComment(String commentId, String text) async {
    await _storiesService.replyToComment(commentId, text);
  }

  Future<void> highlightStory(String storyId, bool isHighlighted) async {
    await _storiesService.highlightStory(storyId, isHighlighted);
  }

  Future<void> deleteStory(String storyId) async {
    await _storiesService.deleteStory(storyId);
  }

  Future<void> viewStory(String storyId) async {
    await _storiesService.viewStory(storyId);
  }

  Future<List<Comment>> getStoryComments(String storyId) async {
    try {
      final data = await _storiesService.getStoryComments(storyId);
      return data.map((json) => _mapToComment(json)).toList();
    } catch (e) {
      throw Exception('Failed to load story comments: $e');
    }
  }

  Future<StoryDetails> getStoryDetails(String storyId) async {
    try {
      final data = await _storiesService.getStoryDetails(storyId);
      final viewersList = (data['viewers'] as List?) ?? [];
      final likesList = (data['likes'] as List?) ?? [];
      final counts = data['counts'] as Map<String, dynamic>? ?? {};

      return StoryDetails(
        viewers: viewersList.map((e) => StoryViewerInfo.fromJson(e)).toList(),
        likes: likesList.map((e) => StoryLikerInfo.fromJson(e)).toList(),
        viewsCount: counts['views'] ?? 0,
        likesCount: counts['likes'] ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to load story details: $e');
    }
  }

  Comment _mapToComment(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final replies = (json['replies'] as List<dynamic>?) ?? [];
    
    return Comment(
      id: json['id'] as String,
      username: user['name'] ?? user['username'] ?? 'Unknown',
      handle: '@${user['username'] ?? 'unknown'}',
      profileImage: user['avatarUrl'] ?? 'https://i.pravatar.cc/150?u=${user['username']}',
      timeAgo: _calculateTimeAgo(json['createdAt'] as String),
      content: json['text'] as String,
      replies: replies.map((r) => _mapToComment(r as Map<String, dynamic>)).toList(),
    );
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

  // Mark story as viewed and reorder
  List<StoryUser> markStoryAsViewed(List<StoryUser> stories, String storyId) {
    final updatedStories = <StoryUser>[];
    StoryUser? viewedStory;

    // Find and mark the story as viewed
    for (var story in stories) {
      if (story.id == storyId) {
        viewedStory = story.copyWith(isViewed: true);
      } else {
        updatedStories.add(story);
      }
    }

    // Add viewed story at the end
    if (viewedStory != null) {
      updatedStories.add(viewedStory);
    }

    return updatedStories;
  }

  // Sort stories: unviewed first, then viewed
  List<StoryUser> sortStories(List<StoryUser> stories) {
    final unviewed = stories.where((s) => !s.isViewed).toList();
    final viewed = stories.where((s) => s.isViewed).toList();
    return [...unviewed, ...viewed];
  }

  // Toggle like on discover story
  List<DiscoverStory> toggleLike(List<DiscoverStory> stories, String storyId) {
    return stories.map((story) {
      if (story.id == storyId) {
        final newIsLiked = !story.isLiked;
        final newLikesCount = newIsLiked 
            ? story.likesCount + 1 
            : story.likesCount - 1;
        return story.copyWith(
          isLiked: newIsLiked,
          likesCount: newLikesCount,
        );
      }
      return story;
    }).toList();
  }

  // Mark discover story as viewed
  List<DiscoverStory> markDiscoverStoryAsViewed(List<DiscoverStory> stories, String storyId) {
    return stories.map((story) {
      if (story.id == storyId) {
        return story.copyWith(isViewed: true);
      }
      return story;
    }).toList();
  }

  // Toggle like on story content
  List<StoryUser> toggleStoryLike(List<StoryUser> stories, String storyId) {
    return stories.map((user) {
      final updatedStories = user.stories.map((story) {
        if (story.id == storyId) {
          final newIsLiked = !story.isLiked;
          final newLikes = newIsLiked ? story.likes + 1 : story.likes - 1;
          return story.copyWith(
            isLiked: newIsLiked,
            likes: newLikes,
          );
        }
        return story;
      }).toList();
      
      return user.copyWith(stories: updatedStories);
    }).toList();
  }
}
