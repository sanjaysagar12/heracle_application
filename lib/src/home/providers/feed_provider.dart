import 'package:flutter/foundation.dart';
import '../data/mutual_feed_repository.dart';
import '../data/profile_repository.dart';
import '../../profile/data/profile_repository.dart' as profile_repo;

/// FeedProvider manages the home feed posts and all interactions.
///
/// This centralizes the complex like/comment logic that was duplicated
/// across home_page.dart and profile_page.dart.
class FeedProvider extends ChangeNotifier {
  final MutualFeedRepository _feedRepository;
  final profile_repo.ProfileRepository _profileRepository;

  // Home feed posts
  List<FeedPost> _posts = [];

  // User-specific posts (for profile pages) keyed by username
  Map<String, List<FeedPost>> _userPosts = {};
  Map<String, bool> _userPostsLoading = {};

  Map<String, List<Comment>> _commentsCache = {};
  Map<String, bool> _loadingComments = {};
  Set<String> _likeInProgress = {};

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;

  FeedProvider({
    MutualFeedRepository? feedRepository,
    profile_repo.ProfileRepository? profileRepository,
  }) : _feedRepository = feedRepository ?? MutualFeedRepository(),
       _profileRepository =
           profileRepository ?? profile_repo.ProfileRepository();

  // Getters
  List<FeedPost> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;

  /// Get user-specific posts
  List<FeedPost> getUserPosts(String username) => _userPosts[username] ?? [];

  /// Check if user posts are loading
  bool isUserPostsLoading(String username) =>
      _userPostsLoading[username] ?? false;

  /// Get comments for a post from cache
  List<Comment> getComments(String postId) => _commentsCache[postId] ?? [];

  /// Check if comments are loading for a post
  bool isCommentsLoading(String postId) => _loadingComments[postId] ?? false;

  /// Check if a like action is in progress
  bool isLikeInProgress(String postId) => _likeInProgress.contains(postId);

