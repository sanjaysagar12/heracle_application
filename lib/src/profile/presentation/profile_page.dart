import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../data/profile_repository.dart';
import '../../home/data/profile_repository.dart' as home_repo;
import '../widgets/profile_header.dart';
import '../widgets/profile_tab_bar.dart';
import '../widgets/highlight_grid.dart';
import '../widgets/profile_skeleton.dart';
import '../../feed/data/stories_repository.dart';
import '../../feed/presentation/tab/reels_tab.dart';
import 'connections_page.dart';
import '../../workout/widgets/sessions_section.dart';
import '../../workout/data/session_repository.dart';
import '../../home/data/mutual_feed_repository.dart';
import '../../home/widgets/comments_bottom_sheet.dart';
import '../../home/widgets/likes_bottom_sheet.dart';
import '../../home/widgets/workout_post_card.dart';
import '../../home/widgets/nutrition_post_card.dart';
import '../../workout/data/post_workout_repository.dart';
import '../../workout/presentation/tab/post_workout_screen.dart';
import 'edit_profile_page.dart';
import '../data/profile_session_repository.dart';
import 'settings_page.dart';
import '../../home/providers/feed_provider.dart';
import '../../nutrition/api/nutrition_service.dart'; // Added for nutrition delete

class ProfilePage extends StatefulWidget {
  final String? username;
  const ProfilePage({super.key, this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileRepository _repository = ProfileRepository();
  final PostWorkoutRepository _postWorkoutRepository = PostWorkoutRepository();
  final ProfileSessionRepository _profileSessionRepository =
      ProfileSessionRepository();

  UserProfile? _profile;
  List<Session> _sessions = [];
  List<DiscoverStory> _discoverStories = [];

  bool _isLoading = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _targetUsername => widget.username ?? '@sanjaysagar';

  Future<void> _loadData() async {
    try {
      // 1. Get profile first
      final profile = await _repository.getUserProfile(_targetUsername);

      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }

      // 2. Load user posts via FeedProvider
      if (mounted) {
        context.read<FeedProvider>().loadUserPosts(_targetUsername);
      }

      // 3. Fetch other data in parallel
      final results = await Future.wait([
        _repository
            .getUserFeed(profile.id)
            .catchError((_) => <DiscoverStory>[]),
        _repository
            .getSessions(username: _targetUsername)
            .catchError((_) => <Session>[]),
      ]);

      if (mounted) {
        setState(() {
          _discoverStories = results[0] as List<DiscoverStory>;
          _sessions = results[1] as List<Session>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (_profile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _onFollowTap() {
    if (_profile != null) {
      final oldProfile = _profile;
      setState(() {
        _profile = _repository.toggleFollow(_profile!);
      });

      _repository.followUser(_profile!.username).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update follow status: $e')),
          );
          setState(() {
            _profile = oldProfile;
          });
        }
      });
    }
  }

  void _onEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage()),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _handleSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          name: _profile?.name,
          email: FirebaseAuth.instance.currentUser?.email,
          uid: FirebaseAuth.instance.currentUser?.uid,
        ),
      ),
    );
  }

  List<DiscoverStory> _handleReelLike(String storyId) {
    setState(() {
      _discoverStories = _discoverStories.map((story) {
        if (story.id == storyId) {
          final newIsLiked = !story.isLiked;
          final newLikesCount = newIsLiked
              ? story.likesCount + 1
              : story.likesCount - 1;
          return story.copyWith(isLiked: newIsLiked, likesCount: newLikesCount);
        }
        return story;
      }).toList();
    });
    return _discoverStories;
  }

  void _handleLike(String postId) {
    context.read<FeedProvider>().toggleLike(postId, username: _targetUsername);
  }

  /// Delete a workout post
  Future<void> _handleDeleteWorkoutPost(String postId) async {
    try {
      await _postWorkoutRepository.deletePost(postId);
      if (mounted) {
        context.read<FeedProvider>().removePost(
          postId,
          username: _targetUsername,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Workout deleted')));
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
        context.read<FeedProvider>().removePost(
          postId, // Use postId for UI removal
          username: _targetUsername,
        );
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

      context.read<FeedProvider>().updatePost(
        updatedPost,
        username: _targetUsername,
      );
    }
  }

  void _handleCommentClick(String postId) {
    final feedProvider = context.read<FeedProvider>();
    final posts = feedProvider.getUserPosts(_targetUsername);
    final post = posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw Exception('Post not found'),
    );
    final isMeal = post is NutritionPost;

    // Start loading comments immediately
    feedProvider.loadComments(postId, isMeal: isMeal);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Consumer<FeedProvider>(
          builder: (sheetContext, feedProv, child) {
            final comments = feedProv.getComments(postId);
            final isLoading = feedProv.isCommentsLoading(postId);

            // Convert to home_repo.Profile for CommentsBottomSheet
            home_repo.Profile? userProfile;
            if (_profile != null) {
              userProfile = home_repo.Profile(
                name: _profile!.name,
                username: _profile!.username,
                age: 0,
                profileImageUrl: _profile!.profileImageUrl,
                hasStory: _profile!.hasStory,
              );
            }

            return CommentsBottomSheet(
              comments: comments,
              isLoading: isLoading,
              onAddComment: (content) async {
                if (userProfile != null) {
                  await feedProv.addComment(
                    postId,
                    content,
                    userProfile,
                    isMeal: isMeal,
                    username: _targetUsername,
                  );
                }
              },
              onAddReply: (commentId, content) async {
                if (userProfile != null) {
                  await feedProv.addReply(
                    postId,
                    commentId,
                    content,
                    userProfile,
                    isMeal: isMeal,
                  );
                }
              },
              onDeleteComment: (commentId) async {
                return await feedProv.deleteComment(
                  postId,
                  commentId,
                  isMeal: isMeal,
                  username: _targetUsername,
                );
              },
              onOptimisticCommentAdd: (comment) {},
              onOptimisticReplyAdd: (commentId, reply) {},
              currentUserProfile: userProfile,
              postOwnerUsername: post.username,
              isPostOwner: post.isOwnPost || (_profile?.isViewer ?? false),
            );
          },
        ),
      ),
    );
  }

  void _handleLikesClick(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) =>
            LikesBottomSheet(postId: postId),
      ),
    );
  }

  void _onHighlightTap(DiscoverStory highlight) {
    final index = _discoverStories.indexWhere((h) => h.id == highlight.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReelsTab(
          stories: _discoverStories,
          initialIndex: index >= 0 ? index : 0,
          onLike: _handleReelLike,
          onStoryViewed: (storyId) {
            setState(() {
              _discoverStories = _discoverStories.map((story) {
                if (story.id == storyId) {
                  return story.copyWith(isViewed: true);
                }
                return story;
              }).toList();
            });
          },
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await _loadData();
    if (mounted) {
      await context.read<FeedProvider>().refreshUserPosts(_targetUsername);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, child) {
        final posts = feedProvider.getUserPosts(_targetUsername);

        return Scaffold(
          backgroundColor: AppColors.black,
          body: _isLoading
              ? const ProfileSkeleton()
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppColors.primary,
                  backgroundColor: AppColors.greyDark,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        if (_profile != null)
                          Stack(
                            children: [
                              ProfileHeader(
                                profile: _profile!,
                                onFollowTap: _profile!.isViewer
                                    ? null
                                    : _onFollowTap,
                                onEditTap: _profile!.isViewer
                                    ? _onEditProfile
                                    : null,
                                onFollowersTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ConnectionsPage(
                                        initialIndex: 0,
                                        username: _profile!.username,
                                      ),
                                    ),
                                  );
                                },
                                onFollowingTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ConnectionsPage(
                                        initialIndex: 1,
                                        username: _profile!.username,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                top: MediaQuery.of(context).size.height * 0.05,
                                left: 12,
                                child: Material(
                                  color: Colors.black38,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SvgPicture.asset(
                                        'assets/icons/back.svg',
                                        width: 22,
                                        height: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_profile!.isViewer)
                                Positioned(
                                  top:
                                      MediaQuery.of(context).size.height * 0.05,
                                  right: 12,
                                  child: Material(
                                    color: Colors.black38,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _handleSettings,
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.settings_outlined,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ProfileTabBar(
                          selectedIndex: _selectedTabIndex,
                          onTabSelected: _onTabSelected,
                        ),
                        _buildTabContent(posts),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildTabContent(List<FeedPost> posts) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildHighlightsTab();
      case 1:
        return _buildSessionsTab();
      case 2:
        return _buildPostsTab(posts);
      default:
        return _buildHighlightsTab();
    }
  }

  Widget _buildHighlightsTab() {
    return Column(
      children: [
        HighlightGrid(
          highlights: _discoverStories,
          onHighlightTap: _onHighlightTap,
        ),
      ],
    );
  }

  Widget _buildSessionsTab() {
    return SessionsSection(
      sessions: _sessions,
      isViewOnly: !_profile!.isViewer,
      repository: _profileSessionRepository,
      onRefreshData: _loadData,
    );
  }

  Widget _buildPostsTab(List<FeedPost> posts) {
    if (posts.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(40),
        child: const Text(
          'No posts yet',
          style: TextStyle(color: AppColors.white60, fontSize: 16),
        ),
      );
    }

    return Column(
      children: posts.map<Widget>((originalPost) {
        final post = (_profile?.isViewer ?? false)
            ? originalPost.copyWith(isOwnPost: true)
            : originalPost;

        if (post is WorkoutPost) {
          return WorkoutPostCard(
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
            likes: post.likes,
            likedBy: post.likedBy,
            isLiked: post.isLiked,
            commentCount: post.commentCount,
            onLike: () => _handleLike(post.id),
            onComment: () => _handleCommentClick(post.id),
            onLikesClick: () => _handleLikesClick(post.id),
            onDelete: () => _handleDeleteWorkoutPost(post.id),
            onEdit: () => _handleEditPost(post),
            isOwnPost: post.isOwnPost,
          );
        } else if (post is NutritionPost) {
          return NutritionPostCard(
            post: post,
            onLike: () => _handleLike(post.id),
            onComment: () => _handleCommentClick(post.id),
            onLikesClick: () => _handleLikesClick(post.id),
            onDelete: () => _handleDeleteNutritionPost(post.id, post.sessionId),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}
