import 'package:flutter/material.dart';
import 'dart:async';

import '../../../widgets/app_bar.dart';
import '../../../route.dart';
import '../data/profile_repository.dart';
import '../data/progress_repository.dart';
import '../data/mutual_feed_repository.dart';
import '../widgets/progress_card.dart';
import '../widgets/track_mutuals_section.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/likes_bottom_sheet.dart';
import '../../workout/data/post_workout_repository.dart';
import '../../workout/presentation/tab/post_workout_screen.dart';
import '../../feed/data/stories_repository.dart';
import '../../feed/presentation/tab/my_story_viewer.dart';
import '../widgets/workout_post_card.dart'; // Ensure this is imported if not already relative, wait, line 16 is imports. 
import '../widgets/nutrition_post_card.dart';
import '../../../core/services/notification_service.dart';
import '../widgets/daily_macro_chart.dart'; // Added

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final ProgressRepository _progressRepository = ProgressRepository();
  final MutualFeedRepository _mutualFeedRepository = MutualFeedRepository();
  final PostWorkoutRepository _postWorkoutRepository = PostWorkoutRepository(); // Added
  final StoriesRepository _storiesRepository = StoriesRepository();
  Profile? _profile;
  ProgressCard? _progress;
  Map<String, double>? _todayNutrition; // Added
  List<FeedPost> _posts = [];
  bool _isLoading = true;
  Map<String, List<Comment>> _commentsCache = {};
  final Map<String, bool> _loadingComments = {}; // Added missing variable
  StreamSubscription<int>? _stepsSubscription;

  // Add a set to track like requests in progress
  final Set<String> _likeInProgress = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeStepTracking();
    NotificationService().requestPermissions();
  }

  // ... (keeping existing methods)

  Future<void> _handleDeletePost(String postId) async {
    try {
      await _postWorkoutRepository.deletePost(postId);
      setState(() {
        _posts.removeWhere((p) => p.id == postId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e')),
        );
      }
    }
  }

  void _handleEditPost(FeedPost post) async {
    if (post is! WorkoutPost) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostWorkoutScreen(
          duration: 0, // Placeholder as we don't have int duration in WorkoutPost
          volume: 0, // Placeholder
          exercises: post.exercises.map((e) => {
            'name': e.name,
            'image': e.imageUrl,
            'sets': [], // No set details in feed
          }).toList(),
          postId: post.id,
          initialCaption: post.content,
          initialTags: post.tags,
        ),
      ),
    );


    // result is now a Map or null if cancelled (or true/false from other paths if any, but we expect Map)
    if (result != null && result is Map) {
      final updatedCaption = result['caption'] as String;
      final updatedTags = result['tags'] as List<String>;

      setState(() {
        _posts = _posts.map((p) {
          if (p.id == post.id && p is WorkoutPost) { // Update only target post
             // Since WorkoutPost is immutable and doesn't have a copyWith for specific fields like caption/tags in the abstract class easily or custom copyWith:
             // We need to cast and use copyWith or create new instance. 
             // Let's check WorkoutPost definition in mutual_feed_repository.dart. 
             // It calls super with content. copyWith in WorkoutPost takes content? 
             // Let's verify WorkoutPost copyWith.
             
             // Wait, WorkoutPost.copyWith signature:
             // WorkoutPost copyWith({bool? isLiked, int? likes, int? commentCount})
             // It does NOT support changing content or tags!
             
             // I need to update WorkoutPost to support full copyWith or reconstruct it.
             // For now, I will reconstruct it manually here or update the repo model first.
             // Better to update the repo model to allow full copyWith.
             
             // BUT, I can't update repo model in this step easily without context switch.
             // Let's assum "copyWith" is limited.
             // I will create a new WorkoutPost instance.
             return WorkoutPost(
              id: p.id,
              username: p.username,
              handle: p.handle,
              profileImage: p.profileImage,
              timeAgo: p.timeAgo,
              content: updatedCaption, // Updated
              tags: updatedTags, // Updated
              images: p.images,
              duration: p.duration,
              volume: p.volume,
              records: p.records,
              exercises: p.exercises,
              likes: p.likes,
              likedBy: p.likedBy,
              isLiked: p.isLiked,
              isOwnPost: p.isOwnPost,
              commentCount: p.commentCount,
             );
          }
          return p;
        }).toList();
      });
      
      // Still reload data in background to be safe
      _loadData(); 
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _isLoading
          ? const SkeletonLoading()
          : RefreshIndicator(
              onRefresh: _loadData,
              backgroundColor: AppColors.black100,
              color: const Color(0xFFD4FC79),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // Ensure scroll even if content is short
                child: Column(
                  children: [
                    if (_profile != null)
                      CustomAppBar(
                        name: _profile!.name,
                        age: _profile!.age,
                        profileImageUrl: _profile!.profileImageUrl,
                        hasStory: _profile!.hasStory,
                        onProfileTap: () {
                          Navigator.pushNamed(
                            context, 
                            AppRoutes.profile,
                            arguments: _profile!.username,
                          );
                        },
                        onStoryTap: _handleStoryTap,
                      ),
                    if (_progress != null)
                      TodayProgressCard(
                        workoutsLeft: _progress!.workoutsLeft,
                        steps: _progress!.steps,
                        calsBurned: _progress!.calsBurned,
                        calsTaken: _progress!.calsTaken,
                        proteinTaken: _progress!.proteinTaken,
                        stepsProgress: _progress!.stepsProgress,
                        calsBurnedProgress: _progress!.calsBurnedProgress,
                        calsTakenProgress: _progress!.calsTakenProgress,
                        proteinTakenProgress: _progress!.proteinTakenProgress,
                        onTargetUpdate: _handleTargetUpdate,
                        onRefresh: _loadData, // Pass refresh callback
                        actualSteps: _progress!.actualSteps,
                        actualCalsBurned: _progress!.actualCalsBurned,
                        actualCalsTaken: _progress!.actualCalsTaken,
                        actualProteinTaken: _progress!.actualProteinTaken,
                        targets: _progress!.targets,
                      ),
                    if (_todayNutrition != null)
                      DailyMacroChart(
                        protein: _todayNutrition!['protein'] ?? 0,
                        carbs: _todayNutrition!['carbs'] ?? 0,
                        fat: _todayNutrition!['fat'] ?? 0,
                        fiber: _todayNutrition!['fiber'] ?? 0,
                      ),
                    TrackMutualsSection(
                      posts: _posts,
                      onLike: _handleLike,
                      onComment: _handleCommentClick,
                      onLikesClick: _handleLikesClick,
                      onDeletePost: _handleDeletePost,
                      onEditPost: _handleEditPost,
                    ),
                  ],
                ),
              ),
            ),
    );
  }



  Future<void> _initializeStepTracking() async {
    try {
      // Start step tracking
      await _progressRepository.startStepTracking();
      
      // Listen to step updates
      _stepsSubscription = _progressRepository.stepsStream.listen((steps) async {
        if (mounted && _progress != null) {
          // Get current targets to recalculate progress
          final targets = await _progressRepository.getTargets();
          final stepsProgress = (steps / (targets['steps'] ?? 10000)).clamp(0.0, 1.0);
          
          // Calculate calories burned based on steps
          final calsBurned = _calculateCaloriesBurned(steps);
          final calsBurnedProgress = (calsBurned / (targets['cals_burned'] ?? 500)).clamp(0.0, 1.0);
          
          setState(() {
            _progress = ProgressCard(
              workoutsLeft: _progress!.workoutsLeft,
              steps: ProgressCard.formatNumber(steps),
              calsBurned: ProgressCard.formatNumber(calsBurned),
              calsTaken: _progress!.calsTaken,
              proteinTaken: _progress!.proteinTaken,
              stepsProgress: stepsProgress,
              calsBurnedProgress: calsBurnedProgress,
              calsTakenProgress: _progress!.calsTakenProgress,
              proteinTakenProgress: _progress!.proteinTakenProgress,
              actualSteps: steps,
              actualCalsBurned: calsBurned,
              actualCalsTaken: _progress!.actualCalsTaken,
              actualProteinTaken: _progress!.actualProteinTaken,
              targets: targets,
            );
          });
        }
      });
    } catch (e) {
      print('Error initializing step tracking: $e');
    }
  }

  /// Calculate calories burned based on steps
  /// Using the same formula as in ProgressRepository
  int _calculateCaloriesBurned(int steps) {
    if (steps <= 0) return 0;
    const double caloriesPerStep = 0.04;
    return (steps * caloriesPerStep).round();
  }

  Future<void> _loadData() async {
    try {
      print('HomePage: Starting to load data...');
      
      final results = await Future.wait([
        _profileRepository.getProfile(),
        _progressRepository.getTodayProgress(),
        _mutualFeedRepository.getMutualFeed(),
        _progressRepository.getTodayNutrition(), // Added
      ]);

      print('HomePage: Data loaded successfully');
      print('Profile: ${results[0]}');
      print('Progress: ${results[1]}');
      print('Posts count: ${(results[2] as List).length}');

      setState(() {
        _profile = results[0] as Profile;
        _progress = results[1] as ProgressCard;
        _posts = results[2] as List<FeedPost>;
        _todayNutrition = results[3] as Map<String, double>; // Added
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('HomePage: Error loading data: $e');
      print('StackTrace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Replace the old _handleLike with this async version that does optimistic update
  Future<void> _handleLike(String postId) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final isMeal = post is NutritionPost;
    final isLiked = post.isLiked;

    // Optimistic update
    setState(() {
      final updatedPost = post.copyWith(
        isLiked: !isLiked,
        likes: isLiked ? post.likes - 1 : post.likes + 1,
      );
      _posts[postIndex] = updatedPost;
    });

    try {
      await _mutualFeedRepository.likePost(postId, isMeal: isMeal);
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _posts[postIndex] = post;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like post: $e')),
        );
      }
    }
  }

  void _handleCommentClick(String postId) {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;
    
    final post = _posts[postIndex];
    final isMeal = post is NutritionPost;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final comments = _commentsCache[postId] ?? [];
          final bool isLoading = _loadingComments[postId] ?? false;

          // If not loaded and not loading, trigger load
          if (!_commentsCache.containsKey(postId) && !isLoading) {
            // We need to trigger load, but we can't await here directly in build
            // Use post frame callback or just call it (it handles async)
            // But we need to pass setModalState to it so it can update this sheet.
            // Or better: define a local load function or modify _loadComments
            
            // Calling _loadCommentsAndRefreshSheet here
            WidgetsBinding.instance.addPostFrameCallback((_) {
               _loadCommentsAndRefreshSheet(postId, isMeal, setModalState);
            });
          }

          return CommentsBottomSheet(
            comments: comments,
            isLoading: isLoading,
            onAddComment: (content) async {
              await _handleAddComment(postId, content, isMeal: isMeal);
              setModalState(() {});
            },
            onAddReply: (commentId, content) async {
              await _handleAddReply(postId, commentId, content, isMeal: isMeal);
              setModalState(() {});
            },
            onOptimisticCommentAdd: (comment) {
              _handleOptimisticCommentAdd(postId, comment);
              setModalState(() {});
            },
            onOptimisticReplyAdd: (commentId, reply) {
              _handleOptimisticReplyAdd(postId, commentId, reply);
              setModalState(() {});
            },
            currentUserProfile: _profile,
          );
        },
      ),
    );
  }

  Future<void> _loadCommentsAndRefreshSheet(String postId, bool isMeal, StateSetter setModalState) async {
    // Check if already loading to prevent loop if logic above isn't strict
    if (_loadingComments[postId] == true) return;

    setState(() {
      _loadingComments[postId] = true;
    });
    setModalState(() {});

    try {
      final comments = await _mutualFeedRepository.getComments(postId, isMeal: isMeal);
      if (mounted) {
        setState(() {
          _commentsCache[postId] = comments;
          _loadingComments[postId] = false;
        });
        setModalState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingComments[postId] = false;
        });
        setModalState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load comments: $e')));
      }
    }
  }



  Future<void> _handleAddComment(String postId, String content, {bool isMeal = false}) async {
    final currentUser = _profile ?? await _profileRepository.getProfile();
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

    _handleOptimisticCommentAdd(postId, tempComment);

    try {
      final newComment = await _mutualFeedRepository.addComment(postId, content, isMeal: isMeal);
      
      setState(() {
        // Replace temporary comment with real comment from API
        _commentsCache[postId] = _replaceTemporaryComment(
          _commentsCache[postId] ?? [],
          newComment,
        );
        
        // Update comment count on post
        final postIndex = _posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
           final post = _posts[postIndex];
           _posts[postIndex] = post.copyWith(commentCount: post.commentCount + 1);
        }
      });
    } catch (e) {
      // Remove temporary comment on error
      setState(() {
        _commentsCache[postId] = _removeTemporaryComments(_commentsCache[postId] ?? []);
      });
      rethrow; 
    }
  }

  Future<void> _handleAddReply(String postId, String commentId, String content, {bool isMeal = false}) async {
    try {
      final newReply = await _mutualFeedRepository.addReply(postId, commentId, content, isMeal: isMeal);
      
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
      rethrow; 
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



  void _handleLikesClick(String postId) {
    // Open sheet immediately (sheet shows skeleton while fetching)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => LikesBottomSheet(
          postId: postId,
        ),
      ),
    );
  }

  Future<void> _handleTargetUpdate(String targetType, int newTarget) async {
    try {
      final success = await _progressRepository.updateTarget(targetType, newTarget);
      if (success && mounted) {
        // Reload progress data to reflect new targets
        final updatedProgress = await _progressRepository.getTodayProgress();
        setState(() {
          _progress = updatedProgress;
        });
      } else {
        throw Exception('Failed to update target');
      }
    } catch (e) {
      print('Error updating target: $e');
      rethrow;
    }
  }

  Future<void> _handleStoryTap() async {
    try {
      final myStory = await _storiesRepository.getMyStories();
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyStoryViewer(myStory: myStory),
        ),
      );
    } catch (e) {
      print('Failed to open story: $e');
    }
  }



  @override
  void dispose() {
    _stepsSubscription?.cancel();
    super.dispose();
  }
}