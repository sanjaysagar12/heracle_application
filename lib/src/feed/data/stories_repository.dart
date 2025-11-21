import '../api/stories_service.dart';
import '../../home/data/mutual_feed_repository.dart';

class StoryContent {
  final String id;
  final String type; // 'image' or 'text'
  final String? imageUrl;
  final String? text;
  final String? backgroundColor;
  final Duration duration;

  StoryContent({
    required this.id,
    required this.type,
    this.imageUrl,
    this.text,
    this.backgroundColor,
    this.duration = const Duration(seconds: 5),
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

  StoryUser({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.hasStory,
    required this.isViewed,
    this.stories = const [],
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
    );
  }

  StoryUser copyWith({
    String? id,
    String? username,
    String? profileImage,
    bool? hasStory,
    bool? isViewed,
    List<StoryContent>? stories,
  }) {
    return StoryUser(
      id: id ?? this.id,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      hasStory: hasStory ?? this.hasStory,
      isViewed: isViewed ?? this.isViewed,
      stories: stories ?? this.stories,
    );
  }
}

class DiscoverStory {
  final String id;
  final String username;
  final String profileImage;
  final String content;
  final List<String> hashtags;
  final String imageUrl;
  final String platform;
  final String platformHandle;
  final String? label;
  final String timeAgo;
  final bool isLiked;
  final int likesCount;
  final List<LikedByUser> likedBy;

  DiscoverStory({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.content,
    required this.hashtags,
    required this.imageUrl,
    required this.platform,
    required this.platformHandle,
    this.label,
    required this.timeAgo,
    this.isLiked = false,
    this.likesCount = 0,
    this.likedBy = const [],
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
      imageUrl: json['imageUrl'] as String,
      platform: json['platform'] as String,
      platformHandle: json['platformHandle'] as String,
      label: json['label'] as String?,
      timeAgo: json['timeAgo'] as String,
      isLiked: json['isLiked'] as bool? ?? false,
      likesCount: json['likesCount'] as int? ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => LikedByUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  DiscoverStory copyWith({
    String? id,
    String? username,
    String? profileImage,
    String? content,
    List<String>? hashtags,
    String? imageUrl,
    String? platform,
    String? platformHandle,
    String? label,
    String? timeAgo,
    bool? isLiked,
    int? likesCount,
    List<LikedByUser>? likedBy,
  }) {
    return DiscoverStory(
      id: id ?? this.id,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      content: content ?? this.content,
      hashtags: hashtags ?? this.hashtags,
      imageUrl: imageUrl ?? this.imageUrl,
      platform: platform ?? this.platform,
      platformHandle: platformHandle ?? this.platformHandle,
      label: label ?? this.label,
      timeAgo: timeAgo ?? this.timeAgo,
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
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

  Future<List<DiscoverStory>> getDiscoverStories() async {
    try {
      final data = await _storiesService.getDiscoverStories();
      return data.map((json) => DiscoverStory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load discover stories: $e');
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
}
