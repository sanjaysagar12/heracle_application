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
        // Add comment to cache
        _commentsCache[postId] = [...(_commentsCache[postId] ?? []), newComment];
        
        // Increment comment count in post
        _posts = _posts.map((post) {
          if (post.id == postId) {
            return post.copyWith(commentCount: post.commentCount + 1);
          }
          return post;
        }).toList();
      });
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  Future<void> _handleAddReply(String postId, String commentId, String content) async {
    try {
      final newReply = await _mutualFeedRepository.addReply(postId, commentId, content);
      
      setState(() {
        // Add reply to the comment in cache
        _commentsCache[postId] = _addReplyToComment(
          _commentsCache[postId] ?? [],
          commentId,
          newReply,
        );
      });
    } catch (e) {
      print('Error adding reply: $e');
    }
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