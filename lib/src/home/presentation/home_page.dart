import 'package:flutter/material.dart';
import '../../../widgets/app_bar.dart';
import '../data/profile_repository.dart';
import '../data/progress_repository.dart';
import '../data/mutual_feed_repository.dart';
import '../widgets/progress_card.dart';
import '../widgets/track_mutuals_section.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/likes_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final ProgressRepository _progressRepository = ProgressRepository();
  final MutualFeedRepository _mutualFeedRepository = MutualFeedRepository();
  Profile? _profile;
  ProgressCard? _progress;
  List<FeedPost> _posts = [];
  bool _isLoading = true;
  Map<String, List<Comment>> _commentsCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _profileRepository.getProfile(),
        _progressRepository.getTodayProgress(),
        _mutualFeedRepository.getMutualFeed(),
      ]);

      setState(() {
        _profile = results[0] as Profile;
        _progress = results[1] as ProgressCard;
        _posts = results[2] as List<FeedPost>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      print('Error loading data: $e');
    }
  }

  void _handleLike(String postId) {
    setState(() {
      _posts = _posts.map((post) {
        if (post.id == postId) {
          final newIsLiked = !post.isLiked;
          final newLikes = newIsLiked ? post.likes + 1 : post.likes - 1;
          return post.copyWith(isLiked: newIsLiked, likes: newLikes);
        }
        return post;
      }).toList();
    });
  }

  Future<void> _handleAddComment(String postId, String content) async {
    try {
      final newComment = await _mutualFeedRepository.addComment(postId, content);
      
      setState(() {
        // Replace temporary comment with real comment from API
        _commentsCache[postId] = _replaceTemporaryComment(
          _commentsCache[postId] ?? [],
          newComment,
        );
      });
    } catch (e) {
      // Remove temporary comment on error
      setState(() {
        _commentsCache[postId] = _removeTemporaryComments(_commentsCache[postId] ?? []);
      });
      rethrow; // Re-throw to let CommentsBottomSheet handle the error
    }
  }

  Future<void> _handleAddReply(String postId, String commentId, String content) async {
    try {
      final newReply = await _mutualFeedRepository.addReply(postId, commentId, content);
      
      setState(() {
        // Replace temporary reply with real reply from API
        _commentsCache[postId] = _replaceTemporaryReply(
          _commentsCache[postId] ?? [],
          newReply,
        );
      });
    } catch (e) {
      // Remove temporary reply on error
      setState(() {
        _commentsCache[postId] = _removeTemporaryReplies(_commentsCache[postId] ?? []);
      });
      rethrow; // Re-throw to let CommentsBottomSheet handle the error
    }
  }

  List<Comment> _replaceTemporaryComment(List<Comment> comments, Comment newComment) {
    // Find and replace the last temporary comment with the real one
    for (int i = comments.length - 1; i >= 0; i--) {
      if (comments[i].id.startsWith('temp_')) {
        comments[i] = newComment;
        break;
      }
    }
    return comments;
  }

  List<Comment> _replaceTemporaryReply(List<Comment> comments, Comment newReply) {
    return comments.map((comment) {
      // Check if this comment has temporary replies
      if (comment.replies.any((reply) => reply.id.startsWith('temp_'))) {
        final updatedReplies = [...comment.replies];
        for (int i = updatedReplies.length - 1; i >= 0; i--) {
          if (updatedReplies[i].id.startsWith('temp_')) {
            updatedReplies[i] = newReply;
            break;
          }
        }
        return Comment(
          id: comment.id,
          username: comment.username,
          handle: comment.handle,
          profileImage: comment.profileImage,
          timeAgo: comment.timeAgo,
          content: comment.content,
          replies: updatedReplies,
        );
      }
      
      // Recursively check nested replies
      if (comment.replies.isNotEmpty) {
        return Comment(
          id: comment.id,
          username: comment.username,
          handle: comment.handle,
          profileImage: comment.profileImage,
          timeAgo: comment.timeAgo,
          content: comment.content,
          replies: _replaceTemporaryReply(comment.replies, newReply),
        );
      }
      
      return comment;
    }).toList();
  }

  List<Comment> _removeTemporaryComments(List<Comment> comments) {
    return comments.where((comment) => !comment.id.startsWith('temp_')).toList();
  }

  List<Comment> _removeTemporaryReplies(List<Comment> comments) {
    return comments.map((comment) => Comment(
      id: comment.id,
      username: comment.username,
      handle: comment.handle,
      profileImage: comment.profileImage,
      timeAgo: comment.timeAgo,
      content: comment.content,
      replies: comment.replies.where((reply) => !reply.id.startsWith('temp_')).toList(),
    )).toList();
  }

  void _handleOptimisticCommentAdd(String postId, Comment comment) {
    setState(() {
      // Add comment to cache optimistically
      _commentsCache[postId] = [...(_commentsCache[postId] ?? []), comment];
      
      // Increment comment count in post optimistically
      _posts = _posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(commentCount: post.commentCount + 1);
        }
        return post;
      }).toList();
    });
  }

  void _handleOptimisticReplyAdd(String postId, String commentId, Comment reply) {
    setState(() {
      // Add reply to the comment in cache optimistically
      _commentsCache[postId] = _addReplyToComment(
        _commentsCache[postId] ?? [],
        commentId,
        reply,
      );
    });
  }

  List<Comment> _addReplyToComment(List<Comment> comments, String commentId, Comment newReply) {
    return comments.map((comment) {
      if (comment.id == commentId) {
        return comment.copyWithReply(newReply);
      }
      if (comment.replies.isNotEmpty) {
        return Comment(
          id: comment.id,
          username: comment.username,
          handle: comment.handle,
          profileImage: comment.profileImage,
          timeAgo: comment.timeAgo,
          content: comment.content,
          replies: _addReplyToComment(comment.replies, commentId, newReply),
        );
      }
      return comment;
    }).toList();
  }

  void _handleCommentClick(String postId) async {
    if (!mounted) return;
    
    // Show modal immediately with skeleton loading
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Check if comments are already cached
          final bool isLoading = !_commentsCache.containsKey(postId);
          final List<Comment>? comments = _commentsCache[postId];
          
          // Load comments if not cached
          if (isLoading) {
            _loadCommentsForModal(postId, setModalState);
          }
          
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => CommentsBottomSheet(
              comments: comments,
              isLoading: isLoading,
              onAddComment: (content) async {
                await _handleAddComment(postId, content);
                setModalState(() {}); // Update modal state
              },
              onAddReply: (commentId, content) async {
                await _handleAddReply(postId, commentId, content);
                setModalState(() {}); // Update modal state
              },
              onOptimisticCommentAdd: (comment) {
                _handleOptimisticCommentAdd(postId, comment);
                setModalState(() {}); // Update modal state
              },
              onOptimisticReplyAdd: (commentId, reply) {
                _handleOptimisticReplyAdd(postId, commentId, reply);
                setModalState(() {}); // Update modal state
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadCommentsForModal(String postId, StateSetter setModalState) async {
    try {
      final comments = await _mutualFeedRepository.getPostComments(postId);
      setState(() {
        _commentsCache[postId] = comments;
      });
      // Update modal state to show loaded comments
      setModalState(() {});
    } catch (e) {
      print('Error loading comments: $e');
      // Show empty state on error
      setState(() {
        _commentsCache[postId] = [];
      });
      setModalState(() {});
    }
  }

  void _handleLikesClick(List<LikedByUser> likedByUsers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => LikesBottomSheet(
          likedByUsers: likedByUsers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _isLoading
          ? const SkeletonLoading()
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_profile != null)
                    CustomAppBar(
                      name: _profile!.name,
                      age: _profile!.age,
                      profileImageUrl: _profile!.profileImageUrl,
                    ),
                  if (_progress != null)
                    TodayProgressCard(
                      workoutsLeft: _progress!.workoutsLeft,
                      steps: _progress!.steps,
                      calsBurned: _progress!.calsBurned,
                      calsTaken: _progress!.calsTaken,
                      proteinTaken: _progress!.proteinTaken,
                    ),
                  TrackMutualsSection(
                    posts: _posts,
                    onLike: _handleLike,
                    onComment: _handleCommentClick,
                    onLikesClick: _handleLikesClick,
                  ),
                ],
              ),
            ),
    );
  }
}