import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../widgets/app_bar.dart';
import '../../../route.dart';
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
import '../../../core/services/notification_service.dart';
import '../providers/user_profile_provider.dart';
import '../providers/feed_provider.dart';
import '../../nutrition/api/nutrition_service.dart'; // Added for nutrition delete

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProgressRepository _progressRepository = ProgressRepository();
  final PostWorkoutRepository _postWorkoutRepository = PostWorkoutRepository();
  final StoriesRepository _storiesRepository = StoriesRepository();

  ProgressCard? _progress;
  bool _isLoading = true;
  StreamSubscription<int>? _stepsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeStepTracking();
    NotificationService().requestPermissions();
  }

  Future<void> _loadData() async {
    try {
      // Load profile via provider
      final profileProvider = context.read<UserProfileProvider>();
      final feedProvider = context.read<FeedProvider>();

      await Future.wait([
        profileProvider.loadProfile(),
        feedProvider.loadFeed(),
        _loadProgress(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('HomePage: Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await _progressRepository.getTodayProgress();
      if (mounted) {
        setState(() {
          _progress = progress;
        });
      }
    } catch (e) {
      debugPrint('HomePage: Error loading progress: $e');
    }
  }

  Future<void> _onRefresh() async {
    final profileProvider = context.read<UserProfileProvider>();
    final feedProvider = context.read<FeedProvider>();

    await Future.wait([
      profileProvider.refreshProfile(),
      feedProvider.refreshFeed(),
      _loadProgress(),
    ]);
  }

  Future<void> _handleDeletePost(String postId) async {
    // Determine if it's a nutrition post or workout post
    final feedProvider = context.read<FeedProvider>();
    final post = feedProvider.posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw Exception('Post not found'),
    );

    if (post is NutritionPost) {
      await _handleDeleteNutritionPost(postId, post.sessionId);
    } else {
      await _handleDeleteWorkoutPost(postId);
    }
  }

  /// Delete a workout post
  Future<void> _handleDeleteWorkoutPost(String postId) async {
    try {
      await _postWorkoutRepository.deletePost(postId);
      if (mounted) {
        context.read<FeedProvider>().removePost(postId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
      }
    }
  }

  /// Delete a nutrition/meal post
  /// postId: The post ID for UI removal
  /// sessionId: The session ID for the API call
  Future<void> _handleDeleteNutritionPost(
    String postId,
    String sessionId,
  ) async {
    try {
      debugPrint(
        '🍽️ Deleting nutrition post: postId=$postId, sessionId=$sessionId',
      );
      await NutritionApiService().deleteSession(sessionId);
      if (mounted) {
        context.read<FeedProvider>().removePost(postId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meal deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete meal: $e')));
      }
    }
  }

  void _handleEditPost(FeedPost post) async {
    if (post is! WorkoutPost) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostWorkoutScreen(
          duration: 0,
          volume: 0,
          exercises: post.exercises
              .map((e) => {'name': e.name, 'image': e.imageUrl, 'sets': []})
              .toList(),
          postId: post.id,
          initialCaption: post.content,
          initialTags: post.tags,
        ),
      ),
    );

    if (result != null && result is Map) {
      final updatedCaption = result['caption'] as String;
      final updatedTags = result['tags'] as List<String>;

      final updatedPost = WorkoutPost(
        id: post.id,
        name: post.name,
        username: post.username,
        handle: post.handle,
        profileImage: post.profileImage,
        timeAgo: post.timeAgo,
        content: updatedCaption,
        tags: updatedTags,
        images: post.images,
        duration: post.duration,
        volume: post.volume,
        records: post.records,
        exercises: post.exercises,
        likes: post.likes,
        likedBy: post.likedBy,
        isLiked: post.isLiked,
        isOwnPost: post.isOwnPost,
        commentCount: post.commentCount,
      );

      context.read<FeedProvider>().updatePost(updatedPost);
    }
  }

  void _handleLike(String postId) {
    context.read<FeedProvider>().toggleLike(postId);
  }

  void _handleCommentClick(String postId) {
    final feedProvider = context.read<FeedProvider>();
    final post = feedProvider.posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw Exception('Post not found'),
    );
    final isMeal = post is NutritionPost;

    // Start loading comments immediately
    feedProvider.loadComments(postId, isMeal: isMeal);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Consumer<FeedProvider>(
        builder: (sheetContext, feedProv, child) {
          final comments = feedProv.getComments(postId);
          final isLoading = feedProv.isCommentsLoading(postId);
          final profile = context.read<UserProfileProvider>().profile;

          return CommentsBottomSheet(
            comments: comments,
            isLoading: isLoading,
            onAddComment: (content) async {
              if (profile != null) {
                await feedProv.addComment(
                  postId,
                  content,
                  profile,
                  isMeal: isMeal,
                );
              }
            },
            onAddReply: (commentId, content) async {
              if (profile != null) {
                await feedProv.addReply(
                  postId,
                  commentId,
                  content,
                  profile,
                  isMeal: isMeal,
                );
              }
            },
            onOptimisticCommentAdd: (comment) {},
            onOptimisticReplyAdd: (commentId, reply) {},
            currentUserProfile: profile,
          );
        },
      ),
    );
  }

  void _handleLikesClick(String postId) {
    final feedProvider = context.read<FeedProvider>();
    final post = feedProvider.posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw Exception('Post not found'),
    );
    final isMeal = post is NutritionPost;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) =>
            LikesBottomSheet(postId: postId, isMeal: isMeal),
      ),
    );
  }

  Future<void> _initializeStepTracking() async {
    try {
      await _progressRepository.startStepTracking();

      _stepsSubscription = _progressRepository.stepsStream.listen((
        steps,
      ) async {
        if (mounted && _progress != null) {
          final targets = await _progressRepository.getTargets();
          final stepsProgress = (steps / (targets['steps'] ?? 10000)).clamp(
            0.0,
            1.0,
          );
          final calsBurned = _calculateCaloriesBurned(steps);
          final calsBurnedProgress =
              (calsBurned / (targets['cals_burned'] ?? 500)).clamp(0.0, 1.0);

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
              streak: _progress!.streak,
              breakDaysUsed: _progress!.breakDaysUsed,
              maxBreakDays: _progress!.maxBreakDays,
              targets: targets,
            );
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing step tracking: $e');
    }
  }

  int _calculateCaloriesBurned(int steps) {
    if (steps <= 0) return 0;
    const double caloriesPerStep = 0.04;
    return (steps * caloriesPerStep).round();
  }

  Future<void> _handleTargetUpdate(String targetType, int newTarget) async {
    try {
      final success = await _progressRepository.updateTarget(
        targetType,
        newTarget,
      );
      if (success && mounted) {
        final updatedProgress = await _progressRepository.getTodayProgress();
        setState(() {
          _progress = updatedProgress;
        });
      } else {
        throw Exception('Failed to update target');
      }
    } catch (e) {
      debugPrint('Error updating target: $e');
      rethrow;
    }
  }

  Future<void> _handleStoryTap() async {
    try {
      final myStory = await _storiesRepository.getMyStories();
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyStoryViewer(myStory: myStory),
        ),
      );
      if (mounted) {
        _onRefresh(); // Refresh data to reflect deletions
      }
    } catch (e) {
      debugPrint('Failed to open story: $e');
    }
  }

  @override
  void dispose() {
    _stepsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProfileProvider, FeedProvider>(
      builder: (context, profileProvider, feedProvider, child) {
        final profile = profileProvider.profile;
        final posts = feedProvider.posts;
        final isProviderLoading =
            profileProvider.isLoading || feedProvider.isLoading;

        return Scaffold(
          backgroundColor: AppColors.black,
          body: (_isLoading || isProviderLoading) && profile == null
              ? const SkeletonLoading()
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  backgroundColor: AppColors.black100,
                  color: const Color(0xFFD4FC79),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        if (profile != null)
                          CustomAppBar(
                            name: profile.name,
                            age: profile.age,
                            profileImageUrl: profile.profileImageUrl,
                            hasStory: profile.hasStory,
                            onProfileTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.profile,
                                arguments: profile.username,
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
                            proteinTakenProgress:
                                _progress!.proteinTakenProgress,
                            onTargetUpdate: _handleTargetUpdate,
                            onRefresh: _onRefresh,
                            actualSteps: _progress!.actualSteps,
                            actualCalsBurned: _progress!.actualCalsBurned,
                            actualCalsTaken: _progress!.actualCalsTaken,
                            actualProteinTaken: _progress!.actualProteinTaken,
                            streak: _progress!.streak,
                            breakDaysUsed: _progress!.breakDaysUsed,
                            maxBreakDays: _progress!.maxBreakDays,
                            targets: _progress!.targets,
                          ),
                        TrackMutualsSection(
                          posts: posts,
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
      },
    );
  }
}
