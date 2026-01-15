import '../api/stories_service.dart';
import '../../home/data/mutual_feed_repository.dart';

// Models
class StoryContent {
  final String id;
  final String type;
  final String imageUrl;
  final String text;
  final int duration;
  final bool isLiked;
  final int likes;
  final int views;
  final List<LikedByUser> likedBy;
  final bool isHighlighted;
  final String? backgroundColor;

  StoryContent({
    required this.id,
    required this.type,
    required this.imageUrl,
    required this.text,
    this.duration = 5,
    this.isLiked = false,
    this.likes = 0,
    this.views = 0,
    this.likedBy = const [],
    this.isHighlighted = false,
    this.backgroundColor,
  });

  factory StoryContent.fromJson(Map<String, dynamic> json) {
    return StoryContent(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'image',
      imageUrl: json['imageUrl'] as String? ?? '',
      text: json['text'] as String? ?? '',
      duration: json['duration'] as int? ?? 5,
      isLiked: json['isLiked'] as bool? ?? false,
      likes: json['likes'] as int? ?? 0,
      views: json['views'] as int? ?? 0,
      likedBy:
          (json['likedBy'] as List<dynamic>?)
              ?.map((e) => LikedByUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isHighlighted: json['isHighlighted'] as bool? ?? false,
      backgroundColor: json['backgroundColor'] as String?,
    );
  }

  StoryContent copyWith({
    String? id,
    String? type,
    String? imageUrl,
    String? text,
    int? duration,
    bool? isLiked,
    int? likes,
    int? views,
    List<LikedByUser>? likedBy,
    bool? isHighlighted,
    String? backgroundColor,
  }) {
    return StoryContent(
      id: id ?? this.id,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      text: text ?? this.text,
      duration: duration ?? this.duration,
      isLiked: isLiked ?? this.isLiked,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      likedBy: likedBy ?? this.likedBy,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}

class StoryUser {
  final String id;
  final String username;
  final String name;
  final String profileImage;
  final bool hasStory;
  final bool isViewed;
  final bool isMyStory;
  final List<StoryContent> stories;

  StoryUser({
    required this.id,
    required this.username,
    this.name = '',
    required this.profileImage,
    this.hasStory = true,
    this.isViewed = false,
    this.isMyStory = false,
    this.stories = const [],
  });

  factory StoryUser.fromJson(Map<String, dynamic> json) {
    return StoryUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profileImage: json['profileImage'] as String? ?? '',
      hasStory: json['hasStory'] as bool? ?? true,
      isViewed: json['isViewed'] as bool? ?? false,
      isMyStory: json['isMyStory'] as bool? ?? false,
      stories:
          (json['stories'] as List<dynamic>?)
              ?.map((e) => StoryContent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  StoryUser copyWith({
    String? id,
    String? username,
    String? name,
    String? profileImage,
    bool? hasStory,
    bool? isViewed,
    bool? isMyStory,
    List<StoryContent>? stories,
  }) {
    return StoryUser(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      hasStory: hasStory ?? this.hasStory,
      isViewed: isViewed ?? this.isViewed,
      isMyStory: isMyStory ?? this.isMyStory,
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
  final String thumbnail;
  final String mediaType;
  final String platform;
  final String platformHandle;
  final String label;
  final String timeAgo;
  final bool isLiked;
  final int likesCount;
  final int commentsCount;
  final List<LikedByUser> likedBy;
  final bool isViewed;

  DiscoverStory({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.content,
    this.hashtags = const [],
    required this.imageUrl,
    this.thumbnail = '',
    this.mediaType = 'IMAGE',
    this.platform = '',
    this.platformHandle = '',
    this.label = '',
    this.timeAgo = '',
    this.isLiked = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.isViewed = false,
  });

  factory DiscoverStory.fromJson(Map<String, dynamic> json) {
    return DiscoverStory(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profileImage: json['profileImage'] as String? ?? '',
      content: json['content'] as String? ?? '',
      hashtags: (json['hashtags'] as List<dynamic>?)?.cast<String>() ?? [],
      imageUrl: json['imageUrl'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? 'IMAGE',
      platform: json['platform'] as String? ?? '',
      platformHandle: json['platformHandle'] as String? ?? '',
      label: json['label'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? '',
      isLiked: json['isLiked'] as bool? ?? false,
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      likedBy:
          (json['likedBy'] as List<dynamic>?)
              ?.map((e) => LikedByUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isViewed: json['isViewed'] as bool? ?? false,
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
    String? mediaType,
    String? platform,
    String? platformHandle,
    String? label,
    String? timeAgo,
    bool? isLiked,
    int? likesCount,
    int? commentsCount,
    List<LikedByUser>? likedBy,
    bool? isViewed,
  }) {
    return DiscoverStory(
      id: id ?? this.id,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      content: content ?? this.content,
      hashtags: hashtags ?? this.hashtags,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      mediaType: mediaType ?? this.mediaType,
      platform: platform ?? this.platform,
      platformHandle: platformHandle ?? this.platformHandle,
      label: label ?? this.label,
      timeAgo: timeAgo ?? this.timeAgo,
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      isViewed: isViewed ?? this.isViewed,
    );
  }
}

class StoryViewerInfo {
  final String id;
  final String username;
  final String? avatarUrl;
  final String viewedAt;

  StoryViewerInfo({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.viewedAt,
  });

  factory StoryViewerInfo.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] is Map<String, dynamic>)
        ? json['user'] as Map<String, dynamic>
        : json;

    return StoryViewerInfo(
      id: user['username']?.toString() ?? '',
      username: user['username']?.toString() ?? 'Unknown',
      avatarUrl: user['avatarUrl']?.toString(),
      viewedAt: '',
    );
  }
}

class StoryLikerInfo {
  final String id;
  final String username;
  final String? avatarUrl;
  final String likedAt;

  StoryLikerInfo({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.likedAt,
  });

  factory StoryLikerInfo.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] is Map<String, dynamic>)
        ? json['user'] as Map<String, dynamic>
        : json;

    return StoryLikerInfo(
      id: user['username']?.toString() ?? '',
      username: user['username']?.toString() ?? 'Unknown',
      avatarUrl: user['avatarUrl']?.toString(),
      likedAt: '',
    );
  }
}

class StoryDetails {
  final List<StoryViewerInfo> viewers;
  final List<StoryLikerInfo> likes;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;

  StoryDetails({
    required this.viewers,
    required this.likes,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
  });
}

class StoriesRepository {
  final StoriesService _storiesService = StoriesService();

  Future<List<StoryUser>> getStories() async {
    final data = await _storiesService.getStories();
    return data.map((e) => StoryUser.fromJson(e)).toList();
  }

  Future<StoryUser> getMyStories() async {
    final data = await _storiesService.getMyStories();
    return StoryUser.fromJson(data);
  }

  Future<List<DiscoverStory>> getDiscoverStories() async {
    final data = await _storiesService.getDiscoverStories();
    return data.map((e) => DiscoverStory.fromJson(e)).toList();
  }

  Future<void> likeStory(String storyId) async {
    await _storiesService.likeStory(storyId);
  }

  Future<void> likeDiscoverStory(String storyId) async {
    await _storiesService.likeDiscoverStory(storyId);
  }

  Future<void> viewStory(String storyId) async {
    await _storiesService.viewStory(storyId);
  }

  Future<void> highlightStory(String storyId, bool isHighlighted) async {
    await _storiesService.highlightStory(storyId, isHighlighted);
  }

  Future<void> deleteStory(String storyId) async {
    await _storiesService.deleteStory(storyId);
  }

  Future<List<Comment>> getStoryComments(String storyId) async {
    final data = await _storiesService.getStoryComments(storyId);
    return data.map((e) => _mapToComment(e)).toList();
  }

  Future<Comment> commentOnStory(String storyId, String text) async {
    final data = await _storiesService.commentOnStory(storyId, text);
    return _mapToComment(data);
  }

  Future<Comment> replyToComment(String commentId, String text) async {
    final data = await _storiesService.replyToComment(commentId, text);
    return _mapToComment(data);
  }

  Future<StoryDetails> getStoryDetails(String storyId) async {
    final data = await _storiesService.getStoryDetails(storyId);
    final viewersList = (data['views'] as List?) ?? [];
    final likesList = (data['likes'] as List?) ?? [];
    final counts = data['counts'] as Map<String, dynamic>? ?? {};

    return StoryDetails(
      viewers: viewersList.map((e) => StoryViewerInfo.fromJson(e)).toList(),
      likes: likesList.map((e) => StoryLikerInfo.fromJson(e)).toList(),
      viewsCount: counts['views'] ?? 0,
      likesCount: counts['likes'] ?? 0,
      commentsCount: counts['comments'] ?? 0,
    );
  }

  Comment _mapToComment(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final replies = (json['replies'] as List<dynamic>?) ?? [];

    return Comment(
      id: json['id'] as String? ?? '',
      username: user?['name'] ?? user?['username'] ?? 'Unknown',
      handle: '@${user?['username'] ?? 'unknown'}',
      profileImage:
          user?['avatarUrl'] ??
          'https://i.pravatar.cc/150?u=${user?['username']}',
      timeAgo: _calculateTimeAgo(json['createdAt'] as String? ?? ''),
      content: json['text'] as String? ?? '',
      replies: replies
          .map((r) => _mapToComment(r as Map<String, dynamic>))
          .toList(),
    );
  }

  String _calculateTimeAgo(String createdAt) {
    if (createdAt.isEmpty) return 'Recently';
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

    for (var story in stories) {
      if (story.id == storyId) {
        viewedStory = story.copyWith(isViewed: true);
      } else {
        updatedStories.add(story);
      }
    }

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
        return story.copyWith(isLiked: newIsLiked, likesCount: newLikesCount);
      }
      return story;
    }).toList();
  }

  // Mark discover story as viewed
  List<DiscoverStory> markDiscoverStoryAsViewed(
    List<DiscoverStory> stories,
    String storyId,
  ) {
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
          return story.copyWith(isLiked: newIsLiked, likes: newLikes);
        }
        return story;
      }).toList();

      return user.copyWith(stories: updatedStories);
    }).toList();
  }

  // Search users
  Future<List<SearchUser>> searchUsers(String query) async {
    final data = await _storiesService.searchUsers(query);
    return data.map((e) => SearchUser.fromJson(e)).toList();
  }

  // Recent searches (stored locally)
  final List<SearchUser> _recentSearches = [];

  Future<List<SearchUser>> getRecentSearches() async {
    return _recentSearches;
  }

  Future<void> addToRecentSearches(SearchUser user) async {
    _recentSearches.removeWhere((u) => u.id == user.id);
    _recentSearches.insert(0, user);
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
  }

  Future<void> removeFromRecentSearches(String userId) async {
    _recentSearches.removeWhere((u) => u.id == userId);
  }
}

// SearchUser class for search results
class SearchUser {
  final String id;
  final String username;
  final String name;
  final String? avatarUrl;
  final bool isFollowing;

  SearchUser({
    required this.id,
    required this.username,
    required this.name,
    this.avatarUrl,
    this.isFollowing = false,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    return SearchUser(
      id: json['id']?.toString() ?? json['username']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }
}