  /// Load the mutual feed (home)
  Future<void> loadFeed() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await _feedRepository.getMutualFeed();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh the feed
  Future<void> refreshFeed() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      _posts = await _feedRepository.getMutualFeed();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isRefreshing = false;
    notifyListeners();
  }

  /// Load user-specific posts (for profile page)
  Future<void> loadUserPosts(String username) async {
    if (_userPostsLoading[username] == true) return;

    _userPostsLoading[username] = true;
    notifyListeners();

    try {
      final posts = await _profileRepository.getPosts(username);
      _userPosts[username] = posts;
      _userPostsLoading[username] = false;
      notifyListeners();
    } catch (e) {
      _userPosts[username] = [];
      _userPostsLoading[username] = false;
      _error = 'Failed to load posts: $e';
      notifyListeners();
    }
  }

  /// Refresh user-specific posts
  Future<void> refreshUserPosts(String username) async {
    try {
      final posts = await _profileRepository.getPosts(username);
      _userPosts[username] = posts;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh posts: $e';
      notifyListeners();
    }
  }

  /// Like/unlike a post with optimistic update (works for both home and user posts)
  Future<void> toggleLike(String postId, {String? username}) async {
    if (_likeInProgress.contains(postId)) return;

    // Find post in appropriate list
    List<FeedPost> targetList;
    int postIndex;

    if (username != null && _userPosts.containsKey(username)) {
      targetList = _userPosts[username]!;
      postIndex = targetList.indexWhere((p) => p.id == postId);
    } else {
      targetList = _posts;
      postIndex = targetList.indexWhere((p) => p.id == postId);
    }

    if (postIndex == -1) return;

    final post = targetList[postIndex];
    final isMeal = post is NutritionPost;
    final wasLiked = post.isLiked;

    // Optimistic update
    _likeInProgress.add(postId);
    targetList[postIndex] = post.copyWith(
      isLiked: !wasLiked,
      likes: wasLiked ? post.likes - 1 : post.likes + 1,
    );
    notifyListeners();

    try {
      await _feedRepository.likePost(postId, isMeal: isMeal);
      _likeInProgress.remove(postId);
      notifyListeners();
    } catch (e) {
      // Revert on error
      targetList[postIndex] = post;
      _likeInProgress.remove(postId);
      _error = 'Failed to like post: $e';
      notifyListeners();
    }
  }

  /// Load comments for a post
  Future<void> loadComments(String postId, {bool isMeal = false}) async {
    if (_loadingComments[postId] == true) return;

    _loadingComments[postId] = true;
    notifyListeners();

    try {
      final comments = await _feedRepository.getComments(
        postId,
        isMeal: isMeal,
      );
      _commentsCache[postId] = comments;
      _loadingComments[postId] = false;
      notifyListeners();
    } catch (e) {
      _loadingComments[postId] = false;
      _error = 'Failed to load comments: $e';
      notifyListeners();
    }
  }

  /// Add a comment to a post with optimistic update
  Future<Comment?> addComment(
    String postId,
    String content,
    Profile currentUser, {
    bool isMeal = false,
    String? username,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final tempComment = Comment(
      id: tempId,
      username: currentUser.username,
      handle: currentUser.username,
      profileImage: currentUser.profileImageUrl,
      timeAgo: 'Just now',
      content: content,
      replies: [],
    );

    // Optimistic add
    _commentsCache[postId] = [...(_commentsCache[postId] ?? []), tempComment];
    _updatePostCommentCount(postId, 1, username: username);
    notifyListeners();

    try {
      final newComment = await _feedRepository.addComment(
        postId,
        content,
        isMeal: isMeal,
      );
      _commentsCache[postId] = _replaceTemporaryComment(
        _commentsCache[postId] ?? [],
        newComment,
      );
      notifyListeners();
      return newComment;
    } catch (e) {
      _commentsCache[postId] = _removeTemporaryComments(
        _commentsCache[postId] ?? [],
      );
      _updatePostCommentCount(postId, -1, username: username);
      _error = 'Failed to add comment: $e';
      notifyListeners();
      return null;
    }
  }

  /// Add a reply to a comment with optimistic update
  Future<Comment?> addReply(
    String postId,
    String commentId,
    String content,
    Profile currentUser, {
    bool isMeal = false,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final tempReply = Comment(
      id: tempId,
      username: currentUser.username,
      handle: currentUser.username,
      profileImage: currentUser.profileImageUrl,
      timeAgo: 'Just now',
      content: content,
      replies: [],
    );

    _commentsCache[postId] = _addReplyToComment(
      _commentsCache[postId] ?? [],
      commentId,
      tempReply,
    );
    notifyListeners();

    try {
      final newReply = await _feedRepository.addReply(
        postId,
        commentId,
        content,
        isMeal: isMeal,
      );
      _commentsCache[postId] = _replaceTemporaryReply(
        _commentsCache[postId] ?? [],
        newReply,
      );
      notifyListeners();
      return newReply;
    } catch (e) {
      _commentsCache[postId] = _removeTemporaryReplies(
        _commentsCache[postId] ?? [],
      );
      _error = 'Failed to add reply: $e';
      notifyListeners();
      return null;
    }
  }

  /// Delete a post locally (from both home and user feeds)
  void removePost(String postId, {String? username}) {
    _posts.removeWhere((p) => p.id == postId);
    if (username != null) {
      _userPosts[username]?.removeWhere((p) => p.id == postId);
    }
    _commentsCache.remove(postId);
    notifyListeners();
  }

  /// Update a post's likes data with fresh data from the API
  /// Called when LikesBottomSheet fetches fresh likes to sync the feed
  void updatePostLikes(String postId, List<LikedByUser> likedByUsers) {
    final likes = likedByUsers.length;

    // Update in home feed
    final homeIndex = _posts.indexWhere((p) => p.id == postId);
    if (homeIndex != -1) {
      final post = _posts[homeIndex];
      if (post is WorkoutPost) {
        _posts[homeIndex] = WorkoutPost(
          id: post.id,
          name: post.name,
          username: post.username,
          handle: post.handle,
          profileImage: post.profileImage,
          timeAgo: post.timeAgo,
          content: post.content,
          tags: post.tags,
          images: post.images,
          duration: post.duration,
          volume: post.volume,
          records: post.records,
          exercises: post.exercises,
          likes: likes,
          likedBy: likedByUsers,
          isLiked: post.isLiked,
          isOwnPost: post.isOwnPost,
          commentCount: post.commentCount,
        );
      } else if (post is NutritionPost) {
        _posts[homeIndex] = NutritionPost(
          id: post.id,
          name: post.name,
          username: post.username,
          handle: post.handle,
          profileImage: post.profileImage,
          timeAgo: post.timeAgo,
          content: post.content,
          images: post.images,
          meals: post.meals,
          likes: likes,
          likedBy: likedByUsers,
          isLiked: post.isLiked,
          isOwnPost: post.isOwnPost,
          commentCount: post.commentCount,
        );
      }
    }

    // Update in all user feeds as well
    for (final username in _userPosts.keys) {
      final userIndex = _userPosts[username]!.indexWhere((p) => p.id == postId);
      if (userIndex != -1) {
        final post = _userPosts[username]![userIndex];
        if (post is WorkoutPost) {
          _userPosts[username]![userIndex] = WorkoutPost(
            id: post.id,
            name: post.name,
            username: post.username,
            handle: post.handle,
            profileImage: post.profileImage,
            timeAgo: post.timeAgo,
            content: post.content,
            tags: post.tags,
            images: post.images,
            duration: post.duration,
            volume: post.volume,
            records: post.records,
            exercises: post.exercises,
            likes: likes,
            likedBy: likedByUsers,
            isLiked: post.isLiked,
            isOwnPost: post.isOwnPost,
            commentCount: post.commentCount,
          );
        } else if (post is NutritionPost) {
          _userPosts[username]![userIndex] = NutritionPost(
            id: post.id,
            name: post.name,
            username: post.username,
            handle: post.handle,
            profileImage: post.profileImage,
            timeAgo: post.timeAgo,
            content: post.content,
            images: post.images,
            meals: post.meals,
            likes: likes,
            likedBy: likedByUsers,
            isLiked: post.isLiked,
            isOwnPost: post.isOwnPost,
            commentCount: post.commentCount,
          );
        }
      }
    }
    notifyListeners();
  }

  /// Update a post locally (after edit)
  void updatePost(FeedPost updatedPost, {String? username}) {
    // Update in home feed
    final homeIndex = _posts.indexWhere((p) => p.id == updatedPost.id);
    if (homeIndex != -1) {
      _posts[homeIndex] = updatedPost;
    }
    // Update in user feed
    if (username != null && _userPosts.containsKey(username)) {
      final userIndex = _userPosts[username]!.indexWhere(
        (p) => p.id == updatedPost.id,
      );
      if (userIndex != -1) {
        _userPosts[username]![userIndex] = updatedPost;
      }
    }
    notifyListeners();
  }

  /// Clear feed (on logout)
  void clear() {
    _posts = [];
    _userPosts = {};
    _userPostsLoading = {};
    _commentsCache = {};
    _loadingComments = {};
    _likeInProgress = {};
    _error = null;
    notifyListeners();
  }

  /// Clear any error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper methods
  void _updatePostCommentCount(String postId, int delta, {String? username}) {
    // Update in home feed
    final homeIndex = _posts.indexWhere((p) => p.id == postId);
    if (homeIndex != -1) {
      final post = _posts[homeIndex];
      _posts[homeIndex] = post.copyWith(
        commentCount: post.commentCount + delta,
      );
    }
    // Update in user feed
    if (username != null && _userPosts.containsKey(username)) {
      final userIndex = _userPosts[username]!.indexWhere((p) => p.id == postId);
      if (userIndex != -1) {
        final post = _userPosts[username]![userIndex];
        _userPosts[username]![userIndex] = post.copyWith(
          commentCount: post.commentCount + delta,
        );
      }
    }
  }

  List<Comment> _replaceTemporaryComment(
    List<Comment> comments,
    Comment newComment,
  ) {
    final result = [...comments];
    for (int i = result.length - 1; i >= 0; i--) {
      if (result[i].id.startsWith('temp_')) {
        result[i] = newComment;
        break;
      }
    }
    return result;
  }

  List<Comment> _replaceTemporaryReply(
    List<Comment> comments,
    Comment newReply,
  ) {
    return comments.map((comment) {
      if (comment.replies.any((reply) => reply.id.startsWith('temp_'))) {
        final updatedReplies = [...comment.replies];
        for (int i = updatedReplies.length - 1; i >= 0; i--) {
          if (updatedReplies[i].id.startsWith('temp_')) {
            updatedReplies[i] = newReply;
            break;
          }
        }
        return comment.copyWith(replies: updatedReplies);
      }
      if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _replaceTemporaryReply(comment.replies, newReply),
        );
      }
      return comment;
    }).toList();
  }

  List<Comment> _removeTemporaryComments(List<Comment> comments) {
    return comments.where((c) => !c.id.startsWith('temp_')).toList();
  }

  List<Comment> _removeTemporaryReplies(List<Comment> comments) {
    return comments
        .map(
          (comment) => comment.copyWith(
            replies: comment.replies
                .where((r) => !r.id.startsWith('temp_'))
                .toList(),
          ),
        )
        .toList();
  }

  List<Comment> _addReplyToComment(
    List<Comment> comments,
    String commentId,
    Comment newReply,
  ) {
    return comments.map((comment) {
      if (comment.id == commentId) {
        return comment.copyWithReply(newReply);
      }
      if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _addReplyToComment(comment.replies, commentId, newReply),
        );
      }
      return comment;
    }).toList();
  }
}
