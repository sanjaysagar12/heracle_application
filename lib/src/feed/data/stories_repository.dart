import '../../core/network/cache_manager.dart';
import '../api/stories_service.dart';
import '../../home/data/mutual_feed_repository.dart';

class StoryViewerInfo {
  final String id;
  final String username;
  final String? avatarUrl;
  final String viewedAt;

  StoryViewerInfo({required this.id, required this.username, this.avatarUrl, required this.viewedAt});
  
  factory StoryViewerInfo.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] is Map<String, dynamic>) 
        ? json['user'] as Map<String, dynamic> 
        : json;
        
    return StoryViewerInfo(
      id: user['username']?.toString() ?? '', 
      username: user['username']?.toString() ?? 'Unknown',
      avatarUrl: user['avatarUrl']?.toString(),
      viewedAt: '', // Date not provided in engagement API
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
    final user = (json['user'] is Map<String, dynamic>) 
        ? json['user'] as Map<String, dynamic> 
        : json;
        
    return StoryLikerInfo(
      id: user['username']?.toString() ?? '',
      username: user['username']?.toString() ?? 'Unknown',
      avatarUrl: user['avatarUrl']?.toString(),
      likedAt: '', // Date not provided in engagement API
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

// ... existing code ...

  Future<StoryDetails> getStoryDetails(String storyId) async {
    try {
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
