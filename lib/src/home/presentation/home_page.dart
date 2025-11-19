import 'package:flutter/material.dart';
import '../../../widgets/app_bar.dart';
import '../data/profile_repository.dart';
import '../data/progress_repository.dart';
import '../data/mutual_feed_repository.dart';
import 'widgets/progress_card.dart';
import 'widgets/track_mutuals_section.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/comments_bottom_sheet.dart';
import 'widgets/skeleton_loading.dart';

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
    try {
      // Load comments if not cached
      if (!_commentsCache.containsKey(postId)) {
        final comments = await _mutualFeedRepository.getPostComments(postId);
        setState(() {
          _commentsCache[postId] = comments;
        });
      }
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) => CommentsBottomSheet(
                comments: _commentsCache[postId] ?? [],
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
    } catch (e) {
      print('Error loading comments: $e');
    }
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
                  ),
                ],
              ),
            ),
    );
  }
}